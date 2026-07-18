/**
 * Cloud Functions entry (PR 10+).
 *
 * Deploy when a Firebase project is linked:
 *   cd functions && npm i && npm run deploy
 *
 * Client prototype uses MemoryMatchRepository until callable is wired.
 */
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { setGlobalOptions } from 'firebase-functions/v2';

admin.initializeApp();
setGlobalOptions({ region: 'europe-west1' }); // pilot default EU

const db = admin.firestore();

/** ISO-ish week key Africa/Harare (UTC+2). */
function weekIdHarare(now = new Date()): string {
  const harareMs = now.getTime() + 2 * 60 * 60 * 1000;
  const d = new Date(harareMs);
  const start = Date.UTC(d.getUTCFullYear(), 0, 1);
  const dayOfYear =
    Math.floor((Date.UTC(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()) - start) /
      86400000) + 1;
  const week = Math.floor((dayOfYear - 1) / 7) + 1;
  return `${d.getUTCFullYear()}-W${String(week).padStart(2, '0')}`;
}

/**
 * requestMatch — server-authoritative session create + free async quota.
 *
 * Input: { mode: 'now'|'async', preferredLanguages?: string[] }
 * Output: { sessionId, listenerId, listenerDisplayName, mode, quotaCharged? }
 */
export const requestMatch = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const uid = request.auth.uid;
  const mode = (request.data?.mode as string) === 'now' ? 'now' : 'async';
  const preferredLanguages: string[] = Array.isArray(request.data?.preferredLanguages)
    ? request.data.preferredLanguages
    : ['English'];

  const configSnap = await db.doc('config/free_match').get();
  const weeklyAsyncQuota = (configSnap.data()?.weeklyAsyncQuota as number) ?? 2;
  const matchEnabled = configSnap.data()?.enabled !== false;
  if (!matchEnabled) {
    throw new HttpsError('failed-precondition', 'MATCH_DISABLED');
  }

  const userSnap = await db.doc(`users/${uid}`).get();
  const userDisplayName =
    (userSnap.data()?.anonymousName as string) ?? 'Anonymous';

  return db.runTransaction(async (tx) => {
    let quotaCharged = false;
    let quotaWeekId: string | undefined;

    if (mode === 'async') {
      quotaWeekId = weekIdHarare();
      const qRef = db.doc(`users/${uid}/match_quota/${quotaWeekId}`);
      const qSnap = await tx.get(qRef);
      const started = (qSnap.data()?.asyncStarted as number) ?? 0;
      const refunded = (qSnap.data()?.asyncRefunded as number) ?? 0;
      if (started - refunded >= weeklyAsyncQuota) {
        throw new HttpsError('resource-exhausted', 'QUOTA_EXCEEDED');
      }
      tx.set(
        qRef,
        {
          weekId: quotaWeekId,
          asyncStarted: started + 1,
          asyncRefunded: refunded,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      quotaCharged = true;
    }

    const publicSnap = await tx.get(
      db.collection('listener_public').where('availableNow', '==', true).limit(20),
    );
    if (publicSnap.empty) {
      throw new HttpsError('unavailable', 'NO_CAPACITY');
    }

    type Pub = {
      id: string;
      displayName: string;
      languages?: string[];
    };
    let pick: Pub | undefined;
    const docs = publicSnap.docs.map((d) => ({ id: d.id, ...(d.data() as object) })) as Pub[];
    for (const lang of preferredLanguages) {
      pick = docs.find((l) => (l.languages ?? []).includes(lang));
      if (pick) break;
    }
    pick = pick ?? docs[0];

    const sessionRef = db.collection('chats').doc();
    const session = {
      id: sessionRef.id,
      userId: uid,
      listenerId: pick.id,
      userDisplayName,
      listenerDisplayName: pick.displayName,
      startedAt: admin.firestore.FieldValue.serverTimestamp(),
      endedAt: null,
      status: 'active',
      mode,
      lastMessagePreview: '',
      lastMessageAt: null,
      userUnreadCount: 0,
      listenerUnreadCount: 0,
      quotaCharged,
      quotaWeekId: quotaWeekId ?? null,
      quotaRefunded: false,
    };
    tx.set(sessionRef, session);

    return {
      sessionId: sessionRef.id,
      listenerId: pick.id,
      listenerDisplayName: pick.displayName,
      mode,
      quotaCharged,
      quotaWeekId: quotaWeekId ?? null,
    };
  });
});
