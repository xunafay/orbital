export EDITOR=nvim;
export DOTNET_ROOT="/etc/profiles/per-user/hannah/share/dotnet/"
export PATH="$PATH:/home/hannah/.dotnet/tools"
alias nixy='sudo -v && sudo nixos-rebuild switch --log.format internal-json -v'
if ! command -v vim > /dev/null; then
  vim() {
    nvim $@
  }
fi

if ! command -v vi > /dev/null; then
  vi() {
    nvim $@
  }
fi
