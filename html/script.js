const RESOURCE = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'bdev-christmas';
const IMAGE_PATH = 'nui://ox_inventory/web/images/';

// Board layout: door numbers are scattered like a real advent calendar.
// Door 25 is the big double door.
const BOARD = [7, 19, 2, 13, 22, 5, 16, 10, 1, 25, 18, 8, 21, 4, 12, 23, 15, 3, 9, 17, 11, 24, 20, 6, 14];
const TONES = { 2: 'gold', 5: 'green', 9: 'green', 12: 'gold', 14: 'green', 17: 'gold', 20: 'green', 23: 'green', 24: 'gold' };
const RARITY_LABEL = { common: 'Common', uncommon: 'Uncommon', rare: 'Rare', epic: 'Epic', legendary: 'Legendary' };
const RANK = { common: 1, uncommon: 2, rare: 3, epic: 4, legendary: 5 };

const el = (id) => document.getElementById(id);
const app = el('app');
const panel = el('panel');
const wheel = el('wheel');
const wctx = wheel.getContext('2d');

let state = null;
let selectedDay = null;
let serverOffset = 0;
let spinning = false;
let refreshing = false;
let ticker = null;
let rotation = 0; // radians
let segments = [];
let tab = 'advent';
let solo = false;
let unwrapCtx = null;
let audio = null;

/* ---------- Utilities ---------- */

