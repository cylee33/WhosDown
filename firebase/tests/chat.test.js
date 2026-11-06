// 1.20 Match chat (D39).
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, serverTimestamp, setDoc, Timestamp, writeBatch } from 'firebase/firestore';
import { hoursFromNow, match, memberRSVP, player, seed } from './helpers.js';

let env;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-whosdown',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

afterAll(async () => { await env.cleanup(); });

beforeEach(async () => {
  await env.clearFirestore();
  await seed(env, match({ createdAt: hoursFromNow(-1), updatedAt: hoursFromNow(-1) }));
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'matches/m1/rsvps/taylor'), {
      ...memberRSVP('taylor', 'approved'), requestedAt: Timestamp.now(), respondedAt: Timestamp.now(),
    });
    await setDoc(doc(db, 'matches/m1/rsvps/pending'), {
      ...memberRSVP('pending', 'pending'), requestedAt: Timestamp.now(), respondedAt: null,
    });
  });
});

function post(db, uid, name = 'Taylor', messageId = 'a') {
  const batch = writeBatch(db);
  batch.set(doc(db, `conversations/m1/messages/${messageId}`), {
    senderId: uid, senderName: name, text: 'On my way', sentAt: serverTimestamp(),
  });
  batch.update(doc(db, 'conversations/m1'), { lastMessageText: 'On my way', lastMessageAt: serverTimestamp() });
  return batch.commit();
}

describe('Match chat', () => {
  it('an approved Player and the Host can read and post', async () => {
    await assertSucceeds(post(player(env, 'taylor'), 'taylor'));
    await assertSucceeds(getDoc(doc(player(env, 'alex'), 'conversations/m1/messages/a')));
    await assertSucceeds(post(player(env, 'alex'), 'alex', 'Alex Morgan', 'b'));
  });

  it('a pending Player and a Guest cannot read or post, and you cannot post as someone else', async () => {
    await assertFails(post(player(env, 'pending'), 'pending'));
    await assertFails(getDoc(doc(player(env, 'pending'), 'conversations/m1')));
    await assertFails(post(player(env, 'taylor'), 'alex', 'Taylor'));
    const guest = env.authenticatedContext('g', { firebase: { sign_in_provider: 'anonymous' } }).firestore();
    await assertFails(getDoc(doc(guest, 'conversations/m1/messages/a')));
  });
});
