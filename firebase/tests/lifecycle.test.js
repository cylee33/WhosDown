// Phase 6: waitlist, edit, cancel, transfer, check-in.
import { readFileSync } from 'node:fs';
import { afterAll, beforeAll, describe, it } from 'vitest';
import { assertFails, assertSucceeds, initializeTestEnvironment } from '@firebase/rules-unit-testing';
import { doc, serverTimestamp, setDoc, Timestamp, updateDoc, writeBatch } from 'firebase/firestore';
import { hoursFromNow, match, memberRSVP, player, seed } from './helpers.js';

let env;

beforeAll(async () => {
  env = await initializeTestEnvironment({
    projectId: 'demo-whosdown',
    firestore: { rules: readFileSync('firestore.rules', 'utf8') },
  });
});

afterAll(async () => { await env.cleanup(); });

async function fullOpen(waitlistIds = []) {
  await env.clearFirestore();
  await seed(env, match({
    joinType: 'open', playerLimit: 14, joinedCount: 14, waitlistEnabled: true,
    waitlistCount: waitlistIds.length, waitlistIds,
    createdAt: hoursFromNow(-1), updatedAt: hoursFromNow(-1),
  }));
}

describe('waitlist', () => {
  it('a Player joins the waitlist of a full Match', async () => {
    await fullOpen();
    const db = player(env, 'taylor');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), {
      waitlistIds: ['taylor'], waitlistCount: 1, updatedAt: serverTimestamp(),
    });
    batch.set(doc(db, 'matches/m1/rsvps/taylor'), {
      ...memberRSVP('taylor', 'waitlisted'),
      requestedAt: serverTimestamp(),
      respondedAt: null,
    });
    await assertSucceeds(batch.commit());
  });

  it('cannot join the waitlist when a spot is free', async () => {
    await env.clearFirestore();
    await seed(env, match({ createdAt: hoursFromNow(-1), updatedAt: hoursFromNow(-1) }));
    const db = player(env, 'taylor');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), {
      waitlistIds: ['taylor'], waitlistCount: 1, updatedAt: serverTimestamp(),
    });
    batch.set(doc(db, 'matches/m1/rsvps/taylor'), {
      ...memberRSVP('taylor', 'waitlisted'),
      requestedAt: serverTimestamp(),
      respondedAt: null,
    });
    await assertFails(batch.commit());
  });

  it('leaving an Open Match promotes the first person in line', async () => {
    await fullOpen(['sam']);
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'matches/m1/rsvps/taylor'), {
        ...memberRSVP('taylor', 'approved'),
        requestedAt: Timestamp.now(),
        respondedAt: Timestamp.now(),
      });
      await setDoc(doc(db, 'matches/m1/rsvps/sam'), {
        ...memberRSVP('sam', 'waitlisted', { displayName: 'Sam' }),
        requestedAt: Timestamp.now(),
        respondedAt: null,
      });
    });
    const db = player(env, 'taylor');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), {
      joinedCount: 14, waitlistCount: 0, waitlistIds: [], updatedAt: serverTimestamp(),
    });
    batch.update(doc(db, 'matches/m1/rsvps/taylor'), { status: 'left' });
    batch.update(doc(db, 'matches/m1/rsvps/sam'), { status: 'approved', respondedAt: serverTimestamp() });
    batch.set(doc(db, 'users/sam/notifications/n1'), {
      type: 'approved', title: "You're in from the waitlist: Pickup Soccer", body: 'A spot opened and you\'re in.',
      matchId: 'm1', fromUserId: 'taylor', changes: null, hostNote: null, isRead: false, createdAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
  });

  it('cannot promote someone who is not first', async () => {
    await fullOpen(['sam', 'jordan']);
    await env.withSecurityRulesDisabled(async (context) => {
      const db = context.firestore();
      await setDoc(doc(db, 'matches/m1/rsvps/taylor'), {
        ...memberRSVP('taylor', 'approved'), requestedAt: Timestamp.now(), respondedAt: Timestamp.now(),
      });
      await setDoc(doc(db, 'matches/m1/rsvps/jordan'), {
        ...memberRSVP('jordan', 'waitlisted', { displayName: 'Jordan' }),
        requestedAt: Timestamp.now(), respondedAt: null,
      });
    });
    const db = player(env, 'taylor');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), {
      joinedCount: 14, waitlistCount: 1, waitlistIds: ['sam'], updatedAt: serverTimestamp(),
    });
    batch.update(doc(db, 'matches/m1/rsvps/taylor'), { status: 'left' });
    batch.update(doc(db, 'matches/m1/rsvps/jordan'), { status: 'approved', respondedAt: serverTimestamp() });
    await assertFails(batch.commit());
  });

  it('the Host lets someone in from the waitlist when a spot is free', async () => {
    await env.clearFirestore();
    await seed(env, match({
      joinType: 'approvalRequired', playerLimit: 2, joinedCount: 1,
      waitlistCount: 1, waitlistIds: ['taylor'],
      createdAt: hoursFromNow(-1), updatedAt: hoursFromNow(-1),
    }));
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'matches/m1/rsvps/taylor'), {
        ...memberRSVP('taylor', 'waitlisted'), requestedAt: Timestamp.now(), respondedAt: null,
      });
    });
    const db = player(env, 'alex');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), {
      joinedCount: 2, waitlistCount: 0, waitlistIds: [], updatedAt: serverTimestamp(),
    });
    batch.update(doc(db, 'matches/m1/rsvps/taylor'), { status: 'approved', respondedAt: serverTimestamp() });
    await assertSucceeds(batch.commit());
    const other = player(env, 'sam');
    await assertFails(updateDoc(doc(other, 'matches/m1/rsvps/taylor'), { status: 'approved', respondedAt: serverTimestamp() }));
  });
});

