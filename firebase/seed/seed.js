// Seeds the local Firebase emulator with Pittsburgh sample data (D41).
// Run with the emulator up:  npm run seed   (from firebase/)
// It only ever talks to the emulator; it refuses to run against a real project.
// Running it again resets the same documents, with times moved relative to now.
import { initializeApp } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';
import { getFirestore, Timestamp } from 'firebase-admin/firestore';
import { geohashForLocation } from 'geofire-common';

process.env.FIRESTORE_EMULATOR_HOST ??= '127.0.0.1:8080';
process.env.FIREBASE_AUTH_EMULATOR_HOST ??= '127.0.0.1:9099';
if (!/^(127\.0\.0\.1|localhost):/.test(process.env.FIRESTORE_EMULATOR_HOST)) {
  console.error('Refusing to seed: FIRESTORE_EMULATOR_HOST is not a local emulator.');
  process.exit(1);
}

initializeApp({ projectId: 'demo-whosdown' });
const auth = getAuth();
const db = getFirestore();

const PASSWORD = 'whosdown123';
const hour = 60 * 60 * 1000;
const now = new Date();
now.setMinutes(0, 0, 0);
const at = (hoursFromNow) => Timestamp.fromMillis(now.getTime() + hoursFromNow * hour);

// ---------- Players ----------
const players = {
  seed_alex: { displayName: 'Alex Morgan', bio: 'Midfielder who likes quick passing and friendly competitive Matches.', homeArea: 'Oakland / CMU', playStyles: ['social', 'competitive'], sportLevels: { soccer: 'allLevels', tennis: 'casual' } },
  seed_jamie: { displayName: 'Jamie Morales', bio: 'I organize weeknight Matches and keep them welcoming but organized.', homeArea: 'Squirrel Hill', playStyles: ['social'], sportLevels: { soccer: 'intermediate', basketball: 'casual' } },
  seed_mina: { displayName: 'Mina Kim', bio: 'Volleyball and soccer. Always down for a pickup game.', homeArea: 'Shadyside', playStyles: ['competitive'], sportLevels: { soccer: 'intermediate', volleyball: 'competitive' } },
  seed_taylor: { displayName: 'Taylor Ross', bio: 'New to soccer, happy to play defense or learn in goal.', homeArea: 'Oakland / CMU', playStyles: ['learning'], sportLevels: { soccer: 'beginner', ultimate: 'casual' } },
  seed_sam: { displayName: 'Sam Lee', bio: 'Hoops most nights.', homeArea: 'Bloomfield', playStyles: ['competitive'], sportLevels: { basketball: 'competitive', soccer: 'casual' } },
};
const nameOf = (uid) => players[uid].displayName;
const initials = (uid) => nameOf(uid).split(' ').map((w) => w[0]).join('');

// ---------- Venues ----------
const venues = {
  v_cmu_soccer: { name: 'CMU Soccer Field', address: '5000 Forbes Ave, Pittsburgh, PA 15213', lat: 40.4433, lng: -79.9436, isIndoor: false, surface: 'turf', hasLights: true, sports: ['soccer', 'football', 'ultimate'] },
  v_schenley_oval: { name: 'Schenley Oval', address: 'Schenley Dr, Pittsburgh, PA 15213', lat: 40.4364, lng: -79.9454, isIndoor: false, surface: 'grass', hasLights: false, sports: ['soccer', 'ultimate', 'baseball'] },
  v_gesling: { name: 'Gesling Stadium', address: '5000 Forbes Ave, Pittsburgh, PA 15213', lat: 40.4428, lng: -79.9402, isIndoor: false, surface: 'turf', hasLights: true, sports: ['soccer', 'football'] },
  v_cmu_courts: { name: 'CMU Tennis Courts', address: 'Margaret Morrison St, Pittsburgh, PA 15213', lat: 40.4446, lng: -79.9419, isIndoor: false, surface: 'court', hasLights: true, sports: ['tennis', 'pickleball'] },
  v_cmu_gym: { name: 'CMU Wiegand Gym', address: '5000 Forbes Ave, Pittsburgh, PA 15213', lat: 40.4436, lng: -79.9424, isIndoor: true, surface: 'hardwood', hasLights: true, sports: ['basketball', 'volleyball'] },
};

