/**
 * Baseline Firestore rules tests (PR 2).
 *
 * Run from repo root:
 *   cd rules_tests && npm install && npm test
 *
 * Requires Java for the Firestore emulator (firebase-tools).
 */
const path = require('path');
const { describe, it, before, after } = require('node:test');
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

function authedDb(uid, claims = {}) {
  return testEnv.authenticatedContext(uid, claims).firestore();
}

function unauthDb() {
  return testEnv.unauthenticatedContext().firestore();
}

describe('Firestore rules baseline', () => {
  it('denies unauthenticated access to users', async () => {
    const db = unauthDb();
    await assertFails(db.collection('users').doc('u1').get());
  });

  it('allows user to create own profile without PII fields', async () => {
    const db = authedDb('user_a');
    await assertSucceeds(
      db.collection('users').doc('user_a').set({
        uid: 'user_a',
        anonymousName: 'Quiet River',
        authMethod: 'phone',
        createdAt: new Date().toISOString(),
      }),
    );
  });

  it('denies user creating another user profile', async () => {
    const db = authedDb('user_a');
    await assertFails(
      db.collection('users').doc('user_b').set({
        uid: 'user_b',
        anonymousName: 'Other',
        authMethod: 'email',
        createdAt: new Date().toISOString(),
      }),
    );
  });

  it('denies profile fields email/phone/legalName on create', async () => {
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
  });

  it('allows participant chat create with required keys (current baseline)', async () => {
    // Note: production will deny client chat create (later PR).
    const db = authedDb('user_chat');
    await assertSucceeds(
      db.collection('chats').doc('chat_1').set({
        userId: 'user_chat',
        listenerId: 'listener_1',
        startedAt: new Date().toISOString(),
        status: 'active',
      }),
    );
  });

  it('denies chat create when userId is not self', async () => {
    const db = authedDb('user_chat');
    await assertFails(
      db.collection('chats').doc('chat_hijack').set({
        userId: 'someone_else',
        listenerId: 'listener_1',
        startedAt: new Date().toISOString(),
        status: 'active',
      }),
    );
  });

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
    await assertFails(ref.update({ status: 'closed' }));
  });

  it('denies report create with wrong reporterId', async () => {
    const db = authedDb('reporter_1');
    await assertFails(
      db.collection('reports').doc('rep_bad').set({
        reporterId: 'not_me',
        targetType: 'user',
        targetId: 'u2',
        reason: 'Spam or fake account',
        createdAt: new Date().toISOString(),
        status: 'open',
      }),
    );
  });

  it('allows booking create for self with pending/confirmed (current baseline)', async () => {
    // Note: production will deny client booking writes (later PR).
    const db = authedDb('user_book');
    await assertSucceeds(
      db.collection('bookings').doc('b1').set({
        userId: 'user_book',
        listenerId: 'listener_1',
        slotStart: new Date().toISOString(),
        status: 'confirmed',
      }),
    );
  });

  it('allows signed-in listener list (current open baseline)', async () => {
    await testEnv.withSecurityRulesDisabled(async (context) => {
      const admin = context.firestore();
      await admin.collection('listeners').doc('listener_1').set({
        id: 'listener_1',
        displayName: 'Listener — Harbor',
        bio: 'Test',
        languages: ['English'],
        availableNow: true,
        role: 'listener',
      });
    });

    const db = authedDb('user_any');
    await assertSucceeds(db.collection('listeners').get());
  });

  it('denies unknown collections by default', async () => {
    const db = authedDb('user_a');
    await assertFails(db.collection('secrets').doc('x').set({ a: 1 }));
  });
});
