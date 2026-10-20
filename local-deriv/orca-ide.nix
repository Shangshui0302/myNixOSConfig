{
  communityOrca,
  python3,
}:

# Keep the community package's source, runtime closure and desktop integration;
# only the machine's startup policy belongs here.
communityOrca.overrideAttrs (old: {
  postInstall = (old.postInstall or "") + ''
    install -m644 ${./orca-ide/default-settings.json} "$out/lib/Orca/resources/nix-default-settings.json"
    ${python3}/bin/python ${./orca-ide/patch-asar.py} "$out/lib/Orca/resources"
    # Keep the private CLI entry used by the local Orca/DSH wrapper.
    ln -s orca "$out/bin/orca-ide-cli"
  '';
})
