# Jewel Calm UI + Hybrid Payment + MVP Depth — Design Spec

**Date:** 2026-07-10  
**Status:** Approved (sections §1–§4); pending user review of this written spec  
**Product:** Confidential emotional support prototype (Flutter MVP)

## Problem

The prototype is functionally present but reads as sparse/basic. It needs a more vibrant, elegant visual language; deeper interaction on every MVP surface; and a realistic **simulated** payment gateway for premium sessions — including regional methods (EcoCash, NetOne, InnBucks) alongside card.

## Goals

- **Jewel calm** visual system, **light mode first** (dark still via system).
- Hybrid monetization: free standard slots; premium slots/listeners require **pay-per-session** *or* **monthly plan**.
- Simulated multi-method checkout: **Card**, **EcoCash**, **NetOne (OneMoney)**, **InnBucks**.
- Functional depth across **Auth, Home, Bookings, Chat, Safety, Listener** — not UI-only paint.
- Investor-demo path: book premium → choose method → process → success (or decline).
- Stay within hard product guardrails (not therapy, not emergency service, Safety never gated).

## Non-goals

- Real payment provider integration (Stripe, Paynow, EcoCash API, etc.).
- Video calls, AI chatbot/diagnosis, social feeds/forums, community features.
- Gamification (badges, streaks, points, ratings-as-game).
- Refunds, invoices, tax, multi-currency FX beyond simple `$` display.
- New packages by default (no `google_fonts`, no payment SDKs) unless later approved.
- Architecture rewrites or live Firestore schema migration (keep Firestore-shaped models/stores).

## Locked decisions

| Decision | Choice |
|----------|--------|
| Visual | Jewel calm, light-first |
| Payment model | Hybrid: free standard; premium = pay once **or** plan unlock |
| Payment methods | Card, EcoCash, NetOne, InnBucks (all simulated) |
| Session price (demo) | $12 per premium session |
| Plan price (demo) | $29 / month |
| Build order | **Demo spine first**: theme tokens → booking/payment/success → Home, Chat, Safety, Auth, Listener |
| Packages | None new without asking |

## Visual system (Jewel calm)

### Color (light primary)

| Role | Direction |
|------|-----------|
| Primary | Soft indigo ~`#6B7FD7` |
| Secondary / CTA blend | Calm teal ~`#5BB8B0` |
| Premium accent | Soft gold ~`#C9A87C` |
| Surfaces | Multi-stop wash: lilac → mint → warm ivory |
| Cards | Frosted white ~78–86% opacity; violet-tinted soft shadows |
| Outline | Low-alpha cool-warm neutral |
| Error | Soft rose (calm, not alarm-red) |

### Dark mode

Supported via `ThemeMode.system`. Dark surfaces: warm charcoal-plum; jewel accents lightened for contrast. **Light is the designed default** for demos and screenshots.

### Shape, elevation, type

- Corner radii 16–24 (cards/buttons); larger hero surfaces 20–28.
- Soft multi-layer shadows; CTA indigo→teal gradient with gentle glow.
- Material 3 text theme refined (stronger titles, comfortable body). System fonts only in this pass.
- One primary action per screen; large tap targets; generous whitespace.

### Trust & safety cues

- Trust chip (lock + short label) on chat-adjacent and welcome surfaces.
- Safety & Privacy ≤2 taps from any screen (quick bar / shield).
- Copy never implies diagnosis, therapy, or clinical relationship.

## Payment hybrid

### Access rules

| Access | Behavior |
|--------|----------|
| Standard slot | Free → Confirm → booking confirmed |
| Premium slot **or** premium listener | If active plan → book with no charge. Else → Checkout (pay $12 **or** subscribe $29/mo) → on success only → booking |
| Active plan | Premium included; no per-session charge |

Premium flag = `TimeSlot.requiresPremium` **or** listener tier `premium` (extend `ListenerProfile` with optional `tier`).

### Methods (simulated)

| Method | UI inputs | Success rule (demo) | Failure rule (demo) |
|--------|-----------|---------------------|---------------------|
| Card | Number, exp, CVC | Number starts with `4242` | Starts with `4000` (or invalid) |
| EcoCash | Phone + PIN | PIN `0000` (or phone ending even) | PIN `9999` (or odd) |
| NetOne | Phone + confirm | Same family of rules | Same |
| InnBucks | Phone/account + approve | Same | Same |

Shared processing state (~1.2–1.8s delay) → success or decline. Receipt line: e.g. “Paid via EcoCash”.

### Screens / steps

1. **Confirm booking** — summary; free CTA **or** “Continue to payment” / “Included in your plan”.
2. **Checkout** — amount; method picker; optional dual CTA: **Pay $12** path vs **Get Plan · $29/mo** (plan uses same method flow then activates membership).
3. **Method form** — fields per method.
4. **Processing** — non-dismissible spinner (or cancel that aborts without booking).
5. **Success** — session details, method used, “View upcoming”; Safety still reachable.
6. **Decline** — calm error, retry, change method; **no** booking created.

### Guardrails

