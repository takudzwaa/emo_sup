/**
 * Seed pilot config + listener_public docs.
 *
 * Usage (from functions/ after firebase login + use project):
 *   GOOGLE_APPLICATION_CREDENTIALS=... node scripts/seed_pilot.js
 * Or with Application Default Credentials after `gcloud auth application-default login`:
 *   node scripts/seed_pilot.js
 */
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}
const db = admin.firestore();

const LISTENERS = [
  {
    id: 'listener_harbor',
    displayName: 'Listener — Harbor',
    bio: 'Calm presence for late-night overthinking. I listen without rushing you.',
    languages: ['English', 'Shona'],
    availableNow: true,
    tier: 'standard',
  },
  {
    id: 'listener_moss',
    displayName: 'Listener — Moss',
    bio: 'Here for family pressure and quiet company. Soft check-ins, no judgment.',
    languages: ['English', 'Ndebele'],
    availableNow: true,
    tier: 'standard',
  },
  {
    id: 'listener_cedar',
    displayName: 'Listener — Cedar',
    bio: 'Steady support when work or business stress piles up.',
    languages: ['English', 'Shona', 'Ndebele'],
    availableNow: true,
    tier: 'standard',
  },
];

async function main() {
  await db.doc('config/free_match').set(
    {
      weeklyAsyncQuota: 2,
      timezone: 'Africa/Harare',
      enabled: true,
    },
    { merge: true },
  );
  console.log('Seeded config/free_match');

  // Payments stay disabled until a real gateway is wired (Phase B).
  // Callables refuse paid checkout / confirm / membership while enabled=false.
  await db.doc('config/payments').set(
    {
      enabled: false,
      // Separate flag: confirmBookingPayment / activateMembership refuse to
      // run unless this is ALSO true, so enabling `enabled` alone (e.g. to
      // test checkout UI) can't accidentally open unverified payment
      // confirmation. Only flip once gateway webhook verification ships.
      gatewayVerified: false,
      note: 'Deferred — enable only after gateway webhook verification ships.',
    },
    { merge: true },
  );
  console.log('Seeded config/payments (enabled: false, gatewayVerified: false)');

  for (const l of LISTENERS) {
    const { id, ...rest } = l;
    await db.doc(`listeners/${id}`).set(
      { id, role: 'listener', createdAt: admin.firestore.FieldValue.serverTimestamp(), ...rest },
      { merge: true },
    );
    await db.doc(`listener_public/${id}`).set(
      {
        id,
        displayName: rest.displayName,
        bio: rest.bio,
        languages: rest.languages,
        availableNow: rest.availableNow,
        tier: rest.tier,
      },
      { merge: true },
    );
    console.log(`Seeded listener ${id}`);
  }
  console.log('Done. Grant real Auth UIDs the listener claim via grant_listener_claim.js');
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
