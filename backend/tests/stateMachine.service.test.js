/**
 * Unit tests for the state machine service.
 * These are pure-logic tests — no DB calls needed.
 * getNextState and calculateReadinessScore are exported for direct testing.
 */

const {
  getNextState,
  calculateReadinessScore,
  resolveIssueAction,
} = require('../src/services/stateMachine.service');

// ─── calculateReadinessScore ────────────────────────────────────────────────
describe('calculateReadinessScore', () => {
  it('returns 0 for a blank user', () => {
    expect(calculateReadinessScore({})).toBe(0);
  });

  it('adds 25 for age >= 18', () => {
    expect(calculateReadinessScore({ age: 18 })).toBe(25);
    expect(calculateReadinessScore({ age: 17 })).toBe(0);
  });

  it('adds 25 for registered status', () => {
    expect(calculateReadinessScore({ registrationStatus: 'registered' })).toBe(25);
    expect(calculateReadinessScore({ registrationStatus: 'not_registered' })).toBe(0);
  });

  it('adds 25 for verified status', () => {
    expect(calculateReadinessScore({ verificationStatus: 'verified' })).toBe(25);
  });

  it('adds 15 for booth known', () => {
    expect(calculateReadinessScore({ boothKnown: true })).toBe(15);
    expect(calculateReadinessScore({ boothKnown: false })).toBe(0);
  });

  it('adds 10 for READY_TO_VOTE state', () => {
    expect(calculateReadinessScore({ currentState: 'READY_TO_VOTE' })).toBe(10);
  });

  it('adds 10 for VOTING_DAY state', () => {
    expect(calculateReadinessScore({ currentState: 'VOTING_DAY' })).toBe(10);
  });

  it('caps at 100 for a fully ready user', () => {
    const fullUser = {
      age: 25,
      registrationStatus: 'registered',
      verificationStatus: 'verified',
      boothKnown: true,
      currentState: 'READY_TO_VOTE',
    };
    expect(calculateReadinessScore(fullUser)).toBe(100);
  });

  it('does not exceed 100 even with extra fields', () => {
    const overUser = {
      age: 30,
      registrationStatus: 'registered',
      verificationStatus: 'verified',
      boothKnown: true,
      currentState: 'VOTING_DAY',
    };
    expect(calculateReadinessScore(overUser)).toBeLessThanOrEqual(100);
  });
});

// ─── getNextState — global actions ─────────────────────────────────────────
describe('getNextState — global actions', () => {
  it('restart from any state returns START', () => {
    expect(getNextState('READY_TO_VOTE', { action: 'restart' }).state).toBe('START');
    expect(getNextState('COMPLETED', { action: 'restart' }).state).toBe('START');
  });

  it('reset from any state returns START', () => {
    expect(getNextState('VERIFICATION', { action: 'reset' }).state).toBe('START');
  });

  it('back from ELIGIBILITY_CHECK returns START', () => {
    expect(getNextState('ELIGIBILITY_CHECK', { action: 'back' }).state).toBe('START');
  });

  it('back from REGISTRATION returns ELIGIBILITY_CHECK', () => {
    expect(getNextState('REGISTRATION', { action: 'back' }).state).toBe('ELIGIBILITY_CHECK');
  });

  it('back from VERIFICATION returns REGISTRATION', () => {
    expect(getNextState('VERIFICATION', { action: 'back' }).state).toBe('REGISTRATION');
  });

  it('back from READY_TO_VOTE returns VERIFICATION', () => {
    expect(getNextState('READY_TO_VOTE', { action: 'back' }).state).toBe('VERIFICATION');
  });

  it('back from an unknown state falls back to START', () => {
    expect(getNextState('UNKNOWN_STATE', { action: 'back' }).state).toBe('START');
  });
});

// ─── getNextState — START ───────────────────────────────────────────────────
describe('getNextState — START', () => {
  it('stays at START when age is missing', () => {
    const r = getNextState('START', { state: 'Delhi' });
    expect(r.state).toBe('START');
    expect(r.error).toBeDefined();
  });

  it('stays at START when state is missing', () => {
    const r = getNextState('START', { age: 25 });
    expect(r.state).toBe('START');
    expect(r.error).toBeDefined();
  });

  it('transitions to EXIT for age < 18', () => {
    const r = getNextState('START', { age: 17, state: 'Delhi' });
    expect(r.state).toBe('EXIT');
    expect(r.reason).toBe('not_eligible_age');
  });

  it('transitions to ELIGIBILITY_CHECK for age >= 18', () => {
    expect(getNextState('START', { age: 18, state: 'Delhi' }).state).toBe('ELIGIBILITY_CHECK');
    expect(getNextState('START', { age: 100, state: 'Maharashtra' }).state).toBe('ELIGIBILITY_CHECK');
  });
});

// ─── getNextState — ELIGIBILITY_CHECK ──────────────────────────────────────
describe('getNextState — ELIGIBILITY_CHECK', () => {
  it('always transitions to REGISTRATION', () => {
    expect(getNextState('ELIGIBILITY_CHECK', {}).state).toBe('REGISTRATION');
  });
});

