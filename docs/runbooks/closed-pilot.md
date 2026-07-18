# Closed pilot runbook (PR 19)

## Goals
- Run a small Zimbabwe-first pilot without open enrollment.
- Keep **Safety & Privacy always on** (crisis, report, block, delete).
- Prefer kill switches over hotfixes for match/bookings/payments.

## Feature flags (Remote Config keys)
| Key | Default | Effect |
|-----|---------|--------|
| `match.enabled` | true | Home “Talk to Someone” / requestMatch |
| `bookings.enabled` | true | Bookings directory + checkout |
| `payments.mobile_money` | true | Paid checkout path |
| `listen.live` | true | Live/`now` match (async free path may stay on) |

**Never** ship a flag that disables Safety hub, crisis pack, report, block, or delete.

## Kill-switch playbook
1. Identify blast radius (match vs bookings vs payments).
2. Flip the corresponding flag in Remote Config (or `FeatureFlags.applyRemoteMap` in prototype).
3. Confirm Safety still opens pre-auth and post-auth.
4. Post to pilot ops channel: what broke, flag flipped, ETA.

## Safety ops (pilot)
- Inbox: `safety_inbox` events (reports, escalations, delete requests).
- Ack target: **24 hours**.
- Escalations: listener taps Escalate → ops inbox; user is not clinically diagnosed.

## Listener claims
- Grant: Admin SDK `setCustomUserClaims(uid, { role: 'listener' })`.
- First admin: Firebase Console custom claim `role: admin` once.
- Local demo: `flutter run -t lib/main_listener.dart --dart-define=LISTENER_CLAIM=true`.

## Crisis pack
- EN pack: `assets/crisis/zw_en.json`.
- Requires non-empty `partnerSignOff` (partner, signedAt, reviewer).
- Re-validate public emergency numbers with a ZW partner before open enrollment.
- sn/nd crisis packs: **blocked** until partner review (PR 27).

## Rollback
- Prefer flag flip over redeploy.
- App rollback: previous Play track; keep Safety assets in all builds.