// ---------- Matches ----------
// rsvps: uid -> status ('approved' | 'pending' | 'waitlisted' | 'declined' | 'left'); host is approved.
const matches = {
  m_soccer_tonight: { title: 'Pickup Soccer', sport: 'soccer', venue: 'v_cmu_soccer', start: 3, length: 1.5, host: 'seed_jamie', joinType: 'approvalRequired', skillLevel: 'allLevels', playerLimit: 14, priceCents: 0, notes: 'Bring a light + dark shirt. Need 1 goalkeeper.', fieldReserved: true, reservationWindow: '6:45–8:45 PM',
    rsvps: { seed_jamie: 'approved', seed_alex: 'approved', seed_mina: 'approved', seed_taylor: 'pending' }, notes2: { seed_taylor: 'Happy to play defense or learn in goal.' } },
  m_7v7_full: { title: '7v7 at Schenley', sport: 'soccer', venue: 'v_schenley_oval', start: 5, length: 1.5, host: 'seed_jamie', joinType: 'open', skillLevel: 'intermediate', playerLimit: 4, priceCents: 500, notes: 'Small-sided, fast.',
    rsvps: { seed_jamie: 'approved', seed_alex: 'approved', seed_mina: 'approved', seed_sam: 'approved', seed_taylor: 'waitlisted' } },
  m_beginner_kick: { title: 'Beginner Kickabout', sport: 'soccer', venue: 'v_gesling', start: 26, length: 1, host: 'seed_mina', joinType: 'open', skillLevel: 'beginner', playerLimit: 10, priceCents: 0, notes: 'First-timers welcome.',
    rsvps: { seed_mina: 'approved', seed_taylor: 'approved' } },
  m_tennis_sun: { title: 'Sunday Tennis', sport: 'tennis', venue: 'v_cmu_courts', start: 72, length: 2, host: 'seed_alex', joinType: 'open', skillLevel: 'casual', playerLimit: 4, priceCents: 0, notes: '',
    rsvps: { seed_alex: 'approved' } },
  m_hoops: { title: 'Basketball Run', sport: 'basketball', venue: 'v_cmu_gym', start: 28, length: 2, host: 'seed_sam', joinType: 'approvalRequired', skillLevel: 'competitive', playerLimit: 10, priceCents: 500, notes: 'Full court, games to 11.',
    rsvps: { seed_sam: 'approved', seed_jamie: 'approved', seed_alex: 'declined' }, responses: { seed_alex: 'Keeping tonight to competitive players, sorry!' } },
  m_ultimate: { title: 'Ultimate Frisbee', sport: 'ultimate', venue: 'v_schenley_oval', start: 50, length: 1.5, host: 'seed_taylor', joinType: 'open', skillLevel: 'allLevels', playerLimit: 20, priceCents: 0, notes: 'Bring water.',
    rsvps: { seed_taylor: 'approved', seed_mina: 'approved' } },
  m_volley: { title: 'Indoor Volleyball', sport: 'volleyball', venue: 'v_cmu_gym', start: 98, length: 2, host: 'seed_mina', joinType: 'approvalRequired', skillLevel: 'intermediate', playerLimit: 12, priceCents: 0, notes: '',
    rsvps: { seed_mina: 'approved' } },
  m_pickle: { title: 'Pickleball Doubles', sport: 'pickleball', venue: 'v_cmu_courts', start: 6, length: 1.5, host: 'seed_alex', joinType: 'open', skillLevel: 'allLevels', playerLimit: 4, priceCents: 0, notes: 'Paddles available.',
    rsvps: { seed_alex: 'approved', seed_sam: 'approved' } },
  m_past_7v7: { title: 'Sunday 7v7', sport: 'soccer', venue: 'v_schenley_oval', start: -72, length: 1.5, host: 'seed_jamie', joinType: 'open', skillLevel: 'intermediate', playerLimit: 14, priceCents: 0, notes: '',
    rsvps: { seed_jamie: 'approved', seed_alex: 'approved', seed_mina: 'approved' }, attended: { seed_jamie: true, seed_alex: true, seed_mina: false } },
  // Ended 1.5 hours ago and not checked in yet, so Check-in (1.27) is open for its Host, Alex.
  m_recent_hoops: { title: 'Recent Hoops', sport: 'basketball', venue: 'v_cmu_gym', start: -3, length: 1.5, host: 'seed_alex', joinType: 'open', skillLevel: 'allLevels', playerLimit: 10, priceCents: 0, notes: '',
    rsvps: { seed_alex: 'approved', seed_mina: 'approved', seed_sam: 'approved' } },
  m_cancelled: { title: 'Spikeball on the Cut', sport: 'other', customSportName: 'Spikeball', venue: 'v_cmu_soccer', start: 30, length: 1, host: 'seed_taylor', joinType: 'open', skillLevel: 'allLevels', playerLimit: 8, priceCents: 0, notes: '',
    status: 'cancelled', cancelReason: 'Rain all afternoon. Next week instead!', rsvps: { seed_taylor: 'approved', seed_sam: 'approved' } },
};

