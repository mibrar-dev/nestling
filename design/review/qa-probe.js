// QA probe: run inside a screen page (390x844). Returns an array of issues.
(() => {
  const W = 390, H = 844, issues = [];
  const add = (type, el, detail) => {
    const d = el ? (el.id ? '#' + el.id : el.tagName.toLowerCase() + (el.className && typeof el.className === 'string' ? '.' + el.className.trim().split(/\s+/).slice(0, 2).join('.') : '')) : '';
    const txt = el ? (el.innerText || el.getAttribute('aria-label') || '').trim().slice(0, 40) : '';
    issues.push({ type, el: d, text: txt, detail });
  };
  const doc = document.documentElement;
  if (doc.scrollWidth > W + 1) add('page-h-overflow', null, `scrollWidth ${doc.scrollWidth}`);
  if (document.body.getBoundingClientRect().width !== W) add('body-width', null, `${document.body.getBoundingClientRect().width}`);
  const visible = el => { const s = getComputedStyle(el); return s.display !== 'none' && s.visibility !== 'hidden' && +s.opacity > 0.05; };
  // Is element clipped by an ancestor that scrolls horizontally-hidden? treat anything beyond frame as overflow
  const all = [...document.body.querySelectorAll('*')].filter(e => !(e.closest('svg') && e.tagName.toLowerCase() !== 'svg'));
  const clippedByAncestor = el => {
    for (let p = el.parentElement; p && p !== document.body; p = p.parentElement) {
      const s = getComputedStyle(p);
      if (/(hidden|clip)/.test(s.overflowX) || /(auto|scroll)/.test(s.overflowX)) return p;
    }
    return null;
  };
  for (const el of all) {
    if (!visible(el)) continue;
    const r = el.getBoundingClientRect();
    if (r.width === 0 || r.height === 0) continue;
    // horizontal escape from device frame
    if ((r.right > W + 1 || r.left < -1) && !clippedByAncestor(el)) add('x-overflow', el, `left ${r.left.toFixed(0)} right ${r.right.toFixed(0)}`);
    // text clipping inside element
    const s = getComputedStyle(el);
    const hasText = [...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim());
    if (hasText && el.scrollWidth > el.clientWidth + 1 && s.textOverflow !== 'ellipsis' && /(hidden|clip)/.test(s.overflowX)) add('text-clipped', el, `scrollW ${el.scrollWidth} > ${el.clientWidth}`);
    if (hasText && el.scrollWidth > el.clientWidth + 1 && s.overflowX === 'visible' && el.clientWidth > 0 && s.display !== 'inline') add('text-spills', el, `scrollW ${el.scrollWidth} > ${el.clientWidth}`);
    // small fonts
    if (hasText && parseFloat(s.fontSize) < 11) add('tiny-font', el, s.fontSize);
  }
  // tap targets
  const kid = !!document.querySelector('.screen.kid');
  const minT = kid ? 56 : 44;
  for (const el of document.querySelectorAll('button, a, [role=button], input, .btn, .chip, .toggle, .list-row[onclick]')) {
    if (!visible(el)) continue;
    const r = el.getBoundingClientRect();
    if (r.width === 0) continue;
    const isInline = el.tagName === 'A' && getComputedStyle(el).display === 'inline';
    if (!isInline && (r.height < minT - 0.5 || r.width < Math.min(minT, 44) - 0.5) && !el.classList.contains('chip')) add('small-target', el, `${r.width.toFixed(0)}x${r.height.toFixed(0)} (min ${minT})`);
    if ((el.tagName === 'BUTTON' || el.getAttribute('role') === 'button') && !(el.innerText || '').trim() && !el.getAttribute('aria-label')) add('no-label', el, 'icon button without aria-label');
  }
  // overlap: fixed bottom bars covering the last scroll content
  const scrollers = [...document.querySelectorAll('.scroll')];
  const bottomBars = [...document.querySelectorAll('.tab-bar, .bottom-cta, .kid-dock, [class*=dock], .fab, .home-indicator')].filter(visible);
  for (const sc of scrollers) {
    const last = sc.lastElementChild; if (!last) continue;
    sc.scrollTop = sc.scrollHeight;
    const lr = last.getBoundingClientRect();
    for (const b of bottomBars) { if (sc.contains(b)) continue; const br = b.getBoundingClientRect(); if (lr.bottom > br.top + 2 && lr.top < br.bottom) add('covered-by-bar', last, `last item bottom ${lr.bottom.toFixed(0)} > bar top ${br.top.toFixed(0)}`); }
    sc.scrollTop = 0;
  }
  // content below the fold with no scroll container
  for (const el of all) { if (!visible(el)) continue; const r = el.getBoundingClientRect(); if (r.top > H + 1 && !el.closest('.scroll') && r.height > 0) { add('below-fold-unscrollable', el, `top ${r.top.toFixed(0)}`); break; } }
  // broken images
  for (const img of document.images) if (!img.complete || img.naturalWidth === 0) add('broken-img', img, img.getAttribute('src'));
  for (const o of document.querySelectorAll('object,use')) {}
  // contrast (approx: solid bg lookup)
  const parse = c => { const m = c.match(/rgba?\(([^)]+)\)/); if (!m) return null; const p = m[1].split(',').map(x => parseFloat(x)); return { r: p[0], g: p[1], b: p[2], a: p[3] ?? 1 }; };
  const lum = ({ r, g, b }) => { const f = v => { v /= 255; return v <= .03928 ? v / 12.92 : Math.pow((v + .055) / 1.055, 2.4); }; return .2126 * f(r) + .7152 * f(g) + .0722 * f(b); };
  const bgOf = el => { for (let p = el; p; p = p.parentElement) { const s = getComputedStyle(p); if (s.backgroundImage !== 'none') return null; const c = parse(s.backgroundColor); if (c && c.a > .9) return c; } return { r: 255, g: 255, b: 255, a: 1 }; };
  let cc = 0;
  for (const el of all) {
    if (!visible(el)) continue;
    const hasText = [...el.childNodes].some(n => n.nodeType === 3 && n.textContent.trim()); if (!hasText) continue;
    const s = getComputedStyle(el); const fg = parse(s.color); const bg = bgOf(el); if (!fg || !bg || fg.a < .9) continue;
    const L1 = lum(fg), L2 = lum(bg); const ratio = (Math.max(L1, L2) + .05) / (Math.min(L1, L2) + .05);
    const big = parseFloat(s.fontSize) >= 24 || (parseFloat(s.fontSize) >= 18.66 && +s.fontWeight >= 700);
    if (ratio < (big ? 3 : 4.5)) { add('low-contrast', el, `${ratio.toFixed(2)}:1`); if (++cc > 8) break; }
  }
  // fonts
  const fams = new Set(all.map(e => getComputedStyle(e).fontFamily.split(',')[0].replace(/["']/g, '').trim()));
  const bad = [...fams].filter(f => !/^(Inter|Nunito|system-ui|-apple-system)$/i.test(f));
  if (bad.length) add('off-spec-font', null, bad.join(', '));
  if (!document.querySelector('link[href*="tokens.css"]')) add('missing-tokens-css', null, '');
  if (!document.querySelector('.status-bar')) add('missing-status-bar', null, '');
  if (!document.querySelector('.home-indicator')) add('missing-home-indicator', null, '');
  if (/lorem|ipsum|TODO|placeholder/i.test(document.body.innerText)) add('placeholder-text', null, '');
  // dedupe
  const seen = new Set();
  return issues.filter(i => { const k = i.type + i.el + i.detail; if (seen.has(k)) return false; seen.add(k); return true; }).slice(0, 40);
})()
