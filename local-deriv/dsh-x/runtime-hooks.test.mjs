import assert from 'node:assert/strict'
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from 'node:fs'
import { tmpdir } from 'node:os'
import { join } from 'node:path'
import test from 'node:test'
import { pathToFileURL } from 'node:url'

const { installCoreRuntimeHooks } = await import(pathToFileURL(process.env.DSH_NIX_RUNTIME_HOOKS))
const launcher = '/nix/test launcher/bin/dsh-x'
const runtime = '/nix/test-node/bin/node'
const linuxSource = `
const IN_ELECTRON = true;
export function launcherExecutable() {
  if (IN_ELECTRON && !process.defaultApp) return process.execPath
  return '';
}
`
const serverSource = `
const RUNTIME_NODE = ${JSON.stringify(runtime)};
const ROOT = '/core';
const join = (...parts) => parts.join('/');
export function repair(spawn, anchor, home, profile, name, options) {
  return spawn(process.execPath, [join(ROOT, 'repair-uninstall.mjs'), anchor, home, profile, name], options);
}
export function restartArgs() {
  return ['--exe', process.env.APPIMAGE || process.execPath,];
}
`

function fixture(t) {
  const dir = mkdtempSync(join(tmpdir(), 'dsh-runtime-test-'))
  t.after(() => rmSync(dir, { recursive: true, force: true }))
  writeFileSync(join(dir, 'package.json'), '{"type":"module"}')
  writeFileSync(join(dir, 'filemanager-linux.js'), linuxSource)
  writeFileSync(join(dir, 'server.js'), serverSource)
  return dir
}

test('autostart and core-update relaunch select the Nix wrapper; repair uses Node', async (t) => {
  const dir = fixture(t)
  const hooks = installCoreRuntimeHooks(dir, launcher)
  t.after(() => hooks.deregister())
  const manager = await import(pathToFileURL(join(dir, 'filemanager-linux.js')))
  const server = await import(pathToFileURL(join(dir, 'server.js')))
  assert.equal(manager.launcherExecutable(), 'dsh-x')
  assert.deepEqual(server.restartArgs(), ['--exe', launcher])
  const args = ['/version/bin.js', '/home/test', 'web', '@test/plugin']
  const options = { cwd: '/home/test/profiles/web', env: { DSH_HOME: '/home/test' } }
  const child = {}
  let captured
  assert.equal(server.repair((...values) => { captured = values; return child }, ...args, options), child)
  assert.deepEqual(captured, [runtime, ['/core/repair-uninstall.mjs', ...args], options])
  assert.equal(readFileSync(join(dir, 'server.js'), 'utf8'), serverSource)
  assert.equal(readFileSync(join(dir, 'filemanager-linux.js'), 'utf8'), linuxSource)

  // The hook must not touch a same-named file outside this core directory.
  const other = fixture(t)
  const untouched = await import(pathToFileURL(join(other, 'filemanager-linux.js')))
  assert.equal(untouched.launcherExecutable(), process.execPath)
})

test('missing or duplicated call sites reject the core before registering hooks', (t) => {
  for (const source of [serverSource.replace('spawn(process.execPath', 'spawn(otherRuntime'), serverSource + serverSource]) {
    const dir = fixture(t)
    writeFileSync(join(dir, 'server.js'), source)
    assert.throws(() => installCoreRuntimeHooks(dir, launcher), { code: 'DSH_NIX_RUNTIME_INCOMPATIBLE' })
    assert.equal(readFileSync(join(dir, 'server.js'), 'utf8'), source)
  }
})

test('a core changed between preflight and import fails explicitly', async (t) => {
  const dir = fixture(t)
  const hooks = installCoreRuntimeHooks(dir, launcher)
  t.after(() => hooks.deregister())
  writeFileSync(join(dir, 'server.js'), serverSource.replace('spawn(process.execPath', 'spawn(otherRuntime'))
  await assert.rejects(import(pathToFileURL(join(dir, 'server.js'))), { code: 'DSH_NIX_RUNTIME_INCOMPATIBLE' })
})

// Exercise the installed shell's real import/recovery block without Electron,
// the manager service, or the user's core. Only fixture modules are evaluated.
const shellSource = readFileSync(process.env.DSH_NIX_SHELL_MAIN, 'utf8')
const begin = shellSource.indexOf('  const runtimeHooks = installCoreRuntimeHooks(coreDir,')
const end = shellSource.indexOf('  server = core', begin)
assert.ok(begin >= 0 && end > begin)
const importBlock = shellSource.slice(begin, end)
const AsyncFunction = Object.getPrototypeOf(async function () {}).constructor
const loadCore = new AsyncFunction(
  'coreDir', 'installCoreRuntimeHooks', 'recoverCore', 'showStartupError', 'pathToFileURL', 'join', importBlock,
)

test('shell adapter errors never invoke destructive core recovery, and hooks are released', async (t) => {
  const dir = fixture(t)
  writeFileSync(join(dir, 'server.js'), "throw Object.assign(new Error('changed core'), { code: 'DSH_NIX_RUNTIME_INCOMPATIBLE' });")
  let recovery = 0
  let released = 0
  let reported = 0
  await loadCore(dir, () => ({ deregister() { released++ } }), () => { recovery++; return true }, () => { reported++ }, pathToFileURL, join)
  assert.equal(recovery, 0)
  assert.equal(reported, 1)
  assert.equal(released, 1)
})

test('shell keeps normal core-recovery behavior for unrelated import failures', async (t) => {
  const dir = fixture(t)
  writeFileSync(join(dir, 'server.js'), "throw new Error('broken core');")
  let recovery = 0
  let released = 0
  await loadCore(dir, () => ({ deregister() { released++ } }), () => { recovery++; return true }, () => assert.fail('unexpected dialog'), pathToFileURL, join)
  assert.equal(recovery, 1)
  assert.equal(released, 1)
})

test('preflight failure stays outside the shell core-recovery block', async (t) => {
  const dir = fixture(t)
  writeFileSync(join(dir, 'server.js'), 'export const incompatible = true;')
  await assert.rejects(loadCore(dir, installCoreRuntimeHooks, () => assert.fail('must not recover'), () => assert.fail('must propagate'), pathToFileURL, join), {
    code: 'DSH_NIX_RUNTIME_INCOMPATIBLE',
  })
})
