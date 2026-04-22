set -euo pipefail

MACHINE="${1:-}"
if [ -z "$MACHINE" ]; then
  echo "Usage: generate <machine>"
  echo "Known machines:"
  for m in $KNOWN_MACHINES; do echo "  - $m"; done
  exit 1
fi

VALID=0
for m in $KNOWN_MACHINES; do [ "$m" = "$MACHINE" ] && VALID=1 && break; done
[ "$VALID" -eq 0 ] && echo "Unknown machine: $MACHINE" && exit 1

REPO_ROOT="$(git rev-parse --show-toplevel)"
KEYS_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"
ADMIN_AGE_KEY=$(grep -i 'public key:' "$KEYS_FILE" | awk '{print $NF}')
MACHINE_AGE_KEY=$(cat "$REPO_ROOT/secrets/machines/$MACHINE/age.pub")

echo "==> Running generators for $MACHINE..."

declare -A VISITED
ORDERED=()
GENERATORS_LIST=$(echo "$GENERATORS_JSON" | jq -r 'keys[]')
MAX_PASSES=$(echo "$GENERATORS_LIST" | wc -l)

for _ in $(seq 1 "$MAX_PASSES"); do
  while IFS= read -r name; do
    [ "${VISITED[$name]:-}" = "1" ] && continue
    deps=$(echo "$GENERATORS_JSON" | jq -r --arg n "$name" '.[$n].dependencies[]')
    all_done=1
    while IFS= read -r dep; do
      [ -z "$dep" ] && continue
      [ "${VISITED[$dep]:-}" != "1" ] && all_done=0 && break
    done <<< "$deps"
    if [ "$all_done" -eq 1 ]; then
      ORDERED+=("$name")
      VISITED[$name]=1
    fi
  done <<< "$GENERATORS_LIST"
done

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

for name in "${ORDERED[@]}"; do
  echo ""
  echo "=> Generator: $name"
  gen=$(echo "$GENERATORS_JSON" | jq -c --arg n "$name" '.[$n]')
  script=$(echo "$gen" | jq -r '.script')

  out="$WORK/out/$name"
  mkdir -p "$out"

  in="$WORK/in/$name"
  mkdir -p "$in"

  # populate $in from deps
  while IFS= read -r dep; do
    [ -z "$dep" ] && continue
    mkdir -p "$in/$dep"
    echo "$GENERATORS_JSON" | jq -c --arg d "$dep" '.[$d].files | to_entries[]' | while read -r entry; do
      fname=$(echo "$entry"  | jq -r '.key')
      secret=$(echo "$entry" | jq -r '.value.secret')
      shared=$(echo "$entry" | jq -r '.value.shared')

      if [ "$secret" = "true" ]; then
        if [ "$shared" = "true" ]; then
          yaml="$REPO_ROOT/secrets/shared/$dep/$fname.yaml"
        else
          yaml="$REPO_ROOT/secrets/machines/$MACHINE/$dep/$fname.yaml"
        fi
        [ -f "$yaml" ] && SOPS_AGE_KEY_FILE="$KEYS_FILE" \
          sops decrypt --input-type yaml --output-type binary "$yaml" > "$in/$dep/$fname"
      else
        if [ "$shared" = "true" ]; then
          plain="$REPO_ROOT/vars/shared/$dep/$fname"
        else
          plain="$REPO_ROOT/vars/$MACHINE/$dep/$fname"
        fi
        [ -f "$plain" ] && cp "$plain" "$in/$dep/$fname"
      fi
    done
  done <<< "$(echo "$gen" | jq -r '.dependencies[]')"

  export out in REPO_ROOT KEYS_FILE MACHINE
  bash -euo pipefail -c "$script"

  # store outputs
  echo "$gen" | jq -c '.files | to_entries[]' | while read -r entry; do
    fname=$(echo "$entry"  | jq -r '.key')
    secret=$(echo "$entry" | jq -r '.value.secret')
    deploy=$(echo "$entry" | jq -r '.value.deploy')
    shared=$(echo "$entry" | jq -r '.value.shared')

    if [ ! -f "$out/$fname" ]; then
      echo "  [warn] generator did not produce $fname, skipping"
      continue
    fi

    if [ "$secret" = "true" ]; then
      if [ "$shared" = "true" ]; then
        dest="$REPO_ROOT/secrets/shared/$name/$fname.yaml"
      else
        dest="$REPO_ROOT/secrets/machines/$MACHINE/$name/$fname.yaml"
      fi
      if [ -f "$dest" ]; then
        echo "  [skip] $dest already exists"
        continue
      fi
      mkdir -p "$(dirname "$dest")"
      recipients="$ADMIN_AGE_KEY"
      [ "$deploy" = "true" ] && recipients="$ADMIN_AGE_KEY,$MACHINE_AGE_KEY"
      echo "  [encrypt] $fname -> $dest (shared=$shared, deploy=$deploy)"
      SOPS_AGE_KEY_FILE="$KEYS_FILE" SOPS_CONFIG=/dev/null \
        sops encrypt --input-type binary --output-type yaml \
        --age "$recipients" "$out/$fname" > "$dest"
    else
      if [ "$shared" = "true" ]; then
        dest="$REPO_ROOT/vars/shared/$name/$fname"
      else
        dest="$REPO_ROOT/vars/$MACHINE/$name/$fname"
      fi
      if [ -f "$dest" ]; then
        echo "  [skip] $dest already exists"
        continue
      fi
      mkdir -p "$(dirname "$dest")"
      echo "  [plain] $fname -> $dest"
      cp "$out/$fname" "$dest"
    fi
  done
done

echo ""
echo "==> Done!"
