// D38 notification writer (1.15).
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, getDoc, serverTimestamp, setDoc, updateDoc, deleteDoc } from 'firebase/firestore';
import { hoursFromNow, match, player, seed } from './helpers.js';

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
});

const note = (from, extra = {}) => ({
  type: 'approved',
  title: "You're in: Pickup Soccer",
  body: 'The Host approved your request.',
  matchId: 'm1',
  fromUserId: from,
  changes: null,
  hostNote: null,
  isRead: false,
  createdAt: serverTimestamp(),
  ...extra,
});

describe('notifications', () => {
  it('the Host can write into a Player inbox, and the Player can only mark it read or delete it', async () => {
    const taylor = player(env, 'taylor');
    await assertSucceeds(setDoc(doc(player(env, 'alex'), 'users/taylor/notifications/n1'), note('alex')));
    await assertSucceeds(getDoc(doc(taylor, 'users/taylor/notifications/n1')));
    await assertFails(getDoc(doc(player(env, 'sam'), 'users/taylor/notifications/n1')));
    await assertSucceeds(updateDoc(doc(taylor, 'users/taylor/notifications/n1'), { isRead: true }));
    await assertFails(updateDoc(doc(taylor, 'users/taylor/notifications/n1'), { title: 'changed' }));
    await assertSucceeds(deleteDoc(doc(taylor, 'users/taylor/notifications/n1')));
  });

  it('a stranger cannot write a notification', async () => {
    await assertFails(setDoc(doc(player(env, 'sam'), 'users/taylor/notifications/n1'), note('sam')));
  });
});
