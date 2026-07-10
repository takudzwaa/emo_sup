You are building a click-through / functional PROTOTYPE (not production-hardened code)
for a confidential emotional support app. Treat every instruction below as a standing
constraint for the rest of this session.

PRODUCT
- Positioning: confidential emotional support and companionship app connecting users
  with trained listeners. Explicitly NOT therapy, NOT a medical service, NOT an
  emergency/crisis service.
- Audience: lonely individuals, students under academic pressure, young professionals,
  high-stress individuals, anyone wanting a non-judgmental space to talk.

MVP SCOPE — build only these 5 screens/flows:
1. Home (mood check-in widget + one prominent "Talk to Someone" CTA)
2. Chat (secure 1:1 text messaging with a listener)
3. Bookings (schedule a future session with a preferred listener)
4. Safety & Privacy hub (crisis resources, report/block, delete-my-data)
5. Listener Dashboard (separate interface: manage chats + availability)
Plus: anonymous account creation (no real names, no public profiles).

EXPLICITLY OUT OF SCOPE — do not build, scaffold, or stub toward these:
video calls, AI chatbot/diagnosis features, social feeds/public forums, community
features, gamification (badges/streaks/points).

TECH STACK
- Flutter (iOS + Android from one codebase)
- Firebase: Firestore (chat + data), Firebase Auth (phone/email), FCM (push)
- Prototype-level only: mock/seed data is fine where a real backend isn't needed yet,
  but structure the code so Firestore reads/writes are the obvious next step.

DESIGN PRINCIPLES (apply to every screen you build)
- Trust/confidentiality must be visually reinforced everywhere.
- No public profiles — anonymous usernames only (e.g. "Quiet River", "Listener #4").
- "Delete my data" and "Report & block" must be reachable in ≤2 taps from any screen
  (e.g. persistent overflow menu or bottom nav item) — never buried.
- Soft, low-saturation color palette; full Dark Mode support; minimal copy per screen.
- Large tap targets, generous whitespace, exactly ONE primary action per screen.
- Visible security cue wherever chat appears (e.g. a lock icon + "End-to-end encrypted"
  label) — this can be a UI cue only at prototype stage, doesn't need real E2E crypto yet.

HARD GUARDRAILS (do not soften or work around these)
- Never let copy, UI microcopy, or listener-facing strings imply diagnosis, therapy,
  or a professional medical/clinical relationship.
- The Safety & Privacy hub must always be present and never gated behind onboarding,
  paywalls, or dead-ends.
- If you're unsure whether a feature counts as "AI chatbot" or "gamification" (out of
  scope), ask me before building it rather than guessing.

When I give you a prompt below for a specific screen, build ONLY that screen/flow,
using these standing constraints. Ask me before introducing any package, dependency,
or architectural pattern not already implied above.
