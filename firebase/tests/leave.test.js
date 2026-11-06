// 1.16 Leave Match or cancel a request.
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

async function withMember(status, matchOverrides = {}) {
  await env.clearFirestore();
  const counts = {
    approved: { joinedCount: 2 },
    pending: { pendingCount: 1 },
    waitlisted: { waitlistCount: 1, waitlistIds: ['taylor'], joinedCount: 14, playerLimit: 14 },
  };
  await seed(env, match({
    joinType: 'open', createdAt: hoursFromNow(-1), updatedAt: hoursFromNow(-1),
    ...counts[status], ...matchOverrides,
  }));
  await env.withSecurityRulesDisabled(async (context) => {
    const { setDoc } = await import('firebase/firestore');
    await setDoc(doc(context.firestore(), 'matches/m1/rsvps/taylor'), {
      ...memberRSVP('taylor', status),
      requestedAt: Timestamp.now(),
      respondedAt: status === 'approved' ? Timestamp.now() : null,
    });
  });
}

function leave(db, { joined, pending, waitlist, ids, uid = 'taylor' }) {
  const batch = writeBatch(db);
  const update = { updatedAt: serverTimestamp() };
  if (joined !== undefined) update.joinedCount = joined;
  if (pending !== undefined) update.pendingCount = pending;
  if (waitlist !== undefined) update.waitlistCount = waitlist;
  if (ids !== undefined) update.waitlistIds = ids;
  batch.update(doc(db, 'matches/m1'), update);
  batch.update(doc(db, `matches/m1/rsvps/${uid}`), { status: 'left' });
  return batch.commit();
}

describe('leave', () => {
  it('an approved Player drops joinedCount by 1', async () => {
    await withMember('approved');
    await assertSucceeds(leave(player(env, 'taylor'), { joined: 1 }));
  });

  it('a pending Player drops pendingCount by 1', async () => {
    await withMember('pending');
    await assertSucceeds(leave(player(env, 'taylor'), { pending: 0 }));
  });

  it('a waitlisted Player drops the waitlist', async () => {
    await withMember('waitlisted');
    await assertSucceeds(leave(player(env, 'taylor'), { waitlist: 0, ids: [] }));
  });

  it('cannot leave someone else, lower the wrong counter, or lower it by 2', async () => {
    await withMember('approved');
    await assertFails(leave(player(env, 'sam'), { joined: 1, uid: 'taylor' }));
    await assertFails(leave(player(env, 'taylor'), { pending: 0 }));
    await assertFails(leave(player(env, 'taylor'), { joined: 0 }));
  });

  beforeEach(() => {});
});
