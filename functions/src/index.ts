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

/**
 * createBookingCheckout — dual entry (PR 13).
 * settlement: plan | sponsored | free | paid
 */
export const createBookingCheckout = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const uid = request.auth.uid;
  const listenerId = String(request.data?.listenerId ?? '');
  const slotStart = request.data?.slotStart;
  const settlement = String(request.data?.settlement ?? 'free');
  const priceCents = Number(request.data?.priceCents ?? 0);
  const currency = String(request.data?.currency ?? 'USD');
  const sponsorId = request.data?.sponsorId as string | undefined;

  if (!listenerId || !slotStart) {
    throw new HttpsError('invalid-argument', 'listenerId and slotStart required.');
  }

  const needsPay = settlement === 'paid';
  const bookingRef = db.collection('bookings').doc();
  const holdMinutes = 12;
  const booking = {
    id: bookingRef.id,
    userId: uid,
    listenerId,
    slotStart: admin.firestore.Timestamp.fromDate(new Date(slotStart)),
    status: needsPay ? 'pending_payment' : 'confirmed',
    paymentStatus: needsPay
      ? 'pending'
      : settlement === 'plan'
        ? 'plan'
        : settlement === 'sponsored'
          ? 'sponsored'
          : 'free',
    priceCents: needsPay ? priceCents : 0,
    currency,
    planApplied: settlement === 'plan',
    sponsorId: sponsorId ?? null,
    holdExpiresAt: needsPay
      ? admin.firestore.Timestamp.fromDate(
          new Date(Date.now() + holdMinutes * 60 * 1000),
        )
      : null,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  await bookingRef.set(booking);

  let paymentId: string | null = null;
  if (needsPay) {
    const payRef = db.collection('payments').doc();
    paymentId = payRef.id;
    await payRef.set({
      id: paymentId,
      bookingId: bookingRef.id,
      userId: uid,
      amountCents: priceCents,
      currency,
      status: 'pending',
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }

  return {
    bookingId: bookingRef.id,
    paymentId,
    requiresPayment: needsPay,
    status: booking.status,
  };
});

/** Listener availability toggle (CF-only write path). */
export const setListenerAvailability = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  if (request.auth.token.role !== 'listener') {
    throw new HttpsError('permission-denied', 'Listener role required.');
  }
  const availableNow = Boolean(request.data?.availableNow);
  const uid = request.auth.uid;
  const batch = db.batch();
  batch.set(
    db.doc(`listeners/${uid}`),
    { availableNow, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true },
  );
  batch.set(
    db.doc(`listener_public/${uid}`),
    { availableNow },
    { merge: true },
  );
  await batch.commit();
  return { availableNow };
});

/** escalateChat — listener flags risk; writes safety_inbox (PR 16). */
export const escalateChat = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  if (request.auth.token.role !== 'listener') {
    throw new HttpsError('permission-denied', 'Listener role required.');
  }
  const sessionId = String(request.data?.sessionId ?? '');
  const reason = String(request.data?.reason ?? 'listener_escalation');
  if (!sessionId) {
    throw new HttpsError('invalid-argument', 'sessionId required.');
  }
  const ref = db.collection('safety_inbox').doc();
  await ref.set({
    id: ref.id,
    kind: 'escalate',
    sessionId,
    listenerId: request.auth.uid,
    reason,
    status: 'open',
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    ackDueAt: admin.firestore.Timestamp.fromDate(
      new Date(Date.now() + 24 * 60 * 60 * 1000),
    ),
  });
  await db.doc(`chats/${sessionId}`).set(
    { status: 'escalated', escalatedAt: admin.firestore.FieldValue.serverTimestamp() },
    { merge: true },
  );
  return { inboxId: ref.id };
});

/**
 * deleteMyData — scrub requester texts, soft-unlink, retain reports (PR 17).
 * Auth user delete is scheduled ≤24h by ops/CF follow-up.
 */
export const deleteMyData = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const uid = request.auth.uid;
  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.doc(`users/${uid}`).set(
    { deletionRequestedAt: now },
    { merge: true },
  );

  const chats = await db
    .collection('chats')
    .where('userId', '==', uid)
    .get();
  let messagesScrubbed = 0;
  for (const chat of chats.docs) {
    await chat.ref.set(
      { userDeleted: true, status: 'ended', endedAt: now },
      { merge: true },
    );
    const msgs = await chat.ref.collection('messages').where('senderId', '==', uid).get();
    for (const m of msgs.docs) {
      await m.ref.update({ text: '[message removed]' });
      messagesScrubbed++;
    }
  }

  const tokens = await db.collection(`users/${uid}/fcm_tokens`).get();
  for (const t of tokens.docs) {
    await t.ref.delete();
  }
  const quotas = await db.collection(`users/${uid}/match_quota`).get();
  for (const q of quotas.docs) {
    await q.ref.delete();
  }

  await db.collection('safety_inbox').add({
    kind: 'delete_request',
    userId: uid,
    messagesScrubbed,
    status: 'open',
    createdAt: now,
  });

  return { messagesScrubbed, authDeleteWithinHours: 24 };
});

/**
 * activateMembership — after payment success (PR 22).
 * Client never writes memberships/{uid}.
 */
export const activateMembership = onCall(async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const uid = request.auth.uid;
  const planId = String(request.data?.planId ?? 'plan_monthly_29');
  const paymentId = String(request.data?.paymentId ?? '');
  // Production: verify paymentId against payments ledger / gateway webhook.
  if (!paymentId) {
    throw new HttpsError('invalid-argument', 'paymentId required.');
  }
  const renewsAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  await db.doc(`memberships/${uid}`).set(
    {
      uid,
      tier: 'planActive',
      planId,
      renewsAt: admin.firestore.Timestamp.fromDate(renewsAt),
      lastPaymentId: paymentId,
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return { planId, renewsAt: renewsAt.toISOString() };
});
