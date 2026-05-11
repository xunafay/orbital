{
  config,
  pkgs,
  inputs,
  ...
}:
{
  home.packages = with pkgs; [
    (
      with dotnetCorePackages;
      combinePackages [
        sdk_8_0
        sdk_9_0
        sdk_10_0
      ]
    )
  ];
}