- Safety hub never paywalled or blocked during checkout.
- Failed/cancelled payment never creates a confirmed booking.
- Microcopy: “session”, “support”, “plan” — not therapy, clinical billing, or insurance language.
- Banner on checkout: “Demo payment only — you will not be charged.”

## Screen-by-screen depth

### Auth / Welcome

- Jewel gradient welcome hero + confidentiality framing.
- Anonymous name reveal (generated name, soft motion).
- Existing email/phone continue paths; clearer privacy microcopy.

### Home

- Time-of-day greeting with anonymous username.
- Mood check-in + recent mood **history strip** (not streaks/points).
- Primary CTA: **Talk to Someone**.
- Secondary cards: upcoming session (if any), **plan status chip** (Free / Plan), book for later.

### Bookings

- Language filter chips on listener list.
- Premium badge (gold) + next available slot.
- Slot picker: standard vs premium labels and price hints.
- Full payment spine for premium; free path for standard.
- Success screen after booking.
- Upcoming: cancel + **reschedule** (re-pick slot; re-checkout only if new slot requires payment and plan does not cover).
- Reschedule v1: no refund UI if moving from paid premium to free.

### Chat

- Session start banner; encryption trust chip in app bar.
- Keep typing indicator; mock sent ✓ / delivered ✓✓.
- Overflow: Report & block, Safety hub, **End session**.
- End session → quiet private close state (no ratings gamification).

### Safety & Privacy

- Richer crisis resource cards; product remains “not an emergency service.”
- Report/block multi-step sheet with reason chips.
- Delete my data: consequences list + type-to-confirm.
- Always ≤2 taps.

### Listener dashboard

- Availability toggle with clear online/away state.
- Queue cards (anonymous usernames only).
- Today summary stub: session count + demo “earnings estimate” (not real payouts).
- Keep distinct listener role accent (plum/sage) within jewel system.

## Architecture

### New / extended pieces

```
lib/
  theme/app_theme.dart          # Jewel tokens, gradients, shadows
  models/
    booking.dart                # + priceCents, currency, paymentStatus, planApplied, paymentMethod
    membership.dart             # free | planActive, planId, renewsAt
    payment_method.dart         # card | ecocash | netone | innbucks
    payment_result.dart         # success | declined | cancelled + message
    listener_profile.dart       # + optional tier (standard | premium)
  data/
    membership_store.dart
    booking_store.dart          # confirm only after payment rules satisfied
  services/
    payment_service.dart        # charge / subscribe with delay + demo rules
  screens/payment/
    checkout_screen.dart
    payment_method_form.dart    # or per-method widgets
    payment_processing.dart     # can be overlay
    booking_success_screen.dart
  widgets/
    premium_badge.dart
    plan_status_chip.dart
    language_filter_chips.dart
    # SoftCard glass treatment, etc.
```

### Data flow (premium booking)

1. User selects premium slot → Confirm shows price and plan inclusion.
2. If `MembershipStore.hasActivePlan` → confirm booking with `planApplied: true`.
3. Else → Checkout → method + details → `PaymentService.charge` or `.subscribe`.
4. On success → `BookingStore.confirmBooking(...)` with payment metadata → Success screen.
5. On decline → snackbar / inline error; remain on form; no booking.

### Error & edge cases

| Case | Behavior |
|------|----------|
| Decline / wrong PIN | Calm copy; retry; switch method |
| Double-tap Pay | CTA disabled while processing |
| Cancel mid-checkout | No booking; back to confirm |
| Reschedule free after paid premium | Session moved; no refund UI v1 |
| Safety during checkout | Quick bar still present |

### Testing

- Unit/widget: `PaymentService` card + mobile money success/fail rules.
- Premium without plan cannot confirm without successful payment.
- Active plan books premium without calling charge (or charge no-ops).
- Standard slot books without `PaymentService`.
- Subscribe activates membership and allows subsequent premium free.
- Update existing auth / chat / safety / bookings tests for new strings and flows.

## Implementation order (demo spine)

1. Theme tokens + shared jewel widgets (SoftCard glass, gradients, badges).
2. Models + `MembershipStore` + `PaymentService`.
3. Checkout / processing / success screens wired into booking confirm.
4. Bookings list filters, premium labeling, reschedule.
5. Home depth (greeting, mood strip, plan chip, upcoming).
6. Chat depth (banner, ticks, end session).
7. Safety polish.
8. Auth welcome polish.
9. Listener dashboard depth.
10. Tests + demo copy pass (not therapy; demo payment disclaimer).

## Open points (resolved for this pass)

| Topic | Resolution |
|-------|------------|
| Currency display | USD `$` for demo simplicity |
| NetOne naming | UI label **NetOne (OneMoney)** |
| Real logos | Styled color blocks / text marks only (no trademark asset pack required) |
| Multiple active bookings payment | Each premium booking checks plan or pays once |

## Success criteria

- Light-mode app feels jewel-calm: indigo/teal, frosted cards, premium gold accents.
- Demo can complete: free standard book **and** premium pay (each method) **and** plan subscribe then free premium book.
- Decline path does not create bookings.
- Safety always reachable; no therapy-implying copy.
- All six MVP areas show tangible interaction depth beyond static chrome.
