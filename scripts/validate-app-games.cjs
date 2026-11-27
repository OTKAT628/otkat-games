'use strict';
const fs = require('node:fs');
const path = require('node:path');
const root = path.resolve('web/apps');
const read = p => fs.readFileSync(path.join(process.cwd(), p), 'utf8');
const fail = message => { console.error('FAIL:', message); process.exitCode = 1; };
const pass = message => console.log('PASS:', message);
const standalone = [
  'clockwork-courier','lumen-garden','cargo-zero','mine-signal','signal-siege',
  'pulse-runner','inkbound','deep-current','rift-cartographer','marble-foundry',
  'kitchen-sprint','orbit-weaver','skyhook','frostline','hex-frontier'
];
const collections = [
  ['mobile-100','mobile-100.js',10,['Pipe Tangle','Bridge Budget','Prism Sort','Tide Fisher','Lunar Touchdown','Power Grid','Shadow Step','Wild Balance','Windwright','Echo Sequence']],
  ['mobile-100-02','mobile-100-02.js',10,['Knot Escape','Magnet Crane','Paper Fold','Color Alchemy','Fossil Brush','Last Bid','Odd One Out','Dice Route','Glyph Cipher','Pendulum Balance']],
  ['mobile-100-03','mobile-100-03.js',10,['Vault Dial','Rooftop Gardener','Comet Catcher','Tiny Tactician','Canyon Courier','Bubble Pop Lab','Time Keeper','Cloud Shepherd','Star Loom','Dungeon Draft']]
];
const engine=read('web/apps/app-games.js');
for (const slug of standalone) {
  const file=`web/apps/${slug}/index.html`;
  if (!fs.existsSync(file)) fail(`missing standalone page: ${slug}`);
  else {
    const html=read(file);
    if (!html.includes(`data-app-game="${slug}"`)) fail(`missing game root: ${slug}`);
    if (!html.includes('src="../app-games.js"')) fail(`missing shared engine: ${slug}`);
    if (!engine.includes(`"${slug}"`)) fail(`game not registered in shared engine: ${slug}`);
  }
}
pass(`${standalone.length} standalone pages and registrations`);
for (const [dir,file,count,names] of collections) {
  const html=read(`web/apps/${dir}/index.html`);
  const js=read(`web/apps/${dir}/${file}`);
  if (!html.includes(file)) fail(`collection page does not load ${file}`);
  const entries=(js.match(/^\[/gm)||[]).length;
  for (const name of names) if (!js.includes(name)) fail(`missing ${name} in ${dir}`);
  if (names.length!==count) fail(`bad expected count for ${dir}`);
  if (entries===0 && !js.includes('const G=[') && !js.includes('const games=[')) fail(`game data not found in ${dir}`);
  pass(`${dir}: expected game names present`);
}
const fourth=read('web/apps/mobile-100-04/mobile-100-04.js');
const match=fourth.match(/const G=(\[[\s\S]*?\]);/);
if (!match) fail('Mobile 100 collection 04 data array not found');
else {
  try {
    const data=JSON.parse(match[1]);
    if (data.length!==55) fail(`collection 04 has ${data.length}, expected 55 challenges`);
    if (new Set(data.map(x=>x.id)).size!==data.length) fail('collection 04 has duplicate IDs');
    if (new Set(data.map(x=>x.name)).size!==data.length) fail('collection 04 has duplicate names');
    pass(`collection 04: ${data.length} unique challenges`);
  } catch (error) { fail('collection 04 data is not valid JSON: '+error.message); }
}
const sw=read('web/sw.js');
const cacheMatch=sw.match(/const CORE=(\[[\s\S]*?\]);/);
if (!cacheMatch) fail('service worker CORE cache list not found');
else {
  try {
    const cache=JSON.parse(cacheMatch[1]);
    const required=[
      ...standalone.map(x=>`./apps/${x}/index.html`),
      ...['mobile-100','mobile-100-02','mobile-100-03','mobile-100-04'].flatMap(x=>[`./apps/${x}/index.html`,`./apps/${x}/${x}.js`])
    ];
    for (const item of required) if (!cache.includes(item)) fail('missing offline cache entry: '+item);
    pass('service worker includes all game pages and collection engines');
  } catch (error) { fail('service worker CORE is not valid JSON: '+error.message); }
}
function walk(dir) {
  return fs.readdirSync(dir,{withFileTypes:true}).flatMap(entry=>{
    const full=path.join(dir,entry.name);
    return entry.isDirectory()?walk(full):[full];
  });
}
let checked=0;
for (const file of walk(root).filter(x=>x.endsWith('.html'))) {
  const html=fs.readFileSync(file,'utf8');
  for (const m of html.matchAll(/\b(?:href|src)\s*=\s*["']([^"']+)["']/gi)) {
    const raw=m[1].trim();
    if (!raw || /^(?:#|https?:|data:|javascript:|mailto:|tel:|\/\/)/i.test(raw)) continue;
    const clean=decodeURIComponent(raw.split(/[?#]/)[0]);
    if (!clean) continue;
    let target=path.resolve(path.dirname(file),clean);
    if (fs.existsSync(target) && fs.statSync(target).isDirectory()) target=path.join(target,'index.html');
    if (!path.extname(target) && fs.existsSync(target+'.html')) target+='.html';
    if (!fs.existsSync(target)) fail(`broken local reference in ${path.relative(process.cwd(),file)}: ${raw}`);
    checked++;
  }
}
if (!process.exitCode) pass(`checked ${checked} local links/assets in app pages`);
