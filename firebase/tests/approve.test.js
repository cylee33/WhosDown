// 1.15 Host approve or decline.
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, serverTimestamp, Timestamp, writeBatch } from 'firebase/firestore';
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
  await seed(env, match({
    joinType: 'approvalRequired', pendingCount: 1, playerLimit: 2, joinedCount: 1,
    createdAt: hoursFromNow(-1), updatedAt: hoursFromNow(-1),
  }));
  await env.withSecurityRulesDisabled(async (context) => {
    const { setDoc } = await import('firebase/firestore');
    await setDoc(doc(context.firestore(), 'matches/m1/rsvps/taylor'), {
      ...memberRSVP('taylor', 'pending'),
      requestedAt: Timestamp.now(),
      respondedAt: null,
    });
  });
});

function decide(db, { status, joined, pending, uid = 'taylor', message = null }) {
  const batch = writeBatch(db);
  batch.update(doc(db, 'matches/m1'), {
    joinedCount: joined,
    pendingCount: pending,
    updatedAt: serverTimestamp(),
    ...(status === 'approved' ? { attendeePreview: ['AM', 'TA'] } : {}),
  });
  batch.update(doc(db, `matches/m1/rsvps/${uid}`), {
    status,
    respondedAt: serverTimestamp(),
    hostResponse: message,
  });
  if (status === 'approved' || status === 'declined') {
    batch.set(doc(db, `users/${uid}/notifications/n1`), {
      type: status,
      title: status === 'approved' ? "You're in: Pickup Soccer" : 'Request declined: Pickup Soccer',
      body: message ?? 'Answered',
      matchId: 'm1',
      fromUserId: 'alex',
      changes: null,
      hostNote: message,
      isRead: false,
      createdAt: serverTimestamp(),
    });
  }
  return batch.commit();
}

describe('approve and decline', () => {
  it('the Host approves and writes a notification', async () => {
    await assertSucceeds(decide(player(env, 'alex'), { status: 'approved', joined: 2, pending: 0 }));
  });

  it('the Host declines with a message', async () => {
    await assertSucceeds(decide(player(env, 'alex'), { status: 'declined', joined: 1, pending: 0, message: 'Full skill range' }));
  });

  it('a non-Host cannot approve, and the Host cannot approve over the limit', async () => {
    await assertFails(decide(player(env, 'taylor'), { status: 'approved', joined: 2, pending: 0 }));
    await env.clearFirestore();
    await seed(env, match({
      joinType: 'approvalRequired', pendingCount: 1, playerLimit: 1, joinedCount: 1,
      createdAt: hoursFromNow(-1), updatedAt: hoursFromNow(-1),
    }));
    await env.withSecurityRulesDisabled(async (context) => {
      const { setDoc } = await import('firebase/firestore');
      await setDoc(doc(context.firestore(), 'matches/m1/rsvps/taylor'), {
        ...memberRSVP('taylor', 'pending'), requestedAt: Timestamp.now(), respondedAt: null,
      });
    });
    await assertFails(decide(player(env, 'alex'), { status: 'approved', joined: 2, pending: 0 }));
  });

  it('a Player cannot approve themselves', async () => {
    await assertFails(decide(player(env, 'taylor'), { status: 'approved', joined: 2, pending: 0, uid: 'taylor' }));
  });
});