async function seedPlayers() {
  for (const [uid, p] of Object.entries(players)) {
    const email = `${uid.replace('seed_', '')}@whosdown.test`;
    try {
      await auth.updateUser(uid, { email, password: PASSWORD, displayName: p.displayName });
    } catch {
      await auth.createUser({ uid, email, password: PASSWORD, displayName: p.displayName });
    }
    await db.doc(`users/${uid}`).set({
      displayName: p.displayName,
      displayNameLowercase: p.displayName.toLowerCase(),
      photoURL: null,
      bio: p.bio,
      homeArea: p.homeArea,
      playStyles: p.playStyles,
      sportLevels: p.sportLevels,
      customSportName: null,
      createdAt: at(-24 * 30),
      onboardedAt: at(-24 * 30),
    });
    await db.doc(`users/${uid}/private/settings`).set({
      email,
      notificationPrefs: { approvals: true, timeOrLocationChanges: true, cancellations: true },
      searchRadiusMiles: 3,
    });
  }
}

// A Player who has an account but hasn't finished onboarding (1.4), for testing that flow.
async function seedNewPlayer() {
  const uid = 'seed_newbie';
  const email = 'newbie@whosdown.test';
  try {
    await auth.updateUser(uid, { email, password: PASSWORD, displayName: 'Nova Newbie' });
  } catch {
    await auth.createUser({ uid, email, password: PASSWORD, displayName: 'Nova Newbie' });
  }
  await db.doc(`users/${uid}`).set({
    displayName: 'Nova Newbie',
    displayNameLowercase: 'nova newbie',
    photoURL: null,
    bio: null,
    homeArea: null,
    playStyles: [],
    sportLevels: {},
    customSportName: null,
    createdAt: at(0),
    onboardedAt: null,
  });
  await db.doc(`users/${uid}/private/settings`).set({
    email,
    notificationPrefs: { approvals: true, timeOrLocationChanges: true, cancellations: true },
    searchRadiusMiles: 3,
  });
}

async function seedVenues() {
  for (const [id, v] of Object.entries(venues)) {
    await db.doc(`venues/${id}`).set({
      name: v.name,
      nameLowercase: v.name.toLowerCase(),
      address: v.address,
      location: { latitude: v.lat, longitude: v.lng },
      geohash: geohashForLocation([v.lat, v.lng]),
      isIndoor: v.isIndoor,
      surface: v.surface,
      hasLights: v.hasLights,
      sports: v.sports,
      createdBy: 'seed_jamie',
    });
  }
}

