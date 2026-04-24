// services/voterRights.service.js
// Voter Rights, Help Guides, Helplines, Accessibility Info

const { query } = require('../config/postgres');

class VoterRightsService {
  
  // ==========================================
  // VOTER RIGHTS GUIDES
  // ==========================================
  
  /**
   * Get all voter rights guides
   */
  async getAllGuides(category = null, language = 'en') {
    let sql = `SELECT * FROM voter_rights_guides WHERE is_active = TRUE AND language = $1`;
    const params = [language];
    
    if (category) {
      sql += ` AND category = $2`;
      params.push(category);
    }
    
    sql += ` ORDER BY priority DESC, created_at ASC`;
    
    const guides = await query(sql, params);
    
    // Seed data if empty
    if (guides.length === 0) {
      await this._seedGuides();
      return this.getAllGuides(category, language);
    }
    
    return {
      guides: guides.map(g => this._formatGuide(g)),
      count: guides.length
    };
  }
  
  /**
   * Get guide by topic
   */
  async getGuideByTopic(topic, language = 'en') {
    const guides = await query(
      `SELECT * FROM voter_rights_guides 
       WHERE topic = $1 AND language = $2 AND is_active = TRUE`,
      [topic, language]
    );
    
    if (guides.length === 0) {
      return this._getHardcodedGuide(topic);
    }
    
    return this._formatGuide(guides[0]);
  }
  
  /**
   * Search guides
   */
  async searchGuides(queryStr, language = 'en') {
    const guides = await query(
      `SELECT * FROM voter_rights_guides 
       WHERE (title ILIKE $1 OR content ILIKE $1) 
       AND language = $2 AND is_active = TRUE
       ORDER BY priority DESC`,
      [`%${queryStr}%`, language]
    );
    
    return {
      guides: guides.map(g => this._formatGuide(g)),
      query: queryStr
    };
  }
  
  // ==========================================
  // HELPLINE CONTACTS
  // ==========================================
  