describe('edit, cancel, transfer, and check-in', () => {
  it('the Host edits the player limit and a Player cannot', async () => {
    await env.clearFirestore();
    await seed(env, match({ createdAt: hoursFromNow(-1), updatedAt: hoursFromNow(-1) }));
    await assertSucceeds(updateDoc(doc(player(env, 'alex'), 'matches/m1'), {
      playerLimit: 16, updatedAt: serverTimestamp(),
    }));
    await assertFails(updateDoc(doc(player(env, 'taylor'), 'matches/m1'), {
      playerLimit: 20, updatedAt: serverTimestamp(),
    }));
  });

  it('the Host cancels with a reason, and a Player cannot', async () => {
    await env.clearFirestore();
    await seed(env, match({ createdAt: hoursFromNow(-1), updatedAt: hoursFromNow(-1) }));
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'matches/m1/rsvps/taylor'), {
        ...memberRSVP('taylor', 'approved'), requestedAt: Timestamp.now(), respondedAt: Timestamp.now(),
      });
    });
    const db = player(env, 'alex');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), {
      status: 'cancelled', cancelReason: 'Rain', updatedAt: serverTimestamp(),
    });
    batch.set(doc(db, 'users/taylor/notifications/n1'), {
      type: 'matchCancelled', title: 'Pickup Soccer was cancelled', body: 'Rain',
      matchId: 'm1', fromUserId: 'alex', changes: null, hostNote: 'Rain', isRead: false, createdAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
    await assertFails(updateDoc(doc(player(env, 'taylor'), 'matches/m1'), {
      status: 'cancelled', cancelReason: 'Nope', updatedAt: serverTimestamp(),
    }));
  });

  it('the Host transfers to an approved Player', async () => {
    await env.clearFirestore();
    await seed(env, match({ joinedCount: 2, createdAt: hoursFromNow(-1), updatedAt: hoursFromNow(-1) }));
    await env.withSecurityRulesDisabled(async (context) => {
      await setDoc(doc(context.firestore(), 'matches/m1/rsvps/taylor'), {
        ...memberRSVP('taylor', 'approved'), requestedAt: Timestamp.now(), respondedAt: Timestamp.now(),
      });
    });
    const db = player(env, 'alex');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), {
      hostId: 'taylor', hostName: 'Taylor', updatedAt: serverTimestamp(),
    });
    batch.update(doc(db, 'matches/m1/rsvps/alex'), { isHost: false });
    batch.update(doc(db, 'matches/m1/rsvps/taylor'), { isHost: true });
    batch.set(doc(db, 'users/taylor/notifications/n1'), {
      type: 'hostTransferred', title: "You're now the Host of Pickup Soccer", body: 'You can edit this Match.',
      matchId: 'm1', fromUserId: 'alex', changes: null, hostNote: null, isRead: false, createdAt: serverTimestamp(),
    });
    await assertSucceeds(batch.commit());
  });

  it('the Host checks in after the start', async () => {
    await env.clearFirestore();
    await seed(env, match({
      startTime: hoursFromNow(-1), endTime: hoursFromNow(1),
      createdAt: hoursFromNow(-2), updatedAt: hoursFromNow(-2),
    }));
    const db = player(env, 'alex');
    const batch = writeBatch(db);
    batch.update(doc(db, 'matches/m1'), { checkedInAt: serverTimestamp(), updatedAt: serverTimestamp() });
    batch.update(doc(db, 'matches/m1/rsvps/alex'), { checkedIn: true, attended: true });
    await assertSucceeds(batch.commit());
  });
});