async function seedMatches() {
  for (const [id, m] of Object.entries(matches)) {
    const v = venues[m.venue];
    const statuses = Object.entries(m.rsvps);
    const count = (s) => statuses.filter(([, st]) => st === s).length;
    const approved = statuses.filter(([, st]) => st === 'approved').map(([uid]) => uid);
    const waitlistIds = statuses.filter(([, st]) => st === 'waitlisted').map(([uid]) => uid);
    const checkedIn = Boolean(m.attended);

    await db.doc(`matches/${id}`).set({
      title: m.title,
      titleLowercase: m.title.toLowerCase(),
      sport: m.sport,
      customSportName: m.customSportName ?? null,
      notes: m.notes,
      hostId: m.host,
      hostName: nameOf(m.host),
      venueId: m.venue,
      venueName: v.name,
      location: { latitude: v.lat, longitude: v.lng },
      geohash: geohashForLocation([v.lat, v.lng]),
      isIndoor: v.isIndoor,
      surface: v.surface,
      hasLights: v.hasLights,
      startTime: at(m.start),
      endTime: at(m.start + m.length),
      skillLevel: m.skillLevel,
      joinType: m.joinType,
      priceCents: m.priceCents,
      playerLimit: m.playerLimit,
      waitlistEnabled: true,
      joinedCount: count('approved'),
      pendingCount: count('pending'),
      waitlistCount: waitlistIds.length,
      waitlistIds,
      attendeePreview: approved.slice(0, 6).map(initials),
      fieldReserved: m.fieldReserved ?? false,
      reservationWindow: m.reservationWindow ?? null,
      facilityNote: null,
      status: m.status ?? 'scheduled',
      cancelReason: m.cancelReason ?? null,
      checkedInAt: checkedIn ? at(m.start + m.length + 1) : null,
      createdAt: at(Math.min(m.start, 0) - 48),
      updatedAt: at(Math.min(m.start, 0) - 48),
    });

    for (const [uid, status] of statuses) {
      await db.doc(`matches/${id}/rsvps/${uid}`).set({
        userId: uid,
        displayName: nameOf(uid),
        skillLevel: players[uid].sportLevels[m.sport] ?? 'allLevels',
        status,
        isHost: uid === m.host,
        noteToHost: m.notes2?.[uid] ?? null,
        hostResponse: m.responses?.[uid] ?? null,
        requestedAt: at(Math.min(m.start, 0) - 24),
        respondedAt: status === 'pending' || status === 'waitlisted' ? null : at(Math.min(m.start, 0) - 23),
        checkedIn: checkedIn && status === 'approved',
        attended: checkedIn && status === 'approved' ? m.attended[uid] : null,
      });
    }

    await db.doc(`conversations/${id}`).set({
      type: 'match',
      title: m.title,
      matchId: id,
      lastMessageText: null,
      lastMessageAt: null,
    });
  }

  const chat = db.collection('conversations/m_soccer_tonight/messages');
  await chat.doc('msg1').set({ senderId: 'seed_mina', senderName: 'Mina Kim', text: 'Can someone bring an extra ball?', sentAt: at(-2) });
  await chat.doc('msg2').set({ senderId: 'seed_jamie', senderName: 'Jamie Morales', text: 'I can bring one 👍', sentAt: at(-1.5) });
  await db.doc('conversations/m_soccer_tonight').update({ lastMessageText: 'I can bring one 👍', lastMessageAt: at(-1.5) });
}

await seedPlayers();
await seedNewPlayer();
await seedVenues();
await seedMatches();
console.log(`Seeded ${Object.keys(players).length} Players, ${Object.keys(venues).length} Venues, ${Object.keys(matches).length} Matches.`);
console.log(`Sign in as alex@whosdown.test (or jamie, mina, taylor, sam) with password "${PASSWORD}".`);
console.log('newbie@whosdown.test has an account but has not finished onboarding.');
