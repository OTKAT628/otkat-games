'use strict';
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
    console.log('PASS mobile browser smoke tests');
  } finally {
    await browser.close();
  }
})().catch(error=>{console.error(error);process.exit(1)});
