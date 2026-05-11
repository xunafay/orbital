{ config, ... }:
{
  # clan.core.vars.generators."hannah-ssh-key" = {
  #   share = true;
  #   files."id_rsa" = {
  #     secret = true;
  #     neededFor = "users";
  #     owner = "hannah";
  #     group = "hannah";
  #     # mode = "0600";
  #   };
  #   files."id_rsa.pub" = {
  #     secret = false;
  #     neededFor = "users";
  #     owner = "hannah";
  #     group = "hannah";
  #     # mode = "0644";
  #   };
  #   prompts."id_rsa" = {
  #     description = "Hannah's private SSH key";
  #     type = "multiline";
  #   };
  #   prompts."id_rsa.pub" = {
  #     description = "Hannah's public SSH key";
  #     type = "line";
  #   };
  #   script = ''
  #     cp $prompts/id_rsa $out/id_rsa
  #     cp $prompts/id_rsa.pub $out/id_rsa.pub
  #   '';
  # };

  # FIXME: this doesn't work because the files are owned by root, and the secret generator doesn't seem to apply the user/group
  # home-manager.users.hannah.home.activation.sshKey =
  #   config.home-manager.users.hannah.lib.dag.entryAfter [ "writeBoundary" ] ''
  #     install -d -m 700 $HOME/.ssh
  #     install -m 600 \
  #       ${config.clan.core.vars.generators."hannah-ssh-key".files."id_rsa".path} \
  #       $HOME/.ssh/id_rsa
  #     install -m 644 \
  #       ${config.clan.core.vars.generators."hannah-ssh-key".files."id_rsa.pub".path} \
  #       $HOME/.ssh/id_rsa.pub
  #   '';
}
