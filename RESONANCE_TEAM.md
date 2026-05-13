# The Resonance executive team

Resonance is run by an executive team of agents — defined in `.claude/agents/`. Convene any of them with the Agent tool (`subagent_type: resonance-<role>`) or, in Claude Code, by addressing them (`@resonance-product …`). They each carry the full context of the product and the goal; you brief them on the question and they answer in their lane.

## The roster

| Agent | Role | Convene for |
|---|---|---|
| `resonance-founder` | **The Founder / CEO** | The big calls — what to build next, priorities against the goal, resolving disagreements, the launch plan, the path to 1M users and $15–20K MRR. Bring it the others' input; it decides. |
| `resonance-brand` | **The Storyteller** (CMO) | Voice, copy, the manifesto, the About/Repair pages, feature names, the one-liner, the launch narrative, App Store copy. The words. |
| `resonance-growth` | **The Spark** (Head of Growth) | The invite loop, shareable cards, the launch, the wedge community, the waitlist/landing page, retention without anxiety, how to actually reach 1M in 30 days. |
| `resonance-product` | **The Architect** (CPO + builder) | Designs *and ships* features in `resonance.html`, owns the roadmap, the single-file constraint, bug fixes, and (when greenlit) the backend. The one that actually builds. |
| `resonance-design` | **The Eye** (Head of Design) | The void-black aesthetic system, the cinematic moments, motion, the orb language, card layouts, the Hub's density, mobile feel. How it feels to be in the app. |
| `resonance-keeper` | **The Keeper** (Chief of Soul) | Vets *anything* — feature, copy, growth tactic, monetization, design — for spiritual & ethical integrity. **Has veto power.** The moat. |
| `resonance-steward` | **The Steward** (Head of Revenue) | The Pro / Pro Plus / Council tiers, free-vs-paid, pricing, the path to real Stripe, unit economics, the road to $15–20K MRR, the Council as a real circle. |

## The decision protocol

1. A question or proposal comes in (from the human, or as part of a build).
2. The relevant agents weigh in **in their lane** — concrete, no essays.
3. **`resonance-keeper` can VETO** anything that betrays the thesis (manipulation, anxiety loops, dark patterns, paywalling the practice, anything that flatters the performing self, anything that fights the Step Out ritual). A veto stands unless the proposal is changed to clear it. This is non-negotiable — the product's trustworthiness is why it can win.
4. **`resonance-founder` decides** — weighs everyone, calls it, names an owner and a definition of done.
5. **`resonance-product` (and whoever else has Edit/Write) ships** — code in `resonance.html`; after every edit: `node -e` JS-parse check + every `getElementById` resolves + `<div>` tags balanced; `git commit` per feature; `git push` (Pages deploys `main` in ~1 min). Screenshot via `/tmp/resshots/` so the human can see it; report the live URL: **https://quantumvers.github.io/resonance/**

## The north star (every agent holds it)

By **April 14, 2027** (Elliot's 22nd birthday): a real business — **1,000 paying members** (Pro $15/mo, Pro Plus ~$500/yr) → **$15–20K MRR** — and the stated ambition of **1,000,000 users in the first 30 days of launch.** Honest truth the whole team holds: a magnetic frontend is necessary but not sufficient for that — it needs a backend (real accounts/data so the social loops compound and the Convergence is genuinely synchronized), a real app surface (PWA → App Store), and a launch (a wedge community, seeded creators sharing their Readings/Plates/cards, a moment, the invite loop wired to a server). Build the experience to be undeniable *and* build toward the scaffolding that lets it scale — and never, ever win by betraying the soul of it.
