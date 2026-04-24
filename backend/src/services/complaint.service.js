// services/complaint.service.js
// One-Tap Complaint & Escalation System

const { query } = require('../config/postgres');
const { generateText } = require('../config/vertexai');

class ComplaintService {
  
  /**
   * File a new complaint with auto-generated details
   */
  async fileComplaint(firebaseUid, complaintData) {
    const { 
      complaintType, 
      description, 
      epicNumber, 
      constituency, 
      boothNumber,
      priority = 'medium'
    } = complaintData;
    
    // Get user details
    const users = await query(
      'SELECT id, state, booth_name, booth_address, phone FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) {
      throw new Error('User not found');
    }
    
    const user = users[0];
    
    // Auto-generate ECI reference number
    const eciRef = this._generateECIReference(complaintType);
    
    // Create complaint record
    const result = await query(
      `INSERT INTO complaints 
       (user_id, firebase_uid, complaint_type, description, 
        epic_number, constituency, booth_number, eci_reference_number, priority,
        status, created_at, updated_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'submitted', NOW(), NOW())
       RETURNING *`,
      [
        user.id,
        firebaseUid,
        complaintType,
        description,
        epicNumber || null,
        constituency || user.state,
        boothNumber || null,
        eciRef,
        priority
      ]
    );
    
    const complaint = result[0];
    
    // Generate auto-filled grievance form for ECI
    const grievanceForm = await this._generateECIGrievanceForm({
      ...complaint,
      userPhone: user.phone,
      userBooth: user.booth_name,
    });
    
    return {
      success: true,
      complaintId: complaint.id,
      eciReferenceNumber: eciRef,
      status: 'submitted',
      message: 'Complaint filed successfully',
      grievanceForm,
      nextSteps: [
        'ECI will acknowledge within 24 hours',
        'Track status using reference number',
        'You will receive SMS updates',
      ],
      escalationPath: this._getEscalationPath(complaintType),
    };
  }
  
  /**
   * Get user's complaints with status
   */
  async getUserComplaints(firebaseUid) {
    const complaints = await query(
      `SELECT * FROM complaints 
       WHERE firebase_uid = $1 
       ORDER BY created_at DESC`,
      [firebaseUid]
    );
    
    return complaints.map(c => this._formatComplaint(c));
  }
  
  /**
   * Get complaint details
   */
  async getComplaintDetails(complaintId, firebaseUid) {
    const complaints = await query(
      `SELECT * FROM complaints 
       WHERE id = $1 AND firebase_uid = $2`,
      [complaintId, firebaseUid]
    );
    
    if (complaints.length === 0) {
      throw new Error('Complaint not found');
    }
    
    const complaint = this._formatComplaint(complaints[0]);
    
    // Add timeline
    complaint.timeline = this._generateTimeline(complaint);
    
    // Add similar cases resolved
    complaint.similarCasesResolved = await this._getSimilarCasesStats(complaint.complaintType);
    
    return complaint;
  }
  
  /**
   * Update complaint status (for admin/webhook from ECI)
   */
  async updateComplaintStatus(complaintId, status, resolutionNotes = null) {
    const updates = ['status = $1', 'updated_at = NOW()'];
    const params = [status];
    
    if (status === 'resolved' || status === 'closed') {
      updates.push('resolved_at = NOW()');
    }
    
    if (resolutionNotes) {
      updates.push(`resolution_notes = $${params.length + 1}`);
      params.push(resolutionNotes);
    }
    
    params.push(complaintId);
    
    const result = await query(
      `UPDATE complaints SET ${updates.join(', ')} 
       WHERE id = $${params.length} RETURNING *`,
      params
    );
    
    if (result.length === 0) {
      throw new Error('Complaint not found');
    }
    
    return this._formatComplaint(result[0]);
  }
  
