// Load built bundle with only Vicinae runtime externals available.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const manifest = JSON.parse(fs.readFileSync(path.join(__dirname, '../dist/package.json'), 'utf8'));
assert.notEqual(manifest.type, 'module');
const bundle = path.join(__dirname, '../dist/browse.js');
const context = {
  module: { exports: {} },
  exports: {},
  require(name) {
    if (['react', 'react/jsx-runtime', '@vicinae/api', '@raycast/api'].includes(name)) return {};
    assert.ok(require('node:module').isBuiltin(name), `Unbundled dependency: ${name}`);
    return require(name);
  },
};
vm.runInNewContext(fs.readFileSync(bundle, 'utf8'), context, { filename: bundle });
assert.equal(typeof context.module.exports.default, 'function');
console.log('Built bundle runtime imports passed');
