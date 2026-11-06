// Shared fixtures for RSVP, approval, leave, and notification rules tests.
import { doc, serverTimestamp, setDoc, Timestamp, writeBatch } from 'firebase/firestore';

export const player = (env, uid) => env.authenticatedContext(uid).firestore();
export const guest = (env, uid) => env.authenticatedContext(uid, { firebase: { sign_in_provider: 'anonymous' } }).firestore();
export const hoursFromNow = (h) => Timestamp.fromMillis(Date.now() + h * 3600 * 1000);

export const match = (overrides = {}) => ({
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
  joinType: 'open',
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

export const hostRSVP = (uid = 'alex') => ({
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

export const memberRSVP = (uid, status, extra = {}) => ({
  userId: uid,
  displayName: 'Taylor',
  skillLevel: 'casual',
  status,
  isHost: false,
  noteToHost: null,
  hostResponse: null,
  requestedAt: serverTimestamp(),
  respondedAt: status === 'pending' || status === 'waitlisted' ? null : serverTimestamp(),
  checkedIn: false,
  attended: null,
  ...extra,
});

const conversation = () => ({
  type: 'match', title: 'Pickup Soccer', matchId: 'm1', lastMessageText: null, lastMessageAt: null,
});

export function publish(db, { matchData = match(), rsvpUid = 'alex', rsvpData = hostRSVP() } = {}) {
  const batch = writeBatch(db);
  batch.set(doc(db, 'matches/m1'), matchData);
  batch.set(doc(db, `matches/m1/rsvps/${rsvpUid}`), rsvpData);
  batch.set(doc(db, 'conversations/m1'), conversation());
  return batch.commit();
}

export async function seed(env, matchData) {
  await env.withSecurityRulesDisabled(async (context) => {
    const db = context.firestore();
    await setDoc(doc(db, 'matches/m1'), matchData);
    await setDoc(doc(db, 'matches/m1/rsvps/alex'), { ...hostRSVP(), requestedAt: Timestamp.now(), respondedAt: Timestamp.now() });
    await setDoc(doc(db, 'conversations/m1'), { ...conversation(), lastMessageText: null, lastMessageAt: null });
  });
}
