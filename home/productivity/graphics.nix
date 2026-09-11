{ pkgs, ... }:

{
  home.packages = with pkgs;
    [
      gthumb
      gimp
      ffmpeg
      kdePackages.kdenlive
      glaxnimate
      blender

      # Screen Toolkit: color picking, QR decoding, calculations, OCR translation,
      # and Wayland recording. grim/slurp/swappy/ImageMagick already live elsewhere.
      hyprpicker
      zbar
      jq
      bc
      translate-shell
      wl-screenrec
    ]
    ++ [
      # Keep useful OCR coverage without pulling the roughly 1 GiB all-language set.
      (tesseract.override {
        enableLanguages = [ "eng" "chi_sim" "jpn" "kor" "rus" ];
      })
    ];
}
