const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const { test } = require('node:test');
const path = require('node:path');

function page() {
  const elements = new Map();
  class Option { constructor(text, value) { this.text = text; this.value = value; } }
  function element(id) {
    if (!elements.has(id)) elements.set(id, {
      value: '', options: [], children: [], events: {}, resetCount: 0,
      addEventListener(type, handler) { this.events[type] = handler; },
      replaceChildren(...items) { this.children = items; this.options = items; this.value = items[0]?.value || ''; },
      appendChild(item) { this.children.push(item); },
      add(item) { this.options.push(item); },
      reset() { this.resetCount++; }
    });
    return elements.get(id);
  }
  const requests = [];
  const context = vm.createContext({
    document: { getElementById: element, createElement: () => ({ textContent: '' }) },
    Option, console,
    fetch: async (url, options = {}) => {
      requests.push({url, options});
      let result = [];
      if (options.method === 'POST') result = {id: 11};
      return { ok: true, status: 200, text: async () => JSON.stringify(result) };
    }
  });
  vm.runInContext(fs.readFileSync(path.join(__dirname, '../../main/resources/static/js/admin.js'), 'utf8'), context);
  return { element, requests, context };
}

test('Create Farm posts farm data to farms, then reloads farms only', async () => {
  const p = page();
  p.element('organizationId').value = '1';
  p.element('farmCode').value = ' F01 ';
  p.element('farmName').value = ' Farm 01 ';
  await p.element('farmForm').events.submit({ preventDefault() {} });
  const posts = p.requests.filter(r => r.options.method === 'POST');
  assert.equal(posts.length, 1);
  assert.equal(posts[0].url, '/api/v1/dev/farms?organizationId=1');
  assert.deepEqual(JSON.parse(posts[0].options.body), {farmCode:'F01', farmName:'Farm 01', addressText:''});
  assert.equal(p.element('plantingForm').resetCount, 0);
  assert.equal(p.element('farmForm').resetCount, 1);
});

test('Reloading farms clears all descendant selections and lists', async () => {
  const p = page();
  p.element('organizationId').value = '1';
  for (const id of ['plotSelect','plantingSelect']) p.element(id).value = '99';
  for (const id of ['plotList','plantingList','cycleList']) p.element(id).children = ['stale'];
  await p.element('loadFarmsBtn').events.click();
  for (const id of ['plotSelect','plantingSelect']) assert.equal(p.element(id).value, '');
  for (const id of ['plotList','plantingList','cycleList']) assert.equal(p.element(id).children.length, 0);
});

test('Changing organization clears all prior selections', () => {
  const p = page();
  p.element('farmSelect').value = '9';
  p.element('plotSelect').value = '8';
  p.element('plantingSelect').value = '7';
  p.element('organizationId').events.input();
  for (const id of ['farmSelect','plotSelect','plantingSelect']) assert.equal(p.element(id).value, '');
});

test('Late farm response from previous organization is ignored', async () => {
  const p = page();
  p.element('organizationId').value = '1';
  let complete;
  p.context.fetch = () => new Promise(resolve => { complete = resolve; });
  const pending = p.element('loadFarmsBtn').events.click();
  p.element('organizationId').value = '2';
  p.element('organizationId').events.input();
  complete({ok: true, text: async () => JSON.stringify([{id: 1, farmCode:'OTHER', farmName:'Other org'}])});
  await pending;
  assert.equal(p.element('farmList').children.length, 0);
});