  /**
   * Quick complaint templates for one-tap filing
   */
  getQuickComplaintTemplates(userDetails) {
    const templates = [
      {
        id: 'name_missing',
        icon: '🚫',
        title: 'My Name Not on Voter List',
        description: 'Generate complaint for missing name in electoral roll',
        autoFill: {
          complaintType: 'name_missing',
          priority: 'high',
          description: `My name is missing from the voter list despite having a valid EPIC number. I visited polling booth ${userDetails.boothName || 'my assigned booth'} but was denied voting.`,
        },
      },
      {
        id: 'wrong_details',
        icon: '✏️',
        title: 'Wrong Details in Voter ID',
        description: 'Name, address, or other details are incorrect',
        autoFill: {
          complaintType: 'wrong_details',
          priority: 'medium',
          description: `My voter ID contains incorrect details. I need to correct my information in the electoral roll.`,
        },
      },
      {
        id: 'booth_issue',
        icon: '🏛️',
        title: 'Polling Booth Problem',
        description: 'EVM not working, long queues, or accessibility issues',
        autoFill: {
          complaintType: 'booth_issue',
          priority: 'urgent',
          description: `Issue at polling booth: ${userDetails.boothName || 'my assigned booth'}. Please provide specific details.`,
        },
      },
      {
        id: 'other',
        icon: '❓',
        title: 'Other Issue',
        description: 'Any other election-related grievance',
        autoFill: {
          complaintType: 'other',
          priority: 'medium',
          description: '',
        },
      },
    ];
    
    return templates;
  }
  
  /**
   * Get ECI helpline and contact info
   */
  getECIContacts(state = null) {
    const national = {
      helpline: '1950',
      tollFree: '1800-111-950',
      website: 'https://eci.gov.in',
      grievancePortal: 'https://eci.gov.in/grievance',
    };
    
    const stateOffices = {
      'Delhi': { phone: '011-23052012', email: 'ceo.delhi@eci.gov.in' },
      'Maharashtra': { phone: '022-23052013', email: 'ceo.maharashtra@eci.gov.in' },
      'Uttar Pradesh': { phone: '0522-2625301', email: 'ceo.up@eci.gov.in' },
      // Add more as needed
    };
    
    return {
      national,
      state: state ? stateOffices[state] || null : null,
      smsComplaint: 'Send SMS to 1950',
    };
  }
  
  /**
   * Get complaint statistics
   */
  async getComplaintStats(firebaseUid = null) {
    let stats;
    
    if (firebaseUid) {
      // User-specific stats
      stats = await query(
        `SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved,
          COUNT(CASE WHEN status = 'submitted' OR status = 'acknowledged' THEN 1 END) as pending,
          AVG(EXTRACT(EPOCH FROM (COALESCE(resolved_at, NOW()) - created_at))/3600) as avg_resolution_hours
         FROM complaints WHERE firebase_uid = $1`,
        [firebaseUid]
      );
    } else {
      // Global stats
      stats = await query(
        `SELECT 
          COUNT(*) as total,
          COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved,
          complaint_type,
          COUNT(*) as count
         FROM complaints GROUP BY complaint_type`
      );
    }
    
    return stats;
  }
  
  // ==========================================
  // Private Helper Methods
  // ==========================================
  
  _generateECIReference(complaintType) {
    const prefix = {
      name_missing: 'NM',
      wrong_details: 'WD',
      booth_issue: 'BI',
      other: 'OT',
    }[complaintType] || 'GN';
    
    const timestamp = Date.now().toString(36).toUpperCase();
    const random = Math.random().toString(36).substring(2, 5).toUpperCase();
    
    return `ECI-${prefix}-${timestamp}${random}`;
  }
  
  async _generateECIGrievanceForm(complaint) {
    const formData = {
      referenceNumber: complaint.eci_reference_number,
      dateFiled: complaint.created_at,
      complainantName: complaint.firebase_uid, // Would be replaced with actual name
      contactNumber: complaint.userPhone,
      email: '', // Would be from user profile
      
      grievanceType: this._mapToECICategory(complaint.complaint_type),
      description: complaint.description,
      
      pollingStation: complaint.userBooth,
      constituency: complaint.constituency,
      epicNumber: complaint.epic_number,
      
      attachments: [],
      
      declaration: 'I hereby declare that the information provided is true to my knowledge.',
    };
    
    // Generate formatted grievance text
    const prompt = `
Format this voter grievance for official submission to Election Commission of India:

Reference: ${formData.referenceNumber}
Type: ${formData.grievanceType}
Description: ${formData.description}
Constituency: ${formData.constituency}
EPIC: ${formData.epicNumber || 'Not provided'}

Generate a formal, professional grievance letter.
`;
    
    try {
      const formattedText = await generateText(prompt, { temperature: 0.2 });
      formData.formattedLetter = formattedText;
    } catch (error) {
      formData.formattedLetter = formData.description;
    }
    
    return formData;
  }
  
