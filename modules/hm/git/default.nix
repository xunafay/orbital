{ lib, pkgs, config, ... }:
with lib;
{
  options = {
    git.user.name = mkOption {
      type = types.str;
    };
    git.user.email = mkOption {
        type = types.str;
    };
  };

  config = {
      home.packages = with pkgs; [
        git
        gh
      ];
 
      programs.gh = {
        extensions = with pkgs; [
          gh-webhook
        ];
      };

      programs.git = {
        enable = true;
        lfs.enable = true;
        aliases = {
          graph = "log --graph --oneline --all";
          prune-untracked = "git fetch -p ; git branch -r | awk '{print $1}' | egrep -v -f /dev/fd/0 <(git branch -vv | grep origin) | awk '{print $1}' | xargs git branch -d";
          default-branch = "!git symbolic-ref refs/remotes/origin/HEAD | sed 's@^refs/remotes/origin/@@'";
          merge-base-origin = "!f() { git merge-base \${1-HEAD} origin/$(git default-branch); };f ";
          push-stepped = builtins.readFile ./push-stepped.sh;
          stack = builtins.readFile ./stack.sh;
          push-stack = builtins.readFile ./push-stack.sh;
          push-stepped-stack = builtins.readFile ./push-stepped-stack.sh;
          red = "rebase --interactive --autosquash --update-refs";
          ca = "commit --amend";
          cc = "commit";
        };
        settings = {
          init.defaultBranch = "main";
          push = {
            autosSetupRemote = true;
          };
          pull = {
            rebase = true;
          };
          rebase = {
            autoStash = true;
          };
          merge = {
            conflictStyle = "zdiff3";
            autoStash = true;
          };
          rerere = {
            enabled = true;
          };
          user = {
            name = config.git.user.name;
            email = config.git.user.email;
          };
        };
      };
  };
}
