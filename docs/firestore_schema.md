# Firestore schema & rules (finalized — Prompt 7a)

Design sketch for the prototype → first real backend. **Not a production security audit.**

This is the Prompt 7 design with one security bug fixed: the original `chats`
collection `list` rule contained a placeholder `|| true` that made every chat
session listable by any signed-in user. That placeholder is replaced with a real
constraint tied to `userId` / `listenerId`. Everything else matches the original
sketch.

Deployable rules live at the repo root: [`firestore.rules`](../firestore.rules).
Indexes: [`firestore.indexes.json`](../firestore.indexes.json).

---

## 1. Collection / document tree

Types use Firestore-ish names: `string`, `number`, `boolean`, `timestamp`, `string[]`, `map`.

**No email / phone / legal name / photo fields on any client-writable doc** — those
stay in Firebase Auth only.

```text
// Firebase Auth (not Firestore)
// auth users hold email/phone credentials only — never mirrored into public docs

users/{uid}                                    // end-user app profile
  uid: string                                  // == document id, Auth uid
  anonymousName: string                        // e.g. "Quiet River"
  authMethod: string                           // "email" | "phone"
  createdAt: timestamp
  // optional prototype fields
  lastMoodValue: number | null                 // 1–5, denormalized convenience
  lastMoodAt: timestamp | null
  // NEVER: legalName, email, phone, photoUrl, birthday

users/{uid}/mood_entries/{entryId}             // Home check-ins (optional subcol)
  timestamp: timestamp
  value: number                                // 1–5

listener_public/{listenerId}                   // directory projection (signed-in list/get)
  id: string
  displayName: string
  bio: string
  languages: string[]
  availableNow: boolean
  tier: string                                 // "standard" | "premium"
  // NEVER: private contact, legal name, earnings

listeners/{listenerId}                         // private ops doc (listener self get only)
  id: string                                   // == document id (often Auth uid)
  displayName: string                          // e.g. "Listener — Harbor"
  bio: string                                  // 1–2 lines, self-written
  languages: string[]
  availableNow: boolean                        // Listener Dashboard toggle
  role: string                                 // always "listener" (custom claim preferred)
  createdAt: timestamp
  // NEVER: legal last name, personal photo, home address
  // availability: listeners/{id}/availability/{slotId} — CF writes; signed-in read

users/{uid}/match_quota/{weekId}               // free async quota (CF write only)
  weekId: string
  asyncStarted: number
  asyncRefunded: number
  updatedAt: timestamp

users/{uid}/fcm_tokens/{tokenId}               // client-managed device tokens

config/free_match                              // CF + optional client get
  weeklyAsyncQuota: number                     // pilot default 2
  timezone: string                             // "Africa/Harare"
  enabled: boolean

chats/{sessionId}                              // 1:1 session header — **CF create only**
  id: string
  userId: string                               // users/{uid}
  listenerId: string                           // listeners/{id}
  userDisplayName: string                      // denormalized anonymous name
  listenerDisplayName: string                  // denormalized listener label
  startedAt: timestamp
  endedAt: timestamp | null
  lastMessagePreview: string                   // dashboard list
  lastMessageAt: timestamp | null
  lastMessageSenderId: string | null
  userUnreadCount: number
  listenerUnreadCount: number
  status: string                               // "active" | "ended" | "escalated"
  mode: string                                 // "now" | "async"
  quotaCharged: boolean
  quotaWeekId: string | null
  quotaRefunded: boolean

chats/{sessionId}/messages/{messageId}
  id: string
  senderId: string                             // userId or listenerId
  text: string                                 // see §3 re: E2E vs at-rest
  timestamp: timestamp
  status: string                               // "sending"|"sent"|"delivered"|"read"|"failed"

bookings/{bookingId}                           // **CF create/update only** (PR 9)
  id: string
  userId: string
  listenerId: string
  slotStart: timestamp
  status: string                               // pending_payment|confirmed|cancelled|completed|expired
  paymentStatus: string                        // free|plan|sponsored|paid|pending
  priceCents: number
  currency: string
  planApplied: boolean
  holdExpiresAt: timestamp | null
  sponsorId: string | null
  createdAt: timestamp
  // optional denorm for UI
  userAnonymousName: string
  listenerDisplayName: string

reports/{reportId}                             // Safety: report / block
  id: string
  reporterId: string                           // Auth uid of submitter
  targetType: string                           // "listener" | "user" | "chat"
  targetId: string                             // listenerId / userId / sessionId
  reason: string                               // dropdown value
  details: string | null                       // optional free text
  createdAt: timestamp
  status: string                               // "open" | "reviewing" | "closed" (admin only)
  // Submitter must NOT be able to re-read or edit after create (rules below)
```

