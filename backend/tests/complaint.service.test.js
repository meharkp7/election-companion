/**
 * Unit tests for ComplaintService
 * Tests ECI reference generation, escalation paths, templates, and contacts.
 * Pure-logic methods are tested without DB mocks; DB methods are mocked.
 */

jest.mock('../src/config/postgres', () => ({ query: jest.fn() }));
jest.mock('../src/config/vertexai', () => ({
  generateText: jest.fn().mockResolvedValue('Formal grievance letter text.'),
}));

const { query } = require('../src/config/postgres');
const complaintService = require('../src/services/complaint.service');

beforeEach(() => jest.clearAllMocks());

// ── _generateECIReference ────────────────────────────────────────────────────
describe('ComplaintService._generateECIReference', () => {
  it('starts with ECI- prefix', () => {
    const ref = complaintService._generateECIReference('name_missing');
    expect(ref).toMatch(/^ECI-/);
  });

  it('uses NM prefix for name_missing', () => {
    expect(complaintService._generateECIReference('name_missing')).toMatch(/^ECI-NM-/);
  });

  it('uses WD prefix for wrong_details', () => {
    expect(complaintService._generateECIReference('wrong_details')).toMatch(/^ECI-WD-/);
  });

  it('uses BI prefix for booth_issue', () => {
    expect(complaintService._generateECIReference('booth_issue')).toMatch(/^ECI-BI-/);
  });

  it('uses OT prefix for other', () => {
    expect(complaintService._generateECIReference('other')).toMatch(/^ECI-OT-/);
  });

  it('uses GN prefix for unknown type', () => {
    expect(complaintService._generateECIReference('unknown')).toMatch(/^ECI-GN-/);
  });

  it('generates unique references on successive calls', () => {
    const r1 = complaintService._generateECIReference('other');
    const r2 = complaintService._generateECIReference('other');
    expect(r1).not.toBe(r2);
  });
});

// ── _getEscalationPath ───────────────────────────────────────────────────────
describe('ComplaintService._getEscalationPath', () => {
  it('returns 3-level path for name_missing', () => {
    const path = complaintService._getEscalationPath('name_missing');
    expect(path).toHaveLength(3);
    expect(path[0].level).toBe(1);
    expect(path[2].level).toBe(3);
  });

  it('first level for name_missing is BLO', () => {
    const path = complaintService._getEscalationPath('name_missing');
    expect(path[0].contact).toContain('BLO');
  });

  it('returns 2-level path for wrong_details', () => {
    expect(complaintService._getEscalationPath('wrong_details')).toHaveLength(2);
  });

  it('returns 3-level path for booth_issue', () => {
    expect(complaintService._getEscalationPath('booth_issue')).toHaveLength(3);
  });

  it('falls back to 1950 helpline for unknown type', () => {
    const path = complaintService._getEscalationPath('unknown_type');
    expect(path).toHaveLength(1);
    expect(path[0].contact).toContain('1950');
  });
});

// ── getQuickComplaintTemplates ───────────────────────────────────────────────
describe('ComplaintService.getQuickComplaintTemplates', () => {
  it('returns 4 templates', () => {
    const templates = complaintService.getQuickComplaintTemplates({});
    expect(templates).toHaveLength(4);
  });

  it('each template has id, title, autoFill', () => {
    const templates = complaintService.getQuickComplaintTemplates({});
    for (const t of templates) {
      expect(t).toHaveProperty('id');
      expect(t).toHaveProperty('title');
      expect(t).toHaveProperty('autoFill');
      expect(t.autoFill).toHaveProperty('complaintType');
    }
  });

  it('name_missing template has high priority', () => {
    const templates = complaintService.getQuickComplaintTemplates({});
    const nm = templates.find(t => t.id === 'name_missing');
    expect(nm.autoFill.priority).toBe('high');
  });

  it('booth_issue template has urgent priority', () => {
    const templates = complaintService.getQuickComplaintTemplates({});
    const bi = templates.find(t => t.id === 'booth_issue');
    expect(bi.autoFill.priority).toBe('urgent');
  });

  it('includes booth name in booth_issue description when provided', () => {
    const templates = complaintService.getQuickComplaintTemplates({ boothName: 'Booth 42' });
    const bi = templates.find(t => t.id === 'booth_issue');
    expect(bi.autoFill.description).toContain('Booth 42');
  });
});

