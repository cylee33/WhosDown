import { readFileSync } from 'node:fs';
import { beforeAll, afterAll, beforeEach, describe, it } from 'vitest';
import { initializeTestEnvironment, assertFails, assertSucceeds } from '@firebase/rules-unit-testing';
import { doc, setDoc, getDoc, getDocs, collection, updateDoc, deleteDoc, serverTimestamp } from 'firebase/firestore';
import { player, guest } from './helpers.js';
let env;
beforeAll(async () => {
  env = await initializeTestEnvironment({ projectId: 'demo-whosdown', firestore: { rules: readFileSync('firestore.rules', 'utf8') } });
});
afterAll(async () => { await env.cleanup(); });
beforeEach(async () => { await env.clearFirestore(); });
const report = (extra = {}) => ({ reporterId: 'alex', reportedUserId: null, matchId: 'm1', reason: 'harassment', details: null, status: 'open', createdAt: serverTimestamp(), ...extra });
describe('reports', () => {
  it('accepts Match and Player reports with optional Match context', async () => {
    const db = player(env, 'alex');
    await assertSucceeds(setDoc(doc(db, 'reports/match'), report()));
    await assertSucceeds(setDoc(doc(db, 'reports/player'), report({ reportedUserId: 'sam', matchId: null, reason: 'noShow', details: 'x'.repeat(1000) })));
    await assertSucceeds(setDoc(doc(db, 'reports/both'), report({ reportedUserId: 'sam', reason: 'misleading' })));
  });
  it('rejects Guests and signed-out clients', async () => {
    await assertFails(setDoc(doc(guest(env, 'alex'), 'reports/r'), report()));
    await assertFails(setDoc(doc(env.unauthenticatedContext().firestore(), 'reports/r'), report()));
  });
  it('rejects impersonation and self reporting', async () => {
    const db = player(env, 'alex');
    await assertFails(setDoc(doc(db, 'reports/r'), report({ reporterId: 'sam' })));
    await assertFails(setDoc(doc(db, 'reports/r'), report({ reportedUserId: 'alex' })));
  });
  it('validates targets, reason, details, status, timestamp and fields', async () => {
    const db = player(env, 'alex');
    for (const extra of [{ matchId: null }, { matchId: '' }, { reportedUserId: 42 }, { reason: 'spam' }, { details: 'x'.repeat(1001) }, { status: 'closed' }, { createdAt: new Date(0) }, { admin: true }]) {
      await assertFails(setDoc(doc(db, 'reports/r'), report(extra)));
    }
  });
  it('denies reads, listing, updates and deletion even to the reporter', async () => {
    const db = player(env, 'alex');
    const ref = doc(db, 'reports/r');
    await assertSucceeds(setDoc(ref, report()));
    await assertFails(getDoc(ref));
    await assertFails(getDocs(collection(db, 'reports')));
    await assertFails(updateDoc(ref, { details: 'Edited' }));
    await assertFails(deleteDoc(ref));
    await assertFails(getDoc(doc(player(env, 'sam'), 'reports/r')));
  });
});
