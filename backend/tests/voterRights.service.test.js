/**
 * Unit tests for VoterRightsService
 * Tests hardcoded fallback data, formatting, and pure-logic methods.
 */

jest.mock('../src/config/postgres', () => ({ query: jest.fn() }));

const { query } = require('../src/config/postgres');
const voterRightsService = require('../src/services/voterRights.service');

beforeEach(() => jest.clearAllMocks());

// ── _getHardcodedHelplines ───────────────────────────────────────────────────
describe('VoterRightsService._getHardcodedHelplines', () => {
  it('always includes national helpline 1950', () => {
    const result = voterRightsService._getHardcodedHelplines(null);
    const has1950 = result.national.some(h => h.phone === '1950');
    expect(has1950).toBe(true);
  });

  it('includes toll-free number', () => {
    const result = voterRightsService._getHardcodedHelplines(null);
    const hasTollFree = result.national.some(h => h.phone === '1800-111-950');
    expect(hasTollFree).toBe(true);
  });

  it('returns Delhi state helpline for Delhi', () => {
    const result = voterRightsService._getHardcodedHelplines('Delhi');
    expect(result.state.length).toBeGreaterThan(0);
    expect(result.state[0].name).toContain('Delhi');
  });

  it('returns empty state array for unknown state', () => {
    const result = voterRightsService._getHardcodedHelplines('UnknownState');
    expect(result.state).toEqual([]);
  });

  it('all array contains national + state entries', () => {
    const result = voterRightsService._getHardcodedHelplines('Delhi');
    expect(result.all.length).toBeGreaterThan(result.national.length);
  });
});

// ── _getHardcodedGuide ───────────────────────────────────────────────────────
describe('VoterRightsService._getHardcodedGuide', () => {
  it('returns guide for missing_name', () => {
    const guide = voterRightsService._getHardcodedGuide('missing_name');
    expect(guide).not.toBeNull();
    expect(guide.topic).toBe('missing_name');
    expect(guide.quickSteps).toBeInstanceOf(Array);
  });

  it('returns guide for evm_issue', () => {
    const guide = voterRightsService._getHardcodedGuide('evm_issue');
    expect(guide).not.toBeNull();
    expect(guide.topic).toBe('evm_issue');
  });

  it('returns null for unknown topic', () => {
    expect(voterRightsService._getHardcodedGuide('unknown_topic')).toBeNull();
  });
});

// ── getVoterRights ───────────────────────────────────────────────────────────
describe('VoterRightsService.getVoterRights', () => {
  it('returns fundamentalRights array', async () => {
    const result = await voterRightsService.getVoterRights();
    expect(result.fundamentalRights).toBeInstanceOf(Array);
    expect(result.fundamentalRights.length).toBeGreaterThan(0);
  });

  it('includes Right to Vote', async () => {
    const result = await voterRightsService.getVoterRights();
    const hasVoteRight = result.fundamentalRights.some(r => r.right === 'Right to Vote');
    expect(hasVoteRight).toBe(true);
  });

  it('includes Right to Secret Ballot', async () => {
    const result = await voterRightsService.getVoterRights();
    const hasSecretBallot = result.fundamentalRights.some(r => r.right === 'Right to Secret Ballot');
    expect(hasSecretBallot).toBe(true);
  });

  it('returns atPollingStation array', async () => {
    const result = await voterRightsService.getVoterRights();
    expect(result.atPollingStation).toBeInstanceOf(Array);
    expect(result.atPollingStation.length).toBeGreaterThan(0);
  });

  it('returns grievanceRedressal with 4 levels', async () => {
    const result = await voterRightsService.getVoterRights();
    expect(result.grievanceRedressal).toHaveLength(4);
  });

  it('returns whatIf scenarios for key situations', async () => {
    const result = await voterRightsService.getVoterRights();
    expect(result.whatIf).toHaveProperty('name_missing');
    expect(result.whatIf).toHaveProperty('evm_problem');
    expect(result.whatIf).toHaveProperty('denied_vote');
  });
});

// ── getEmergencyScenarios ────────────────────────────────────────────────────
describe('VoterRightsService.getEmergencyScenarios', () => {
  it('returns 6 scenarios', async () => {
    const result = await voterRightsService.getEmergencyScenarios();
    expect(result.scenarios).toHaveLength(6);
  });

  it('each scenario has id, title, urgency, steps, contacts', async () => {
    const result = await voterRightsService.getEmergencyScenarios();
    for (const s of result.scenarios) {
      expect(s).toHaveProperty('id');
      expect(s).toHaveProperty('title');
      expect(s).toHaveProperty('urgency');
      expect(s.steps).toBeInstanceOf(Array);
      expect(s.contacts).toBeInstanceOf(Array);
    }
  });

  it('name_missing scenario has critical urgency', async () => {
    const result = await voterRightsService.getEmergencyScenarios();
    const nm = result.scenarios.find(s => s.id === 'name_missing');
    expect(nm.urgency).toBe('critical');
  });

  it('intimidation scenario has critical urgency', async () => {
    const result = await voterRightsService.getEmergencyScenarios();
    const intim = result.scenarios.find(s => s.id === 'intimidation');
    expect(intim.urgency).toBe('critical');
  });

  it('queue_too_long scenario has low urgency', async () => {
    const result = await voterRightsService.getEmergencyScenarios();
    const queue = result.scenarios.find(s => s.id === 'queue_too_long');
    expect(queue.urgency).toBe('low');
  });
});

// ── getAccessibilityInfo ─────────────────────────────────────────────────────
describe('VoterRightsService.getAccessibilityInfo', () => {
  it('returns rights array with PWD rights', async () => {
    // getAllGuides will call query → return empty → seed → getAllGuides again
    // Mock to return empty guides to exercise fallback
    query.mockResolvedValue([]);

    const result = await voterRightsService.getAccessibilityInfo();
    expect(result.rights).toBeInstanceOf(Array);
    expect(result.rights.length).toBeGreaterThan(0);
  });

  it('returns facilities array', async () => {
    query.mockResolvedValue([]);
    const result = await voterRightsService.getAccessibilityInfo();
    expect(result.facilities).toBeInstanceOf(Array);
    expect(result.facilities.length).toBeGreaterThan(0);
  });

  it('includes emergency contact 1950', async () => {
    query.mockResolvedValue([]);
    const result = await voterRightsService.getAccessibilityInfo();
    expect(result.emergencyContact.number).toBe('1950');
  });
});

// ── getHelplines (with DB mock) ──────────────────────────────────────────────
describe('VoterRightsService.getHelplines', () => {
  it('falls back to hardcoded data when DB returns empty', async () => {
    query.mockResolvedValue([]);
    const result = await voterRightsService.getHelplines('Delhi');
    expect(result.national).toBeInstanceOf(Array);
    expect(result.national.length).toBeGreaterThan(0);
  });

  it('returns formatted contacts from DB when available', async () => {
    query.mockResolvedValue([{
      id: 1,
      name: 'ECI Control Room',
      contact_type: 'helpline',
      phone: '1950',
      email: null,
      state: null,
      constituency: null,
      purpose: 'General helpline',
      available_hours: '24/7',
      is_primary: true,
    }]);

    const result = await voterRightsService.getHelplines(null);
    expect(result.all).toHaveLength(1);
    expect(result.all[0].phone).toBe('1950');
    expect(result.all[0].isPrimary).toBe(true);
  });
});
