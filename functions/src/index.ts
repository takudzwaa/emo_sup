/**
 * Cloud Functions entry — Pilot MVP callables + triggers.
 *
 * Deploy: cd functions && npm i && npm run build && firebase deploy --only functions
 */
import * as admin from 'firebase-admin';
import { onCall, HttpsError } from 'firebase-functions/v2/https';
import { onDocumentCreated } from 'firebase-functions/v2/firestore';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import { setGlobalOptions } from 'firebase-functions/v2';

admin.initializeApp();
setGlobalOptions({ region: 'europe-west1' });

const db = admin.firestore();

/**
 * App Check enforcement — set per environment via functions/.env.<project-id>
 * (staging soaks with false, prod ships true). Resolved at deploy time.
 */
const ENFORCE_APP_CHECK = process.env.ENFORCE_APP_CHECK === 'true';
const callOpts = { enforceAppCheck: ENFORCE_APP_CHECK };

/**
 * Payments kill switch — fail closed. Real gateway integration is deferred
 * (Phase B); until `config/payments { enabled: true }` is set by an operator,
 * paid checkout and client-asserted payment confirmation are refused.
 */
async function paymentsEnabled(): Promise<boolean> {
  const snap = await db.doc('config/payments').get();
  return snap.data()?.enabled === true;
}

/**
 * A SEPARATE flag from `enabled`, deliberately: `confirmBookingPayment` and
 * `activateMembership` still trust a client-supplied paymentId with no
 * gateway webhook verification (Phase B). Gating them on the same
 * `enabled` flag used for the rest of checkout would mean one operator
 * flipping that flag to test booking/checkout UI also silently opens a
 * free-money hole. Requiring this second, unambiguously-named flag means
 * that can't happen by accident — it must be turned on deliberately, and
 * only once real gateway verification actually replaces the client-trust
 * code below.
 */
async function gatewayVerificationImplemented(): Promise<boolean> {
  const snap = await db.doc('config/payments').get();
  return snap.data()?.gatewayVerified === true;
}

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

/** Hour bucket key Africa/Harare (UTC+2), for the 'now' mode rate limit. */
function hourKeyHarare(now = new Date()): string {
  const harareMs = now.getTime() + 2 * 60 * 60 * 1000;
  const d = new Date(harareMs);
  return `${d.getUTCFullYear()}${String(d.getUTCMonth() + 1).padStart(2, '0')}` +
    `${String(d.getUTCDate()).padStart(2, '0')}-${String(d.getUTCHours()).padStart(2, '0')}`;
}

/** 'now' mode has no weekly quota (it's not free-async) but still must not
 *  be spammable — each session consumes scarce, real listener capacity. */
const NOW_MODE_HOURLY_LIMIT = 5;

async function isBlockedPair(a: string, b: string): Promise<boolean> {
  const id1 = `${a}_${b}`;
  const id2 = `${b}_${a}`;
  const [x, y] = await Promise.all([
    db.doc(`blocks/${id1}`).get(),
    db.doc(`blocks/${id2}`).get(),
  ]);
  return x.exists || y.exists;
}

/**
 * requestMatch — server-authoritative session create + free async quota.
 */
