// Runs the actual inline player against a minimal DOM and real PNG headers.
// Browser rendering still requires visual review in a browser.
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const assert = require('node:assert/strict');
const root = path.resolve(__dirname, '../../..');
const html = fs.readFileSync(path.join(root, 'index.html'), 'utf8');
const nodes = new Map();
const draws = [];
class Element {
  constructor() { this.value = ''; this.options = []; this.checked = false; this.dataset = {}; }
  add(option) { this.options.push(option); if (this.options.length === 1) this.value = option.value; }
  replaceChildren() { this.options = []; this.value = ''; }
  removeAttribute(name) { delete this[name]; }
}
const get = id => { if (!nodes.has(id)) nodes.set(id, new Element()); return nodes.get(id); };
get('character').value = 'female'; get('fps').value = '12'; get('loop').checked = true;
get('preview').width = get('preview').height = 512;
get('preview').getContext = () => ({ clearRect() {}, save() {}, restore() {}, translate() {}, scale() {},
  drawImage(...args) { draws.push(args); } });
let now = 0, pending = [];
const ctx = vm.createContext({ document: { getElementById: get, querySelector: get, addEventListener() {} },
  performance: { now: () => now }, requestAnimationFrame() {},
  Option: function(text, value) { this.text = text; this.value = value; },
  Image: class {
    set src(value) {
      this.url = value;
      pending.push(() => {
        try {
          const data = fs.readFileSync(path.join(root, decodeURIComponent(value)));
          this.naturalWidth = data.readUInt32BE(16); this.naturalHeight = data.readUInt32BE(20);
        } catch { this.onerror(); return; }
        this.onload();
      });
    }
    get src() { return this.url; }
  },
});
const run = code => vm.runInContext(code, ctx);
const flush = () => { const queue = pending; pending = []; queue.forEach(f => f()); };
run(html.match(/<script>([\s\S]*?)<\/script>/)[1]); flush();
const names = get('animation').options.map(o => o.value);
assert.equal(names.length, 10);
for (const name of names) {
  get('animation').value = name; get('animation').onchange(); flush();
  assert.equal(get('direction').options.length, 8);
  assert.equal(run('count'), 12);
  assert.equal(get('frame').disabled, false, name);
  for (let direction = 0; direction < 8; direction++) {
    get('direction').value = String(direction); get('direction').onchange(); flush();
    for (let frame = 0; frame < 12; frame++) {
      get('frame').value = String(frame); get('frame').oninput();
      const [, x, y, w, h] = draws.at(-1);
      assert.deepEqual([x, y, w, h], [frame * 256, direction * 256, 256, 256], `${name}/${direction}/${frame}`);
    }
  }
}
get('animation').value = 'Walk'; get('animation').onchange(); flush();
get('frame').value = '7'; get('frame').oninput();
get('direction').value = '2'; get('direction').onchange(); flush();
assert.equal(run('frame'), 7); assert.equal(run('playing'), false);
get('play').onclick(); now += 90; run(`tick(${now})`); assert.equal(run('frame'), 8);
get('frame').value = '11'; get('frame').oninput(); get('play').onclick();
now += 90; run(`tick(${now})`); assert.equal(run('frame'), 0);
get('animation').value = 'Death'; get('animation').onchange(); flush();
assert.equal(get('loop').checked, false);
now += 2000; run(`tick(${now})`);
assert.equal(run('frame'), 11); assert.equal(run('playing'), false);
get('play').onclick(); assert.equal(run('frame'), 0); assert.equal(run('playing'), true);
// Responses from superseded loads must not replace the selected character.
get('character').value = 'original'; get('character').onchange();
get('character').value = 'female'; get('character').onchange(); flush();
assert.equal(run('count'), 12); assert.equal(run('sprite.naturalWidth'), 3072);
get('character').value = 'original'; get('character').onchange(); flush();
assert.equal(get('direction').options.length, 16);
assert.equal(get('frame').disabled, false);
console.log('PASS: 960 frame crops; direction continuity; pause/resume; loop wrap; death stop/replay; stale load protection; original sprites.');
