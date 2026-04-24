// services/pollingDayKit.service.js
// Polling Day Survival Kit - Documents, Checklist, Panic Button

const { query } = require('../config/postgres');
const { generateText } = require('../config/vertexai');

class PollingDayKitService {
  
  // ==========================================
  // VOTER SLIP MANAGEMENT
  // ==========================================
  
  /**
   * Save digital voter slip
   */
  async saveVoterSlip(firebaseUid, slipData) {
    const { 
      epicNumber, voterName, partNumber, serialNumber,
      pollingStationName, pollingStationAddress,
      slipImageUrl, epicFrontImageUrl, epicBackImageUrl, idProofImageUrl
    } = slipData;
    
    // Get user ID
    const users = await query(
      'SELECT id FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) throw new Error('User not found');
    const userId = users[0].id;
    
    // Check if slip already exists
    const existing = await query(
      'SELECT id FROM voter_slips WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    let result;
    if (existing.length > 0) {
      // Update existing
      result = await query(
        `UPDATE voter_slips SET
          epic_number = $2, voter_name = $3, part_number = $4, serial_number = $5,
          polling_station_name = $6, polling_station_address = $7,
          slip_image_url = $8, epic_front_image_url = $9, epic_back_image_url = $10, id_proof_image_url = $11,
          updated_at = NOW()
         WHERE firebase_uid = $1 RETURNING *`,
        [firebaseUid, epicNumber, voterName, partNumber, serialNumber,
         pollingStationName, pollingStationAddress,
         slipImageUrl, epicFrontImageUrl, epicBackImageUrl, idProofImageUrl]
      );
    } else {
      // Create new
      result = await query(
        `INSERT INTO voter_slips 
         (user_id, firebase_uid, epic_number, voter_name, part_number, serial_number,
          polling_station_name, polling_station_address,
          slip_image_url, epic_front_image_url, epic_back_image_url, id_proof_image_url)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12)
         RETURNING *`,
        [userId, firebaseUid, epicNumber, voterName, partNumber, serialNumber,
         pollingStationName, pollingStationAddress,
         slipImageUrl, epicFrontImageUrl, epicBackImageUrl, idProofImageUrl]
      );
    }
    
    return {
      success: true,
      message: 'Voter slip saved',
      slip: this._formatVoterSlip(result[0])
    };
  }
  
  /**
   * Get voter slip with offline cache status
   */
  async getVoterSlip(firebaseUid) {
    const slips = await query(
      'SELECT * FROM voter_slips WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (slips.length === 0) {
      return null;
    }
    
    const slip = slips[0];
    
    // Get user's booth info if slip is incomplete
    const userBooth = await query(
      'SELECT booth_name, booth_address, voter_id_number FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    return {
      ...this._formatVoterSlip(slip),
      userBooth: userBooth[0] || null,
      isOfflineReady: slip.offline_synced,
      cacheTime: slip.cached_at
    };
  }
  
  /**
   * Validate documents for booth visit
   */
  async validateDocuments(firebaseUid) {
    const slip = await this.getVoterSlip(firebaseUid);
    
    if (!slip) {
      return {
        valid: false,
        missing: ['voter_slip'],
        message: 'No voter slip found. Please upload your documents.',
        checklist: this._getDocumentChecklist()
      };
    }
    
    const missing = [];
    const has = [];
    
    if (!slip.epicNumber) missing.push('epic_number');
    else has.push('epic_number');
    
    if (!slip.epicFrontImageUrl && !slip.slipImageUrl) missing.push('voter_id_image');
    else has.push('voter_id_image');
    
    if (!slip.idProofImageUrl) missing.push('photo_id_proof');
    else has.push('photo_id_proof');
    
    const isValid = missing.length === 0;
    
    // Update verification status
    if (isValid) {
      await query(
        `UPDATE voter_slips SET documents_verified = TRUE, verified_at = NOW() WHERE firebase_uid = $1`,
        [firebaseUid]
      );
    }
    
    return {
      valid: isValid,
      missing,
      has,
      message: isValid 
        ? 'All documents ready for booth visit!' 
        : `Missing: ${missing.join(', ')}`,
      checklist: this._getDocumentChecklist(),
      canVoteWith: isValid ? ['EPIC Card', 'Photo ID'] : []
    };
  }
  
  // ==========================================
  // CHECKLIST MANAGEMENT
  // ==========================================
  
  /**
   * Get or create user's polling checklist
   */
  async getChecklist(firebaseUid) {
    const checklists = await query(
      'SELECT * FROM polling_checklists WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (checklists.length > 0) {
      return this._formatChecklist(checklists[0]);
    }
    
    // Create new checklist
    const users = await query(
      'SELECT id FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) throw new Error('User not found');
    
    const result = await query(
      `INSERT INTO polling_checklists (user_id, firebase_uid) VALUES ($1, $2) RETURNING *`,
      [users[0].id, firebaseUid]
    );
    
    return this._formatChecklist(result[0]);
  }
  
  /**
   * Update checklist items
   */
  async updateChecklist(firebaseUid, updates) {
    const checklist = await this.getChecklist(firebaseUid);
    
    const allowedFields = [
      'has_epic', 'has_photo_id', 'has_voter_slip', 'phone_charged',
      'knows_booth_location', 'checked_documents_night_before'
    ];
    
    const setClauses = [];
    const values = [];
    let i = 1;
    
    for (const [key, value] of Object.entries(updates)) {
      const snakeKey = this._camelToSnake(key);
      if (allowedFields.includes(snakeKey)) {
        setClauses.push(`${snakeKey} = $${i}`);
        values.push(value);
        i++;
      }
    }
    
    if (setClauses.length === 0) {
      return checklist;
    }
    
    // Check if all items completed
    const allComplete = [
      updates.hasEpic || checklist.hasEpic,
      updates.hasPhotoId || checklist.hasPhotoId,
      updates.hasVoterSlip || checklist.hasVoterSlip,
      updates.phoneCharged || checklist.phoneCharged,
      updates.knowsBoothLocation || checklist.knowsBoothLocation,
    ].every(Boolean);
    
    if (allComplete && !checklist.checklistCompleted) {
      setClauses.push('checklist_completed = TRUE');
      setClauses.push('completed_at = NOW()');
    }
    
    setClauses.push('updated_at = NOW()');
    values.push(firebaseUid);
    
    const result = await query(
      `UPDATE polling_checklists SET ${setClauses.join(', ')} WHERE firebase_uid = $${i} RETURNING *`,
      values
    );
    
    return this._formatChecklist(result[0]);
  }
  
  /**
   * Get standard checklist items
   */
  _getDocumentChecklist() {
    return [
      { id: 'epic', label: 'EPIC (Voter ID Card)', required: true, icon: '🪪' },
      { id: 'photo_id', label: 'Photo ID (Aadhaar/Driving License/Passport)', required: true, icon: '📷' },
      { id: 'voter_slip', label: 'Voter Slip (digital/physical)', required: false, icon: '📋' },
      { id: 'phone', label: 'Phone charged', required: false, icon: '🔋' },
      { id: 'water', label: 'Water bottle', required: false, icon: '💧' },
      { id: 'emergency_contacts', label: 'Emergency contacts saved', required: false, icon: '📞' },
    ];
  }
  
  // ==========================================
  // PANIC BUTTON
  // ==========================================
  
  /**
   * Trigger panic button at booth
   */
  async triggerPanicButton(firebaseUid, reason, location) {
    const validReasons = [
      'name_missing',
      'booth_not_found',
      'long_queue',
      'evm_issue',
      'staff_rude',
      'accessibility_issue',
      'other'
    ];
    
    if (!validReasons.includes(reason)) {
      throw new Error('Invalid panic reason');
    }
    
    // Get user details
    const users = await query(
      'SELECT id, state, booth_name, phone FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) throw new Error('User not found');
    const user = users[0];
    
    // Record panic event
    await query(
      `UPDATE polling_checklists 
       SET panic_button_used = TRUE, panic_reason = $2, panic_resolved = FALSE, panic_triggered_at = NOW(), updated_at = NOW()
       WHERE firebase_uid = $1`,
      [firebaseUid, reason]
    );
    
    // Get help based on reason
    const helpResponse = await this._getPanicHelp(reason, user, location);
    
    return {
      triggered: true,
      timestamp: new Date().toISOString(),
      referenceId: `PANIC-${Date.now().toString(36).toUpperCase()}`,
      reason,
      help: helpResponse,
      message: 'Help is on the way. Stay calm.',
      actions: [
        { type: 'call', label: 'Call Control Room', number: '1950' },
        { type: 'nearby_help', label: 'Find Help Nearby', action: 'show_map' },
        { type: 'live_chat', label: 'Chat with Support', action: 'open_chat' },
      ]
    };
  }
  
  /**
   * Mark panic as resolved
   */
  async resolvePanic(firebaseUid, resolutionNotes) {
    await query(
      `UPDATE polling_checklists 
       SET panic_resolved = TRUE, updated_at = NOW()
       WHERE firebase_uid = $1`,
      [firebaseUid]
    );
    
    return { resolved: true, notes: resolutionNotes };
  }
  
  /**
   * Get contextual help for panic situation
   */
  async _getPanicHelp(reason, user, location) {
    const helpMap = {
      name_missing: {
        immediate: 'Ask for BLO (Booth Level Officer) at the helpdesk',
        steps: [
          'Go to the helpdesk at your polling station',
          'Show your EPIC card to the BLO',
          'Request to check supplementary list',
          'If still not found, call 1950 immediately'
        ],
        contacts: ['BLO', 'ERO Office', '1950 Helpline']
      },
      booth_not_found: {
        immediate: 'Check voter slip for exact booth address',
        steps: [
          'Verify booth address on your voter slip',
          'Ask locals for directions',
          'Call 1950 for booth location help',
          'Check ECI website for booth locator'
        ],
        contacts: ['1950 Helpline', 'Local Police']
      },
      long_queue: {
        immediate: 'Check if there\'s a separate queue for senior citizens/PWD',
        steps: [
          'Look for priority queue signs',
          'Ask polling officer about facility',
          'Consider coming back during less crowded hours',
          'Check app for live queue status'
        ],
        contacts: ['Presiding Officer']
      },
      evm_issue: {
        immediate: 'Inform the Presiding Officer immediately',
        steps: [
          'Do not panic - EVM issues are common and fixable',
          'Report to Presiding Officer',
          'Wait for technical team if needed',
          'Your right to vote is protected'
        ],
        contacts: ['Presiding Officer', 'Observer', '1950']
      },
      staff_rude: {
        immediate: 'Note the officer\'s name/badge number if possible',
        steps: [
          'Remain calm and polite',
          'Note the incident details',
          'File complaint after voting',
          'Contact Observer if needed'
        ],
        contacts: ['Observer', 'CEO Office', '1950']
      },
      accessibility_issue: {
        immediate: 'Ask for assistance - polling staff must help PWD voters',
        steps: [
          'Request wheelchair/ramp if needed',
          'Ask for volunteer assistance',
          'PWD voters have priority access',
          'Companion allowed for assistance'
        ],
        contacts: ['Presiding Officer', 'BLO']
      },
      other: {
        immediate: 'Contact Control Room at 1950',
        steps: [
          'Describe your issue clearly',
          'Share your booth location',
          'Stay at the location',
          'Help will reach you'
        ],
        contacts: ['1950 Helpline', 'Local Police']
      }
    };
    
    return helpMap[reason] || helpMap.other;
  }
  
  // ==========================================
  // UTILITY METHODS
  // ==========================================
  
  _formatVoterSlip(row) {
    return {
      id: row.id,
      epicNumber: row.epic_number,
      voterName: row.voter_name,
      partNumber: row.part_number,
      serialNumber: row.serial_number,
      pollingStationName: row.polling_station_name,
      pollingStationAddress: row.polling_station_address,
      slipImageUrl: row.slip_image_url,
      epicFrontImageUrl: row.epic_front_image_url,
      epicBackImageUrl: row.epic_back_image_url,
      idProofImageUrl: row.id_proof_image_url,
      documentsVerified: row.documents_verified,
      verificationMethod: row.verification_method,
      verifiedAt: row.verified_at,
      offlineSynced: row.offline_synced,
      cachedAt: row.cached_at
    };
  }
  
  _formatChecklist(row) {
    return {
      id: row.id,
      firebaseUid: row.firebase_uid,
      hasEpic: row.has_epic,
      hasPhotoId: row.has_photo_id,
      hasVoterSlip: row.has_voter_slip,
      phoneCharged: row.phone_charged,
      knowsBoothLocation: row.knows_booth_location,
      checkedDocumentsNightBefore: row.checked_documents_night_before,
      checklistCompleted: row.checklist_completed,
      completedAt: row.completed_at,
      panicButtonUsed: row.panic_button_used,
      panicReason: row.panic_reason,
      panicResolved: row.panic_resolved,
      panicTriggeredAt: row.panic_triggered_at
    };
  }
  
  _camelToSnake(str) {
    return str.replace(/[A-Z]/g, letter => `_${letter.toLowerCase()}`);
  }
}

module.exports = new PollingDayKitService();