export const requestMatch = onCall(callOpts, async (request) => {
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
    } else {
      // 'now' mode: no weekly quota, but rate-limit per rolling hour so a
      // user can't spam-create sessions and burn listener capacity.
      const hourKey = hourKeyHarare();
      const rateRef = db.doc(`users/${uid}/match_quota/now_${hourKey}`);
      const rateSnap = await tx.get(rateRef);
      const count = (rateSnap.data()?.count as number) ?? 0;
      if (count >= NOW_MODE_HOURLY_LIMIT) {
        throw new HttpsError('aborted', 'RATE_LIMITED_NOW');
      }
      tx.set(
        rateRef,
        { count: count + 1, updatedAt: admin.firestore.FieldValue.serverTimestamp() },
        { merge: true },
      );
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
    const allCandidates = publicSnap.docs.map((d) => ({ id: d.id, ...(d.data() as object) })) as Pub[];
    // A blocked pair must never be re-matched — checking only at message-send
    // time (onMessageCreate) is too late, since the session itself would
    // already exist and be visible to both sides.
    const blockedFlags = await Promise.all(
      allCandidates.map((c) => isBlockedPair(uid, c.id)),
    );
    const docs = allCandidates.filter((_, i) => !blockedFlags[i]);
    if (docs.length === 0) {
      throw new HttpsError('unavailable', 'NO_CAPACITY');
    }
    let pick: Pub | undefined;
    for (const lang of preferredLanguages) {
      pick = docs.find((l) => (l.languages ?? []).includes(lang));
      if (pick) break;
    }
    pick = pick ?? docs[0];

    const sessionRef = db.collection('chats').doc();
    const opener =
      "Hi — I'm here to listen. This is a private space; share only " +
      'what feels comfortable. Take your time.';
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
      lastMessagePreview: opener.slice(0, 120),
      lastMessageAt: admin.firestore.FieldValue.serverTimestamp(),
      userUnreadCount: 1,
      listenerUnreadCount: 0,
      quotaCharged,
      quotaWeekId: quotaWeekId ?? null,
      quotaRefunded: false,
    };
    tx.set(sessionRef, session);
    const msgRef = sessionRef.collection('messages').doc();
    tx.set(msgRef, {
      id: msgRef.id,
      senderId: pick.id,
      text: opener,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'delivered',
    });

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
 */
export const createBookingCheckout = onCall(callOpts, async (request) => {
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
  if (!['free', 'plan', 'sponsored', 'paid'].includes(settlement)) {
    throw new HttpsError('invalid-argument', 'Unknown settlement type.');
  }

  const needsPay = settlement === 'paid';
  if (needsPay) {
    if (!(await paymentsEnabled())) {
      throw new HttpsError('failed-precondition', 'PAYMENTS_DISABLED');
    }
    if (!Number.isInteger(priceCents) || priceCents <= 0) {
      throw new HttpsError('invalid-argument', 'priceCents must be a positive integer.');
    }
  }
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

/**
 * Confirm booking payment.
 *
 * IMPORTANT: still trusts the caller's claim of success — acceptable ONLY
 * while `config/payments.enabled` is false (the gate below refuses all
 * calls). Phase B must replace this with gateway webhook verification
 * BEFORE payments are enabled. `gatewayVerificationImplemented()` is a
 * second, separately-named config flag specifically so that flipping
 * `enabled` alone (e.g. to test checkout UI) can't accidentally activate
 * this unverified path — see the doc comment on that function.
 */
export const confirmBookingPayment = onCall(callOpts, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  if (!(await paymentsEnabled())) {
    throw new HttpsError('failed-precondition', 'PAYMENTS_DISABLED');
  }
  if (!(await gatewayVerificationImplemented())) {
    throw new HttpsError('failed-precondition', 'PAYMENT_VERIFICATION_NOT_IMPLEMENTED');
  }
  const uid = request.auth.uid;
  const bookingId = String(request.data?.bookingId ?? '');
  const paymentId = String(request.data?.paymentId ?? '');
  const method = String(request.data?.method ?? 'card');
  if (!bookingId || !paymentId) {
    throw new HttpsError('invalid-argument', 'bookingId and paymentId required.');
  }
  const bookingRef = db.doc(`bookings/${bookingId}`);
  const snap = await bookingRef.get();
  if (!snap.exists) {
    throw new HttpsError('not-found', 'Booking not found.');
  }
  if (snap.data()?.userId !== uid) {
    throw new HttpsError('permission-denied', 'Not your booking.');
  }
  const paySnap = await db.doc(`payments/${paymentId}`).get();
  if (!paySnap.exists || paySnap.data()?.bookingId !== bookingId) {
    throw new HttpsError('invalid-argument', 'Payment does not match booking.');
  }
  await bookingRef.set(
    {
      status: 'confirmed',
      paymentStatus: 'paid',
      paymentMethod: method,
      holdExpiresAt: null,
      confirmedAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await db.doc(`payments/${paymentId}`).set(
    {
      status: 'succeeded',
      method,
      settledAt: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return { bookingId, status: 'confirmed' };
});

export const cancelBooking = onCall(callOpts, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  const uid = request.auth.uid;
  const bookingId = String(request.data?.bookingId ?? '');
  if (!bookingId) {
    throw new HttpsError('invalid-argument', 'bookingId required.');
  }
  const ref = db.doc(`bookings/${bookingId}`);
  const snap = await ref.get();
  if (!snap.exists) return { cancelled: false };
  const data = snap.data()!;
  const isListener = request.auth.token.role === 'listener';
  if (data.userId !== uid && !(isListener && data.listenerId === uid)) {
    throw new HttpsError('permission-denied', 'Not allowed.');
  }
  await ref.set({ status: 'cancelled' }, { merge: true });
  return { cancelled: true };
});

/** Listener availability toggle (CF-only write path). */
export const setListenerAvailability = onCall(callOpts, async (request) => {
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
export const escalateChat = onCall(callOpts, async (request) => {
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
  const chatSnap = await db.doc(`chats/${sessionId}`).get();
  if (!chatSnap.exists) {
    throw new HttpsError('not-found', 'Session not found.');
  }
  if (chatSnap.data()?.listenerId !== request.auth.uid) {
    throw new HttpsError('permission-denied', 'Not the listener on this session.');
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
 */
export const deleteMyData = onCall(callOpts, async (request) => {
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
  let sessionsUnlinked = 0;
  for (const chat of chats.docs) {
    await chat.ref.set(
      { userDeleted: true, status: 'ended', endedAt: now },
      { merge: true },
    );
    sessionsUnlinked++;
    const msgs = await chat.ref.collection('messages').where('senderId', '==', uid).get();
    for (const m of msgs.docs) {
      await m.ref.update({ text: '[message removed]' });
      messagesScrubbed++;
    }
  }

  let tokensCleared = 0;
  const tokens = await db.collection(`users/${uid}/fcm_tokens`).get();
  for (const t of tokens.docs) {
    await t.ref.delete();
    tokensCleared++;
  }
  let quotaDocsRemoved = 0;
  const quotas = await db.collection(`users/${uid}/match_quota`).get();
  for (const q of quotas.docs) {
    await q.ref.delete();
    quotaDocsRemoved++;
  }

  await db.collection('safety_inbox').add({
    kind: 'delete_request',
    userId: uid,
    messagesScrubbed,
    status: 'open',
    createdAt: now,
  });

  // Delete the Auth account last so a mid-run failure leaves a signed-in
  // user who can simply retry. The client signs out on success.
  await admin.auth().deleteUser(uid);

  return {
    messagesScrubbed,
    sessionsUnlinked,
    tokensCleared,
    quotaDocsRemoved,
    authDeleted: true,
  };
});

/**
 * activateMembership — after payment success (PR 22).
 *
 * IMPORTANT: trusts the client-supplied paymentId — acceptable ONLY while
 * `config/payments.enabled` is false (gate below). Phase B must verify the
 * payment against the gateway BEFORE payments are enabled. See
 * `gatewayVerificationImplemented()` — a second flag guards this
 * specifically so `enabled` alone can't accidentally activate it.
 */
export const activateMembership = onCall(callOpts, async (request) => {
  if (!request.auth?.uid) {
    throw new HttpsError('unauthenticated', 'Sign in required.');
  }
  if (!(await paymentsEnabled())) {
    throw new HttpsError('failed-precondition', 'PAYMENTS_DISABLED');
  }
  if (!(await gatewayVerificationImplemented())) {
    throw new HttpsError('failed-precondition', 'PAYMENT_VERIFICATION_NOT_IMPLEMENTED');
  }
  const uid = request.auth.uid;
  const planId = String(request.data?.planId ?? 'plan_monthly_29');
  const paymentId = String(request.data?.paymentId ?? '');
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

/**
 * onMessageCreate — preview/unread + reject if blocked (PR 11).
 */
export const onMessageCreate = onDocumentCreated(
  'chats/{sessionId}/messages/{messageId}',
  async (event) => {
    const snap = event.data;
    if (!snap) return;
    const sessionId = event.params.sessionId;
    const msg = snap.data();
    const senderId = msg.senderId as string;
    const text = (msg.text as string) ?? '';
    const chatRef = db.doc(`chats/${sessionId}`);
    const chatSnap = await chatRef.get();
    if (!chatSnap.exists) return;
    const chat = chatSnap.data()!;
    const userId = chat.userId as string;
    const listenerId = chat.listenerId as string;

    if (await isBlockedPair(userId, listenerId)) {
      await snap.ref.delete();
      return;
    }

    const fromUser = senderId === userId;
    await chatRef.set(
      {
        lastMessagePreview: text.slice(0, 120),
        lastMessageAt: msg.timestamp ?? admin.firestore.FieldValue.serverTimestamp(),
        lastMessageSenderId: senderId,
        userUnreadCount: fromUser
          ? (chat.userUnreadCount as number) ?? 0
          : ((chat.userUnreadCount as number) ?? 0) + 1,
        listenerUnreadCount: fromUser
          ? ((chat.listenerUnreadCount as number) ?? 0) + 1
          : (chat.listenerUnreadCount as number) ?? 0,
      },
      { merge: true },
    );
  },
);

/** Expire unpaid booking holds (PR 13). */
export const expireBookingHolds = onSchedule('every 5 minutes', async () => {
  const now = admin.firestore.Timestamp.now();
  const snap = await db
    .collection('bookings')
    .where('status', '==', 'pending_payment')
    .where('holdExpiresAt', '<=', now)
    .get();
  const batch = db.batch();
  for (const doc of snap.docs) {
    batch.set(doc.ref, { status: 'expired' }, { merge: true });
  }
  if (!snap.empty) await batch.commit();
});