  _mapToECICategory(complaintType) {
    const mapping = {
      name_missing: 'Deletion from Electoral Roll',
      wrong_details: 'Correction in Electoral Roll',
      booth_issue: 'Polling Station Issue',
      other: 'General Grievance',
    };
    return mapping[complaintType] || 'General Grievance';
  }
  
  _getEscalationPath(complaintType) {
    const paths = {
      name_missing: [
        { level: 1, contact: 'BLO (Booth Level Officer)', time: 'Within 24 hours' },
        { level: 2, contact: 'ERO (Electoral Registration Officer)', time: 'If not resolved in 3 days' },
        { level: 3, contact: 'CEO (Chief Electoral Officer)', time: 'If not resolved in 7 days' },
      ],
      wrong_details: [
        { level: 1, contact: 'Online Form 8 submission', time: 'Immediate' },
        { level: 2, contact: 'ERO Office', time: 'If online fails' },
      ],
      booth_issue: [
        { level: 1, contact: 'Presiding Officer at Booth', time: 'Immediate' },
        { level: 2, contact: 'Control Room (1950)', time: 'If urgent' },
        { level: 3, contact: 'Observer/CEO Office', time: 'If unresolved' },
      ],
    };
    
    return paths[complaintType] || [
      { level: 1, contact: 'ECI Helpline 1950', time: 'Immediate' },
    ];
  }
  
  _formatComplaint(c) {
    return {
      id: c.id,
      complaintType: c.complaint_type,
      description: c.description,
      status: c.status,
      priority: c.priority,
      eciReferenceNumber: c.eci_reference_number,
      epicNumber: c.epic_number,
      constituency: c.constituency,
      boothNumber: c.booth_number,
      createdAt: c.created_at,
      updatedAt: c.updated_at,
      resolvedAt: c.resolved_at,
      resolutionNotes: c.resolution_notes,
      escalationPath: this._getEscalationPath(c.complaint_type),
    };
  }
  
  _generateTimeline(complaint) {
    const timeline = [
      {
        date: complaint.createdAt,
        status: 'Complaint Filed',
        description: `Reference: ${complaint.eciReferenceNumber}`,
      },
    ];
    
    if (complaint.status !== 'submitted') {
      timeline.push({
        date: complaint.updatedAt,
        status: 'Acknowledged by ECI',
        description: 'Your complaint has been received and is being processed.',
      });
    }
    
    if (complaint.status === 'in_progress') {
      timeline.push({
        date: new Date(),
        status: 'Under Investigation',
        description: 'Your complaint is being investigated by the appropriate officer.',
      });
    }
    
    if (complaint.status === 'resolved') {
      timeline.push({
        date: complaint.resolvedAt,
        status: 'Resolved',
        description: complaint.resolutionNotes || 'Your complaint has been resolved.',
      });
    }
    
    return timeline;
  }
  
  async _getSimilarCasesStats(complaintType) {
    const result = await query(
      `SELECT 
        COUNT(*) as total,
        COUNT(CASE WHEN status = 'resolved' THEN 1 END) as resolved,
        AVG(EXTRACT(EPOCH FROM (COALESCE(resolved_at, NOW()) - created_at))/3600) as avg_hours
       FROM complaints WHERE complaint_type = $1`,
      [complaintType]
    );
    
    const stats = result[0];
    const resolutionRate = stats.total > 0 
      ? Math.round((stats.resolved / stats.total) * 100) 
      : 0;
    
    return {
      totalCases: parseInt(stats.total) || 0,
      resolutionRate,
      avgResolutionHours: Math.round(stats.avg_hours) || 'N/A',
    };
  }
}

module.exports = new ComplaintService();
