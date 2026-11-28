'use strict';
const fs = require('node:fs');
const path = require('node:path');
const { chromium } = require('playwright');
const standalone = [
  'clockwork-courier','lumen-garden','cargo-zero','mine-signal','signal-siege',
  'pulse-runner','inkbound','deep-current','rift-cartographer','marble-foundry',
  'kitchen-sprint','orbit-weaver','skyhook','frostline','hex-frontier'
];
const collections = [
  { path:'mobile-100', selector:'#games button', title:'#title', count:10 },
  { path:'mobile-100-02', selector:'#list button', title:'#name', count:10 },
  { path:'mobile-100-03', selector:'#list button', title:'#name', count:10 },
  { path:'mobile-100-04', selector:'#list button', title:'#name', count:60 }
];
(async()=>{
  const browser=await chromium.launch({headless:true});
  const page=await browser.newPage({viewport:{width:390,height:844},deviceScaleFactor:1,isMobile:true,hasTouch:true});
  const errors=[];
  page.on('pageerror',error=>errors.push(error.message));
  const checkWidth=async label=>{
    const width=await page.evaluate(()=>({inner:window.innerWidth,scroll:document.documentElement.scrollWidth}));
    if(width.scroll>width.inner+1) throw new Error(label+' horizontal overflow: '+JSON.stringify(width));
  };
  try {
    for(const slug of standalone){
      errors.length=0;
      await page.goto('http://127.0.0.1:4173/apps/'+slug+'/index.html',{waitUntil:'domcontentloaded'});
      await page.locator('main[data-app-game="'+slug+'"]').waitFor();
      await page.locator('canvas').waitFor();
      await page.waitForTimeout(250);
      if(await page.locator('canvas').count()!==1) throw new Error(slug+': expected one canvas');
      const size=await page.locator('canvas').evaluate(el=>({w:el.clientWidth,h:el.clientHeight}));
      if(!size.w||!size.h) throw new Error(slug+': canvas has no visible size');
      const restart=page.getByRole('button',{name:'Заново'});
      if(await restart.count()) await restart.click();
      await checkWidth(slug);
      if(errors.length) throw new Error(slug+': '+errors.join(' | '));
      console.log('PASS standalone',slug);
    }
    for(const item of collections){
      errors.length=0;
      await page.goto('http://127.0.0.1:4173/apps/'+item.path+'/index.html',{waitUntil:'domcontentloaded'});
      const buttons=page.locator(item.selector);
      await page.waitForFunction(({selector,count})=>document.querySelectorAll(selector).length===count,{selector:item.selector,count:item.count});
      if(await buttons.count()!==item.count) throw new Error(item.path+': wrong game count');
      await buttons.first().click();
      await page.locator(item.title).waitFor();
      const title=(await page.locator(item.title).innerText()).trim();
      if(!title||/выбери игру/i.test(title)) throw new Error(item.path+': selecting a game did not update title');
      await page.waitForTimeout(100);
      await checkWidth(item.path);
      if(errors.length) throw new Error(item.path+': '+errors.join(' | '));
      console.log('PASS collection',item.path,'games='+item.count,'first='+title);
    }
    // Every one of the 90 Mobile 100 entries must launch as its own downloadable page.
    const individualRoot='web/apps/individual-games';
    const individualPages=fs.readdirSync(individualRoot).filter(slug=>fs.existsSync(path.join(individualRoot,slug,'index.html')));
    if(individualPages.length!==90) throw new Error('Expected 90 individual game pages, found '+individualPages.length);
    for(const slug of individualPages){
      errors.length=0;
      await page.goto('http://127.0.0.1:4173/apps/individual-games/'+slug+'/index.html',{waitUntil:'domcontentloaded'});
      await page.locator('h1').first().waitFor();
      const title=(await page.locator('h1').first().innerText()).trim();
      if(!title) throw new Error(slug+': missing game title');
      if(await page.locator('a[download]').count()!==1) throw new Error(slug+': missing standalone download link');
      await page.waitForTimeout(60);
      await checkWidth(slug);
      if(errors.length) throw new Error(slug+': '+errors.join(' | '));
    }
    console.log('PASS 90 individual Mobile 100 game pages and downloads');
    // Functional regression checks for the newly repaired mechanics.
    const clickBoard=async(x,y)=>{
      const box=await page.locator('canvas').boundingBox();
      await page.mouse.click(box.x+x*box.width/720,box.y+y*box.height/460);
    };
    await page.goto('http://127.0.0.1:4173/apps/lumen-garden/index.html',{waitUntil:'domcontentloaded'});
    for(const n of [2,3,6,7,8,9]) await page.getByRole('button',{name:'Зеркало '+n}).click();
    if(!(await page.locator('#help').innerText()).includes('Свет достиг цветка')) throw new Error('Lumen Garden: solved mirror layout did not win');
    console.log('PASS Lumen Garden win condition');
    await page.goto('http://127.0.0.1:4173/apps/rift-cartographer/index.html',{waitUntil:'domcontentloaded'});
    for(const [x,y] of [[296,122],[360,122],[424,122],[488,122],[488,186],[488,250],[488,314],[488,378]]) await clickBoard(x,y);
    if(!(await page.locator('#help').innerText()).includes('Портал найден')) throw new Error('Rift Cartographer: valid route did not reach portal');
    console.log('PASS Rift Cartographer connected route');
    await page.goto('http://127.0.0.1:4173/apps/cargo-zero/index.html',{waitUntil:'domcontentloaded'});
    for(const key of ['ArrowLeft','ArrowUp','ArrowRight','ArrowRight','ArrowRight','ArrowUp','ArrowUp','ArrowLeft','ArrowLeft','ArrowDown','ArrowDown','ArrowLeft','ArrowDown','ArrowRight','ArrowRight','ArrowRight']) await page.keyboard.press(key);
    if(!(await page.locator('#help').innerText()).includes('Оба ящика на местах')) throw new Error('Cargo Zero: solved warehouse did not win');
    console.log('PASS Cargo Zero box goals');
    await page.goto('http://127.0.0.1:4173/apps/kitchen-sprint/index.html',{waitUntil:'domcontentloaded'});
    for(const [x,y] of [[105,147],[270,147],[435,147],[600,147],[105,222],[270,147],[270,222],[435,222],[600,222]]) await clickBoard(x,y);
    if(!(await page.locator('#help').innerText()).includes('Все три заказа выполнены')) throw new Error('Kitchen Sprint: all correct recipes did not win');
    console.log('PASS Kitchen Sprint three recipes');
    await page.goto('http://127.0.0.1:4173/apps/mobile-100/index.html',{waitUntil:'domcontentloaded'});
    await page.getByRole('button',{name:/Tide Fisher/}).click();
    await page.waitForTimeout(180);
    await page.getByRole('button',{name:/Pipe Tangle/}).click();
    await page.waitForTimeout(350);
    if(await page.locator('#board button').count()!==6) throw new Error('Mobile 100: old fishing timer overwrote the next game');
    console.log('PASS Mobile 100 timer cleanup');
    await page.goto('http://127.0.0.1:4173/index.html',{waitUntil:'domcontentloaded'});
    if(!(await page.locator('link[rel="manifest"]').count())) throw new Error('PWA manifest link missing on home page');
    const manifest=await page.evaluate(async()=>await (await fetch('/manifest.webmanifest')).json());
    if(manifest.display!=='standalone') throw new Error('PWA manifest is not standalone');
    console.log('PASS PWA install manifest');
    console.log('PASS mobile browser smoke tests');
  } finally {
    await browser.close();
  }
})().catch(error=>{console.error(error);process.exit(1)});
