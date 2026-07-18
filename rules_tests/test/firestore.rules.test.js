/**
 * Firestore rules unit tests (PR 2 + PR 7–10 lockdowns).
 *
 * Run: cd rules_tests && npm install && npm test
 * Requires Java 17+ for the Firestore emulator.
 */
const path = require('path');
const { describe, it, before, after, beforeEach } = require('node:test');
const assert = require('node:assert/strict');
const {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} = require('@firebase/rules-unit-testing');

const RULES_PATH = path.resolve(__dirname, '../../firestore.rules');
const PROJECT_ID = 'demo-emo-sup';

/** @type {import('@firebase/rules-unit-testing').RulesTestEnvironment} */
let testEnv;

before(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: PROJECT_ID,
    firestore: {
      rules: require('fs').readFileSync(RULES_PATH, 'utf8'),
      host: '127.0.0.1',
      port: 8080,
    },
  });
});

after(async () => {
  if (testEnv) await testEnv.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

function authedDb(uid, claims = {}) {
  return testEnv.authenticatedContext(uid, claims).firestore();
}

function unauthDb() {
  return testEnv.unauthenticatedContext().firestore();
}

describe('Users + field ACL (PR 7)', () => {
  it('denies unauthenticated access to users', async () => {
    await assertFails(unauthDb().collection('users').doc('u1').get());
  });

  it('allows user to create own profile without PII', async () => {
    const db = authedDb('user_a');
    await assertSucceeds(
      db.collection('users').doc('user_a').set({
        uid: 'user_a',
        anonymousName: 'Quiet River',
        authMethod: 'phone',
        createdAt: new Date().toISOString(),
        preferredLanguages: ['English', 'Shona'],
        locale: 'en',
      }),
    );
  });

  it('denies email/phone/legalName and deletionRequestedAt on create', async () => {
    const db = authedDb('user_pii');
    await assertFails(
      db.collection('users').doc('user_pii').set({
        uid: 'user_pii',
        anonymousName: 'Hidden',
        authMethod: 'email',
        email: 'leak@example.com',
        createdAt: new Date().toISOString(),
      }),
    );
    await assertFails(
      db.collection('users').doc('user_del').set({
        uid: 'user_del',
        anonymousName: 'X',
        authMethod: 'phone',
        createdAt: new Date().toISOString(),
        deletionRequestedAt: new Date().toISOString(),
      }),
    );
  });

  it('allows own fcm_tokens write; denies match_quota write', async () => {
    const db = authedDb('user_a');
    await assertSucceeds(
      db.collection('users').doc('user_a').collection('fcm_tokens').doc('t1').set({
        token: 'abc',
        updatedAt: new Date().toISOString(),
      }),
    );
    await assertFails(
      db.collection('users').doc('user_a').collection('match_quota').doc('2026-W29').set({
        asyncStarted: 0,
        asyncRefunded: 0,
      }),
    );
  });

  it('allows match_quota read for self after admin seed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore()
        .collection('users').doc('user_a')
        .collection('match_quota').doc('2026-W29')
        .set({ weekId: '2026-W29', asyncStarted: 1, asyncRefunded: 0 });
    });
    const db = authedDb('user_a');
    await assertSucceeds(
      db.collection('users').doc('user_a').collection('match_quota').doc('2026-W29').get(),
    );
  });
});

describe('listener_public + private listeners (PR 8)', () => {
  it('allows signed-in list of listener_public', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('listener_public').doc('listener_1').set({
        id: 'listener_1',
        displayName: 'Listener — Harbor',
        bio: 'Test',
        languages: ['English', 'Shona'],
        availableNow: true,
        tier: 'standard',
      });
    });
    const db = authedDb('user_any');
    await assertSucceeds(db.collection('listener_public').get());
  });

  it('denies client write to listener_public', async () => {
    const db = authedDb('user_any');
    await assertFails(
      db.collection('listener_public').doc('x').set({ id: 'x', displayName: 'Nope' }),
    );
  });

  it('denies open list of private listeners collection', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('listeners').doc('listener_1').set({
        id: 'listener_1',
        displayName: 'Listener — Harbor',
        role: 'listener',
      });
    });
    const db = authedDb('user_any');
    await assertFails(db.collection('listeners').get());
  });

  it('allows listener to get own private listener doc', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('listeners').doc('listener_1').set({
        id: 'listener_1',
        displayName: 'Listener — Harbor',
        role: 'listener',
      });
    });
    const db = authedDb('listener_1', { role: 'listener' });
    await assertSucceeds(db.collection('listeners').doc('listener_1').get());
  });
});

describe('chats create denied (PR 10)', () => {
  it('denies client chat create even for self', async () => {
    const db = authedDb('user_chat');
    await assertFails(
      db.collection('chats').doc('chat_1').set({
        userId: 'user_chat',
        listenerId: 'listener_1',
        startedAt: new Date().toISOString(),
        status: 'active',
      }),
    );
  });

  it('allows participant message create after admin session seed', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('chats').doc('chat_1').set({
        userId: 'user_chat',
        listenerId: 'listener_1',
        startedAt: new Date().toISOString(),
        status: 'active',
      });
    });
    const db = authedDb('user_chat');
    await assertSucceeds(
      db.collection('chats').doc('chat_1').collection('messages').doc('m1').set({
        senderId: 'user_chat',
        text: 'Hello',
        timestamp: new Date().toISOString(),
        status: 'sent',
      }),
    );
  });
});

describe('bookings server-only writes (PR 9)', () => {
  it('denies client booking create', async () => {
    const db = authedDb('user_book');
    await assertFails(
      db.collection('bookings').doc('b1').set({
        userId: 'user_book',
        listenerId: 'listener_1',
        slotStart: new Date().toISOString(),
        status: 'confirmed',
      }),
    );
  });

  it('allows participant read of booking seeded by admin', async () => {
    await testEnv.withSecurityRulesDisabled(async (ctx) => {
      await ctx.firestore().collection('bookings').doc('b1').set({
        userId: 'user_book',
        listenerId: 'listener_1',
        slotStart: new Date().toISOString(),
        status: 'confirmed',
      });
    });
    const db = authedDb('user_book');
    await assertSucceeds(db.collection('bookings').doc('b1').get());
  });
});

describe('reports + default deny', () => {
  it('allows report create once; denies read by submitter', async () => {
    const db = authedDb('reporter_1');
    const ref = db.collection('reports').doc('rep_1');
    await assertSucceeds(
      ref.set({
        reporterId: 'reporter_1',
        targetType: 'listener',
        targetId: 'listener_1',
        reason: 'Felt unsafe or pressured',
        createdAt: new Date().toISOString(),
        status: 'open',
      }),
    );
    await assertFails(ref.get());
  });

  it('denies unknown collections', async () => {
    await assertFails(authedDb('user_a').collection('secrets').doc('x').set({ a: 1 }));
  });
});
