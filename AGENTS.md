# The Resonance build swarm

Five specialists share one file. This doc keeps them out of each other's way.

The strategy layer lives in [`RESONANCE_TEAM.md`](RESONANCE_TEAM.md) — the executive team (founder / brand / growth / product / design / keeper / steward) decides *what* and *why*. The build swarm below decides *how*, in lanes.

## The roster

| Agent | Lane | One-line job |
|---|---|---|
| `AUDIO_AGENT` | Sound & Synthesis | Turn a frequency into a sound. Nothing else. |
| `UX_AGENT` | Navigation, Flow & Layout | Decide what tab a thing lives on and what to tap next. |
| `FEATURES_AGENT` | Mechanics & Progression | Write the rules of awakenings / streaks / quests / Plates / Locker / etc. |
| `DATA_AGENT` | Persistence & Backend Readiness | Every `localStorage` read/write goes through me. |
| `POLISH_AGENT` | Motion, Micro-interactions, Cinematics | Every keyframe, every notification, every glass surface. |

Full charters and ownership lists live in [`agents-config.json`](agents-config.json).

## The constraint

**Everything is one file.** `/Users/elliotgoldmanai/resonance/resonance.html` (≈600 KB). CSS in the one `<style>`. JS in the one inline `<script>`. There is no module system, no per-agent file split. So "files each agent edits" maps to **sections of resonance.html** — not separate files.

The rules below exist because five agents editing one file is the failure mode we are designing against.

## Section markers

Every block of code one agent owns is bracketed with a banner comment. The banner is the contract — if you didn't write it, don't touch the body.

```css
/* ============ POLISH_AGENT · NOTIFICATION STACK ============ */
.notify-card { … }
/* ============ /POLISH_AGENT ============ */
```

```js
// =================== FEATURES_AGENT · LOCKER ===================
function lockerLog(hz) { … }
// =================== /FEATURES_AGENT ===================
```

When you add a new block, banner it. When you find an un-bannered block in your lane, banner it as you touch it (lightweight cleanup, no big refactors).

## Which lane edits what (within resonance.html)

Single-file means the agent boundaries are **by responsibility, not by location**. But there are recognizable zones:

| Zone | Owner | Examples |
|---|---|---|
| `<style>` blocks marked `@keyframes`, `.notify-*`, `.moment*`, `.float-gain`, `.boot-*` | `POLISH_AGENT` | animations, glass surfaces, cinematic overlays |
| `<style>` blocks for layout (`.lobby`, `.depth-page`, `.council-*`, `.ascend-*`, `.tab-bar`, `.page`) | `UX_AGENT` | structure, spacing, breakpoints |
| `<style>` blocks for game pieces (`.tier-card`, `.plate-*`, `.season-*`, `.rising-*`, `.locker-*`, `.ch-*`, `.awk-*`) | `FEATURES_AGENT` (visual) + `POLISH_AGENT` (motion) | feature-specific UI |
| `<body>` page markup (`#page-home` / `-sync` / `-depth` / `-ascend` / `-council`) | `UX_AGENT` | tab content shells |
| Overlay markup (`#chamberOverlay`, `#lockerModal`, `#paywallOverlay`, etc.) | `UX_AGENT` (shell) + the feature owner (body) | shared chrome |
| `<script>` audio code (Tone.*, `startTone`, `ensureAudio`, `speakAsInnerSelf`) | `AUDIO_AGENT` | synthesis only |
| `<script>` data code (every `localStorage.*`, every `load*`/`save*`, schema, migrations) | `DATA_AGENT` | persistence only |
| `<script>` mechanic code (`unlockAwakening`, `recordDailySync`, `addCloseness`, `addPassDepth`, `lockerLog`, `passTiers`, etc.) | `FEATURES_AGENT` | rules only |
| `<script>` render code (`renderLobby`, `renderDepth`, `renderCouncil`, `renderLadder`, page hooks in `gotoTab`) | `UX_AGENT` | layout fill only |
| `<script>` cinematic helpers (`notify`, `cinematicMoment`, `floatGain`, `toast`, `_animateSayCard`, boot IIFE) | `POLISH_AGENT` | celebration only |

When two agents legitimately need to touch the same block (e.g., the Locker needs `FEATURES_AGENT` rules **and** `POLISH_AGENT` animation **and** `DATA_AGENT` persistence), each adds their own section with their banner. **Don't merge logic across lanes inside one banner.**

## The wrap pattern (the only cross-lane edit allowed)

Cross-cutting concerns extend an existing function without modifying its body. This is how an agent in another lane "hooks" your function without touching it.

```js
// AUDIO_AGENT defines:
function applyFrequency(hz, fromSlider) { /* tones, color, etc. */ }

// FEATURES_AGENT extends it without rewriting:
(function () {
  const _f = applyFrequency;
  applyFrequency = function (hz, fromSlider) {
    _f.apply(this, arguments);
    if (typeof lockerLog === 'function') lockerLog(hz);   // FEATURES_AGENT's addition
  };
})();
```

Rules:
- Wrap **never deletes** original behavior; it only appends.
- Wrap blocks belong to the **outer** agent (the one adding behavior), not the inner agent.
- If you find yourself wanting to modify the inner function, stop — open a handshake (next section).

## What to do if you need another lane's code changed

You hit a wall: your work needs `applyFrequency` to take a third argument, or `notify` to support a sub-component, or the schema for a record to gain a field. **Don't reach in.** Instead:

