// 1.13 Join an open Match and 1.14 Request to join.
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, serverTimestamp, writeBatch } from 'firebase/firestore';
import { hoursFromNow, match, memberRSVP, player, publish, seed } from './helpers.js';

let env;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-whosdown',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

afterAll(async () => { await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });

function joinOpen(db, { joined = 2, status = 'approved', joinType = 'open', limit = 14, uid = 'taylor' } = {}) {
  const batch = writeBatch(db);
  batch.update(doc(db, 'matches/m1'), {
    joinedCount: joined,
    updatedAt: serverTimestamp(),
    attendeePreview: ['AM', 'TA'],
  });
  batch.set(doc(db, `matches/m1/rsvps/${uid}`), memberRSVP(uid, status));
  return batch.commit();
}

function request(db, { pending = 1, note = null, status = 'pending', uid = 'taylor' } = {}) {
  const batch = writeBatch(db);
  batch.update(doc(db, 'matches/m1'), { pendingCount: pending, updatedAt: serverTimestamp() });
  batch.set(doc(db, `matches/m1/rsvps/${uid}`), memberRSVP(uid, status, { noteToHost: note, respondedAt: null }));
  return batch.commit();
}

describe('join an open Match', () => {
  it('writes an approved RSVP and joinedCount + 1', async () => {
    await assertSucceeds(publish(player(env, 'alex'), { matchData: match({ joinType: 'open' }) }));
    await assertSucceeds(joinOpen(player(env, 'taylor')));
  });

  it('refuses a self-approve on an Approval-required Match', async () => {
    await assertSucceeds(publish(player(env, 'alex'), { matchData: match({ joinType: 'approvalRequired' }) }));
    await assertFails(joinOpen(player(env, 'taylor')));
  });

  it('refuses a Full Match and a joinedCount jump of 2', async () => {
    await seed(env, match({
      joinType: 'open', playerLimit: 2, joinedCount: 2,
      createdAt: hoursFromNow(-1), updatedAt: hoursFromNow(-1),
    }));
    await assertFails(joinOpen(player(env, 'taylor'), { joined: 3 }));
    await env.clearFirestore();
    await assertSucceeds(publish(player(env, 'alex'), { matchData: match({ joinType: 'open', joinedCount: 1 }) }));
    await assertFails(joinOpen(player(env, 'taylor'), { joined: 3 }));
  });

  it('refuses a started or cancelled Match', async () => {
    await seed(env, match({ joinType: 'open', startTime: hoursFromNow(-1), endTime: hoursFromNow(1), createdAt: hoursFromNow(-2), updatedAt: hoursFromNow(-2) }));
    await assertFails(joinOpen(player(env, 'taylor')));
    await env.clearFirestore();
    await seed(env, match({ joinType: 'open', status: 'cancelled', cancelReason: 'Rain', createdAt: hoursFromNow(-2), updatedAt: hoursFromNow(-2) }));
    await assertFails(joinOpen(player(env, 'taylor')));
  });
});

describe('request to join', () => {
  it('creates a pending RSVP and pendingCount + 1', async () => {
    await assertSucceeds(publish(player(env, 'alex'), { matchData: match({ joinType: 'approvalRequired' }) }));
    await assertSucceeds(request(player(env, 'taylor'), { note: 'I can bring a ball' }));
  });

  it('refuses an approved RSVP, someone else\'s RSVP, pendingCount + 2, and a long note', async () => {
    await assertSucceeds(publish(player(env, 'alex'), { matchData: match({ joinType: 'approvalRequired' }) }));
    await assertFails(request(player(env, 'taylor'), { status: 'approved', pending: 0 }));
    await assertFails(request(player(env, 'taylor'), { uid: 'alex', pending: 1 }));
    await assertFails(request(player(env, 'taylor'), { pending: 2 }));
    await assertFails(request(player(env, 'taylor'), { note: 'x'.repeat(301) }));
  });

  it('refuses a second request after a decline', async () => {
    await seed(env, match({ joinType: 'approvalRequired', createdAt: hoursFromNow(-2), updatedAt: hoursFromNow(-2) }));
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      const { setDoc, Timestamp } = await import('firebase/firestore');
      await setDoc(doc(db, 'matches/m1/rsvps/taylor'), {
        ...memberRSVP('taylor', 'declined'),
        requestedAt: Timestamp.now(),
        respondedAt: Timestamp.now(),
      });
    });
    await assertFails(request(player(env, 'taylor')));
  });

  it('the Host cannot request their own Match', async () => {
    await assertSucceeds(publish(player(env, 'alex'), { matchData: match({ joinType: 'approvalRequired' }) }));
    await assertFails(request(player(env, 'alex'), { uid: 'alex' }));
  });
});
