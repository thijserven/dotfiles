import assert from 'node:assert/strict';
import { test } from 'node:test';
import { mkdtempSync, readFileSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { customShortcuts, aerospaceShortcuts, loadShortcuts, formatKeys } from '../src/data.ts';

test('first-run manifest enables deployed sources without preferences', () => {
  const manifest = JSON.parse(readFileSync('package.json', 'utf8'));
  assert.notEqual(manifest.type, 'module', 'Vicinae emits CommonJS .js bundles');
  const defaults = Object.fromEntries(
    manifest.preferences.map((preference: { name: string; default?: unknown }) => [
      preference.name,
      preference.default,
    ]),
  );
  assert.equal(defaults.jsonPath, '~/.config/vicinae/keybindings.json');
  assert.equal(defaults.detectAerospace, true);
  assert.equal(defaults.sketchybarPath, '~/.cache/sketchybar/keybindings.json');
  assert.deepEqual(Object.keys(defaults), ['jsonPath', 'sketchybarPath', 'aerospacePath', 'detectAerospace']);
  assert.equal(defaults.aerospacePath, undefined);
});

test('JSON validates required fields and optional tags', () => {
  assert.equal(
    customShortcuts('[{"title":"Find","keys":"Space f","tags":["files"]}]', '/x')[0].category,
    'Uncategorized',
  );
  assert.equal(
    customShortcuts(
      '[{"source":"aerospace","id":"main.alt-h","title":"Focus left","keys":"opt + h"}]',
      '/x',
    )[0].id,
    'main.alt-h',
  );
  for (const text of [
    '{}',
    '[null]',
    '[{"title":" ","keys":"x"}]',
    '[{"title":"Find","keys":"x","tags":[1]}]',
    '[{"source":"other","id":"toggle","title":"Toggle","keys":"x"}]',
    '[{"source":"aerospace","title":"Focus","keys":"x"}]',
    '[{"id":"main.alt-h","title":"Focus","keys":"x"}]',
  ]) {
    assert.throws(() => customShortcuts(text, '/x'));
  }
});
test('SketchyBar JSON is optional, independent, validated, and read fresh', () => {
  const dir = mkdtempSync(join(tmpdir(), 'sketchybar-shortcuts-'));
  try {
    const file = join(dir, 'keybindings.json');
    const json = join(dir, 'custom.json');
    const options = { sketchybarPath: file, jsonPath: json };
    writeFileSync(json, '[{"title":"Custom","keys":"x"}]');
    assert.deepEqual(loadShortcuts(options).warnings, []);
    assert.equal(loadShortcuts(options).shortcuts.length, 1);

    writeFileSync(file, '[{"title":"Toggle coffee popup","keys":"hyper + 1","category":"SketchyBar","tags":["popup"]}]');
    const result = loadShortcuts(options);
    assert.deepEqual(result.warnings, []);
    assert.deepEqual(result.shortcuts.map(row => row.title), ['Custom', 'Toggle coffee popup']);
    assert.equal(result.shortcuts[1].file, file);
    assert.equal(result.shortcuts[1].keys, 'Hyper + 1');
    assert.deepEqual(result.shortcuts[1].tags, ['popup']);
    assert.equal(loadShortcuts({ ...options, jsonPath: '' }).shortcuts.length, 1);
    assert.equal(loadShortcuts({ ...options, sketchybarPath: '' }).shortcuts.length, 1);

    writeFileSync(file, '[{"title":"Toggle volume popup","keys":"hyper + 2"}]');
    assert.equal(loadShortcuts(options).shortcuts[1].title, 'Toggle volume popup');
    for (const text of ['broken', '[{"title":"Invalid"}]']) {
      writeFileSync(file, text);
      const invalid = loadShortcuts(options);
      assert.equal(invalid.warnings.length, 1);
      assert.match(invalid.warnings[0], /SketchyBar:/);
      assert.deepEqual(invalid.shortcuts.map(row => row.title), ['Custom']);
    }

    writeFileSync(file, '[{"title":"Popup","keys":"hyper + 0"}]');
    writeFileSync(json, 'broken');
    const invalidCustom = loadShortcuts(options);
    assert.equal(invalidCustom.warnings.length, 1);
    assert.match(invalidCustom.warnings[0], /JSON:/);
    assert.equal(invalidCustom.shortcuts[0].title, 'Popup');
  } finally {
    rmSync(dir, { recursive: true });
  }
});
test('AeroSpace parses quoted keys, arrays, modes, and comments through TOML parser', () => {
  const rows = aerospaceShortcuts(
    '[mode.main.binding]\n"ctrl-h" = "focus left" # comment\n[mode.service.binding]\nesc = ["reload-config", "mode main"]',
    '/x',
  );
  assert.equal(rows[0].title, 'Focus left');
  assert.equal(rows[0].keys, 'Ctrl + H');
  assert.equal(formatKeys('ctrl + slash'), 'Ctrl + /');
  assert.equal(formatKeys('ctrl + cmd + f'), 'Ctrl + Cmd + F');
  assert.equal(formatKeys('alt + tab'), 'Opt + Tab');
  assert.equal(formatKeys('comma + period + semicolon'), ', + . + ;');
  assert.equal(formatKeys('super+control+alt+shift+RETURN'), 'Hyper + Return');
  assert.equal(rows[1].category, 'AeroSpace - Service');
  assert.equal(rows[1].title, 'Reload config - Return to normal shortcuts');
  assert.equal(
    aerospaceShortcuts('[mode.main.binding]\nx = "mode service"', '/x')[0].title,
    'Switch to service shortcuts',
  );
  assert.equal(
    aerospaceShortcuts('[mode.service.binding]\nesc = "mode main"', '/x')[0].title,
    'Return to normal shortcuts',
  );
});
test('custom entries and AeroSpace overrides support fresh reads and isolated errors', () => {
  const dir = mkdtempSync(join(tmpdir(), 'local-shortcuts-'));
  try {
    const file = join(dir, 'aerospace.toml');
    const json = join(dir, 'shortcuts.json');
    writeFileSync(file, '[mode.main.binding]\nalt-h = "focus left"\nalt-l = "focus right"');
    writeFileSync(
      json,
      JSON.stringify([
        { title: 'Toggle launcher', keys: 'cmd + space', category: 'Vicinae' },
        { source: 'aerospace', id: 'main.alt-h', title: 'Left', keys: 'opt + H', tags: ['window'] },
        {
          source: 'aerospace',
          id: 'main.alt-l',
          title: 'Right',
          keys: 'opt + L',
          category: 'Windows',
        },
        { source: 'aerospace', id: 'main.alt-x', title: 'Missing', keys: 'x' },
      ]),
    );
    const options = { jsonPath: json, detectAerospace: true, aerospacePath: file };
    const result = loadShortcuts(options);
    assert.deepEqual(result.warnings, []);
    assert.equal(result.shortcuts.length, 3);
    assert.equal(result.shortcuts[0].title, 'Toggle launcher');
    assert.equal(result.shortcuts[0].file, json);
    assert.equal(result.shortcuts[1].title, 'Left');
    assert.equal(result.shortcuts[0].keys, 'Cmd + Space');
    assert.equal(result.shortcuts[1].keys, 'Opt + H');
    assert.equal(result.shortcuts[1].category, 'AeroSpace - Main');
    -assert.deepEqual(result.shortcuts[1].tags, ['aerospace', 'main', 'window']);
    assert.equal(result.shortcuts[1].file, file);
    assert.equal(result.shortcuts[2].category, 'Windows');
    assert.equal(loadShortcuts({ ...options, detectAerospace: false }).shortcuts.length, 1);

    writeFileSync(json, '[{"title":"New","keys":"y"}]');
    writeFileSync(file, '[mode.main.binding]\nalt-j = "focus down"');
    const fresh = loadShortcuts(options);
    assert.deepEqual(
      fresh.shortcuts.map((row) => row.title),
      ['New', 'Focus down'],
    );
    assert.deepEqual(fresh.warnings, []);

    writeFileSync(json, 'broken');
    const badJson = loadShortcuts(options);
    assert.match(badJson.warnings[0], /JSON:/);
    assert.equal(badJson.warnings.length, 1);
    assert.equal(badJson.shortcuts[0].title, 'Focus down');

    writeFileSync(json, '[{"title":"Custom","keys":"x"}]');
    writeFileSync(file, 'broken');
    const badToml = loadShortcuts(options);
    assert.match(badToml.warnings[0], /AeroSpace:/);
    assert.equal(badToml.warnings.length, 1);
    assert.equal(badToml.shortcuts[0].title, 'Custom');
    assert.deepEqual(loadShortcuts({}), { shortcuts: [], warnings: [] });
  } finally {
    rmSync(dir, { recursive: true });
  }
});