1. Stop where you are.
2. Write a one-paragraph **ask** at the top of your output:  
   *"`FEATURES_AGENT` needs `notify(title, sub, glyph, color, opts)` to accept `opts.persistent: true` so the Locker can post a sticky reminder. POLISH_AGENT, can you add it and confirm the API?"*
3. The receiving agent owns the change.
4. When they confirm, continue.

This is how five specialists move fast without overwriting each other.

## How to convene an agent

Two paths.

**A. Via the strategy team** (when the question is "what / should we"):  
Use the `Agent` tool with one of the executive subagents — `resonance-founder`, `resonance-brand`, `resonance-growth`, `resonance-product`, `resonance-design`, `resonance-keeper`, `resonance-steward`. These exist as named agents and carry product context.

**B. Via the build swarm** (when the question is "how / build it"):  
Use the `Agent` tool with `subagent_type: general-purpose` and **paste the agent's charter from `agents-config.json` at the top of the prompt**, plus the specific task. Example:

```
You are AUDIO_AGENT.

Charter:
- Owns: Tone.js synthesis, startTone/stopTone, the Sound Sphere instrument, the Beat
  Maker audio engine, TTS, ensureAudio.
- Does NOT touch: page layout (UX_AGENT), CSS animations (POLISH_AGENT), localStorage
  schema (DATA_AGENT), feature mechanics (FEATURES_AGENT).

Task: …

Verify after edits: JS-parse + getElementById-resolves + div-balance.
```

The build agents are not yet registered as named subagents in `.claude/agents/` (only the executive seven are). When the swarm is needed often enough, give each a real `.md` file in `.claude/agents/` so they're convene-able by name.

## Parallel work safety

You **can** run multiple build agents in parallel — but only if their work doesn't overlap. Safe parallel pairings:

- ✅ `AUDIO_AGENT` (new oscillator preset) + `POLISH_AGENT` (new keyframe) — disjoint zones.
- ✅ `DATA_AGENT` (new persistence helper) + `UX_AGENT` (new page shell) — disjoint zones.
- ❌ `FEATURES_AGENT` (new mechanic) + `UX_AGENT` (new feature placement) — they'll both touch the same page.
- ❌ Two agents in the same lane on adjacent features at the same time — serialize them.

If in doubt: serialize. Single-file conflicts cost more time than they save.

## Per-edit verification (mandatory)

After every edit, every agent runs the same check. Bash it as one command:

```sh
node -e "const fs=require('fs');const h=fs.readFileSync('resonance.html','utf8');const m=h.match(/<script>([\s\S]*?)<\/script>/);try{new Function(m[1]);console.log('JS OK')}catch(e){console.log('ERR '+e.message);process.exit(1)} const o=(h.match(/<div\b/g)||[]).length,c=(h.match(/<\/div>/g)||[]).length;console.log('div',o,c,o===c?'OK':'MISMATCH'); const ids=new Set();let r;const re=/id=\"([^\"]+)\"/g;while(r=re.exec(h))ids.add(r[1]);const used=new Set();const re2=/getElementById\(['\"]([^'\"]+)['\"]\)/g;while(r=re2.exec(h))used.add(r[1]);console.log('missing ids:',[...used].filter(x=>!ids.has(x)).join(', ')||'none');"
```

Three pass-conditions:
1. `JS OK` — the inline script parses (no syntax errors).
2. `div N N OK` — every `<div>` has a matching `</div>`.
3. `missing ids: none` — every `getElementById('x')` finds an `id="x"` somewhere.

If any fail, the edit is reverted and the agent fixes before committing.

## Commit discipline

One feature per commit. Commit messages start with the owning agent's name in `ALL_CAPS`:

```
FEATURES_AGENT: Frequency Locker — per-Hz visit log + notes
POLISH_AGENT: Notification stack (iOS-style top / right-rail) replaces middle-screen pop-ups
DATA_AGENT: Versioned schema for resonance_freq_locker with a forward migration from v0
UX_AGENT: 5-tab IA — Home / Sync / Depth / Ascend / Council
AUDIO_AGENT: Sound Sphere — house-style chord progression mode
```

Co-author line stays:
```
Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
```

`git push` to `main` deploys to `https://quantumvers.github.io/resonance/` in ~60 seconds. Screenshots go to `~/resonance/.shots/` (gitignored).

## The Keeper veto (cross-cuts every lane)

`resonance-keeper` can veto a `FEATURES_AGENT` mechanic that:
- Uses loss framing or "don't break the streak!" language
- Adds a leaderboard, public follower count, or comparison surface
- Paywalls the practice (true self, closeness, transmission, kindred, Convergence, Reading, Plates earned by living-the-practice)
- Manufactures urgency or dishonest scarcity
- Adds engagement loops that fight the Step Out ritual

A Keeper veto stands until the mechanic is reshaped to clear. This applies *before* DATA / UX / POLISH does any work on the rejected mechanic.

## North star (every agent holds it)

By **2027-04-14** (Elliot's 22nd birthday): a real business — **1,000 paying members** (Pro $15/mo, Pro Plus $333/yr) → **$15–20K MRR** — and the stated ambition of **1,000,000 users in the first 30 days of launch**.

The frontend swarm gets the experience to *undeniable.* The backend (when `resonance-product` greenlights it) carries it to *real and shared.* Don't, ever, win by betraying the soul of the thing.