function post(endpoint, data = {}) {
    return fetch(`https://${RESOURCE}/${endpoint}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data),
    }).then((res) => res.json()).catch(() => null);
}

const serverNow = () => Math.floor(Date.now() / 1000) + serverOffset;
const pad = (n) => String(n).padStart(2, '0');
const rc = (rarity) => `var(--r-${rarity || 'common'})`;

function splitTime(seconds) {
    seconds = Math.max(0, seconds);
    return {
        d: Math.floor(seconds / 86400),
        h: Math.floor((seconds % 86400) / 3600),
        m: Math.floor((seconds % 3600) / 60),
        s: seconds % 60,
    };
}

function svgFor(name) {
    return `<svg viewBox="0 0 64 64" xmlns="http://www.w3.org/2000/svg">${ART[name] || ART.xmas_present}</svg>`;
}

/** Item picture: bundled art for this resource's items, ox_inventory image for anything else. */
function iconHtml(name) {
    if (ART[name]) return svgFor(name);
    return `<img src="${IMAGE_PATH}${name}.png" alt="" onerror="this.outerHTML=svgFor('xmas_present')">`;
}

function prizeText(reward) {
    return reward.money ? `$${Number(reward.count).toLocaleString()}` : `${reward.count}x ${reward.label}`;
}

function escapeHtml(text) {
    return String(text ?? '').replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c]));
}

function ago(at) {
    const s = serverNow() - at;
    if (s < 60) return 'just now';
    if (s < 3600) return `${Math.floor(s / 60)}m ago`;
    if (s < 86400) return `${Math.floor(s / 3600)}h ago`;
    return `${Math.floor(s / 86400)}d ago`;
}

let toastTimer = null;
function toast(message) {
    const t = el('toast');
    t.textContent = message;
    t.classList.remove('hidden');
    clearTimeout(toastTimer);
    toastTimer = setTimeout(() => t.classList.add('hidden'), 3200);
}

/* ---------- Sound: sleigh bells made with WebAudio, no files needed ---------- */

function ensureAudio() {
    if (!audio) {
        try { audio = new (window.AudioContext || window.webkitAudioContext)(); } catch { audio = null; }
    }
    return audio;
}

function bell(freq, duration = 0.3, volume = 0.05, delay = 0) {
    const ctx = ensureAudio();
    if (!ctx) return;
    const t = ctx.currentTime + delay;
    [1, 2.76].forEach((mult, i) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = 'sine';
        osc.frequency.setValueAtTime(freq * mult, t);
        gain.gain.setValueAtTime(volume / (i + 1), t);
        gain.gain.exponentialRampToValueAtTime(0.0001, t + duration);
        osc.connect(gain).connect(ctx.destination);
        osc.start(t);
        osc.stop(t + duration);
    });
}

function jingle(rank) {
    const notes = rank >= RANK.epic ? [659, 659, 659, 659, 659, 659, 659, 784, 523, 587, 659] : [659, 659, 659];
    const gap = rank >= RANK.epic ? 0.13 : 0.16;
    notes.forEach((f, i) => bell(f, 0.35, 0.05, i * gap));
}

/* ---------- Snow ---------- */

const snow = el('snow');
const sctx = snow.getContext('2d');
let flakes = [];
let snowRunning = false;

function sizeSnow() {
    snow.width = panel.clientWidth;
    snow.height = panel.clientHeight;
    const count = Math.round(40 + (state ? cheer() : 0) * 90);
    flakes = Array.from({ length: count }, () => ({
        x: Math.random() * snow.width,
        y: Math.random() * snow.height,
        r: Math.random() * 2 + 0.6,
        s: Math.random() * 0.5 + 0.25,
        d: Math.random() * Math.PI * 2,
    }));
}

function snowLoop() {
    if (!snowRunning) return;
    sctx.clearRect(0, 0, snow.width, snow.height);
    sctx.fillStyle = 'rgba(243, 239, 230, 0.7)';
    for (const f of flakes) {
        f.y += f.s;
        f.d += 0.01;
        f.x += Math.sin(f.d) * 0.3;
        if (f.y > snow.height) { f.y = -4; f.x = Math.random() * snow.width; }
        sctx.beginPath();
        sctx.arc(f.x, f.y, f.r, 0, Math.PI * 2);
        sctx.fill();
    }
    requestAnimationFrame(snowLoop);
}

/* ---------- Confetti ---------- */

function confetti(rank) {
    const c = el('confetti');
    const x = c.getContext('2d');
    c.width = innerWidth;
    c.height = innerHeight;
    const colors = ['#c8303f', '#e9b955', '#f3efe6', '#2f7a5f', rank >= RANK.legendary ? '#ffc94a' : '#c58cff'];
    const n = rank >= RANK.legendary ? 240 : rank >= RANK.epic ? 160 : 90;
    const parts = Array.from({ length: n }, () => ({
        x: c.width / 2, y: c.height * 0.4,
        vx: (Math.random() - 0.5) * 18, vy: Math.random() * -16 - 4,
        r: Math.random() * Math.PI, w: Math.random() * 8 + 4,
        c: colors[Math.floor(Math.random() * colors.length)],
    }));
    const t0 = performance.now();
    (function loop(t) {
        x.clearRect(0, 0, c.width, c.height);
        parts.forEach((p) => {
            p.vy += 0.42; p.vx *= 0.985; p.x += p.vx; p.y += p.vy; p.r += 0.15;
            x.save(); x.translate(p.x, p.y); x.rotate(p.r);
            x.fillStyle = p.c; x.fillRect(-p.w / 2, -p.w / 4, p.w, p.w / 2);
            x.restore();
        });
        if (t - t0 < 3200) requestAnimationFrame(loop);
        else x.clearRect(0, 0, c.width, c.height);
    })(t0);
}

/* ---------- Cheer ---------- */

function todayEntry() {
    if (!state) return null;
    const index = Math.min(Math.max(state.today, 1), state.days.length);
    return state.days[index - 1];
}

function cheer() {
    const today = todayEntry();
    return today && state.phase !== 'before' ? today.intensity : 0;
}

function applyCheer() {
    const today = todayEntry();
    if (!today) return;
    el('cheer-label').textContent = state.phase === 'before' ? 'Waiting' : today.cheer;
    el('cheer-fill').style.width = `${Math.round(Math.max(0.04, cheer()) * 100)}%`;
    panel.style.setProperty('--cheer', cheer().toFixed(3));
}

/* ---------- Countdown ---------- */

function renderCountdownUnits() {
    el('countdown-main').innerHTML = ['Days', 'Hours', 'Min', 'Sec']
        .map((label, i) => `<div class="unit"><span id="cd-${i}">00</span><small>${label}</small></div>`)
        .join('');
}

function tick() {
    if (!state) return;
    const now = serverNow();
    const main = el('countdown-main');
    const sub = el('countdown-sub');
    const anyOpen = state.days.some((d) => d.status === 'available' || d.status === 'pending');

    const toChristmas = state.christmas - now;
    if (toChristmas <= 0 || state.phase === 'after') {
        main.classList.add('done');
        main.textContent = state.phase === 'after' && !anyOpen ? 'See you next Christmas!' : 'Merry Christmas!';
    } else {
        if (main.classList.contains('done') || !main.childElementCount) {
            main.classList.remove('done');
            renderCountdownUnits();
        }
        const t = splitTime(toChristmas);
        [t.d, t.h, t.m, t.s].forEach((v, i) => { el(`cd-${i}`).textContent = pad(v); });
    }

    if (state.nextUnlock) {
        const remaining = state.nextUnlock - now;
        if (remaining <= 0) {
            sub.textContent = 'A new door just unlocked!';
            refresh();
        } else {
            const t = splitTime(remaining);
            const clock = `${t.d > 0 ? `${t.d}d ` : ''}${pad(t.h)}:${pad(t.m)}:${pad(t.s)}`;
            const label = state.phase === 'before' ? 'The first door opens in' : 'Next door unlocks in';
            sub.innerHTML = `${label} <b>${clock}</b>`;
        }
    } else if (state.phase === 'active') {
        sub.textContent = 'Door 25 is open. Best wheel of the season!';
    } else if (state.phase === 'after') {
        sub.textContent = anyOpen ? 'Last chance! Your last door expires at midnight.' : 'The advent calendar has closed.';
    } else {
        sub.textContent = '';
    }
}

async function refresh() {
    if (refreshing || spinning) return;
    refreshing = true;
    const fresh = await post('refresh');
    refreshing = false;
    if (fresh) setState(fresh);
}

/* ---------- Wheel ---------- */

const artImages = {};
function artImage(name) {
    if (!artImages[name]) {
        const img = new Image();
        img.onload = () => drawWheel();
        img.src = `data:image/svg+xml;charset=utf-8,${encodeURIComponent(svgFor(name))}`;
        artImages[name] = img;
    }
    return artImages[name];
}

function setSegments(list) {
    const total = list.reduce((sum, s) => sum + s.weight, 0) || 1;
    let angle = 0;
    segments = list.map((s) => {
        const span = (s.weight / total) * Math.PI * 2;
        const seg = { ...s, start: angle, end: angle + span };
        angle += span;
        return seg;
    });
}

function drawWheel(winner) {
    const W = wheel.width;
    const c = W / 2;
    const R = c - 16;
    wctx.clearRect(0, 0, W, W);
    wctx.save();
    wctx.translate(c, c);

    wctx.beginPath(); wctx.arc(0, 0, R + 12, 0, Math.PI * 2); wctx.fillStyle = '#5a3b0a'; wctx.fill();
    wctx.beginPath(); wctx.arc(0, 0, R + 7, 0, Math.PI * 2); wctx.fillStyle = '#e9b955'; wctx.fill();

    wctx.save();
    wctx.rotate(rotation);
    segments.forEach((seg, i) => {
        // Angles are measured clockwise from the top.
        const a0 = seg.start - Math.PI / 2;
        const a1 = seg.end - Math.PI / 2;
        wctx.beginPath(); wctx.moveTo(0, 0); wctx.arc(0, 0, R, a0, a1); wctx.closePath();
        wctx.fillStyle = seg.color;
        wctx.fill();
        if (i % 2) { wctx.fillStyle = 'rgba(0,0,0,0.12)'; wctx.fill(); }
        if (winner === i + 1) { wctx.fillStyle = 'rgba(255,255,255,0.25)'; wctx.fill(); }
        wctx.strokeStyle = 'rgba(12,31,27,0.6)';
        wctx.lineWidth = 3;
        wctx.stroke();

        const span = seg.end - seg.start;
        if (span < 0.12) return; // tiny slices just show colour
        const mid = (seg.start + seg.end) / 2;
        const size = Math.min(70, 30 + span * 70);
        wctx.save();
        wctx.rotate(mid);
        const img = artImage(seg.art);
        if (img.complete && img.naturalWidth) wctx.drawImage(img, -size / 2, -R * 0.9, size, size);
        if (span > 0.35) {
            wctx.translate(0, -R * 0.9 + size + 26);
            wctx.rotate(Math.PI / 2 * (mid > Math.PI ? 1 : -1));
            wctx.font = '800 22px Karla, sans-serif';
            wctx.textAlign = 'center';
            wctx.textBaseline = 'middle';
            wctx.lineWidth = 4;
            wctx.strokeStyle = 'rgba(0,0,0,0.45)';
            wctx.strokeText(seg.label, 0, 0);
            wctx.fillStyle = '#fff';
            wctx.fillText(seg.label, 0, 0);
        }
        wctx.restore();
    });
    wctx.restore();

    for (let i = 0; i < 28; i++) {
        const t = (i / 28) * Math.PI * 2;
        wctx.beginPath();
        wctx.arc(Math.cos(t) * (R + 4), Math.sin(t) * (R + 4), 5, 0, Math.PI * 2);
        wctx.fillStyle = i % 2 ? '#fff6d0' : '#ff6b6b';
        wctx.fill();
    }
    wctx.restore();
}

function segmentUnderPointer(rot) {
    const angle = ((Math.PI * 2 - (rot % (Math.PI * 2))) % (Math.PI * 2) + Math.PI * 2) % (Math.PI * 2);
    return segments.findIndex((s) => angle >= s.start && angle < s.end);
}

function animateTo(segment, intensity) {
    const seg = segments[segment - 1];
    const span = seg.end - seg.start;
    const landAt = seg.start + span * (0.15 + Math.random() * 0.7);
    const full = Math.PI * 2;
    const spins = 5 + Math.round(intensity * 3);
    const duration = 5200 + intensity * 2000;
    const from = rotation;
    const base = Math.ceil(from / full) * full;
    const to = base + spins * full + ((full - landAt) % full);
    const ease = (t) => 1 - Math.pow(1 - t, 4);

    const pointer = el('pointer');
    let last = segmentUnderPointer(from);
    const t0 = performance.now();

    return new Promise((resolve) => {
        function frame(now) {
            const t = Math.min(1, (now - t0) / duration);
            rotation = from + (to - from) * ease(t);
            drawWheel();
            const current = segmentUnderPointer(rotation);
            if (current !== last) {
                last = current;
                pointer.classList.remove('tick');
                void pointer.offsetWidth;
                pointer.classList.add('tick');
                bell(1400, 0.05, 0.02);
            }
            if (t < 1) requestAnimationFrame(frame);
            else { rotation %= full; resolve(); }
        }
        requestAnimationFrame(frame);
    });
}

/* ---------- Advent board ---------- */

const selected = () => state && state.days[selectedDay - 1];

function doorTag(day) {
    switch (day.status) {
        case 'available': return 'Open';
        case 'pending': return 'Collect';
        case 'missed': return 'Expired';
        case 'locked': return `Dec ${day.day}`;
        default: return '';
    }
}

function renderBoard() {
    const board = el('board');
    board.innerHTML = '';
    BOARD.forEach((n) => {
        const day = state.days[n - 1];
        if (!day) return;
        const door = document.createElement('button');
        door.className = `door ${day.status} tone-${TONES[n] || 'red'}${n === state.days.length ? ' big' : ''}${n === selectedDay ? ' selected' : ''}`;
        const inside = day.reward
            ? `${iconHtml(day.reward.name)}<span class="count">${day.reward.money ? '$' : '×'}${day.reward.money ? Number(day.reward.count).toLocaleString() : day.reward.count}</span>`
            : '';
        door.innerHTML = `<span class="inside">${inside}</span><span class="flap"><span class="n">${n}</span><span class="tag">${doorTag(day)}</span></span>`;
        door.addEventListener('click', () => {
            if (spinning) return;
            selectedDay = n;
            renderBoard();
            renderSpinPanel();
        });
        board.appendChild(door);
    });
}

function renderSpinPanel() {
    const day = selected();
    if (!day) return;
    const grand = day.day === state.days.length;

    el('detail-eyebrow').textContent = grand ? 'Christmas Day' : `Door ${day.day} · ${day.cheer}`;
    el('detail-title').textContent = `December ${day.day}`;
    el('hub').textContent = day.day;

    if (!spinning) {
        setSegments(day.wheel);
        drawWheel(day.status === 'claimed' ? day.segment : undefined);
    }

    const btn = el('spin');
    const note = el('detail-note');
    btn.disabled = spinning;

    switch (day.status) {
        case 'available':
            btn.textContent = 'Spin';
            note.textContent = grand ? 'The best wheel of the season.' : 'One spin per door. Slices are drawn at their real odds.';
            break;
        case 'pending':
            btn.textContent = 'Collect prize';
            note.textContent = day.reward ? `You won ${prizeText(day.reward)}. Make room in your pockets to collect it.` : 'Your prize is waiting.';
            break;
        case 'claimed':
            btn.textContent = 'Opened';
            btn.disabled = true;
            note.textContent = day.reward ? `You won ${prizeText(day.reward)}.` : 'Already opened.';
            break;
        case 'missed':
            btn.textContent = 'Expired';
            btn.disabled = true;
            note.textContent = 'This door expired. Doors stay open for their own day plus a short grace period.';
            break;
        default:
            btn.textContent = 'Locked';
            btn.disabled = true;
            note.textContent = `Unlocks at midnight on December ${day.day}.`;
    }
}

async function onSpin() {
    const day = selected();
    if (!day || spinning || (day.status !== 'available' && day.status !== 'pending')) return;

    spinning = true;
    renderSpinPanel();
    const res = await post('spin', { day: day.day });

    if (!res) {
        spinning = false;
        renderSpinPanel();
        toast('No response from the server.');
        return;
    }

    if (res.segment && res.animate) {
        await animateTo(res.segment, day.intensity);
        drawWheel(res.segment);
    }
    spinning = false;

    if (res.reward && (res.ok || res.animate)) showResult(day, res);
    else if (res.message) toast(res.message);

    if (res.state) setState(res.state);
    else refresh();
}

function showResult(day, res) {
    const reward = res.reward;
    const card = el('result-card');
    card.style.setProperty('--rc', rc(reward.rarity));
    el('result-eyebrow').textContent = `Door ${day.day}`;
    el('result-icon').innerHTML = iconHtml(reward.name);
    el('result-title').textContent = prizeText(reward);
    el('result-tier').textContent = `${reward.tierLabel || ''} · ${RARITY_LABEL[reward.rarity] || 'Common'}`;
    el('result-note').textContent = res.ok
        ? (reward.name.startsWith('xmas_present') ? 'Use it from your inventory or the Presents tab to unwrap it.' : 'Added to your pockets.')
        : res.message;
    el('result').classList.remove('hidden');
    jingle(RANK[reward.rarity] || 1);
    if ((RANK[reward.rarity] || 1) >= RANK.rare) confetti(RANK[reward.rarity]);
}

/* ---------- Presents view ---------- */

function renderPresents() {
    const presents = el('presents');
    presents.innerHTML = '';
    let total = 0;
    (state.presents || []).forEach((p) => {
        total += p.count;
        const card = document.createElement('div');
        card.className = `present${p.count ? '' : ' empty'}`;
        card.style.setProperty('--rc', rc(p.rarity));
        card.innerHTML = `<span class="qty">×${p.count}</span>${iconHtml(p.name)}<span class="nm">${escapeHtml(p.label)}</span><span class="rar">${RARITY_LABEL[p.rarity]}</span>`;
        const btn = document.createElement('button');
        btn.className = 'btn gold small';
        btn.textContent = 'Unwrap';
        btn.disabled = !p.count;
        btn.addEventListener('click', () => unwrapFromMenu(p.name));
        card.appendChild(btn);
        presents.appendChild(card);
    });
    el('opened-count').textContent = `${state.opened || 0} unwrapped`;

    const pending = state.pending || [];
    el('pending-block').classList.toggle('hidden', !pending.length);
    el('pending').innerHTML = '';
    pending.forEach((g) => {
        const row = document.createElement('div');
        row.className = 'row';
        row.innerHTML = `${iconHtml(g.reward.name)}<span class="t"><b>${escapeHtml(prizeText(g.reward))}</b><small>From a ${escapeHtml(g.present.label)}</small></span>`;
        const btn = document.createElement('button');
        btn.className = 'btn small';
        btn.textContent = 'Collect';
        btn.addEventListener('click', async () => {
            btn.disabled = true;
            const res = await post('collect', { id: g.id });
            toast(res ? res.message : 'No response from the server.');
            refresh();
        });
        row.appendChild(btn);
        el('pending').appendChild(row);
    });

    const collection = state.collection || [];
    const found = collection.filter((c) => c.found).length;
    el('collection-count').textContent = `${found} of ${collection.length}`;
    el('collection').innerHTML = collection.map((c) => `
        <div class="slot${c.found ? '' : ' missing'}" style="--rc:${rc(c.rarity)}">
            ${iconHtml(c.name)}
            <span class="lbl">${c.found ? escapeHtml(c.label) : '???'}</span>
            <span class="rar">${RARITY_LABEL[c.rarity]}</span>
        </div>`).join('');

    const feed = state.feed || [];
    el('feed').innerHTML = feed.length
        ? feed.map((f) => `<li class="row" style="--rc:${rc(f.reward.rarity)}">${iconHtml(f.reward.name)}
            <span class="t"><b>${escapeHtml(f.who)}</b> found <b style="color:${rc(f.reward.rarity)}">${escapeHtml(prizeText(f.reward))}</b>
            <small>in a ${escapeHtml(f.present.label)}</small></span><time>${ago(f.at)}</time></li>`).join('')
        : '<li class="empty-note">No rare finds yet. Unwrap a present and you could be first.</li>';

    const leaders = state.leaderboard || [];
    el('board-block').classList.toggle('hidden', !leaders.length);
    el('leaders').innerHTML = leaders.map((l, i) =>
        `<li><b>${i + 1}</b><span>${escapeHtml(l.who || 'Someone')}</span><em>${l.total}</em></li>`).join('');

    const advent = state.days.filter((d) => d.status === 'available' || d.status === 'pending').length;
    setBadge('badge-advent', advent);
    setBadge('badge-presents', total + pending.length);
}

function setBadge(id, n) {
    const b = el(id);
    b.textContent = n;
    b.classList.toggle('hidden', !n);
}

function setTab(name) {
    tab = name;
    document.querySelectorAll('.tab').forEach((t) => t.classList.toggle('active', t.dataset.tab === name));
    el('view-advent').classList.toggle('hidden', name !== 'advent');
    el('view-presents').classList.toggle('hidden', name !== 'presents');
}

/* ---------- Unwrap (loot box) ---------- */

async function unwrapFromMenu(name) {
    const res = await post('unwrap', { name });
    if (!res || !res.ok) {
        toast(res ? res.message : 'No response from the server.');
        refresh();
        return;
    }
    startUnwrap(res);
}

function startUnwrap(data) {
    unwrapCtx = { ...data, taps: 0, done: false };
    const stage = el('stage');
    stage.classList.remove('revealed');
    stage.style.setProperty('--rc', rc(data.reward.rarity));

    const gift = el('gift');
    gift.innerHTML = svgFor(data.present.name);
    gift.style.visibility = '';
    el('prize').innerHTML = iconHtml(data.reward.name);

    const rar = el('u-rarity');
    rar.textContent = data.present.label;
    rar.style.setProperty('--rc', rc(data.present.rarity));
    el('u-title').textContent = 'Tap to unwrap';
    const text = el('u-text');
    text.textContent = 'Give it three good shakes.';
    text.classList.remove('warn');
    el('taps').classList.remove('hidden');
    [...el('taps').children].forEach((s) => s.classList.remove('on'));
    el('u-actions').innerHTML = '';
    el('unwrap').classList.remove('hidden');
}

el('gift').addEventListener('click', () => {
    const u = unwrapCtx;
    if (!u || u.done) return;
    u.taps += 1;
    [...el('taps').children].forEach((s, i) => s.classList.toggle('on', i < u.taps));
    const gift = el('gift');
    gift.classList.remove('shake');
    void gift.offsetWidth;
    gift.classList.add('shake');
    bell(900 + u.taps * 120, 0.15, 0.04);

    const rank = RANK[u.reward.rarity] || 1;
    if (u.taps === 2) el('u-text').textContent = rank >= RANK.epic ? 'Something heavy is rattling in there…' : 'One more!';
    if (u.taps >= 3) {
        u.done = true;
        setTimeout(reveal, 380);
    }
});

async function reveal() {
    const u = unwrapCtx;
    const reward = u.reward;
    const rank = RANK[reward.rarity] || 1;

    el('stage').classList.add('revealed');
    el('taps').classList.add('hidden');
    const rar = el('u-rarity');
    rar.textContent = RARITY_LABEL[reward.rarity] || 'Common';
    rar.style.setProperty('--rc', rc(reward.rarity));
    el('u-title').textContent = prizeText(reward);
    el('u-text').textContent = 'Wrapping it up for you…';
    setTimeout(() => { el('gift').style.visibility = 'hidden'; }, 550);

    jingle(rank);
    if (rank >= RANK.rare) confetti(rank);

    const res = await post('collect', { id: u.id });
    const text = el('u-text');
    if (res && res.ok) {
        text.textContent = reward.name.startsWith('xmas_present') ? 'Another present! Unwrap it whenever you like.' : 'Added to your pockets.';
    } else {
        text.textContent = res ? res.message : 'No response from the server. Your gift is saved, collect it from the Presents tab.';
        text.classList.add('warn');
    }

    const remaining = res && typeof res.remaining === 'number' ? res.remaining : 0;
    const actions = el('u-actions');
    actions.innerHTML = '';
    if (remaining > 0) {
        const again = document.createElement('button');
        again.className = 'btn gold';
        again.textContent = `Unwrap another (${remaining} left)`;
        again.addEventListener('click', () => unwrapFromMenu(u.present.name));
        actions.appendChild(again);
    }
    const done = document.createElement('button');
    done.className = 'btn';
    done.textContent = solo ? 'Close' : 'Back to the calendar';
    done.addEventListener('click', finishUnwrap);
    actions.appendChild(done);
}

function finishUnwrap() {
    el('unwrap').classList.add('hidden');
    unwrapCtx = null;
    if (solo) {
        post('close');
        hide();
    } else {
        refresh();
    }
}

/* ---------- Open / close ---------- */

function setState(next) {
    state = next;
    serverOffset = state.now - Math.floor(Date.now() / 1000);
    el('server-name').textContent = state.serverName || '';

    if (!selectedDay || !state.days[selectedDay - 1]) {
        const open = state.days.find((d) => d.status === 'available' || d.status === 'pending');
        selectedDay = open ? open.day : Math.max(1, Math.min(state.today || 1, state.days.length));
    }

    applyCheer();
    renderBoard();
    renderSpinPanel();
    renderPresents();
    tick();
}

function show(isSolo) {
    solo = isSolo;
    app.classList.toggle('solo', solo);
    app.classList.remove('hidden');
    if (!solo) {
        sizeSnow();
        if (!snowRunning) { snowRunning = true; snowLoop(); }
        clearInterval(ticker);
        ticker = setInterval(tick, 1000);
    }
}

function hide() {
    app.classList.add('hidden');
    el('result').classList.add('hidden');
    el('unwrap').classList.add('hidden');
    snowRunning = false;
    clearInterval(ticker);
    unwrapCtx = null;
    solo = false;
}

function requestClose() {
    if (spinning) return;
    if (unwrapCtx && !unwrapCtx.done) {
        // Closing mid-unwrap is fine: the gift is saved and shows under Unclaimed gifts.
        toast('Your gift is saved under Unclaimed gifts.');
    }
    post('close');
    hide();
}

window.addEventListener('message', (event) => {
    const msg = event.data || {};
    if (msg.action === 'open') {
        setTab('advent');
        show(false);
        setState(msg.state);
    } else if (msg.action === 'unwrap') {
        show(!!msg.solo);
        startUnwrap(msg.data);
    } else if (msg.action === 'close') {
        hide();
    }
});

document.addEventListener('keydown', (e) => {
    if (e.key !== 'Escape' || app.classList.contains('hidden')) return;
    if (!el('result').classList.contains('hidden')) { el('result').classList.add('hidden'); return; }
    if (!el('unwrap').classList.contains('hidden') && unwrapCtx && unwrapCtx.done && !solo) { finishUnwrap(); return; }
    requestClose();
});

el('close').addEventListener('click', requestClose);
el('spin').addEventListener('click', onSpin);
el('result-ok').addEventListener('click', () => el('result').classList.add('hidden'));
document.querySelectorAll('.tab').forEach((t) => t.addEventListener('click', () => setTab(t.dataset.tab)));
window.addEventListener('resize', () => { if (snowRunning) sizeSnow(); });