  /**
   * Get helpline contacts for user
   */
  async getHelplinesForUser(firebaseUid) {
    const users = await query(
      'SELECT state FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) throw new Error('User not found');
    const state = users[0].state;
    
    return this.getHelplines(state);
  }
  
  /**
   * Get helpline contacts by state
   */
  async getHelplines(state = null) {
    let sql = `SELECT * FROM helpline_contacts WHERE is_active = TRUE`;
    const params = [];
    
    if (state) {
      sql += ` AND (state = $1 OR state IS NULL)`;
      params.push(state);
    }
    
    sql += ` ORDER BY is_primary DESC, priority DESC`;
    
    const contacts = await query(sql, params);
    
    if (contacts.length === 0) {
      return this._getHardcodedHelplines(state);
    }
    
    return {
      national: contacts.filter(c => !c.state),
      state: contacts.filter(c => c.state === state),
      all: contacts.map(c => this._formatContact(c))
    };
  }
  
  /**
   * Get emergency contacts (polling day)
   */
  async getEmergencyContacts(state = null) {
    const helplines = await this.getHelplines(state);
    
    return {
      priority: [
        { name: 'ECI Control Room', number: '1950', available: '24/7', type: 'helpline' },
        { name: 'Toll Free', number: '1800-111-950', available: '24/7', type: 'helpline' },
      ],
      ...helplines,
      quickActions: [
        { label: 'SMS Complaint', instruction: 'Send SMS to 1950' },
        { label: 'Online Portal', url: 'https://eci.gov.in/grievance' },
      ]
    };
  }
  
  // ==========================================
  // ACCESSIBILITY INFO
  // ==========================================
  
  /**
   * Get accessibility information for PWD voters
   */
  async getAccessibilityInfo() {
    const guides = await this.getAllGuides('accessibility');
    
    return {
      title: 'Accessibility for Persons with Disabilities',
      rights: [
        'Free transport to polling station (where available)',
        'Wheelchair access at polling stations',
        'Priority voting (no waiting in queue)',
        'Companion assistance allowed',
        'Braille ballot papers (where available)',
        'Sign language interpreters at select booths',
      ],
      facilities: [
        { name: 'Ramps', available: 'At all booths', icon: '🦽' },
        { name: 'Wheelchairs', available: 'On request', icon: '♿' },
        { name: 'Assistance', available: 'Volunteers available', icon: '🤝' },
        { name: 'Priority Queue', available: 'PWD/Senior Citizens', icon: '⏩' },
      ],
      guides: guides.guides,
      howToRequest: [
        'Contact your BLO (Booth Level Officer) before election day',
        'Call 1950 and request PWD facilities',
        'Visit ECI portal and register as PWD voter',
        'Reach polling station - help desk will assist you',
      ],
      emergencyContact: {
        name: 'PWD Voter Helpline',
        number: '1950',
        note: 'Mention you need accessibility support'
      }
    };
  }
  
  // ==========================================
  // VOTER RIGHTS KNOWLEDGE BASE
  // ==========================================
  
  /**
   * Get comprehensive voter rights info
   */
  async getVoterRights() {
    return {
      title: 'Your Rights as a Voter',
      fundamentalRights: [
        {
          right: 'Right to Vote',
          description: 'Every citizen 18+ has the right to vote (Article 326)',
          exceptions: 'None for eligible citizens'
        },
        {
          right: 'Right to Secret Ballot',
          description: 'Your vote is confidential and cannot be revealed',
          protection: 'VVPAT ensures vote verification without disclosure'
        },
        {
          right: 'Right to Free & Fair Election',
          description: 'ECI ensures level playing field for all',
          complaint: 'File complaint if you witness unfair practices'
        },
        {
          right: 'Right to Information',
          description: 'Know your candidates, their assets, criminal records',
          source: 'Affidavits on ECI website'
        }
      ],
      atPollingStation: [
        'Entry to polling station with valid ID',
        'Check your name in voter list',
        'Cast your vote without intimidation',
        'Request assistance if needed',
        'Verify your vote on VVPAT for 7 seconds',
        'File complaint if any issue',
      ],
      grievanceRedressal: [
        { level: 'BLO', time: 'Immediate at booth', contact: 'Booth helpdesk' },
        { level: 'ERO', time: 'Within 24 hours', contact: 'Electoral Registration Officer' },
        { level: 'CEO', time: 'Within 3 days', contact: 'Chief Electoral Officer' },
        { level: 'ECI', time: 'Immediate for serious issues', contact: '1950' },
      ],
      whatIf: {
        name_missing: {
          scenario: 'My name is not in the voter list',
          action: 'Ask for BLO, check supplementary list, call 1950',
          time: 'Immediate resolution expected'
        },
        wrong_details: {
          scenario: 'My details are wrong in the list',
          action: 'File Form 8 for correction (online or with ERO)',
          time: 'Correction before next election'
        },
        evm_problem: {
          scenario: 'EVM is not working',
          action: 'Inform Presiding Officer immediately',
          time: 'Immediate - technical team called'
        },
        denied_vote: {
          scenario: 'I am being denied voting',
          action: 'Demand reason in writing, call 1950, contact Observer',
          time: 'Immediate - this is serious'
        }
      }
    };
  }
  
  /**
   * Get "What to do if..." scenarios
   */
  async getEmergencyScenarios() {
    return {
      scenarios: [
        {
          id: 'name_missing',
          icon: '🚫',
          title: 'Name Missing from List',
          urgency: 'critical',
          immediateAction: 'Ask for BLO at helpdesk',
          steps: [
            'Stay calm and ask for the BLO (Booth Level Officer)',
            'Show your EPIC card and voter slip',
            'Request to check supplementary list',
            'If still not found, demand Form 12 (Denied Voting Certificate)',
            'Call 1950 immediately',
          ],
          contacts: ['BLO', 'Presiding Officer', '1950'],
          rights: 'You have the right to demand a reason in writing'
        },
        {
          id: 'evm_issue',
          icon: '⚡',
          title: 'EVM Not Working',
          urgency: 'medium',
          immediateAction: 'Report to Presiding Officer',
          steps: [
            'Do not panic - this is common',
            'Inform Presiding Officer immediately',
            'Wait for technical team',
            'Your turn will be preserved',
            'Alternative EVM may be arranged',
          ],
          contacts: ['Presiding Officer', 'Technical Team'],
          note: 'Polling time may be extended if EVM failure is widespread'
        },
        {
          id: 'queue_too_long',
          icon: '⏰',
          title: 'Queue is Too Long',
          urgency: 'low',
          immediateAction: 'Check for priority queue',
          steps: [
            'Look for priority queue for senior citizens/PWD',
            'Ask polling officer about facility',
            'Best time: 11 AM - 3 PM (usually less crowded)',
            'Check app for live queue status',
          ],
          contacts: ['Polling Officer'],
          tip: 'PWD, senior citizens (65+), and pregnant women get priority'
        },
        {
          id: 'staff_misbehavior',
          icon: '😠',
          title: 'Staff Misbehavior',
          urgency: 'high',
          immediateAction: 'Note details and report',
          steps: [
            'Note the officer\'s name/badge number',
            'Complete your voting first',
            'Report to Observer at the booth',
            'File formal complaint after voting',
            'Call 1950 if severe',
          ],
          contacts: ['Observer', 'CEO Office', '1950'],
          note: 'You have the right to respectful treatment'
        },
        {
          id: 'intimidation',
          icon: '😰',
          title: 'Intimidation/Pressure',
          urgency: 'critical',
          immediateAction: 'Report to security immediately',
          steps: [
            'Do not give in to pressure',
            'Report to Police/Security at booth',
            'Contact Observer immediately',
            'Call 1950 - this is a criminal offense',
            'Your vote is secret - vote freely',
          ],
          contacts: ['Police', 'Observer', '1950', 'Control Room'],
          warning: 'Voter intimidation is punishable under law'
        },
        {
          id: 'wrong_booth',
          icon: '📍',
          title: 'At Wrong Polling Station',
          urgency: 'medium',
          immediateAction: 'Check correct booth on voter slip',
          steps: [
            'Check your voter slip for exact booth address',
            'Ask for helpdesk at current location',
            'They can guide you to correct booth',
            'Call 1950 for booth location',
            'You have time - polling hours are 7 AM - 6 PM',
          ],
          contacts: ['Helpdesk', '1950'],
          note: 'Keep 2-3 hours buffer for booth change'
        }
      ]
    };
  }
  
  // ==========================================
  // SEED DATA
  // ==========================================
  
  async _seedGuides() {
    const guides = [
      {
        topic: 'missing_name',
        title: 'What to do if your name is missing from voter list',
        content: `If your name is not found in the electoral roll at the polling station:

1. Stay calm and ask for the BLO (Booth Level Officer) at the helpdesk
2. Show your EPIC card and any voter slip you have
3. Request them to check the supplementary list (this contains recent additions)
4. If still not found, ask for the reason in writing
5. Demand Form 12 (Denied Voting Certificate) - this documents that you were denied your right
6. Call 1950 immediately and report the issue
7. You can also approach the Observer at the polling station

Remember: You have the legal right to vote if you have a valid EPIC and are in the correct constituency.`,
        quick_steps: ['Ask for BLO', 'Check supplementary list', 'Call 1950', 'Demand Form 12'],
        category: 'emergency',
        priority: 100
      },
      {
        topic: 'evm_issue',
        title: 'EVM Malfunction - What to do',
        content: `If the Electronic Voting Machine (EVM) is not working:

1. Do not panic - EVM malfunctions are rare but handled promptly
2. Immediately inform the Presiding Officer
3. The technical team will be called
4. Your turn in queue is preserved
5. Alternative EVM may be arranged
6. Polling time may be extended if needed

Remember: Your vote is important and ECI ensures everyone gets to vote.`,
        quick_steps: ['Inform Presiding Officer', 'Wait for technical team', 'Your place is saved'],
        category: 'emergency',
        priority: 90
      },
      {
        topic: 'rights',
        title: 'Know Your Voting Rights',
        content: `As a voter in India, you have these fundamental rights:

1. Right to Vote (Article 326) - Every citizen 18+ can vote
2. Right to Secret Ballot - No one can know who you voted for
3. Right to Free & Fair Election - Level playing field guaranteed
4. Right to Information - Know about candidates before voting

At polling station, you have:
- Right to enter with valid ID
- Right to check your name in voter list
- Right to cast vote without intimidation
- Right to assistance if needed
- Right to verify vote on VVPAT for 7 seconds
- Right to file complaint if any issue`,
        quick_steps: ['Valid ID', 'Check voter list', 'Secret ballot', 'VVPAT verification'],
        category: 'rights',
        priority: 80
      },
      {
        topic: 'accessibility',
        title: 'Accessibility Facilities for PWD Voters',
        content: `Persons with Disabilities have special rights:

Facilities Available:
- Ramps at all polling stations
- Wheelchairs (on request)
- Priority voting (no queue waiting)
- Volunteer assistance
- Companion allowed for help
- Braille ballot papers (select locations)

How to request:
1. Contact BLO before election day
2. Call 1950 and mention PWD requirement
3. Register on ECI portal
4. At booth, go to helpdesk

PWD voters include: Physically disabled, visually impaired, hearing impaired, senior citizens (65+), pregnant women.`,
        quick_steps: ['Contact BLO', 'Request wheelchair', 'Priority queue', 'Volunteer help'],
        category: 'accessibility',
        priority: 85
      }
    ];
    
    for (const guide of guides) {
      await query(
        `INSERT INTO voter_rights_guides 
         (topic, title, content, quick_steps, category, priority, language)
         VALUES ($1, $2, $3, $4, $5, $6, 'en')
         ON CONFLICT DO NOTHING`,
        [guide.topic, guide.title, guide.content, guide.quick_steps, guide.category, guide.priority]
      );
    }
    
    // Seed helpline contacts
    const contacts = [
      { name: 'ECI Control Room', contact_type: 'helpline', phone: '1950', is_primary: true, priority: 100 },
      { name: 'ECI Toll Free', contact_type: 'helpline', phone: '1800-111-950', is_primary: true, priority: 90 },
      { name: 'SMS Complaint', contact_type: 'helpline', phone: '1950', purpose: 'Send SMS complaint', priority: 80 },
    ];
    
    for (const contact of contacts) {
      await query(
        `INSERT INTO helpline_contacts 
         (name, contact_type, phone, purpose, is_primary, priority)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT DO NOTHING`,
        [contact.name, contact.contact_type, contact.phone, contact.purpose, contact.is_primary, contact.priority]
      );
    }
  }
  
  // ==========================================
  // HARD CODED FALLBACK DATA
  // ==========================================
  
  _getHardcodedGuide(topic) {
    const guides = {
      missing_name: {
        topic: 'missing_name',
        title: 'What to do if your name is missing',
        content: 'Ask for BLO, check supplementary list, call 1950',
        quickSteps: ['Find BLO', 'Show EPIC', 'Call 1950']
      },
      evm_issue: {
        topic: 'evm_issue',
        title: 'EVM Not Working',
        content: 'Report to Presiding Officer immediately',
        quickSteps: ['Inform officer', 'Wait for fix']
      }
    };
    
    return guides[topic] || null;
  }
  
  _getHardcodedHelplines(state) {
    const national = [
      { name: 'ECI Control Room', phone: '1950', type: 'helpline', available: '24/7' },
      { name: 'Toll Free', phone: '1800-111-950', type: 'helpline', available: '24/7' },
    ];
    
    const stateHelplines = {
      'Delhi': [
        { name: 'CEO Delhi', phone: '011-23052012', email: 'ceo.delhi@eci.gov.in' }
      ],
      'Maharashtra': [
        { name: 'CEO Maharashtra', phone: '022-23052013', email: 'ceo.maharashtra@eci.gov.in' }
      ]
    };
    
    return {
      national,
      state: state ? (stateHelplines[state] || []) : [],
      all: [...national, ...(state ? (stateHelplines[state] || []) : [])]
    };
  }
  
  // ==========================================
  // FORMATTERS
  // ==========================================
  
  _formatGuide(row) {
    return {
      id: row.id,
      topic: row.topic,
      title: row.title,
      content: row.content,
      quickSteps: row.quick_steps,
      category: row.category,
      priority: row.priority,
      videoUrl: row.video_url,
      infographicUrl: row.infographic_url,
      language: row.language
    };
  }
  
  _formatContact(row) {
    return {
      id: row.id,
      name: row.name,
      type: row.contact_type,
      phone: row.phone,
      email: row.email,
      state: row.state,
      constituency: row.constituency,
      purpose: row.purpose,
      availableHours: row.available_hours,
      isPrimary: row.is_primary
    };
  }
}

module.exports = new VoterRightsService();
