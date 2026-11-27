(()=>{'use strict';
const DATA={
'arcade-mix':{name:'Arcade Mix',tag:'Аркады · реакция и скорость',story:'В Неонополисе погасли городские огни. Пройди испытания Аркадной лиги и собери энергию для восстановления города.',games:[['Neon Dodge','Лови зелёные импульсы и избегай красных.','targets'],['Sky Hop','Повторяй растущую последовательность прыжков.','memory'],['Pulse Runner','Решай быстрые примеры, чтобы держать темп.','math'],['Target Blitz','Попадай по целям до конца таймера.','targets']]},
'puzzle-lab':{name:'Puzzle Lab',tag:'Головоломки · логика',story:'В лаборатории закрылись четыре сектора. Решай задачи на память, последовательности и внимание, чтобы восстановить главный компьютер.',games:[['Memory Vault','Повтори последовательность плиток.','memory'],['Number Flash','Запомни число и введи его после исчезновения.','number'],['Pattern Finder','Найди отличающийся символ в сетке.','pattern'],['Quick Math','Решай примеры на время.','math']]},
'party-duo':{name:'Party Duo',tag:'Локальные игры для двоих',story:'Старая консоль запускает чемпионат друзей. Соревнуйтесь на одном экране и соберите кубок из четырёх дисциплин.',games:[['Tap Duel','Кто быстрее нажмёт свою кнопку после сигнала?','duel'],['Memory Race','По очереди повторяйте последовательность и зарабатывайте очки.','memoryduo'],['Quick Quiz','Отвечайте на вопросы по очереди.','quiz'],['Score Battle','Наберите больше очков за раунд кликами по своей зоне.','scoreduo']]},
'action-rush':{name:'Action Rush',tag:'Экшен · выживание',story:'На станции Рубеж оборонительные дроны вышли из-под контроля. Пройди тренировку, удержи сектор и восстанови защиту.',games:[['Drone Strike','Нажимай на появляющиеся цели, пока они не исчезли.','targets'],['Last Stand','Удерживай оборону и не пропускай цели.','survive'],['Rapid Fire','Набери максимум попаданий за короткий раунд.','targets'],['Core Defense','Собирай энергию и не допускай перегрузки.','survive']]},
'cozy-worlds':{name:'Cozy Worlds',tag:'Казуальные · уютные игры',story:'Ты унаследовал домик на острове Тихая Бухта. Выполняй небольшие задания, выращивай сад и открывай новые уголки острова.',games:[['Garden Pairs','Открывай карточки и находи одинаковые цветы.','pairs'],['Fishing Time','Останови движущийся индикатор в зелёной зоне.','timing'],['Color Garden','Запомни и повтори цветовую последовательность.','memory'],['Daily Calm','Найди отличающийся символ.','pattern']]}
};
const $=(s,r=document)=>r.querySelector(s),root=$('#app'),app=document.body.dataset.app,cfg=DATA[app];
if(!root||!cfg)return;
let difficulty='normal',timer=null,clock=null,score=0,round=0,locked=false,seq=[],duo=[0,0],activeGame=null,timeout=null;
const key='otkat-mini-'+app;
let saved={best:{},total:0};try{saved=Object.assign(saved,JSON.parse(localStorage.getItem(key)||'{}'))}catch(e){}
const persist=()=>{try{localStorage.setItem(key,JSON.stringify(saved))}catch(e){}};
const stop=()=>{if(timer){clearInterval(timer);timer=null}if(clock){clearInterval(clock);clock=null}if(timeout){clearTimeout(timeout);timeout=null}};
const seconds=()=>difficulty==='easy'?35:difficulty==='hard'?18:25;
const targetCount=()=>difficulty==='easy'?7:difficulty==='hard'?13:10;
const styles='<style>.collection{max-width:980px;margin:auto}.collection .intro{max-width:760px}.gamegrid{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:14px;margin:25px 0}.mini{background:#142238;border:1px solid #ffffff22;border-radius:12px;padding:20px}.mini h3{margin:0 0 8px}.mini p,.muted{color:#a4b2c4;line-height:1.6;font-size:13px}.playarea{margin:20px 0;padding:22px;background:#111e30;border:1px solid #ffffff22;border-radius:14px;min-height:250px}.playarea button{margin:6px;padding:13px 18px;border:1px solid #6ce5df88;background:#162d3c;color:#f5f7fb;border-radius:9px;font-weight:700}.playarea button:active{transform:scale(.97)}.playarea .target{font-size:26px;min-width:100px;min-height:70px}.stats{display:flex;gap:20px;flex-wrap:wrap;color:#6ce5df;margin:14px 0}.choice{font-size:24px;min-width:60px}.two{display:grid;grid-template-columns:1fr 1fr;gap:12px}.two button{min-height:120px;font-size:20px}.statusline{min-height:28px;color:#ffcf79;margin:12px 0}.flash-number{font-size:42px;letter-spacing:5px;color:#6ce5df;text-align:center;padding:20px}.meter{height:34px;background:#27384d;border-radius:20px;position:relative;overflow:hidden;margin:22px 4px}.meter .safe{position:absolute;left:43%;width:14%;height:100%;background:#2d9b77}.meter .needle{position:absolute;left:0;top:0;height:100%;width:5px;background:#fff;box-shadow:0 0 12px #fff}.question{font-size:22px;font-weight:700;margin:20px 0}@media(max-width:650px){.gamegrid{grid-template-columns:1fr}.playarea{padding:14px}}</style>';
function shell(){
stop();
root.innerHTML=styles+'<section class="section collection"><p class="eyebrow">OTKAT GAMES · '+cfg.tag.toUpperCase()+'</p><h1>'+cfg.name+'</h1><p class="intro">'+cfg.story+'</p><div class="stats"><span>Лучший результат: <b id="best">0</b></span><span>Всего очков: <b id="total">0</b></span><span id="net">● Офлайн-сохранения включены</span></div><label class="muted">Сложность: <select id="difficulty"><option value="easy">Лёгкая</option><option value="normal" selected>Средняя</option><option value="hard">Сложная</option></select></label><div class="gamegrid">'+cfg.games.map((g,i)=>'<article class="mini"><h3>'+g[0]+'</h3><p>'+g[1]+'</p><button data-game="'+i+'">Играть</button></article>').join('')+'</div><div id="stage" class="playarea"><h2>Выбери мини-игру</h2><p class="muted">Результаты сохраняются локально на этом устройстве.</p></div></section>';
$('#best').textContent=Math.max(0,...Object.values(saved.best));$('#total').textContent=saved.total||0;
$('#difficulty').value=difficulty;$('#difficulty').onchange=e=>difficulty=e.target.value;
root.querySelectorAll('[data-game]').forEach(b=>b.onclick=()=>start(+b.dataset.game));
}
function finish(points,msg){
stop();points=Math.max(0,Math.round(points));saved.total=(saved.total||0)+points;saved.best[activeGame]=Math.max(saved.best[activeGame]||0,points);persist();
$('#best').textContent=Math.max(0,...Object.values(saved.best));$('#total').textContent=saved.total;
$('#stage').innerHTML='<h2>Раунд завершён</h2><p>'+msg+'</p><h3>Результат: '+points+'</h3><button id="again">Повторить</button><button id="menu">К списку игр</button>';
$('#again').onclick=()=>start(activeGame);$('#menu').onclick=shell;
}
function start(i){
stop();activeGame=i;score=0;round=0;locked=false;duo=[0,0];seq=[];
const g=cfg.games[i],type=g[2],stage=$('#stage'),time=seconds();
if(type==='targets'||type==='survive'){
let left=time,good=true;
stage.innerHTML='<h2>'+g[0]+'</h2><p>'+g[1]+'</p><div class="stats"><span>Очки: <b id="s">0</b></span><span>Время: <b id="t">'+left+'</b></span></div><button class="target" id="hit">🟢 ЦЕЛЬ</button><p id="msg" class="statusline">Нажимай на зелёную цель, избегай красной!</p>';
const hit=$('#hit');
function next(){good=Math.random()>.28;hit.textContent=good?'🟢 ЦЕЛЬ':'🔴 ЛОВУШКА';hit.dataset.good=good?'1':'0'}
hit.onclick=()=>{if(left<=0)return;if(hit.dataset.good==='1'){score+=difficulty==='hard'?2:1;round++;$('#msg').textContent='Попадание! Целей: '+round}else{score=Math.max(0,score-2);$('#msg').textContent='Ловушка! Минус 2 очка'}$('#s').textContent=score;next()};
next();timer=setInterval(()=>{left--;$('#t').textContent=left;if(left<=0)finish(score,'Попаданий: '+round+'.')},1000);return;
}
if(type==='memory'){
const symbols=['●','◆','▲','★'],len=difficulty==='easy'?3:difficulty==='hard'?6:4;
seq=Array.from({length:len},()=>Math.floor(Math.random()*4));
stage.innerHTML='<h2>'+g[0]+'</h2><p>'+g[1]+'</p><p id="msg" class="statusline">Запомни порядок: '+seq.map(n=>symbols[n]).join(' ')+'</p><div id="pad"></div><p>Шаг: <b id="step">0</b> / '+len+'</p>';
timeout=setTimeout(()=>{if(!$('#pad'))return;$('#msg').textContent='Повтори последовательность';$('#pad').innerHTML=symbols.map((s,n)=>'<button class="choice" data-n="'+n+'">'+s+'</button>').join('');$('#pad').querySelectorAll('button').forEach(b=>b.onclick=()=>{if(locked)return;const n=+b.dataset.n;if(n!==seq[round]){finish(round*10,'Последовательность сбилась.');return}round++;$('#step').textContent=round;if(round===len)finish(len*20,'Отличная память!')})},difficulty==='hard'?2600:1800);return;
}
if(type==='memoryduo'){
const symbols=['●','◆','▲','★'];let player=0,level=0,step=0,pattern=[];
stage.innerHTML='<h2>'+g[0]+'</h2><p>'+g[1]+'</p><p id="msg" class="statusline"></p><div id="pad"></div><p>Игрок 1: <b id="p1s">0</b> · Игрок 2: <b id="p2s">0</b></p>';
function nextTurn(){
if(level>=6){finish(duo[0]*10+duo[1]*10,'Игрок 1: '+duo[0]+' очков · Игрок 2: '+duo[1]+' очков. '+(duo[0]===duo[1]?'Ничья!':duo[0]>duo[1]?'Победил игрок 1!':'Победил игрок 2!'));return}
player=level%2;step=0;pattern=Array.from({length:3+Math.floor(level/2)},()=>Math.floor(Math.random()*4));
$('#msg').textContent='Ход игрока '+(player+1)+'. Запомни: '+pattern.map(n=>symbols[n]).join(' ');
$('#pad').innerHTML='';
timeout=setTimeout(()=>{$('#msg').textContent='Игрок '+(player+1)+': повтори последовательность';$('#pad').innerHTML=symbols.map((s,n)=>'<button class="choice" data-n="'+n+'">'+s+'</button>').join('');$('#pad').querySelectorAll('button').forEach(b=>b.onclick=()=>{if(locked)return;const n=+b.dataset.n;if(n!==pattern[step]){$('#msg').textContent='Ошибка игрока '+(player+1)+'. Очко не начислено.';level++;timeout=setTimeout(nextTurn,850);return}step++;if(step===pattern.length){duo[player]+=pattern.length;$('#p1s').textContent=duo[0];$('#p2s').textContent=duo[1];level++;timeout=setTimeout(nextTurn,650)}})},1800);
}
nextTurn();return;
}
if(type==='duel'||type==='scoreduo'){
let left=20;
stage.innerHTML='<h2>'+g[0]+'</h2><p>'+g[1]+'</p><div class="two"><button id="p1">Игрок 1<br><b>0</b></button><button id="p2">Игрок 2<br><b>0</b></button></div><p id="msg" class="statusline">Нажимайте по своей стороне!</p><p>Время: <b id="t">20</b></p>';
[1,2].forEach(n=>$('#p'+n).onclick=()=>{if(left<=0)return;duo[n-1]++;$('#p'+n).querySelector('b').textContent=duo[n-1]});
timer=setInterval(()=>{left--;$('#t').textContent=left;if(left<=0)finish(Math.max(...duo)*10,'Игрок 1: '+duo[0]+' · Игрок 2: '+duo[1]+'. '+(duo[0]===duo[1]?'Ничья!':duo[0]>duo[1]?'Победил игрок 1!':'Победил игрок 2!'))},1000);return;
}
if(type==='quiz'){
const bank=[
['Сколько будет 2 + 2?',['3','4','5'],1],['Какая планета известна как Красная?',['Венера','Марс','Юпитер'],1],
['Сколько дней в неделе?',['5','6','7'],2],['Какой океан самый большой?',['Тихий','Атлантический','Индийский'],0],
['Сколько сторон у шестиугольника?',['5','6','8'],1],['Как называется замёрзшая вода?',['Пар','Лёд','Соль'],1],
['Какое животное называют царём зверей?',['Тигр','Лев','Волк'],1],['Сколько минут в одном часе?',['50','60','100'],1],
['Какой цвет получится из синего и жёлтого?',['Зелёный','Фиолетовый','Оранжевый'],0],['Сколько месяцев в году?',['10','11','12'],2],
['Как называется столица Франции?',['Рим','Париж','Мадрид'],1],['Какое число идёт после 99?',['100','101','90'],0]
];
let q=0;const order=bank.slice().sort(()=>Math.random()-.5).slice(0,Math.min(10,bank.length));
stage.innerHTML='<h2>'+g[0]+'</h2><p>'+g[1]+'</p><p class="statusline" id="msg"></p><div class="question" id="question"></div><div id="answers"></div><p>Игрок 1: <b id="p1s">0</b> · Игрок 2: <b id="p2s">0</b></p><p>Вопрос: <b id="qnum">1</b> / '+order.length+'</p>';
function ask(){if(q>=order.length){finish(duo[0]*10+duo[1]*10,'Игрок 1: '+duo[0]+' · Игрок 2: '+duo[1]+'. '+(duo[0]===duo[1]?'Ничья!':duo[0]>duo[1]?'Победил игрок 1!':'Победил игрок 2!'));return}
const item=order[q],player=q%2;$('#msg').textContent='Отвечает игрок '+(player+1);$('#question').textContent=item[0];$('#qnum').textContent=q+1;
$('#answers').innerHTML=item[1].map((a,n)=>'<button data-answer="'+n+'">'+a+'</button>').join('');
$('#answers').querySelectorAll('button').forEach(b=>b.onclick=()=>{if(+b.dataset.answer===item[2]){duo[player]++;$('#msg').textContent='Верно! Очко игроку '+(player+1)}else $('#msg').textContent='Неверно. Правильный ответ: '+item[1][item[2]];$('#p1s').textContent=duo[0];$('#p2s').textContent=duo[1];q++;timeout=setTimeout(ask,900)});
}
ask();return;
}
if(type==='number'){
const digits=difficulty==='easy'?4:difficulty==='hard'?7:5,number=Array.from({length:digits},()=>Math.floor(Math.random()*10)).join('');
stage.innerHTML='<h2>'+g[0]+'</h2><p>'+g[1]+'</p><div class="flash-number" id="flash">'+number+'</div><p id="msg" class="statusline">Запомни число…</p>';
timeout=setTimeout(()=>{$('#flash').textContent='?';$('#msg').textContent='Введи число по памяти';$('#flash').insertAdjacentHTML('afterend','<input id="ans" inputmode="numeric" placeholder="Число"><button id="check">Проверить</button>');$('#check').onclick=()=>finish($('#ans').value.trim()===number?digits*20:0,$('#ans').value.trim()===number?'Верно! Отличная память.':'Правильное число: '+number)},difficulty==='hard'?3200:2200);return;
}
if(type==='math'){
let question=0,errors=0,answer=0;
stage.innerHTML='<h2>'+g[0]+'</h2><p>'+g[1]+'</p><div class="question" id="q"></div><input id="ans" inputmode="numeric" placeholder="Ответ"><button id="check">Проверить</button><p id="msg" class="statusline"></p><p>Верно: <b id="s">0</b> · Ошибки: <b id="err">0</b></p>';
function ask(){let a=Math.floor(Math.random()*(difficulty==='hard'?40:15))+1,b=Math.floor(Math.random()*(difficulty==='hard'?30:10))+1;answer=a+b;$('#q').textContent=a+' + '+b+' = ?';$('#ans').value='';$('#ans').focus()}
ask();$('#check').onclick=()=>{if($('#ans').value.trim()==='')return;if(+$('#ans').value===answer){score+=10;question++;$('#msg').textContent='Верно!'}else{errors++;$('#msg').textContent='Попробуй ещё.'}$('#s').textContent=question;$('#err').textContent=errors;if(question>=targetCount())finish(score,'Правильных ответов: '+question+'.');else ask()};return;
}
if(type==='pattern'){
const symbols=['◆','●','▲','★','■','♥','✚','⬟'],size=difficulty==='easy'?3:difficulty==='hard'?5:4,total=size*size;
let left=time,odd=0,base=Math.floor(Math.random()*symbols.length),different=(base+1+Math.floor(Math.random()*(symbols.length-1)))%symbols.length;
function draw(){base=Math.floor(Math.random()*symbols.length);different=(base+1+Math.floor(Math.random()*(symbols.length-1)))%symbols.length;odd=Math.floor(Math.random()*total);$('#pad').innerHTML=Array.from({length:total},(_,n)=>'<button class="choice" data-i="'+n+'">'+symbols[n===odd?different:base]+'</button>').join('');$('#pad').querySelectorAll('button').forEach(b=>b.onclick=()=>{if(left<=0)return;if(+b.dataset.i===odd){score+=5;round++;$('#msg').textContent='Нашёл!';$('#s').textContent=score;draw()}else{$('#msg').textContent='Не тот символ. Попробуй ещё.'}})}
stage.innerHTML='<h2>'+g[0]+'</h2><p>'+g[1]+'</p><div class="stats">Очки: <b id="s">0</b> · Время: <b id="t">'+left+'</b></div><div id="pad" class="gamegrid"></div><p id="msg" class="statusline">Найди единственный отличающийся символ.</p>';
draw();timer=setInterval(()=>{left--;$('#t').textContent=left;if(left<=0)finish(score,'Найдено отличий: '+round+'.')},1000);return;
}
if(type==='timing'){
let pos=0,dir=1,attempts=0,hits=0,left=time;
stage.innerHTML='<h2>'+g[0]+'</h2><p>'+g[1]+'</p><div class="stats">Попадания: <b id="s">0</b> · Попытки: <b id="a">0</b> / 5 · Время: <b id="t">'+left+'</b></div><div class="meter"><div class="safe"></div><div class="needle" id="needle"></div></div><button id="stop">СТОП</button><p id="msg" class="statusline">Останови маркер в зелёной зоне.</p>';
timer=setInterval(()=>{pos+=dir*(difficulty==='hard'?3.1:2.1);if(pos>=98){pos=98;dir=-1}if(pos<=0){pos=0;dir=1}$('#needle').style.left=pos+'%'},30);
$('#stop').onclick=()=>{if(attempts>=5)return;attempts++;if(pos>=43&&pos<=57){hits++;score+=20;$('#msg').textContent='Точно в цель!'}else{$('#msg').textContent='Мимо! Попробуй ещё.'}$('#s').textContent=hits;$('#a').textContent=attempts;if(attempts>=5)finish(score,'Попаданий в зелёную зону: '+hits+' из 5.')};
clock=setInterval(()=>{left--;if($('#t'))$('#t').textContent=left;if(left<=0)finish(score,'Время вышло. Попаданий: '+hits+'.')},1000);return;
}
if(type==='pairs'){
const items=difficulty==='easy'?['🌷','🌻','🌼','🌹']:difficulty==='hard'?['🌷','🌻','🌼','🌹','🌺','🌸','🍀','🌱']:['🌷','🌻','🌼','🌹','🌺','🌸'];
const arr=items.concat(items).sort(()=>Math.random()-.5);let opened=[],matched=0;
stage.innerHTML='<h2>'+g[0]+'</h2><p>'+g[1]+'</p><div id="pad" class="gamegrid">'+arr.map((x,n)=>'<button class="choice" data-i="'+n+'">?</button>').join('')+'</div><p id="msg" class="statusline">Найди все пары.</p>';
$('#pad').querySelectorAll('button').forEach(b=>b.onclick=()=>{if(locked||b.textContent!=='?')return;b.textContent=arr[+b.dataset.i];opened.push(b);if(opened.length===2){locked=true;if(opened[0].textContent===opened[1].textContent){matched++;score+=10;opened=[];locked=false;if(matched===items.length)finish(score,'Все пары найдены!')}else timeout=setTimeout(()=>{opened.forEach(x=>x.textContent='?');opened=[];locked=false},650)}});return;
}
}
shell();
if('serviceWorker'in navigator)navigator.serviceWorker.register('../../sw.js').catch(()=>{});
})();