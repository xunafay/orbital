{ lib, inventory, pkgs, nixosConfigs }:
let
  machinesForTags = tags:
    lib.filterAttrs (_: machine:
      builtins.any (tag:
        tag == "all" || builtins.elem tag machine.tags
      ) tags
    ) inventory.machines;

  mkDeployScript = name: machine:
    let
      targetHost = machine.deploy.targetHost
        or (abort "machine '${name}' has no deploy.targetHost");
      targetPort = toString(machine.deploy.targetPort or 22);
      buildHost  = machine.deploy.buildHost or null;
      buildFlags = lib.optionalString (buildHost != null) "--build-host ${buildHost}";
    in
    pkgs.writeShellApplication {
      name = "deploy-${name}";
      runtimeInputs = [ pkgs.openssh pkgs.nixos-rebuild ];
      text = ''
        set -euo pipefail
        echo "==> Deploying ${name} to ${targetHost}"

        export NIX_SSHOPTS="-p ${targetPort}"
        nixos-rebuild switch \
          --flake ".#${name}" \
          --target-host "${targetHost}" \
          ${buildFlags} \
          || {
            echo "==> Failed — attempting rollback on ${targetHost}..."
            ssh "${targetHost}" "nixos-rebuild --rollback switch" || true
            echo "==> Rollback attempted. Check the machine."
            exit 1
          }

        echo "==> Done."
      '';
    };

  mkDeployTagScript = tag:
    let
      targets = builtins.attrNames (machinesForTags [ tag ]);
    in
    pkgs.writeShellApplication {
      name = "deploy-tag-${tag}";
      text = ''
        set -euo pipefail
        echo "==> Deploying tag [${tag}]: ${lib.concatStringsSep ", " targets}"
        ${lib.concatMapStringsSep "\n" (n: "nix run .#deploy-${n}") targets}
      '';
    };

  deployScripts = lib.mapAttrs mkDeployScript inventory.machines;

  allTags = lib.unique (
    lib.concatLists (
      lib.mapAttrsToList (_: m: m.tags) inventory.machines
    )
  );

  tagScripts = builtins.listToAttrs (
    map (tag: {
      name  = "deploy-tag-${tag}";
      value = mkDeployTagScript tag;
    }) allTags
  );
in
{
  apps =
    lib.mapAttrs' (name: script: {
      name  = "deploy-${name}";
      value = { type = "app"; program = "${script}/bin/deploy-${name}"; };
    }) deployScripts
    //
    lib.mapAttrs' (name: script: {
      name  = name;
      value = { type = "app"; program = "${script}/bin/${name}"; };
    }) tagScripts;
}
