import { readFileSync } from 'node:fs';
import { beforeAll, afterAll, beforeEach, describe, it } from 'vitest';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, updateDoc, writeBatch, serverTimestamp } from 'firebase/firestore';
import { player, seed, match, memberRSVP, hoursFromNow } from './helpers.js';
let env;
beforeAll(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-whosdown', firestore: { rules: readFileSync('firestore.rules', 'utf8') } });
});
afterAll(async () => { await env.cleanup(); });
beforeEach(async () => {
  await env.clearFirestore();
  await seed(env, match({ joinedCount: 2, startTime: hoursFromNow(3), endTime: hoursFromNow(4) }));
  await env.withSecurityRulesDisabled(async c => {
    await setDoc(doc(c.firestore(), 'matches/m1/rsvps/sam'), memberRSVP('sam', 'approved', { displayName: 'Sam' }));
  });
});
describe('final lifecycle integrity audit', () => {
  it('an approved Player cannot increment the joined count again', async () => {
    const db = player(env, 'sam');
    await assertFails(updateDoc(doc(db, 'matches/m1'), { joinedCount: 3, updatedAt: serverTimestamp() }));
  });
  it('counter writes cannot add unknown Match fields', async () => {
    const db = player(env, 'taylor');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), { joinedCount: 3, updatedAt: serverTimestamp(), forgedField: true });
    batch.set(doc(db, 'matches/m1/rsvps/taylor'), {
      ...memberRSVP('taylor', 'approved'), requestedAt: serverTimestamp(), respondedAt: serverTimestamp(),
    });
    await assertFails(batch.commit());
  });
  it('a Player cannot leave without updating the counter', async () => {
    await assertFails(updateDoc(doc(player(env, 'sam'), 'matches/m1/rsvps/sam'), { status: 'left' }));
  });
  it('cancellation cannot smuggle unrelated changes', async () => {
    await assertFails(updateDoc(doc(player(env, 'alex'), 'matches/m1'), {
      status: 'cancelled', cancelReason: 'Rain', venueName: 'Changed venue', updatedAt: serverTimestamp(),
    }));
  });
  it('host transfer cannot smuggle time changes', async () => {
    const db = player(env, 'alex');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), { hostId: 'sam', hostName: 'Sam', startTime: hoursFromNow(6), updatedAt: serverTimestamp() });
    batch.update(doc(db, 'matches/m1/rsvps/alex'), { isHost: false });
    batch.update(doc(db, 'matches/m1/rsvps/sam'), { isHost: true });
    await assertFails(batch.commit());
  });
  it('host flags cannot change unrelated RSVP fields', async () => {
    const db = player(env, 'alex');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), { hostId: 'sam', hostName: 'Sam', updatedAt: serverTimestamp() });
    batch.update(doc(db, 'matches/m1/rsvps/alex'), { isHost: false, displayName: 'Impostor' });
    batch.update(doc(db, 'matches/m1/rsvps/sam'), { isHost: true });
    await assertFails(batch.commit());
  });
  it('check-in cannot change details or RSVP identity', async () => {
    await env.withSecurityRulesDisabled(async c => {
      await updateDoc(doc(c.firestore(), 'matches/m1'), { startTime: hoursFromNow(-1), endTime: hoursFromNow(1) });
    });
    const db = player(env, 'alex');
    await assertFails(updateDoc(doc(db, 'matches/m1'), { checkedInAt: serverTimestamp(), playerLimit: 50, updatedAt: serverTimestamp() }));
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), { checkedInAt: serverTimestamp(), updatedAt: serverTimestamp() });
    batch.update(doc(db, 'matches/m1/rsvps/sam'), { checkedIn: true, attended: true, userId: 'alex' });
    await assertFails(batch.commit());
  });
  it('valid check-in still works and cannot be submitted outside its window', async () => {
    await env.withSecurityRulesDisabled(async c => {
      await updateDoc(doc(c.firestore(), 'matches/m1'), { startTime: hoursFromNow(-1), endTime: hoursFromNow(1) });
    });
    const db = player(env, 'alex');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), { checkedInAt: serverTimestamp(), updatedAt: serverTimestamp() });
    batch.update(doc(db, 'matches/m1/rsvps/sam'), { checkedIn: true, attended: false });
    await assertSucceeds(batch.commit());
    await env.withSecurityRulesDisabled(async c => {
      await updateDoc(doc(c.firestore(), 'matches/m1'), { startTime: hoursFromNow(-52), endTime: hoursFromNow(-49) });
    });
    await assertFails(updateDoc(doc(db, 'matches/m1'), { checkedInAt: serverTimestamp(), updatedAt: serverTimestamp() }));
  });
});
