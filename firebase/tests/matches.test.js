// 1.11 Create Match: W3 publishes the Match, the Host's RSVP, and the Match chat in one batch.
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, beforeEach, describe, it } from 'vitest';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, serverTimestamp, setDoc, Timestamp, writeBatch } from 'firebase/firestore';

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
const hoursFromNow = (h) => Timestamp.fromMillis(Date.now() + h * 3600 * 1000);

const match = (overrides = {}) => ({
  title: 'Pickup Soccer',
  titleLowercase: 'pickup soccer',
  sport: 'soccer',
  customSportName: null,
  notes: 'Bring a light + dark shirt.',
  hostId: 'alex',
  hostName: 'Alex Morgan',
  venueId: 'v_cmu_soccer',
  venueName: 'CMU Soccer Field',
  location: { latitude: 40.4433, longitude: -79.9436 },
  geohash: 'dppnhf6z71',
  isIndoor: false,
  surface: 'turf',
  hasLights: true,
  startTime: hoursFromNow(3),
  endTime: hoursFromNow(4.5),
  skillLevel: 'allLevels',
  joinType: 'approvalRequired',
  priceCents: 0,
  playerLimit: 14,
  waitlistEnabled: true,
  joinedCount: 1,
  pendingCount: 0,
  waitlistCount: 0,
  waitlistIds: [],
  attendeePreview: ['AM'],
  fieldReserved: false,
  reservationWindow: null,
  facilityNote: null,
  status: 'scheduled',
  cancelReason: null,
  checkedInAt: null,
  createdAt: serverTimestamp(),
  updatedAt: serverTimestamp(),
  ...overrides,
});

const hostRSVP = (uid = 'alex') => ({
  userId: uid,
  displayName: 'Alex Morgan',
  skillLevel: 'allLevels',
  status: 'approved',
  isHost: true,
  noteToHost: null,
  hostResponse: null,
  requestedAt: serverTimestamp(),
  respondedAt: serverTimestamp(),
  checkedIn: false,
  attended: null,
});

const conversation = (matchId = 'm1') => ({
  type: 'match', title: 'Pickup Soccer', matchId, lastMessageText: null, lastMessageAt: null,
});

function publish(db, { matchData = match(), rsvpUid = 'alex', rsvpData = hostRSVP(), withRSVP = true, withChat = true } = {}) {
  const batch = writeBatch(db);
  batch.set(doc(db, 'matches/m1'), matchData);
  if (withRSVP) batch.set(doc(db, `matches/m1/rsvps/${rsvpUid}`), rsvpData);
  if (withChat) batch.set(doc(db, 'conversations/m1'), conversation());
  return batch.commit();
}

describe('W3 publish Match', () => {
  it('a Player publishes a Match with their RSVP and the chat in one batch', async () => {
    await assertSucceeds(publish(player('alex')));
  });

  it('a custom "Other" sport needs its name', async () => {
    const db = player('alex');
    await assertSucceeds(publish(db, { matchData: match({ sport: 'other', customSportName: 'Spikeball' }) }));
    await env.clearFirestore();
    await assertFails(publish(db, { matchData: match({ sport: 'other', customSportName: null }) }));
  });

  it('a Guest cannot publish', async () => {
    await assertFails(publish(guest('g1'), { matchData: match({ hostId: 'g1' }), rsvpUid: 'g1', rsvpData: hostRSVP('g1') }));
  });

  it('cannot publish for another Host', async () => {
    await assertFails(publish(player('mina'), { rsvpUid: 'mina', rsvpData: hostRSVP('mina') }));
  });

  it('cannot start with made-up counters', async () => {
    const db = player('alex');
    await assertFails(publish(db, { matchData: match({ joinedCount: 10 }) }));
    await assertFails(publish(db, { matchData: match({ pendingCount: 3 }) }));
    await assertFails(publish(db, { matchData: match({ waitlistIds: ['mina'] }) }));
  });

  it('cannot publish in the past, end before start, or run past 6 hours', async () => {
    const db = player('alex');
    await assertFails(publish(db, { matchData: match({ startTime: hoursFromNow(-1), endTime: hoursFromNow(1) }) }));
    await assertFails(publish(db, { matchData: match({ endTime: hoursFromNow(2) }) }));
    await assertFails(publish(db, { matchData: match({ endTime: hoursFromNow(10) }) }));
  });

  it('refuses a player limit or price out of range, and extra fields', async () => {
    const db = player('alex');
    await assertFails(publish(db, { matchData: match({ playerLimit: 1 }) }));
    await assertFails(publish(db, { matchData: match({ playerLimit: 60 }) }));
    await assertFails(publish(db, { matchData: match({ priceCents: 20000 }) }));
    await assertFails(publish(db, { matchData: { ...match(), featured: true } }));
  });

  it('needs the Host RSVP and the chat in the same batch', async () => {
    const db = player('alex');
    await assertFails(publish(db, { withRSVP: false }));
    await assertFails(publish(db, { withChat: false }));
  });

  it('cannot add a Host RSVP or chat to an existing Match later', async () => {
    await env.withSecurityRulesDisabled(async (ctx) => {
      await setDoc(doc(ctx.firestore(), 'matches/m1'), match({ createdAt: Timestamp.now(), updatedAt: Timestamp.now() }));
    });
    const db = player('alex');
    await assertFails(setDoc(doc(db, 'matches/m1/rsvps/alex'), hostRSVP()));
    await assertFails(setDoc(doc(db, 'conversations/m1'), conversation()));
  });
});
