"""Isolated tests: temporary palettes and commands, no desktop or session bus."""

import importlib.util
import json
from pathlib import Path
import tempfile
import sys
import unittest

SOURCE = Path(__file__).resolve().parents[1] / "home/theme/kde-colors.py"
spec = importlib.util.spec_from_file_location("kde_colors", SOURCE)
kde = importlib.util.module_from_spec(spec)
spec.loader.exec_module(kde)


class AppearanceTests(unittest.TestCase):
    def read(self, text):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "kdeglobals"
            path.write_text(text)
            return kde.read_appearance(path)

    def test_original_wallpaper_accent_is_not_tinted_selection(self):
        self.assertEqual(self.read(
            "[General]\nAccentColor=33,47,68\n"
            "[Colors:Selection]\nBackgroundNormal=99,109,124\n"
            "[Colors:Window]\nBackgroundNormal=255,255,255\n"), ("#212f44", "light"))

    def test_effective_background_drives_mode_for_custom_schemes(self):
        self.assertEqual(self.read(
            "[General]\nColorScheme=UserCustom\nAccentColor=#0080FF\n"
            "[Colors:Window]\nBackgroundNormal=36, 36, 36\n"), ("#0080ff", "dark"))
        self.assertEqual(self.read(
            "[Colors:Selection]\nBackgroundNormal=49,91,239\n"
            "[Colors:View]\nBackgroundNormal=255,255,255\n"), ("#315bef", "light"))

    def test_incomplete_or_invalid_config_is_rejected(self):
        for value in ("", "bad", "-1,0,0", "256,0,0", "1,2", "#12345g"):
            with self.subTest(accent=value), self.assertRaises(ValueError):
                self.read(f"[General]\nAccentColor={value}\n"
                          "[Colors:Window]\nBackgroundNormal=36,36,36\n")
        with self.assertRaises(ValueError):
            self.read("[General]\nAccentColor=33,47,68\n")

    def test_fcitx_keeps_user_fields_and_section_values(self):
        original = ("# User configuration\nTheme=old\nFont=Example 13\n"
                    "Vertical Candidate List=False\nUseDarkTheme=False\n\n"
                    "[SomeSection]\nTheme=section-theme\nDarkTheme=section-dark\n")
        result = kde.update_fcitx_text(original, "light")
        self.assertIn("Theme=mellow-kde\n", result)
        self.assertIn("DarkTheme=mellow-kde-dark\n", result)
        self.assertIn("UseDarkTheme=True\n", result)
        for text in ("# User configuration\n", "Font=Example 13\n",
                     "Vertical Candidate List=False\n", "[SomeSection]\nTheme=section-theme\nDarkTheme=section-dark\n"):
            self.assertIn(text, result)
        self.assertEqual(kde.update_fcitx_text(result, "light"), result)
        self.assertEqual(kde.update_fcitx_text("Font=Example 13", "dark"),
                         "Font=Example 13\nTheme=mellow-kde-dark\nDarkTheme=mellow-kde-dark\nUseDarkTheme=True\n")


class RenderTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        self.log = self.root / "calls"
        self.failure = self.root / "fail"
        # The fake implements Matugen's command boundary, not its color algorithm.
        self.command = self.root / "matugen"
        self.command.write_text(
            f"#!{sys.executable}\nimport pathlib,sys,tomllib\n"
            f"log=pathlib.Path({str(self.log)!r})\n"
            "with log.open('a') as stream: stream.write(' '.join(sys.argv[1:])+'\\n')\n"
            f"if pathlib.Path({str(self.failure)!r}).exists(): sys.exit(3)\n"
            "configuration=tomllib.loads(pathlib.Path(sys.argv[sys.argv.index('-c')+1]).read_text())\n"
            "for template in configuration['templates'].values():\n"
            "    pathlib.Path(template['output_path']).write_text(pathlib.Path(template['input_path']).read_text())\n")
        self.command.chmod(0o755)
        self.notifier = self.root / "notify"
        self.notification_log = self.root / "notifications"
        self.notifier.write_text(f"#!{sys.executable}\nimport pathlib,sys\n"
                                 f"with pathlib.Path({str(self.notification_log)!r}).open('a') as stream: stream.write(' '.join(sys.argv[1:])+'\\n')\n")
        self.notifier.chmod(0o755)
        self.manifest = {"cacheRoot": str(self.root / "cache"), "matugen": str(self.command),
                         "templates": [], "fcitxAssets": {},
                         "kdeGlobals": str(self.root / "kdeglobals"),
                         "fcitxConfig": str(self.root / "config" / "classicui.conf"),
                         "fcitxReload": str(self.notifier), "btopReload": str(self.notifier)}
        for mode in kde.MODES:
            assets = self.root / f"assets-{mode}"
            assets.mkdir()
            (assets / "theme.conf").write_text("[Metadata]\nName=Mellow\n")
            (assets / "asset.svg").write_text("<svg />")
            for path in assets.iterdir():
                path.chmod(0o444)
            assets.chmod(0o555)
            self.manifest["fcitxAssets"][mode] = str(assets)
            template = self.root / f"template-{mode}"
            template.write_text(f"{mode}: generated colors")
            self.manifest["templates"].append({"input": str(template), "output": f"{mode}/nvim-colors.lua"})
        self.renderer = kde.Renderer(self.manifest)

    def calls(self):
        return self.log.read_text().splitlines() if self.log.exists() else []

    def test_idempotence_mode_switch_and_seed_replacement(self):
        config = Path(self.manifest["fcitxConfig"])
        config.parent.mkdir()
        config.write_text("Font=User 14\n[Extra]\nTheme=user-section\n")
        self.assertTrue(self.renderer.apply("#636d7c", "light"))
        cache = Path(self.manifest["cacheRoot"])
        first_generation = (cache / "current").resolve()
        self.assertEqual(len(self.calls()), 2)
        self.assertFalse(self.renderer.apply("#636d7c", "light"))
        self.assertTrue(self.renderer.apply("#636d7c", "dark"))
        self.assertEqual(len(self.calls()), 2, "mode change must reuse both palettes")
        self.assertEqual((cache / "current").resolve(), first_generation)
        self.assertEqual((cache / "selected").resolve(), first_generation / "dark")
        self.assertIn("Name=Mellow KDE Dark", (cache / "current/dark/fcitx5/theme.conf").read_text())
        self.assertIn("Font=User 14\n", config.read_text())
        self.assertIn("[Extra]\nTheme=user-section\n", config.read_text())
        self.assertEqual(self.notification_log.read_text().splitlines(), ["-r", "-USR2 -x btop", "-r"])
        self.assertTrue(self.renderer.apply("#0080ff", "light"))
        self.assertEqual(len(self.calls()), 4)
        self.assertFalse(first_generation.exists(), "only the published generation is retained")
        self.assertEqual(len(list(cache.glob("generation-*"))), 1)

    def test_failure_keeps_published_outputs_and_selected_mode(self):
        self.renderer.apply("#636d7c", "light")
        cache = Path(self.manifest["cacheRoot"])
        previous = (cache / "current").resolve()
        config = Path(self.manifest["fcitxConfig"]).read_bytes()
        notifications = self.notification_log.read_bytes()
        self.failure.touch()
        with self.assertRaises(Exception):
            self.renderer.apply("#0080ff", "dark")
        self.assertEqual((cache / "current").resolve(), previous)
        self.assertEqual((cache / "selected").resolve(), previous / "light")
        self.assertEqual(Path(self.manifest["fcitxConfig"]).read_bytes(), config)
        self.assertEqual(self.notification_log.read_bytes(), notifications)
        self.assertEqual(list(cache.glob("generation-*")), [previous])

    def test_repeated_sync_and_invalid_snapshot_keep_published_output(self):
        snapshot = Path(self.manifest["kdeGlobals"])
        snapshot.write_text("[General]\nAccentColor=33,47,68\n"
                            "[Colors:Window]\nBackgroundNormal=255,255,255\n")
        self.assertTrue(kde.synchronize(self.manifest))
        self.assertFalse(kde.synchronize(self.manifest))
        cache = Path(self.manifest["cacheRoot"])
        previous = (cache / "current").resolve()
        self.assertEqual(json.loads((previous / ".metadata.json").read_text())["seed"], "#212f44")
        # A mode-only save switches outputs without rerunning Matugen.
        snapshot.write_text(snapshot.read_text().replace("255,255,255", "36,36,36"))
        self.assertTrue(kde.synchronize(self.manifest))
        self.assertEqual(len(self.calls()), 2)
        self.assertEqual((cache / "selected").resolve(), previous / "dark")
        snapshot.write_text("[General]\nAccentColor=not-a-color\n")
        with self.assertRaises(ValueError):
            kde.synchronize(self.manifest)
        self.assertEqual((cache / "current").resolve(), previous)
        self.assertEqual((cache / "selected").resolve(), previous / "dark")

    def test_output_paths_cannot_escape_generation(self):
        for output in ("../escape", "/tmp/escape", "dark/../../escape", "other/escape"):
            with self.subTest(output=output):
                manifest = dict(self.manifest, templates=[{"input": str(SOURCE), "output": output}])
                with self.assertRaises(ValueError):
                    kde.Renderer(manifest)

    def test_reload_failures_do_not_rollback_valid_palette(self):
        self.manifest["fcitxReload"] = "/does/not/exist"
        self.manifest["btopReload"] = "/does/not/exist"
        self.assertTrue(kde.Renderer(self.manifest).apply("#636d7c", "dark"))
        self.assertTrue((Path(self.manifest["cacheRoot"]) / "selected/nvim-colors.lua").is_file())


if __name__ == "__main__":
    unittest.main()