### Indexes

| Query | Suggested composite index |
|--------|---------------------------|
| User’s bookings | `bookings`: `userId` ASC, `slotStart` ASC |
| Listener’s bookings | `bookings`: `listenerId` ASC, `slotStart` ASC |
| Listener’s active chats | `chats`: `listenerId` ASC, `status` ASC, `lastMessageAt` DESC |
| User’s chats | `chats`: `userId` ASC, `status` ASC, `lastMessageAt` DESC |

**Role note:** Prefer a Firebase Auth **custom claim** `role: "listener"` (set by
Admin SDK after vetting) over trusting a field on `listeners/{id}` alone. Rules
use both: claim for privilege, doc membership for assignment.

---

## 2. Security rules (summary)

Principles:

- Default deny.
- **No public list** of whole collections (clients only `get` known ids or query
  with equality on their own uid / assignment).
- Users: own profile, own chats/bookings/moods.
- Listeners: only chats/bookings where `listenerId == request.auth.uid`.
- Reports: **create-only** for submitter; no read/update/delete by client.

### Corrected `chats` block (bug fix)

```javascript
match /chats/{sessionId} {
  // Client must always query with .where('userId','==', uid)
  // or .where('listenerId','==', uid) — this rule requires that shape.
  allow list: if signedIn() && (
    resource.data.userId == request.auth.uid
    || (isListener() && resource.data.listenerId == request.auth.uid)
  );

  allow get: if signedIn()
    && (resource.data.userId == request.auth.uid
        || (isListener() && resource.data.listenerId == request.auth.uid));

  allow create: if signedIn()
    && request.resource.data.userId == request.auth.uid
    && request.resource.data.keys().hasAll([
         'userId', 'listenerId', 'startedAt', 'status'
       ]);
  // Prefer creating via Admin SDK / Cloud Function after matchmaking,
  // rather than trusting client-supplied listenerId directly.

  allow update: if signedIn()
    && (resource.data.userId == request.auth.uid
        || (isListener() && resource.data.listenerId == request.auth.uid))
    && !request.resource.data.diff(resource.data)
        .affectedKeys()
        .hasAny(['userId', 'listenerId', 'startedAt']);

  allow delete: if false; // soft-end via endedAt / status

  match /messages/{messageId} {
    allow list, get: if isChatParticipant(sessionId);

    allow create: if isChatParticipant(sessionId)
      && request.resource.data.senderId == request.auth.uid
      && request.resource.data.keys().hasAll([
           'senderId', 'text', 'timestamp', 'status'
         ])
      && request.resource.data.text is string
      && request.resource.data.text.size() > 0
      && request.resource.data.text.size() < 4000;

    allow update: if isChatParticipant(sessionId)
      && request.resource.data.senderId == resource.data.senderId
      && request.resource.data.text == resource.data.text
      && request.resource.data.timestamp == resource.data.timestamp;

    allow delete: if false;
  }
}
```

All other rules (`users`, `listeners`, `bookings`, `reports`, default-deny
catch-all) are unchanged from the original sketch and did not have this bug.
See the full file: [`firestore.rules`](../firestore.rules).

### Client query shapes required by rules

