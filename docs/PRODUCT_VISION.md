# MyShop — Product vision

MyShop is a mobile-first automotive repair and shop-management simulator: satisfying hands-on mechanical work, real diagnostic reasoning, customer relationships, and building a profitable repair business. The player starts with a struggling one-bay shop, earns trust, learns harder repairs, hires staff, upgrades equipment, and builds a business worth being proud of.

It is not a Car Mechanic Simulator copy and not an idle tycoon.

## Visual direction: stylized realism

- Real-world proportions and scale (metres, real wheelbases, real lift dimensions).
- Clean, readable surfaces: solid paint, simple normal-mapped PBR, no photoreal grime noise.
- Slightly warm, controlled palette; the car and the active work area are the focal point.
- Silhouettes read at phone size. Interactive parts stay readable under lighting and clutter.
- Real assets with documented rights (see `ASSET_REGISTER.md`). No primitive-box cars or engines as final art.

## Learning first: a game an automotive teacher could recommend

- The goal is that a player who learned a job in MyShop could do it on their own car. Example: the alternator fails on a Civic-class commuter, and the player practises the diagnosis and replacement in-game first.
- Procedures follow real service logic: real component locations, real order of operations (disconnect the battery before electrical work, relieve belt tension before removing an alternator), real tool types, and real safety steps.
- Real part names and real terminology. No invented "magic" parts or game-only steps.
- Numbers (torque, capacities, prices) are either sourced and cited in the data files or clearly labelled as game values. Never present an invented spec as real.
- MyShop is not a service manual. Every procedure screen states that, and points players to the manufacturer's service information for their actual vehicle.
- Visual style is stylized realism, not cartoon: real proportions, believable materials, readable parts. No "game style" exaggeration that would mislead a learner.

## Vehicle design rule (fictional, but true to life)

- Vehicles are original designs evoking real-world segments and eras (for example "early-2010s Japanese compact sedan"), the way GTA does it. They borrow general proportions and layout, not identity.
- Never use real manufacturer names, model names, logos, badges, or a model's distinctive signature design (grille shape, headlight graphic, body lines). Blend cues from several vehicles so no single real car is copied.
- **Mechanically**, vehicles should be faithful to their real-world archetype: transverse I4 with FWD for the commuter, belt-driven alternator in a realistic place, and so on. That is what makes the learning transfer.
- Legal note: copying a car's exact shape can infringe design rights or trade dress even without the name. Get a real legal review before release, and before any vehicle is modelled closely on one specific car.

## What competing mechanic games get wrong, and our answer

| Common player complaint | MyShop rule |
| --- | --- |
| Repetitive clicking, the same bolt and fluid minigames dozens of times | Every interaction has a purpose. Quick actions, contextual controls, and automation once a procedure is mastered. Hands-on detail is saved for interesting repairs. |
| Different cars that are mechanically identical | Vehicle families, engine layouts, component locations, faults and procedures differ, not just paint. |
| The garage feels like a menu | The shop is a living workplace: bays, equipment, employees working, visible upgrades, a place to show finished builds. |
| Shallow diagnosis | Symptoms have several plausible causes. Inspect, test, gather evidence, choose, verify. Never just highlight the broken part. The simulation rules decide the fault, not generative AI. |
| Grind and pay-to-progress | Fair money management. No repair is made impossible to force a purchase. The core game is playable without spending real money. |
| No consequences or business depth | Estimates, parts costs, labour time, customer budgets, reputation, wages, capacity and expansion all interact. Mistakes have consequences, explained with a way to recover. |
| Lifeless customers | Customers differ in patience, budget, knowledge and communication style. Reviews reflect what the player actually did. |
| Unnecessary disassembly | Only remove what the repair logically needs. Dependencies are shown clearly. |

## Pillars

- **A. Hands-on repairs that respect time.** Component interaction system: tools, dependencies, removal and installation states, satisfying feedback.
- **B. Diagnosis as reasoning.** Example: a no-start could be the battery, starter, fuel delivery, or ignition. Tests narrow the possibilities.
- **C. A real business.** Start with one bay and little cash. Oil, tyres, batteries, filters, brakes and inspections first, then diagnostics, engine work, more bays, and staff. Revenue, parts, labour, wages, overhead and profit are shown separately. Equipment unlocks capabilities, not arbitrary levels.
- **D. Customers and reputation.** Estimates, authorization, quality, time and fairness drive satisfaction.
- **E. A living workshop.** The same vehicle identity and mechanical state across Bay, Under Car and Engine views. Touch-first interaction.
- **F. Vehicle variety through modular architecture.** Each vehicle references a family, an engine configuration, components, repair dependencies and supported faults. A few well-built vehicles before many shallow ones.
- **G. Fair long-term progression.** Goals beyond money. Monetization, if ever, is optional cosmetics or real expansions.

## Build order

1. Preserve the playable prototype and economy.
2. One convincing fictional vehicle, a detailed engine bay, a proper lift, a coherent workshop, and a reusable scene architecture. **(current)**
3. Keep the oil-change workflow and all three views.
4. Make mechanical components independently addressable.
5. A reliable repair-component and tool-interaction architecture.
6. Diagnosis and varied repair procedures.
7. Shop management, employees, customers, reputation.
8. Vehicle variety. Evaluate monetization only after the core game is fun.

## Quality test for every feature

Does it create a meaningful decision, teach the player something, improve the fantasy of being a mechanic, or make the business more interesting? If not, simplify it or cut it. Always label features as implemented, planned, or placeholder.
