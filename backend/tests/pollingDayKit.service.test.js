/**
 * Unit tests for PollingDayKitService
 * Tests checklist formatting, panic button validation, and document checklist.
 */

jest.mock('../src/config/postgres', () => ({ query: jest.fn() }));
jest.mock('../src/config/vertexai', () => ({
  generateText: jest.fn().mockResolvedValue('AI response'),
}));

const { query } = require('../src/config/postgres');
const pollingDayKitService = require('../src/services/pollingDayKit.service');

beforeEach(() => jest.clearAllMocks());

// ── _camelToSnake ────────────────────────────────────────────────────────────
describe('PollingDayKitService._camelToSnake', () => {
  it('converts camelCase to snake_case', () => {
    expect(pollingDayKitService._camelToSnake('hasEpic')).toBe('has_epic');
    expect(pollingDayKitService._camelToSnake('phoneCharged')).toBe('phone_charged');
    expect(pollingDayKitService._camelToSnake('knowsBoothLocation')).toBe('knows_booth_location');
    expect(pollingDayKitService._camelToSnake('checkedDocumentsNightBefore')).toBe('checked_documents_night_before');
  });

  it('leaves already snake_case strings unchanged', () => {
    expect(pollingDayKitService._camelToSnake('has_epic')).toBe('has_epic');
  });
});

// ── _getDocumentChecklist ────────────────────────────────────────────────────
describe('PollingDayKitService._getDocumentChecklist', () => {
  it('returns 6 checklist items', () => {
    const items = pollingDayKitService._getDocumentChecklist();
    expect(items).toHaveLength(6);
  });

  it('EPIC is marked as required', () => {
    const items = pollingDayKitService._getDocumentChecklist();
    const epic = items.find(i => i.id === 'epic');
    expect(epic.required).toBe(true);
  });

  it('photo_id is marked as required', () => {
    const items = pollingDayKitService._getDocumentChecklist();
    const photoId = items.find(i => i.id === 'photo_id');
    expect(photoId.required).toBe(true);
  });

  it('voter_slip is not required', () => {
    const items = pollingDayKitService._getDocumentChecklist();
    const slip = items.find(i => i.id === 'voter_slip');
    expect(slip.required).toBe(false);
  });

  it('each item has id, label, required, icon', () => {
    const items = pollingDayKitService._getDocumentChecklist();
    for (const item of items) {
      expect(item).toHaveProperty('id');
      expect(item).toHaveProperty('label');
      expect(item).toHaveProperty('required');
      expect(item).toHaveProperty('icon');
    }
  });
});

// ── triggerPanicButton ───────────────────────────────────────────────────────
describe('PollingDayKitService.triggerPanicButton', () => {
  it('throws for invalid panic reason', async () => {
    await expect(
      pollingDayKitService.triggerPanicButton('uid-1', 'invalid_reason', null)
    ).rejects.toThrow('Invalid panic reason');
  });

  it('throws when user not found', async () => {
    query.mockResolvedValue([]); // no user
    await expect(
      pollingDayKitService.triggerPanicButton('uid-x', 'name_missing', null)
    ).rejects.toThrow('User not found');
  });

  it('returns triggered=true with help for valid reason', async () => {
    // user query
    query.mockResolvedValueOnce([{ id: 1, state: 'Delhi', booth_name: 'Booth 1', phone: '9999' }]);
    // update checklist
    query.mockResolvedValueOnce([]);

    const result = await pollingDayKitService.triggerPanicButton(
      'uid-1', 'name_missing', null
    );

    expect(result.triggered).toBe(true);
    expect(result.referenceId).toMatch(/^PANIC-/);
    expect(result.help).toBeDefined();
    expect(result.help.steps).toBeInstanceOf(Array);
    expect(result.actions).toHaveLength(3);
  });

  it('accepts all valid panic reasons', async () => {
    const validReasons = [
      'name_missing', 'booth_not_found', 'long_queue',
      'evm_issue', 'staff_rude', 'accessibility_issue', 'other'
    ];

    for (const reason of validReasons) {
      query.mockResolvedValueOnce([{ id: 1, state: 'Delhi', booth_name: 'B', phone: '9' }]);
      query.mockResolvedValueOnce([]);

      const result = await pollingDayKitService.triggerPanicButton('uid-1', reason, null);
      expect(result.triggered).toBe(true);
    }
  });
});

