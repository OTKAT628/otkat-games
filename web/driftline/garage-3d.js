import * as THREE from 'https://cdn.jsdelivr.net/npm/three@0.180.0/build/three.module.js';

(() => {
  const host = document.querySelector('#garage3d');
  const canvas = document.querySelector('#garage3d-view');
  const select = document.querySelector('#car');
  const paintPicker = document.querySelector('#colors');
  if (!host || !canvas || !select) return;

  const models = [
    { name: 'VOLTRIX V8', type: 'hyper', length: 4.2, width: 1.9, height: .48, wheel: .34, wing: true },
    { name: 'NOVA GT-R', type: 'coupe', length: 4.0, width: 1.82, height: .55, wheel: .33 },
    { name: 'ZENITH RALLY', type: 'rally', length: 3.9, width: 1.86, height: .72, wheel: .38, rack: true },
    { name: 'PHANTOM S', type: 'sedan', length: 4.25, width: 1.84, height: .62, wheel: .34 },
    { name: 'AETHER X', type: 'electric', length: 4.35, width: 1.92, height: .48, wheel: .35 },
    { name: 'IRONCLAD 4X', type: 'offroad', length: 4.1, width: 2.0, height: .82, wheel: .48, rack: true },
    { name: 'KESTREL RS', type: 'track', length: 4.25, width: 1.95, height: .43, wheel: .36, wing: true },
    { name: 'MIRAGE ROADSTER', type: 'roadster', length: 3.85, width: 1.82, height: .52, wheel: .33, open: true },
    { name: 'VANDAL DRIFT', type: 'drift', length: 4.0, width: 1.98, height: .5, wheel: .35, wing: true },
    { name: 'TITAN HAULER', type: 'pickup', length: 4.65, width: 1.95, height: .75, wheel: .4 },
    { name: 'COMET 69', type: 'classic', length: 4.05, width: 1.82, height: .65, wheel: .32 },
    { name: 'WRAITH NX', type: 'armored', length: 4.35, width: 2.0, height: .57, wheel: .4, wing: true }
  ];

  let renderer, scene, camera, carGroup, raf, dragging = false, lastX = 0, spin = 0;
  let selectedPaint = '#33d6cb';
  const clamp = (n, a, b) => Math.max(a, Math.min(b, n));

  function mat(color, metalness = 0.15, roughness = 0.42) {
    return new THREE.MeshStandardMaterial({ color, metalness, roughness });
  }
  function addBox(parent, size, pos, material, bevel = false) {
    const geometry = new THREE.BoxGeometry(...size);
    const mesh = new THREE.Mesh(geometry, material);
    mesh.position.set(...pos);
    mesh.castShadow = true;
    mesh.receiveShadow = true;
    parent.add(mesh);
    return mesh;
  }
  function addBody(parent, model, color) {
    const w = model.width, l = model.length;
    const shape = new THREE.Shape();
    const nose = model.type === 'armored' ? .18 : model.type === 'pickup' ? .1 : .29;
    shape.moveTo(-w * .32, -l * .5);
    shape.quadraticCurveTo(-w * .48, -l * .43, -w * .47, -l * .25);
    shape.lineTo(-w * .5, l * .25);
    shape.quadraticCurveTo(-w * .48, l * .49, -w * .29, l * .5);
    shape.lineTo(w * .29, l * .5);
    shape.quadraticCurveTo(w * .48, l * .49, w * .5, l * .25);
    shape.lineTo(w * .47, -l * .25);
    shape.quadraticCurveTo(w * .48, -l * .43, w * .32, -l * .5);
    shape.lineTo(w * nose, -l * .5);
    const geo = new THREE.ExtrudeGeometry(shape, { depth: .44, bevelEnabled: true, bevelSegments: 2, steps: 1, bevelSize: .045, bevelThickness: .035 });
    geo.rotateX(Math.PI / 2);
    const shell = new THREE.Mesh(geo, mat(color, .62, .27));
    shell.position.y = .91;
    shell.castShadow = true;
    shell.receiveShadow = true;
    parent.add(shell);
  }
  function addCabin(parent, model, glass) {
    const w = model.width, l = model.length;
    const cabin = new THREE.Group();
    const shape = new THREE.Shape();
    const cw = w * (model.type === 'offroad' ? .34 : .32);
    const front = model.type === 'pickup' ? -.03 : -l * .25;
    const back = model.type === 'pickup' ? l * .12 : l * .24;
    shape.moveTo(-cw, front);
    shape.lineTo(-cw * .82, back);
    shape.quadraticCurveTo(0, back + .12, cw * .82, back);
    shape.lineTo(cw, front);
    shape.quadraticCurveTo(0, front - .14, -cw, front);
    const geo = new THREE.ExtrudeGeometry(shape, { depth: model.open ? .27 : .39, bevelEnabled: true, bevelSegments: 2, bevelSize: .035, bevelThickness: .025 });
    geo.rotateX(Math.PI / 2);
    const shell = new THREE.Mesh(geo, mat(model.open ? 0x263a4b : glass, .25, .18));
    shell.position.y = 1.3;
    shell.castShadow = true;
    cabin.add(shell);
    if (model.open) {
      addBox(cabin, [cw * 1.65, .055, .055], [0, 1.32, back - .02], mat(0xbac6d3, .65, .3));
    }
    parent.add(cabin);
  }
  function buildCar(model, color) {
    const root = new THREE.Group();
    const bodyColor = new THREE.Color(color);
    addBody(root, model, bodyColor);
    const w = model.width, l = model.length;
    const glass = model.type === 'armored' ? 0x182331 : 0x91c8d5;
    addCabin(root, model, glass);

    const tireMat = mat(0x11151c, .05, .92);
    const hubMat = mat(0xb8c6d5, .82, .24);
    const wheelGeo = new THREE.CylinderGeometry(model.wheel, model.wheel, .22, 20);
    wheelGeo.rotateZ(Math.PI / 2);
    const hubGeo = new THREE.CylinderGeometry(model.wheel * .48, model.wheel * .48, .235, 16);
    hubGeo.rotateZ(Math.PI / 2);
    for (const side of [-1, 1]) {
      for (const z of [-l * .32, l * .32]) {
        const wheel = new THREE.Mesh(wheelGeo, tireMat);
        wheel.position.set(side * (w * .48), model.wheel, z);
        wheel.castShadow = true;
        root.add(wheel);
        const hub = new THREE.Mesh(hubGeo, hubMat);
        hub.position.copy(wheel.position);
        root.add(hub);
      }
    }

    const light = mat(0xe8fbff, .2, .18);
    const tail = mat(0xff344e, .15, .2);
    addBox(root, [w * .34, .1, .08], [0, .72, -l * .48], light);
    addBox(root, [w * .3, .1, .08], [0, .72, l * .48], tail);
    addBox(root, [w * .68, .09, .08], [0, .48, -l * .5], mat(0x17212c, .5, .35));

    if (model.type === 'pickup') {
      addBox(root, [w * .76, .22, l * .25], [0, .78, l * .34], mat(0x263548, .35, .45));
      addBox(root, [w * .78, .08, l * .23], [0, .9, l * .34], mat(0x101923, .1, .7));
    }
    if (model.rack || model.type === 'offroad') {
      addBox(root, [w * .72, .07, .07], [0, 1.75, .04], mat(0x9caab9, .8, .25));
      if (model.type === 'offroad') {
        for (const side of [-1, 1]) addBox(root, [.06, .6, .06], [side * w * .34, 1.5, .02], mat(0x9caab9, .75, .3));
      }
    }
    if (model.wing) {
      addBox(root, [w * .82, .08, .25], [0, 1.05, l * .43], mat(0x202a37, .65, .3));
      for (const side of [-1, 1]) addBox(root, [.07, .24, .08], [side * w * .28, .94, l * .4], mat(0x202a37));
    }
    if (model.type === 'rally') {
      addBox(root, [w * .5, .1, .16], [0, 1.68, -.02], mat(0xf5d16a, .4, .35));
    }
    if (model.type === 'classic') {
      for (const side of [-1, 1]) {
        const lamp = new THREE.Mesh(new THREE.CylinderGeometry(.09, .09, .035, 16), light);
        lamp.rotation.x = Math.PI / 2;
        lamp.position.set(side * w * .28, .77, -l * .49);
        root.add(lamp);
      }
    }
    if (model.type === 'armored') {
      addBox(root, [w * .68, .16, .1], [0, 1.0, -l * .36], mat(0x273342, .65, .35));
      addBox(root, [w * .58, .12, .12], [0, .98, l * .4], mat(0x273342, .65, .35));
    }
    if (model.type === 'electric') {
      addBox(root, [w * .46, .05, l * .18], [0, .96, 0], mat(0x8be6e3, .7, .18));
    }

    root.rotation.y = Math.PI;
    return root;
  }

  function setup() {
    const activeSwatch = document.querySelector('.swatch.sel');
    if (activeSwatch) selectedPaint = activeSwatch.style.backgroundColor || selectedPaint;
    const width = Math.max(280, host.clientWidth);
    const height = 260;
    renderer = new THREE.WebGLRenderer({ canvas, antialias: true, alpha: false });
    renderer.setPixelRatio(Math.min(window.devicePixelRatio || 1, 2));
    renderer.setSize(width, height, false);
    renderer.shadowMap.enabled = true;
    renderer.shadowMap.type = THREE.PCFSoftShadowMap;
    scene = new THREE.Scene();
    scene.background = new THREE.Color(0x0c1928);
    scene.fog = new THREE.Fog(0x0c1928, 9, 20);
    camera = new THREE.PerspectiveCamera(34, width / height, .1, 80);
    camera.position.set(5.5, 3.6, 6.4);
    camera.lookAt(0, .65, 0);
    scene.add(new THREE.HemisphereLight(0xbad9ff, 0x152234, 2.1));
    const key = new THREE.DirectionalLight(0xffffff, 3.2);
    key.position.set(-4, 8, 5);
    key.castShadow = true;
    scene.add(key);
    const fill = new THREE.PointLight(0x36d9e8, 20, 12);
    fill.position.set(4, 2.5, -3);
    scene.add(fill);

    const floor = new THREE.Mesh(new THREE.CircleGeometry(6, 64), mat(0x16283b, .25, .68));
    floor.rotation.x = -Math.PI / 2;
    floor.position.y = .01;
    floor.receiveShadow = true;
    scene.add(floor);
    const ring = new THREE.Mesh(new THREE.TorusGeometry(3.4, .018, 8, 100), mat(0x37cbd5, .55, .3));
    ring.rotation.x = Math.PI / 2;
    ring.position.y = .035;
    scene.add(ring);
    const grid = new THREE.GridHelper(12, 24, 0x31536b, 0x20364a);
    grid.position.y = .025;
    scene.add(grid);

    replaceCar();
    canvas.addEventListener('pointerdown', event => { dragging = true; lastX = event.clientX; canvas.setPointerCapture(event.pointerId); });
    canvas.addEventListener('pointermove', event => {
      if (!dragging) return;
      spin += (event.clientX - lastX) * .012;
      lastX = event.clientX;
    });
    canvas.addEventListener('pointerup', () => { dragging = false; });
    canvas.addEventListener('pointercancel', () => { dragging = false; });
    select.addEventListener('change', replaceCar);
    paintPicker?.addEventListener('click', event => {
      const button = event.target.closest('button.swatch');
      if (!button) return;
      selectedPaint = button.style.backgroundColor || selectedPaint;
      replaceCar();
    });
    window.addEventListener('resize', resize);
    animate();
    host.dataset.ready = 'true';
    const status = host.querySelector('[data-garage-status]');
    if (status) status.textContent = '12 оригинальных 3D-концептов · перетаскивай модель, чтобы осмотреть со всех сторон';
  }

  function replaceCar() {
    if (!scene) return;
    if (carGroup) {
      scene.remove(carGroup);
      carGroup.traverse(obj => {
        if (obj.geometry) obj.geometry.dispose();
      });
    }
    const model = models[clamp(select.selectedIndex, 0, models.length - 1)];
    const paint = selectedPaint || getComputedStyle(document.querySelector('.swatch.sel') || host).backgroundColor;
    const normalized = paint && paint.startsWith('rgb') ? new THREE.Color(paint).getStyle() : paint;
    carGroup = buildCar(model, normalized || '#33d6cb');
    scene.add(carGroup);
  }
  function resize() {
    if (!renderer || !camera) return;
    const width = Math.max(280, host.clientWidth);
    renderer.setSize(width, 260, false);
    camera.aspect = width / 260;
    camera.updateProjectionMatrix();
  }
  function animate() {
    raf = requestAnimationFrame(animate);
    if (carGroup && !dragging) spin += .002;
    if (carGroup) carGroup.rotation.y = Math.PI + spin;
    renderer.render(scene, camera);
  }
  try {
    setup();
  } catch (error) {
    const status = host.querySelector('[data-garage-status]');
    if (status) status.textContent = '3D-гараж не загрузился в этом браузере. Остальная игра доступна.';
    console.error('Driftline 3D garage failed:', error);
  }
})();