// ── getECIContacts ───────────────────────────────────────────────────────────
describe('ComplaintService.getECIContacts', () => {
  it('returns national helpline 1950', () => {
    const contacts = complaintService.getECIContacts();
    expect(contacts.national.helpline).toBe('1950');
  });

  it('returns toll-free number', () => {
    const contacts = complaintService.getECIContacts();
    expect(contacts.national.tollFree).toBeDefined();
  });

  it('returns state office for Delhi', () => {
    const contacts = complaintService.getECIContacts('Delhi');
    expect(contacts.state).toBeDefined();
    expect(contacts.state.phone).toBeDefined();
  });

  it('returns null state for unknown state', () => {
    const contacts = complaintService.getECIContacts('UnknownState');
    expect(contacts.state).toBeNull();
  });

  it('returns null state when no state provided', () => {
    const contacts = complaintService.getECIContacts();
    expect(contacts.state).toBeNull();
  });
});

// ── _mapToECICategory ────────────────────────────────────────────────────────
describe('ComplaintService._mapToECICategory', () => {
  it('maps name_missing to Deletion from Electoral Roll', () => {
    expect(complaintService._mapToECICategory('name_missing'))
      .toBe('Deletion from Electoral Roll');
  });

  it('maps wrong_details to Correction in Electoral Roll', () => {
    expect(complaintService._mapToECICategory('wrong_details'))
      .toBe('Correction in Electoral Roll');
  });

  it('maps booth_issue to Polling Station Issue', () => {
    expect(complaintService._mapToECICategory('booth_issue'))
      .toBe('Polling Station Issue');
  });

  it('falls back to General Grievance for unknown type', () => {
    expect(complaintService._mapToECICategory('unknown'))
      .toBe('General Grievance');
  });
});

// ── fileComplaint ────────────────────────────────────────────────────────────
describe('ComplaintService.fileComplaint', () => {
  it('throws when user not found', async () => {
    query.mockResolvedValue([]); // no user
    await expect(
      complaintService.fileComplaint('uid-x', {
        complaintType: 'name_missing',
        description: 'My name is missing',
      })
    ).rejects.toThrow('User not found');
  });

  it('returns success with ECI reference on valid complaint', async () => {
    // user query
    query.mockResolvedValueOnce([{ id: 1, state: 'Delhi', booth_name: 'Booth 1', phone: '9999999999' }]);
    // insert complaint
    query.mockResolvedValueOnce([{
      id: 'complaint-1',
      eci_reference_number: 'ECI-NM-ABC123',
      complaint_type: 'name_missing',
      description: 'My name is missing',
      created_at: new Date(),
    }]);

    const result = await complaintService.fileComplaint('uid-1', {
      complaintType: 'name_missing',
      description: 'My name is missing from the voter list',
    });

    expect(result.success).toBe(true);
    expect(result.eciReferenceNumber).toMatch(/^ECI-/);
    expect(result.nextSteps).toHaveLength(3);
    expect(result.escalationPath).toBeDefined();
  });
});

// ── getUserComplaints ────────────────────────────────────────────────────────
describe('ComplaintService.getUserComplaints', () => {
  it('returns empty array when no complaints', async () => {
    query.mockResolvedValue([]);
    const result = await complaintService.getUserComplaints('uid-1');
    expect(result).toEqual([]);
  });

  it('formats complaints correctly', async () => {
    query.mockResolvedValue([{
      id: 1,
      complaint_type: 'booth_issue',
      description: 'EVM not working',
      status: 'submitted',
      priority: 'urgent',
      eci_reference_number: 'ECI-BI-XYZ',
      epic_number: null,
      constituency: 'Delhi',
      booth_number: null,
      created_at: new Date(),
      updated_at: new Date(),
      resolved_at: null,
      resolution_notes: null,
    }]);

    const result = await complaintService.getUserComplaints('uid-1');
    expect(result).toHaveLength(1);
    expect(result[0].complaintType).toBe('booth_issue');
    expect(result[0].eciReferenceNumber).toBe('ECI-BI-XYZ');
    expect(result[0].escalationPath).toBeDefined();
  });
});
