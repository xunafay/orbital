set -euo pipefail

COMMAND="${1:-}"
SECRET_PATH="${2:-}"

usage() {
  echo "Usage: secret <command> <path>"
  echo ""
  echo "Commands:"
  echo "  edit    <path>   Create or edit a secret (opens \$EDITOR via sops)"
  echo "  delete  <path>   Delete a secret file from the repo"
  echo ""
  echo "Examples:"
  echo "  secret edit   secrets/machines/mun/nebula.yaml"
  echo "  secret delete secrets/machines/mun/nebula.yaml"
}

if [ -z "$COMMAND" ]; then
  usage
  exit 1
fi

if [ -z "$SECRET_PATH" ]; then
  echo "Error: no path given"
  echo ""
  usage
  exit 1
fi

REPO_ROOT="$(git rev-parse --show-toplevel)"
SECRET_FULL="$REPO_ROOT/$SECRET_PATH"
KEYS_FILE="${SOPS_AGE_KEY_FILE:-$HOME/.config/sops/age/keys.txt}"

case "$COMMAND" in
  edit)
    mkdir -p "$(dirname "$SECRET_FULL")"
    SOPS_AGE_KEY_FILE="$KEYS_FILE" sops "$SECRET_FULL"
    ;;

  delete)
    if [ ! -f "$SECRET_FULL" ]; then
      echo "Error: $SECRET_PATH does not exist"
      exit 1
    fi
    echo "==> Deleting $SECRET_PATH..."
    rm "$SECRET_FULL"
    echo "    Done. Remember to remove any references to this secret and commit the deletion."
    ;;

  *)
    echo "Error: unknown command '$COMMAND'"
    echo ""
    usage
    exit 1
    ;;
esac
