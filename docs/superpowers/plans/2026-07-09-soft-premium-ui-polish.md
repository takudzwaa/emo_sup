# Soft Premium (Warmer) UI Polish — Implementation Plan

> **For agentic workers:** Implement task-by-task. Checkboxes track progress.

**Goal:** Make the full MVP investor-ready with warmer Soft Premium visuals (depth, hierarchy, trust cues) without new features or packages.

**Architecture:** Upgrade theme tokens first, add shared Soft Premium primitives, polish shared widgets, then sweep every MVP screen. No backend/schema changes.

**Tech Stack:** Flutter Material 3, existing Firebase Auth wiring, mock stores.

**Spec:** `docs/superpowers/specs/2026-07-09-soft-premium-ui-polish-design.md`

---

### Task 1: Themes

- [x] Warmer Soft Premium light/dark in `lib/theme/app_theme.dart`
- [x] Matching patterns in `listener_theme.dart` + quieter warmer `safety_theme.dart`
- [x] Card / button / input / snackbar defaults with soft elevation

### Task 2: Shared primitives

- [x] `lib/widgets/soft_surface.dart` — SoftCard, SoftGradientBackground, TrustChip
- [x] Optional decoration helpers colocated or in theme

### Task 3: Shared widgets

- [x] Avatar, mood check-in, message bubble, chat input, typing, listener card, booking tile, safety bar

### Task 4: Screens

- [x] Welcome + auth screens, Home, Chat, Bookings flow, Safety hub, Listener dashboard

### Task 5: Verify

- [x] `flutter test` green (42 tests); analyzer clean

---

**Execution:** Inline in this session (user requested start building immediately).
