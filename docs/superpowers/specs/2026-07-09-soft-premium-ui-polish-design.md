# Soft Premium UI Polish (Warmer) — Design Spec

**Date:** 2026-07-09  
**Status:** Approved (direction + scope); pending user review of this written spec  
**Product:** Confidential emotional support prototype (Flutter MVP)

## Problem

The prototype is functionally complete for MVP demos but reads as sparse and low-contrast. For potential investors, it needs clearer hierarchy, modern surface treatment, and more visual “flesh” — without looking clinical, flashy, or like therapy software.

## Goals

- Investor-ready Soft Premium visual language across the **full MVP** (all 5 flows + auth).
- Slightly **warmer** Soft Premium: soft teal-slate kept as trust primary, with warmer ivory/sand surfaces and soft amber-warm secondary accents.
- Reinforce confidentiality and safety cues (trust chips, lock labels, always-reachable Safety hub).
- Stay within product hard guardrails (not therapy, not emergency, no AI chatbot, no gamification).

## Non-goals

- New product features or flows.
- Real E2EE crypto, video, social feeds, AI diagnosis, badges/streaks/points.
- Architecture rewrites or Firestore schema changes.
- New packages unless later approved (default: **no new packages**, including no `google_fonts` in v1).

## Direction (locked)

| Decision | Choice |
|----------|--------|
| Visual style | Soft Premium, **slightly warmer** |
| Scope | Full MVP surface pass |
| Implementation approach | Design system layer + systematic screen sweep |

## Visual system

### Color (warmer Soft Premium)

Keep trust/teal primary; warm the canvas and secondary accents.

**User app (light)**
- Primary: muted teal-slate (existing family, may nudge slightly warmer — not cold blue).
- Surface / scaffold: warm ivory / sand off-white (e.g. ~`#F8F4EF`–`#F5F0EA` range) instead of cool gray-beige.
- Secondary: soft sage-warm or muted clay (low saturation).
- Surface containers: warm stone, not blue-gray.
- Outline: warm taupe at low alpha.
- Error: soft rose (unchanged intent — calm, not alarm-red).

**User app (dark)**
- Warm charcoal surfaces (slight brown undertone, not pure cold black).
- Primary lightened for contrast on dark; same soft elevation language.

**Listener theme**
- Keep distinct plum-sage role accent.
- Apply same elevation, radius, card, and CTA patterns so the product feels one system, two roles.

**Safety theme**
- Slightly quieter / sturdier than main app.
- Inherit warmer surfaces so it doesn’t feel like a different product; keep calmer primary.

### Elevation & shape

- Soft multi-layer shadows (low opacity, large blur) for cards and primary CTA.
- Corner radii: 16–24 for cards/buttons; 20–28 for large hero surfaces; chat bubbles keep asymmetric corners.
- Prefer filled soft surfaces over hard 1px borders; borders when used stay low-alpha.

### Typography

- Material 3 text theme refined: slightly stronger title weights, tighter headline letter-spacing, comfortable body line-height.
- No custom font package in v1 (system / Material defaults).

### Trust & confidentiality cues

- **TrustChip** shared widget: lock icon + short label (`Private & confidential`, `Encrypted`, etc.).
- Visible on Welcome, Home, Chat app bar, and other chat-adjacent surfaces.
- UI cue only — no real crypto claims beyond existing prototype wording.

### Motion

- Keep existing selection / `AnimatedSize` patterns.
- Optional light press feedback on primary CTA; no streaks, confetti, or reward loops.

## Design system deliverables

Centralize Soft Premium so screens stay consistent:

1. **`lib/theme/app_theme.dart`** — warmer Soft Premium `ColorScheme`, text theme, button/card/input/app bar defaults; light + dark.
2. **`lib/theme/listener_theme.dart`** — same structural patterns; plum role accent retained.
3. **`lib/theme/safety_theme.dart`** — quieter primary; warmer surface alignment.
4. **Shared visual primitives** (new, small widgets under `lib/widgets/` or `lib/theme/`):
   - Soft surface / elevated card container
   - Soft gradient scaffold background (subtle, not loud)
   - Trust chip
   - Primary CTA styling (via theme and/or thin wrapper)
