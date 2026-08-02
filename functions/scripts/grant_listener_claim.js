/**
 * Grant Firebase Auth custom claim role: listener.
 *
 * Usage:
 *   node scripts/grant_listener_claim.js <uid>
 */
const admin = require('firebase-admin');

if (!admin.apps.length) {
  admin.initializeApp();
}

async function main() {
  const uid = process.argv[2];
  if (!uid) {
    console.error('Usage: node scripts/grant_listener_claim.js <uid>');
    process.exit(1);
  }
  const user = await admin.auth().getUser(uid);
  const claims = { ...(user.customClaims || {}), role: 'listener' };
  await admin.auth().setCustomUserClaims(uid, claims);

  // Mirror public directory under the Auth uid (preferred for setListenerAvailability).
  const existingPublic = await admin.firestore().doc(`listener_public/${uid}`).get();
  if (!existingPublic.exists) {
    await admin.firestore().doc(`listeners/${uid}`).set(
      {
        id: uid,
        displayName: 'Listener — Harbor',
        bio: 'Trained listener. Private 1:1 support.',
        languages: ['English', 'Shona', 'Ndebele'],
        availableNow: true,
        role: 'listener',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    await admin.firestore().doc(`listener_public/${uid}`).set(
      {
        id: uid,
        displayName: 'Listener — Harbor',
        bio: 'Trained listener. Private 1:1 support.',
        languages: ['English', 'Shona', 'Ndebele'],
        availableNow: true,
        tier: 'standard',
      },
      { merge: true },
    );
  }
  console.log(`Granted role:listener to ${uid}. User must refresh ID token.`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
