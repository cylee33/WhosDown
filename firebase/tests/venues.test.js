// 1.12 Choose location: saving a new Venue (W18).
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { deleteDoc, doc, setDoc, updateDoc } from 'firebase/firestore';

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
const guest = (uid) => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).firestore();

const venue = (overrides = {}) => ({
  name: 'Frick Park Field',
  nameLowercase: 'frick park field',
  address: 'Beechwood Blvd, Pittsburgh, PA',
  location: { latitude: 40.4342, longitude: -79.9058 },
  geohash: 'dppnr3h1q2',
  isIndoor: false,
  surface: 'grass',
  hasLights: false,
  sports: [],
  createdBy: 'alex',
  ...overrides,
});

describe('W18 create Venue', () => {
  it('a Player saves a new Venue as themselves', async () => {
    await assertSucceeds(setDoc(doc(player('alex'), 'venues/v1'), venue()));
  });

  it('a Guest cannot create a Venue', async () => {
    await assertFails(setDoc(doc(guest('g1'), 'venues/v1'), venue({ createdBy: 'g1' })));
  });

  it('cannot create a Venue in someone else\'s name', async () => {
    await assertFails(setDoc(doc(player('mina'), 'venues/v1'), venue()));
  });

  it('refuses bad data', async () => {
    const db = player('alex');
    await assertFails(setDoc(doc(db, 'venues/v1'), venue({ surface: 'lava' })));
    await assertFails(setDoc(doc(db, 'venues/v1'), venue({ nameLowercase: 'something else' })));
    await assertFails(setDoc(doc(db, 'venues/v1'), venue({ location: { latitude: 120, longitude: 0 } })));
    await assertFails(setDoc(doc(db, 'venues/v1'), { ...venue(), verified: true }));
  });
});

describe('editing and deleting', () => {
  beforeEach(async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'venues/v1'), venue());
    });
  });

  it('only the creator can edit, and cannot hand it to someone else', async () => {
    await assertSucceeds(updateDoc(doc(player('alex'), 'venues/v1'), { hasLights: true }));
    await assertFails(updateDoc(doc(player('mina'), 'venues/v1'), { hasLights: true }));
    await assertFails(updateDoc(doc(player('alex'), 'venues/v1'), { createdBy: 'mina' }));
  });

  it('nobody deletes a Venue', async () => {
    await assertFails(deleteDoc(doc(player('alex'), 'venues/v1')));
  });
});