// ─── getNextState — REGISTRATION ───────────────────────────────────────────
describe('getNextState — REGISTRATION', () => {
  it('transitions to VERIFICATION when registered', () => {
    expect(getNextState('REGISTRATION', { registrationStatus: 'registered' }).state).toBe('VERIFICATION');
  });

  it('stays at REGISTRATION with form6 action when not_registered', () => {
    const r = getNextState('REGISTRATION', { registrationStatus: 'not_registered' });
    expect(r.state).toBe('REGISTRATION');
    expect(r.action).toBe('show_form6_guide');
  });

  it('transitions to CHECK_STATUS when not_sure', () => {
    expect(getNextState('REGISTRATION', { registrationStatus: 'not_sure' }).state).toBe('CHECK_STATUS');
  });

  it('stays at REGISTRATION with no input', () => {
    expect(getNextState('REGISTRATION', {}).state).toBe('REGISTRATION');
  });
});

// ─── getNextState — CHECK_STATUS ───────────────────────────────────────────
describe('getNextState — CHECK_STATUS', () => {
  it('transitions to VERIFICATION when found=true', () => {
    expect(getNextState('CHECK_STATUS', { found: true }).state).toBe('VERIFICATION');
  });

  it('transitions to REGISTRATION with form6 when found=false', () => {
    const r = getNextState('CHECK_STATUS', { found: false });
    expect(r.state).toBe('REGISTRATION');
    expect(r.action).toBe('show_form6_guide');
  });

  it('stays at CHECK_STATUS with no input', () => {
    expect(getNextState('CHECK_STATUS', {}).state).toBe('CHECK_STATUS');
  });
});

// ─── getNextState — VERIFICATION ───────────────────────────────────────────
describe('getNextState — VERIFICATION', () => {
  it('transitions to READY_TO_VOTE when verified and booth known', () => {
    const r = getNextState('VERIFICATION', { verificationStatus: 'verified', boothKnown: true });
    expect(r.state).toBe('READY_TO_VOTE');
  });

  it('transitions to ISSUE_RESOLVER when issue found', () => {
    expect(getNextState('VERIFICATION', { verificationStatus: 'issue' }).state).toBe('ISSUE_RESOLVER');
  });

  it('stays at VERIFICATION with find_booth action when verified but booth unknown', () => {
    const r = getNextState('VERIFICATION', { verificationStatus: 'verified', boothKnown: false });
    expect(r.state).toBe('VERIFICATION');
    expect(r.action).toBe('find_booth');
  });

  it('stays at VERIFICATION with no input', () => {
    expect(getNextState('VERIFICATION', {}).state).toBe('VERIFICATION');
  });
});

// ─── getNextState — ISSUE_RESOLVER ─────────────────────────────────────────
describe('getNextState — ISSUE_RESOLVER', () => {
  it('transitions back to VERIFICATION when issue resolved', () => {
    expect(getNextState('ISSUE_RESOLVER', { issueResolved: true }).state).toBe('VERIFICATION');
  });

  it('stays at ISSUE_RESOLVER when not resolved', () => {
    const r = getNextState('ISSUE_RESOLVER', { issueType: 'missing_name' });
    expect(r.state).toBe('ISSUE_RESOLVER');
    expect(r.action).toBeDefined();
  });
});

// ─── getNextState — READY_TO_VOTE ──────────────────────────────────────────
describe('getNextState — READY_TO_VOTE', () => {
  it('transitions to VOTING_DAY when electionMode is true', () => {
    expect(getNextState('READY_TO_VOTE', { electionMode: true }).state).toBe('VOTING_DAY');
  });

  it('stays at READY_TO_VOTE without electionMode', () => {
    expect(getNextState('READY_TO_VOTE', {}).state).toBe('READY_TO_VOTE');
  });
});

// ─── getNextState — VOTING_DAY ─────────────────────────────────────────────
describe('getNextState — VOTING_DAY', () => {
  it('transitions to COMPLETED when votingDone is true', () => {
    expect(getNextState('VOTING_DAY', { votingDone: true }).state).toBe('COMPLETED');
  });

  it('stays at VOTING_DAY without votingDone', () => {
    expect(getNextState('VOTING_DAY', {}).state).toBe('VOTING_DAY');
  });
});

// ─── getNextState — COMPLETED / POST_VOTING_EXPLORE ────────────────────────
describe('getNextState — COMPLETED', () => {
  it('transitions to POST_VOTING_EXPLORE', () => {
    expect(getNextState('COMPLETED', {}).state).toBe('POST_VOTING_EXPLORE');
  });
});

describe('getNextState — POST_VOTING_EXPLORE', () => {
  it('stays at POST_VOTING_EXPLORE', () => {
    expect(getNextState('POST_VOTING_EXPLORE', {}).state).toBe('POST_VOTING_EXPLORE');
  });
});

describe('getNextState — unknown state', () => {
  it('falls back to START', () => {
    expect(getNextState('GARBAGE_STATE', {}).state).toBe('START');
  });
});

// ─── resolveIssueAction ─────────────────────────────────────────────────────
describe('resolveIssueAction', () => {
  it('returns Form 6 for missing_name', () => {
    const r = resolveIssueAction('missing_name');
    expect(r.form).toBe('Form 6');
    expect(r.url).toContain('eci.gov.in');
  });

  it('returns Form 8 for wrong_details', () => {
    expect(resolveIssueAction('wrong_details').form).toBe('Form 8');
  });

  it('returns Form 8A for transfer', () => {
    expect(resolveIssueAction('transfer').form).toBe('Form 8A');
  });

  it('returns null form for booth_issue (contact BLO)', () => {
    expect(resolveIssueAction('booth_issue').form).toBeNull();
  });

  it('falls back to Form 6 for unknown issue type', () => {
    expect(resolveIssueAction('unknown_issue').form).toBe('Form 6');
  });
});