// ── getVoterSlip ─────────────────────────────────────────────────────────────
describe('PollingDayKitService.getVoterSlip', () => {
  it('returns null when no slip exists', async () => {
    query.mockResolvedValue([]);
    const result = await pollingDayKitService.getVoterSlip('uid-1');
    expect(result).toBeNull();
  });

  it('returns formatted slip when found', async () => {
    query.mockResolvedValueOnce([{
      id: 1,
      epic_number: 'ABC1234567',
      voter_name: 'Rahul Sharma',
      part_number: '42',
      serial_number: '100',
      polling_station_name: 'Govt School Booth 1',
      polling_station_address: '123 Main St',
      slip_image_url: null,
      epic_front_image_url: 'https://example.com/front.jpg',
      epic_back_image_url: null,
      id_proof_image_url: null,
      documents_verified: true,
      verification_method: 'ocr',
      verified_at: new Date(),
      offline_synced: false,
      cached_at: null,
    }]);
    // user booth query
    query.mockResolvedValueOnce([{ booth_name: 'Govt School', booth_address: '123 Main', voter_id_number: 'ABC1234567' }]);

    const result = await pollingDayKitService.getVoterSlip('uid-1');
    expect(result).not.toBeNull();
    expect(result.epicNumber).toBe('ABC1234567');
    expect(result.voterName).toBe('Rahul Sharma');
    expect(result.documentsVerified).toBe(true);
  });
});

// ── validateDocuments ────────────────────────────────────────────────────────
describe('PollingDayKitService.validateDocuments', () => {
  it('returns valid=false with missing voter_slip when no slip', async () => {
    query.mockResolvedValue([]); // no slip
    const result = await pollingDayKitService.validateDocuments('uid-1');
    expect(result.valid).toBe(false);
    expect(result.missing).toContain('voter_slip');
  });

  it('returns valid=true when all required fields present', async () => {
    // getVoterSlip → slip query
    query.mockResolvedValueOnce([{
      id: 1,
      epic_number: 'ABC1234567',
      voter_name: 'Test User',
      part_number: '1',
      serial_number: '1',
      polling_station_name: 'Booth 1',
      polling_station_address: 'Addr',
      slip_image_url: 'https://example.com/slip.jpg',
      epic_front_image_url: 'https://example.com/front.jpg',
      epic_back_image_url: null,
      id_proof_image_url: 'https://example.com/id.jpg',
      documents_verified: false,
      verification_method: null,
      verified_at: null,
      offline_synced: false,
      cached_at: null,
    }]);
    // user booth query inside getVoterSlip
    query.mockResolvedValueOnce([{ booth_name: 'B', booth_address: 'A', voter_id_number: 'X' }]);
    // update verified status
    query.mockResolvedValueOnce([]);

    const result = await pollingDayKitService.validateDocuments('uid-1');
    expect(result.valid).toBe(true);
    expect(result.missing).toHaveLength(0);
  });
});

// ── getChecklist ─────────────────────────────────────────────────────────────
describe('PollingDayKitService.getChecklist', () => {
  it('returns existing checklist when found', async () => {
    query.mockResolvedValue([{
      id: 1,
      firebase_uid: 'uid-1',
      has_epic: true,
      has_photo_id: false,
      has_voter_slip: false,
      phone_charged: true,
      knows_booth_location: false,
      checked_documents_night_before: false,
      checklist_completed: false,
      completed_at: null,
      panic_button_used: false,
      panic_reason: null,
      panic_resolved: false,
      panic_triggered_at: null,
    }]);

    const result = await pollingDayKitService.getChecklist('uid-1');
    expect(result.hasEpic).toBe(true);
    expect(result.hasPhotoId).toBe(false);
    expect(result.phoneCharged).toBe(true);
  });

  it('creates new checklist when none exists', async () => {
    // getChecklist → no existing
    query.mockResolvedValueOnce([]);
    // user query
    query.mockResolvedValueOnce([{ id: 1 }]);
    // insert
    query.mockResolvedValueOnce([{
      id: 2,
      firebase_uid: 'uid-new',
      has_epic: false,
      has_photo_id: false,
      has_voter_slip: false,
      phone_charged: false,
      knows_booth_location: false,
      checked_documents_night_before: false,
      checklist_completed: false,
      completed_at: null,
      panic_button_used: false,
      panic_reason: null,
      panic_resolved: false,
      panic_triggered_at: null,
    }]);

    const result = await pollingDayKitService.getChecklist('uid-new');
    expect(result.hasEpic).toBe(false);
    expect(result.checklistCompleted).toBe(false);
  });
});
