// Phase 0 baseline rules (1.1): deny by default, public reads for signed-in users,
// owner-only private settings, Guests can't write.
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, getDoc, setDoc } from 'firebase/firestore';

let env;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-whosdown',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.withSecurityRulesDisabled(async (ctx) => {
    const db = ctx.firestore();
    await setDoc(doc(db, 'matches/m1'), { title: 'Pickup Soccer', hostId: 'alex' });
    await setDoc(doc(db, 'matches/m1/rsvps/alex'), { status: 'approved' });
    await setDoc(doc(db, 'users/alex'), { displayName: 'Alex Morgan' });
    await setDoc(doc(db, 'users/alex/private/settings'), { email: 'alex@example.com' });
  });
});

const player = (uid) => env.authenticatedContext(uid).firestore();
const guest = (uid) =>
  env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).firestore();
const nobody = () => env.unauthenticatedContext().firestore();

describe('reads', () => {
  it('signed-in Players and Guests can read Matches, RSVPs, and profiles', async () => {
    for (const db of [player('mina'), guest('g1')]) {
      await assertSucceeds(getDoc(doc(db, 'matches/m1')));
      await assertSucceeds(getDoc(doc(db, 'matches/m1/rsvps/alex')));
      await assertSucceeds(getDoc(doc(db, 'users/alex')));
    }
  });

  it('signed-out users can read nothing', async () => {
    await assertFails(getDoc(doc(nobody(), 'matches/m1')));
    await assertFails(getDoc(doc(nobody(), 'users/alex')));
  });
});

describe('private settings', () => {
  it('the owner can read and write their own settings', async () => {
    const db = player('alex');
    await assertSucceeds(getDoc(doc(db, 'users/alex/private/settings')));
    await assertSucceeds(setDoc(doc(db, 'users/alex/private/settings'), { searchRadiusMiles: 5 }));
  });

  it('another Player can neither read nor write them', async () => {
    const db = player('mina');
    await assertFails(getDoc(doc(db, 'users/alex/private/settings')));
    await assertFails(setDoc(doc(db, 'users/alex/private/settings'), { searchRadiusMiles: 5 }));
  });
});

describe('Guests', () => {
  it('can write nothing, not even their own settings', async () => {
    const db = guest('g1');
    await assertFails(setDoc(doc(db, 'users/g1/private/settings'), { searchRadiusMiles: 5 }));
    await assertFails(setDoc(doc(db, 'users/g1'), { displayName: 'Guest' }));
    await assertFails(setDoc(doc(db, 'matches/m2'), { title: 'x' }));
  });

  it('can read Matches but cannot RSVP, report, or write notifications (1.3)', async () => {
    const db = guest('g1');
    await assertSucceeds(getDoc(doc(db, 'matches/m1')));
    await assertFails(setDoc(doc(db, 'matches/m1/rsvps/g1'), { status: 'pending' }));
    await assertFails(setDoc(doc(db, 'reports/r1'), { reporterId: 'g1', reason: 'other' }));
    await assertFails(setDoc(doc(db, 'users/alex/notifications/n1'), { fromUserId: 'g1' }));
  });
});

describe('deny by default', () => {
  it('Players cannot write Matches, RSVPs, Venues, or reports until a feature allows it', async () => {
    const db = player('mina');
    await assertFails(setDoc(doc(db, 'matches/m2'), { title: 'x', hostId: 'mina' }));
    await assertFails(setDoc(doc(db, 'matches/m1/rsvps/mina'), { status: 'approved' }));
    await assertFails(setDoc(doc(db, 'venues/v1'), { name: 'x' })); // fails validation (1.12)
    await assertFails(setDoc(doc(db, 'reports/r1'), { reason: 'other' }));
  });
});
