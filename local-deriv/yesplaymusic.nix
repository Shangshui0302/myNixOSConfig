{ pkgs }:
pkgs.appimageTools.wrapType2 {
  pname = "yesplaymusic";
  version = "0.4.10";
  src = pkgs.fetchurl {
    url = "https://github.com/qier222/YesPlayMusic/releases/download/v0.4.10/YesPlayMusic-0.4.10.AppImage";
    sha256 = "0vi9zp79x6pkfsdj6962m8zghgzynbbmlmqr83vabk7an50mjgs2";
  };
  extraPkgs = pkgs: with pkgs; [ libxshmfence ];
  meta = with pkgs.lib; {
    description = "High-quality third-party NetEase Cloud Music player";
    homepage = "https://github.com/qier222/YesPlayMusic";
    license = licenses.mit;
    platforms = [ "x86_64-linux" ];
  };
}
