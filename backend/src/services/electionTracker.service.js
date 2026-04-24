// services/electionTracker.service.js
// Live Election Tracker - Dates, Calendar, Turnout, Sample Ballot

const { query } = require('../config/postgres');

class ElectionTrackerService {
  
  // ==========================================
  // ELECTION DATES & PHASES
  // ==========================================
  
  /**
   * Get election phases for user's state
   */
  async getElectionPhasesForUser(firebaseUid) {
    // Get user's state
    const users = await query(
      'SELECT state FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) throw new Error('User not found');
    const state = users[0].state;
    
    return this.getElectionPhasesByState(state);
  }
  
  /**
   * Get election phases by state
   */
  async getElectionPhasesByState(state, year = new Date().getFullYear()) {
    const phases = await query(
      `SELECT * FROM election_phases 
       WHERE (state = $1 OR state IS NULL) 
       AND election_year = $2
       ORDER BY polling_date ASC`,
      [state, year]
    );
    
    if (phases.length === 0) {
      // Return mock data for demo
      return this._getMockElectionPhases(state, year);
    }
    
    return {
      state,
      year,
      phases: phases.map(p => this._formatPhase(p)),
      totalPhases: phases.length
    };
  }
  
  /**
   * Get upcoming elections (all states)
   */
  async getUpcomingElections() {
    const phases = await query(
      `SELECT * FROM election_phases 
       WHERE polling_date >= CURRENT_DATE
       AND status IN ('upcoming', 'active')
       ORDER BY polling_date ASC
       LIMIT 10`
    );
    
    if (phases.length === 0) {
      return this._getMockUpcomingElections();
    }
    
    return {
      elections: phases.map(p => this._formatPhase(p)),
      count: phases.length
    };
  }
  
  // ==========================================
  // USER CALENDAR & REMINDERS
  // ==========================================
  
  /**
   * Get user's personalized election calendar
   */
  async getUserCalendar(firebaseUid) {
    const calendar = await query(
      `SELECT uc.*, ep.* 
       FROM user_election_calendar uc
       JOIN election_phases ep ON uc.election_phase_id = ep.id
       WHERE uc.firebase_uid = $1`,
      [firebaseUid]
    );
    
    if (calendar.length === 0) {
      // Auto-create calendar for user's state
      return this._createUserCalendar(firebaseUid);
    }
    
    return {
      calendar: calendar.map(c => ({
        ...this._formatCalendar(c),
        phase: this._formatPhase(c)
      }))
    };
  }
  
  /**
   * Set user reminder preferences
   */
  async setReminderPreferences(firebaseUid, preferences) {
    const { reminderTiming, notificationMethod } = preferences;
    
    const calendar = await query(
      `SELECT id FROM user_election_calendar WHERE firebase_uid = $1`,
      [firebaseUid]
    );
    
    if (calendar.length === 0) {
      await this._createUserCalendar(firebaseUid);
    }
    
    await query(
      `UPDATE user_election_calendar 
       SET reminder_timing = $2, notification_method = $3, updated_at = NOW()
       WHERE firebase_uid = $1`,
      [firebaseUid, reminderTiming, notificationMethod]
    );
    
    return {
      success: true,
      preferences: { reminderTiming, notificationMethod }
    };
  }
  
  /**
   * Mark sample ballot as viewed
   */
  async markSampleBallotViewed(firebaseUid, phaseId) {
    await query(
      `UPDATE user_election_calendar 
       SET sample_ballet_viewed = TRUE, sample_ballot_viewed_at = NOW(), updated_at = NOW()
       WHERE firebase_uid = $1 AND election_phase_id = $2`,
      [firebaseUid, phaseId]
    );
    
    return { success: true, viewedAt: new Date().toISOString() };
  }
  
  /**
   * Create user calendar entries
   */
  async _createUserCalendar(firebaseUid) {
    const users = await query(
      'SELECT id, state FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) throw new Error('User not found');
    const { id: userId, state } = users[0];
    
    // Get phases for user's state
    const phases = await query(
      `SELECT id FROM election_phases 
       WHERE (state = $1 OR state IS NULL) 
       AND polling_date >= CURRENT_DATE
       ORDER BY polling_date ASC`,
      [state]
    );
    
    if (phases.length === 0) {
      return { calendar: [], message: 'No upcoming elections found for your state' };
    }
    
    // Create calendar entries
    const created = [];
    for (const phase of phases) {
      const result = await query(
        `INSERT INTO user_election_calendar (user_id, firebase_uid, election_phase_id)
         VALUES ($1, $2, $3)
         ON CONFLICT (user_id, election_phase_id) DO NOTHING
         RETURNING *`,
        [userId, firebaseUid, phase.id]
      );
      if (result.length > 0) created.push(result[0]);
    }
    
    return { calendar: created, message: 'Calendar created with upcoming elections' };
  }
  
  // ==========================================
  // LIVE TURNOUT DATA
  // ==========================================
  
  /**
   * Get live turnout for user's constituency
   */
  async getLiveTurnoutForUser(firebaseUid) {
    const users = await query(
      'SELECT state, booth_name FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) throw new Error('User not found');
    const { state, booth_name: boothName } = users[0];
    
    // Extract constituency from booth name
    const constituency = this._extractConstituency(boothName) || state;
    
    return this.getLiveTurnout(state, constituency);
  }
  
  /**
   * Get live turnout data
   */
  async getLiveTurnout(state, constituency) {
    const turnout = await query(
      `SELECT * FROM live_turnout_data 
       WHERE state = $1 AND constituency = $2
       AND recorded_at >= CURRENT_DATE
       ORDER BY hour_interval ASC`,
      [state, constituency]
    );
    
    if (turnout.length === 0) {
      return this._getMockTurnout(state, constituency);
    }
    
    const latest = turnout[turnout.length - 1];
    
    return {
      state,
      constituency,
      currentTurnout: latest.cumulative_percentage,
      hourlyData: turnout.map(t => ({
        hour: t.hour_interval,
        turnout: t.cumulative_percentage,
        votesPolled: t.votes_polled
      })),
      comparison: {
        previousElection: latest.previous_election_percentage,
        difference: latest.difference_from_previous
      },
      lastUpdated: latest.recorded_at
    };
  }
  
  /**
   * Get turnout for all constituencies in a state
   */
  async getStateTurnout(state) {
    const turnouts = await query(
      `SELECT DISTINCT ON (constituency) constituency, cumulative_percentage, recorded_at
       FROM live_turnout_data 
       WHERE state = $1
       ORDER BY constituency, recorded_at DESC`,
      [state]
    );
    
    if (turnouts.length === 0) {
      return this._getMockStateTurnout(state);
    }
    
    const avgTurnout = turnouts.reduce((sum, t) => sum + parseFloat(t.cumulative_percentage), 0) / turnouts.length;
    
    return {
      state,
      constituencies: turnouts.map(t => ({
        name: t.constituency,
        turnout: parseFloat(t.cumulative_percentage),
        lastUpdated: t.recorded_at
      })),
      averageTurnout: Math.round(avgTurnout * 100) / 100,
      totalConstituencies: turnouts.length
    };
  }
  
  // ==========================================
  // SAMPLE BALLOT
  // ==========================================
  
  /**
   * Get sample ballot for user's constituency
   */
  async getSampleBallot(firebaseUid) {
    const users = await query(
      'SELECT state, booth_name FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) throw new Error('User not found');
    const { state, booth_name: boothName } = users[0];
    
    const constituency = this._extractConstituency(boothName) || state;
    
    // Get candidates for this constituency
    const candidates = await query(
      `SELECT * FROM candidates WHERE state = $1 AND constituency = $2 ORDER BY party`,
      [state, constituency]
    );
    
    const candidateList = candidates.length > 0 
      ? candidates.map(c => ({
          name: c.name,
          party: c.party,
          partySymbol: c.party_symbol || '🏛️'
        }))
      : this._getMockCandidatesForBallot();
    
    return {
      state,
      constituency,
      electionType: 'Lok Sabha General Election 2024',
      date: 'Sample Layout',
      candidates: candidateList,
      instructions: [
        'Check your name and details on the voter register',
        'Collect the ink mark on your finger',
        'Enter the polling booth',
        'Press the button next to your chosen candidate\'s symbol',
        'Wait for the beep/beep confirmation',
        'Check the VVPAT slip for 7 seconds',
        'Exit the booth'
      ],
      note: 'This is a sample layout. Actual ballot may vary.'
    };
  }
  
  // ==========================================
  // MOCK DATA HELPERS
  // ==========================================
  
  _getMockElectionPhases(state, year) {
    return {
      state,
      year,
      currentPhase: {
        phaseNumber: 3,
        pollingDate: '2024-05-07',
        status: 'ongoing',
        daysUntil: 0
      },
      phases: [
        {
          id: 'phase-1',
          electionType: 'lok_sabha',
          state: 'Various',
          phaseNumber: 1,
          pollingDate: '2024-04-19',
          countingDate: '2024-06-04',
          status: 'completed',
          totalSeats: 102
        },
        {
          id: 'phase-2', 
          electionType: 'lok_sabha',
          state: 'Various',
          phaseNumber: 2,
          pollingDate: '2024-04-26',
          countingDate: '2024-06-04',
          status: 'completed',
          totalSeats: 88
        },
        {
          id: 'phase-3',
          electionType: 'lok_sabha', 
          state: 'Various',
          phaseNumber: 3,
          pollingDate: '2024-05-07',
          countingDate: '2024-06-04',
          status: 'ongoing',
          totalSeats: 93
        },
        {
          id: 'phase-4',
          electionType: 'lok_sabha', 
          state: 'Various',
          phaseNumber: 4,
          pollingDate: '2024-05-13',
          countingDate: '2024-06-04',
          status: 'upcoming',
          totalSeats: 96
        },
        {
          id: 'phase-5',
          electionType: 'lok_sabha', 
          state: 'Various',
          phaseNumber: 5,
          pollingDate: '2024-05-20',
          countingDate: '2024-06-04',
          status: 'upcoming',
          totalSeats: 49
        }
      ],
      totalPhases: 7,
      note: 'Live Lok Sabha 2024 Schedule'
    };
  }
  
  _getMockUpcomingElections() {
    return {
      elections: [
        { state: 'Andhra Pradesh', pollingDate: '2024-05-13', electionType: 'lok_sabha', phase: 4 },
        { state: 'Bihar', pollingDate: '2024-05-13', electionType: 'lok_sabha', phase: 4 },
        { state: 'Maharashtra', pollingDate: '2024-05-20', electionType: 'lok_sabha', phase: 5 },
        { state: 'Uttar Pradesh', pollingDate: '2024-05-25', electionType: 'lok_sabha', phase: 6 },
      ],
      count: 4,
      note: 'Demo data'
    };
  }
  
  _getMockTurnout(state, constituency) {
    return {
      state,
      constituency,
      currentTurnout: 48.7,
      previousElectionTurnout: 45.2,
      trend: 'up',
      genderBreakdown: {
        male: 49.2,
        female: 48.1,
        others: 42.5
      },
      urbanRural: {
        urban: 44.3,
        rural: 52.8
      },
      hourlyData: [
        { hour: '07:00', turnout: 5.2, votesPolled: 8400 },
        { hour: '09:00', turnout: 16.5, votesPolled: 24900 },
        { hour: '11:00', turnout: 28.3, votesPolled: 42700 },
        { hour: '13:00', turnout: 38.7, votesPolled: 58900 },
        { hour: '15:00', turnout: 48.7, votesPolled: 74200 },
      ],
      lastUpdated: new Date().toISOString(),
      note: 'Live data stream simulated'
    };
  }
  
  _getMockStateTurnout(state) {
    return {
      state,
      constituencies: [
        { name: 'Delhi (East)', turnout: 45.2 },
        { name: 'Delhi (North)', turnout: 48.1 },
        { name: 'Delhi (South)', turnout: 52.3 },
        { name: 'Delhi (West)', turnout: 46.8 },
      ],
      averageTurnout: 48.1,
      totalConstituencies: 4,
      note: 'Demo data'
    };
  }
  
  _getMockCandidatesForBallot() {
    return [
      { name: 'Candidate A', party: 'Party A', partySymbol: '🌸' },
      { name: 'Candidate B', party: 'Party B', partySymbol: '🔥' },
      { name: 'Candidate C', party: 'Party C', partySymbol: '🌟' },
      { name: 'Candidate D', party: 'Party D', partySymbol: '🚜' },
      { name: 'NOTA', party: 'None of the Above', partySymbol: '❌' },
    ];
  }
  
  // ==========================================
  // UTILITY METHODS
  // ==========================================
  
  _formatPhase(row) {
    return {
      id: row.id,
      electionYear: row.election_year,
      electionType: row.election_type,
      state: row.state,
      phaseNumber: row.phase_number,
      pollingDate: row.polling_date,
      countingDate: row.counting_date,
      resultDeclarationDate: row.result_declaration_date,
      constituencies: row.constituencies,
      totalSeats: row.total_seats,
      status: row.status,
      turnoutDataUrl: row.turnout_data_url,
      resultsDataUrl: row.results_data_url
    };
  }
  
  _formatCalendar(row) {
    return {
      id: row.id,
      firebaseUid: row.firebase_uid,
      electionPhaseId: row.election_phase_id,
      boothVisitReminderSent: row.booth_visit_reminder_sent,
      documentsReminderSent: row.documents_reminder_sent,
      transportReminderSent: row.transport_reminder_sent,
      reminderTiming: row.reminder_timing,
      notificationMethod: row.notification_method,
      sampleBallotViewed: row.sample_ballet_viewed,
      sampleBallotViewedAt: row.sample_ballot_viewed_at
    };
  }
  
  _extractConstituency(boothName) {
    if (!boothName) return null;
    const parts = boothName.split(',');
    if (parts.length >= 2) {
      return parts[parts.length - 2].trim();
    }
    return null;
  }
}

module.exports = new ElectionTrackerService();
