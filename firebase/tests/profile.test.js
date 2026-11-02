// 1.4 Onboarding (and 1.22 edits): profile updates and the avatar in Storage.
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import {
  assertFails,
  assertSucceeds,
  initializeTestEnvironment,
} from '@firebase/rules-unit-testing';
import { doc, setDoc, Timestamp, updateDoc } from 'firebase/firestore';
import { ref, uploadBytes } from 'firebase/storage';

let env;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-whosdown',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
    storage: { rules: readFileSync('storage.rules', 'utf8') },
  });
});

afterAll(async () => {
  await env.cleanup();
});

beforeEach(async () => {
  await env.clearFirestore();
  await env.clearStorage();
  await env.withSecurityRulesDisabled(async (ctx) => {
    await setDoc(doc(ctx.firestore(), 'users/alex'), {
      displayName: 'Alex Morgan',
      displayNameLowercase: 'alex morgan',
      photoURL: null,
      bio: null,
      homeArea: null,
      playStyles: [],
      sportLevels: {},
      customSportName: null,
      createdAt: Timestamp.now(),
      onboardedAt: null,
    });
  });
});

const player = (uid) => env.authenticatedContext(uid);
const guest = (uid) => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } });

const onboardingFields = {
  displayName: 'Alex Morgan',
  displayNameLowercase: 'alex morgan',
  photoURL: 'http://127.0.0.1:9199/avatar.jpg',
  bio: 'Midfielder.',
  homeArea: 'Oakland / CMU',
  playStyles: ['social', 'competitive'],
  sportLevels: { soccer: 'allLevels', other: 'casual' },
  customSportName: 'Spikeball',
};

describe('profile updates', () => {
  it('the owner saves sports, levels, play styles, bio, home area, and photo', async () => {
    await assertSucceeds(updateDoc(doc(player('alex').firestore(), 'users/alex'), onboardingFields));
  });

  it("can't edit someone else's profile", async () => {
    await assertFails(updateDoc(doc(player('mina').firestore(), 'users/alex'), onboardingFields));
  });

  it('refuses an over-long bio, home area, or custom sport name', async () => {
    const db = player('alex').firestore();
    await assertFails(updateDoc(doc(db, 'users/alex'), { bio: 'x'.repeat(301) }));
    await assertFails(updateDoc(doc(db, 'users/alex'), { homeArea: 'x'.repeat(61) }));
    await assertFails(updateDoc(doc(db, 'users/alex'), { customSportName: 'x'.repeat(31) }));
  });

  it('refuses fields that are not on the profile', async () => {
    await assertFails(updateDoc(doc(player('alex').firestore(), 'users/alex'), { isVerified: true }));
  });

  it('the owner saves their notification preferences', async () => {
    const db = player('alex').firestore();
    await assertSucceeds(setDoc(doc(db, 'users/alex/private/settings'), {
      email: 'alex@example.com',
      notificationPrefs: { approvals: true, timeOrLocationChanges: false, cancellations: true },
      searchRadiusMiles: 3,
    }));
  });
});

describe('avatar upload', () => {
  const jpeg = new Uint8Array([0xff, 0xd8, 0xff, 0xd9]);

  it('the owner uploads a JPEG', async () => {
    const storage = player('alex').storage();
    await assertSucceeds(uploadBytes(ref(storage, 'users/alex/avatar.jpg'), jpeg, { contentType: 'image/jpeg' }));
  });

  it("can't upload someone else's avatar, or as a Guest", async () => {
    await assertFails(uploadBytes(ref(player('mina').storage(), 'users/alex/avatar.jpg'), jpeg, { contentType: 'image/jpeg' }));
    await assertFails(uploadBytes(ref(guest('g1').storage(), 'users/g1/avatar.jpg'), jpeg, { contentType: 'image/jpeg' }));
  });

  it('refuses a non-image file', async () => {
    const storage = player('alex').storage();
    await assertFails(uploadBytes(ref(storage, 'users/alex/avatar.jpg'), jpeg, { contentType: 'application/pdf' }));
  });

  it('refuses any other path', async () => {
    const storage = player('alex').storage();
    await assertFails(uploadBytes(ref(storage, 'users/alex/other.jpg'), jpeg, { contentType: 'image/jpeg' }));
  });
});
