// 1.2 Account and sign-in: W1 creates the profile; onboarding sets onboardedAt once.
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, serverTimestamp, setDoc, Timestamp, updateDoc, writeBatch } from 'firebase/firestore';

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
});

const player = (uid) => env.authenticatedContext(uid).firestore();
const guest = (uid) =>
  env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).firestore();

const newProfile = (overrides = {}) => ({
  displayName: 'Alex Morgan',
  displayNameLowercase: 'alex morgan',
  photoURL: null,
  bio: null,
  homeArea: null,
  playStyles: [],
  sportLevels: {},
  customSportName: null,
  createdAt: serverTimestamp(),
  onboardedAt: null,
  ...overrides,
});

describe('W1 create profile', () => {
  it('a Player creates their own profile and settings in one batch', async () => {
    const db = player('alex');
    const batch = writeBatch(db);
    batch.set(doc(db, 'users/alex'), newProfile());
    batch.set(doc(db, 'users/alex/private/settings'), {
      email: 'alex@example.com',
      notificationPrefs: { approvals: true, timeOrLocationChanges: true, cancellations: true },
      searchRadiusMiles: 3,
    });
    await assertSucceeds(batch.commit());
  });

  it("can't create someone else's profile", async () => {
    await assertFails(setDoc(doc(player('mina'), 'users/alex'), newProfile()));
  });

  it('a Guest cannot create a profile', async () => {
    await assertFails(setDoc(doc(guest('g1'), 'users/g1'), newProfile()));
  });

  it('refuses an empty or over-long display name', async () => {
    const db = player('alex');
    await assertFails(setDoc(doc(db, 'users/alex'), newProfile({ displayName: '', displayNameLowercase: '' })));
    const long = 'x'.repeat(41);
    await assertFails(setDoc(doc(db, 'users/alex'), newProfile({ displayName: long, displayNameLowercase: long })));
  });

  it('refuses a lowercase name that does not match', async () => {
    await assertFails(setDoc(doc(player('alex'), 'users/alex'), newProfile({ displayNameLowercase: 'someone else' })));
  });

  it('refuses extra fields, a client-chosen createdAt, or starting already onboarded', async () => {
    const db = player('alex');
    await assertFails(setDoc(doc(db, 'users/alex'), { ...newProfile(), isAdmin: true }));
    await assertFails(setDoc(doc(db, 'users/alex'), newProfile({ createdAt: Timestamp.fromMillis(0) })));
    await assertFails(setDoc(doc(db, 'users/alex'), newProfile({ onboardedAt: serverTimestamp() })));
  });
});

describe('onboardedAt', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'users/alex'), newProfile({ createdAt: Timestamp.now() }));
    });
  });

  it('the owner sets it once with the server clock', async () => {
    await assertSucceeds(updateDoc(doc(player('alex'), 'users/alex'), { onboardedAt: serverTimestamp() }));
  });

  it('cannot be set to a made-up time, or by someone else', async () => {
    await assertFails(updateDoc(doc(player('alex'), 'users/alex'), { onboardedAt: Timestamp.fromMillis(0) }));
    await assertFails(updateDoc(doc(player('mina'), 'users/alex'), { onboardedAt: serverTimestamp() }));
  });

  it('createdAt cannot change', async () => {
    await assertFails(updateDoc(doc(player('alex'), 'users/alex'), { createdAt: serverTimestamp() }));
  });
});
