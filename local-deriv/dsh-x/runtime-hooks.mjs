import { readFileSync } from 'node:fs'
import { registerHooks } from 'node:module'
import { basename, join } from 'node:path'
import { pathToFileURL } from 'node:url'

function incompatibleCore(file) {
  const error = new Error(`DSH-X 核心的 ${file} 与 Nix 运行时适配不兼容；请更新 Nix 包。`)
  error.code = 'DSH_NIX_RUNTIME_INCOMPATIBLE'
  return error
}

// These modules belong to the writable, independently updated core. Adapt only
// the known call sites in memory, without replacing the core or editing it.
export function patchCoreSource(file, source, launcher) {
  const replacements = file === 'filemanager-linux.js' ? [
    [
      'if (IN_ELECTRON && !process.defaultApp) return process.execPath',
      // Resolve the installed command at login, so an autostart entry does not
      // pin an obsolete store path after a Nix generation change.
      `if (IN_ELECTRON && !process.defaultApp) return ${JSON.stringify(basename(launcher))}`,
    ],
  ] : [
    [
      "spawn(process.execPath, [join(ROOT, 'repair-uninstall.mjs'),",
      "spawn(RUNTIME_NODE, [join(ROOT, 'repair-uninstall.mjs'),",
    ],
    [
      "'--exe', process.env.APPIMAGE || process.execPath,",
      `'--exe', ${JSON.stringify(launcher)},`,
    ],
  ]
  for (const [from, to] of replacements) {
    if (source.split(from).length !== 2) throw incompatibleCore(file)
    source = source.replace(from, to)
  }
  return source
}

export function installCoreRuntimeHooks(coreDir, launcher) {
  const targets = new Map()
  for (const file of ['filemanager-linux.js', 'server.js']) {
    const path = join(coreDir, file)
    // Check before entering the shell's core-import recovery block: an adapter
    // mismatch must never classify a valid core as corrupt and delete it.
    patchCoreSource(file, readFileSync(path, 'utf8'), launcher)
    targets.set(pathToFileURL(path).href, file)
  }
  return registerHooks({
    load(url, context, nextLoad) {
      const result = nextLoad(url, context)
      const file = targets.get(url)
      if (!file) return result
      if (result.format !== 'module' || result.source == null) throw incompatibleCore(file)
      const source = typeof result.source === 'string'
        ? result.source
        : Buffer.from(result.source).toString('utf8')
      return { ...result, source: patchCoreSource(file, source, launcher) }
    },
  })
}