```dart
// User’s chats — required filter for list rule
firestore
  .collection('chats')
  .where('userId', isEqualTo: uid)
  .where('status', isEqualTo: 'active')
  .orderBy('lastMessageAt', descending: true);

// Listener’s chats
firestore
  .collection('chats')
  .where('listenerId', isEqualTo: uid)
  .where('status', isEqualTo: 'active')
  .orderBy('lastMessageAt', descending: true);

// Bookings (same pattern: filter on userId or listenerId)
```

---

## 3. What must not live in client-writable docs / E2E vs at-rest

| Data | Where it lives | Client-writable? |
|------|----------------|------------------|
| Email / phone | Firebase Auth only | **Never** in Firestore product docs |
| Legal name / photo | Not collected (anonymous accounts) | **Never** add without redesign |
| Report free-text | `reports` (admin-only read) | Yes create; **not** re-readable by reporter |
| Chat body text | `messages.text` | Yes for MVP; treat as sensitive |
| Mood values | private to user | Yes, user-only rules |
| Payment / tier (future) | Billing provider + server | Not raw card data |

If real names were ever collected later, they would be **PII**: store only if
required, minimize, encrypt or isolate, separate from anonymous display names,
and never use them as chat titles.

### Encryption-at-rest vs end-to-end (Chat)

| | **Encryption at rest (GCP / Firestore default)** | **End-to-end encryption (E2E)** |
|--|--------------------------------------------------|----------------------------------|
| **What it means** | Google encrypts data on disk; anyone with Firebase Admin / project access can still read plaintext via backend | Only endpoints with message keys can read content; server stores ciphertext |
| **Who can read chat text** | User client, listener client, **your** Cloud Functions, Firebase console, anyone with service account | Only the two participants (and devices holding keys)—**not** support staff by default |
| **Matches current UI cue** | Partial: “Encrypted” can mean transport TLS + at-rest | Full meaning of lock / “Encrypted” product copy |
| **Prototype today** | Fine: rules + TLS + at-rest; no real E2E crypto | Out of scope until key exchange, multi-device, and listener recovery are designed |
| **Tradeoffs for this product** | Simpler moderation, escalation, and “delete my data”; staff can assist on reports | Stronger confidentiality; escalation/moderation needs explicit key escrow or metadata-only flags |

**Practical recommendation before launch:**

1. Keep **Auth credentials** only in Firebase Auth.
2. Keep **anonymousName** as the only identity field in product surfaces.
3. Ship v1 with **TLS + Firestore at-rest + tight rules**; label UI honestly
   (e.g. **“Private conversation”** until E2E is real).
4. If marketing promises **E2E**, plan client-side encrypt of `messages.text`
   (and maybe `lastMessagePreview`), store ciphertext + key ids, and decide
   whether a **safety escrow** exists for escalate (otherwise staff cannot read
   escalated content).
5. **Reports** should remain server-readable by a small safety team even if chats
   go E2E—report text is a separate trust path.

---

## 4. Screen → collection mapping

| Screen | Primary collections |
|--------|---------------------|
| Auth / Home | `users`, `users/.../mood_entries` |
| Chat | `chats`, `chats/.../messages` |
| Bookings | `listeners`, `bookings` |
| Safety & Privacy | `reports` (+ Admin for delete/export jobs) |
| Listener Dashboard | `listeners` (availability), `chats`, `bookings` |

Maps to existing Dart models: `UserProfile`, `MoodEntry`, `ChatSession` /
`ChatMessage`, `Booking`, `ListenerProfile`, plus the report form on the Safety
hub.

---

## 5. Still-open items for a real launch (not fixed here)

1. **Listeners directory:** currently `allow list: if signedIn()` for convenience
   in Bookings. Before scaling past the initial 5–10 vetted listeners, split out a
   `listener_public/{id}` projection so private fields aren’t broadly listable.
2. **Chats create:** client-trusted `listenerId` on create should move to an
   Admin SDK / Cloud Function matchmaking step rather than staying fully
   client-driven.
3. **UI copy:** use **“Private conversation,”** not “Encrypted” /
   “End-to-end encrypted,” until real E2E exists (Chat app bar + Safety hub
   “How your messages are protected” section still use “Encrypted” in the
   prototype UI — intentional honesty gap to close before launch).