5. **Existing widgets upgraded in place:**
   - `AnonymousAvatar` — soft gradient fill, clearer presence
   - `MoodCheckIn` — card wrapper, stronger selected state
   - `MessageBubble` / `ChatInputBar` / `TypingIndicator` — refined soft bubbles & input chrome
   - `ListenerCard` / `UpcomingBookingTile` — elevated Soft Premium cards
   - `SafetyQuickAccessBar` — slightly more visible but still secondary (not competing with primary CTA)

## Screen-by-screen polish

No new features; layout hierarchy and visual flesh only.

### Auth / Welcome

- Soft gradient hero area, stronger headline hierarchy, refined lock mark.
- Single primary: “Get started anonymously.”
- Keep: “Not therapy. Not an emergency service.”
- Credential / display name / consent screens inherit Soft Premium form chrome (filled fields, soft cards).

### Home

- Header with warmer avatar + anonymous identity.
- Trust chip under header.
- Mood check-in inside elevated soft card.
- One primary CTA: “Talk to Someone” (gradient + soft shadow).
- Secondary: “Book a session for later” (quiet text/outlined, never equal weight to primary).
- Persistent Safety quick access footer remains ≤2 taps.

### Chat

- App bar: peer name + TrustChip (“Encrypted”) + overflow (report/block, end chat).
- Crisis strip stays reachable; soft surface treatment.
- Bubbles: warmer user primary, soft peer containers; timestamps on long-press unchanged.
- Input bar: rounded filled field + clear send affordance.
- Safety footer for end-user perspective.

### Bookings (+ slot picker / confirm)

- Elevated listener cards, clearer next-slot affordance.
- Tabs visually refined (soft selected state).
- Confirm screen: clear summary card + one primary confirm action.

### Safety & Privacy hub

- Section cards with icons; calmer primary; warmer canvas.
- Crisis resources, report/block, delete-my-data remain prominent and ungated.
- No flashy marketing chrome — sturdy trust room with Soft Premium depth.

### Listener Dashboard

- Soft Premium cards for active chats + availability controls.
- Role accent (plum) preserved; escalate/safety copy unchanged (never diagnose).

## Copy constraints (hard)

- Never imply diagnosis, therapy, or professional medical/clinical relationship.
- Keep anonymous usernames only (e.g. “Quiet River”, “Listener #4”).
- Safety hub always reachable; never behind paywall/onboarding dead-ends.
- “Flesh” means visual polish and hierarchy — not gamification or AI chatbot features.

## Dependencies

- **Default:** no new pub packages.
- Custom fonts or illustration packages require explicit approval later.

## Testing & verification

- Existing widget/flow tests remain green (`test/*`).
- Prefer theme/widget visual changes that do not break `find.text` / key interactions.
- Manual smoke: light + dark, user shell + listener shell, navigate all 5 MVP surfaces + auth welcome.
- If a test asserts exact colors or fragile tree structure, update tests to behavior/copy assertions.

## Implementation order

1. Theme tokens (warmer Soft Premium light/dark) + card/button/scaffold defaults.
2. Shared primitives (soft card, gradient scaffold, trust chip).
3. Shared widgets (avatar, mood, chat chrome, listener card, safety bar).
4. Screens: Welcome/auth → Home → Chat → Bookings flow → Safety → Listener dashboard.
5. Run tests + fix regressions; quick dark-mode pass.

## Success criteria

- Investor can open the app and immediately see craft: depth, hierarchy, warmth, modern calm.
- Primary action per screen is obvious; confidentiality is visible without shouting.
- Full MVP feels one product, not a mix of polished and sparse screens.
- Guardrails and existing MVP behavior intact.
