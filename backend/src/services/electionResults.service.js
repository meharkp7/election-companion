// services/electionResults.service.js
// Live Election Results, Historical Analysis, Vote Share

const { query } = require('../config/postgres');

class ElectionResultsService {
  
  // ==========================================
  // LIVE RESULTS
  // ==========================================
  
  /**
   * Get live results for user's constituency
   */
  async getResultsForUser(firebaseUid) {
    const users = await query(
      'SELECT state, booth_name FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) throw new Error('User not found');
    const { state, booth_name: boothName } = users[0];
    
    const constituency = this._extractConstituency(boothName) || state;
    
    return this.getConstituencyResults(state, constituency);
  }
  
  /**
   * Get constituency results
   */
  async getConstituencyResults(state, constituency) {
    const results = await query(
      `SELECT * FROM election_results 
       WHERE state = $1 AND constituency = $2
       ORDER BY last_updated DESC
       LIMIT 1`,
      [state, constituency]
    );
    
    if (results.length === 0) {
      return this._getMockResults(state, constituency);
    }
    
    const result = results[0];
    
    // Get candidate results
    const candidates = await query(
      `SELECT * FROM candidate_results 
       WHERE result_id = $1 
       ORDER BY position ASC, votes_received DESC`,
      [result.id]
    );
    
    return {
      state,
      constituency,
      status: result.status,
      winner: result.winning_candidate ? {
        name: result.winning_candidate,
        party: result.winning_party,
        margin: result.winning_margin,
        marginPercentage: result.winning_margin_percentage
      } : null,
      turnout: {
        registeredVoters: result.registered_voters,
        votesPolled: result.votes_polled,
        percentage: result.turnout_percentage,
        rejectedVotes: result.rejected_votes
      },
      candidates: candidates.map(c => this._formatCandidateResult(c)),
      lastUpdated: result.last_updated,
      historicalComparison: {
        previousWinner: result.previous_winner,
        previousWinnerParty: result.previous_winner_party,
        previousTurnout: result.previous_turnout
      }
    };
  }
  
  /**
   * Get all results for a state
   */
  async getStateResults(state) {
    const results = await query(
      `SELECT DISTINCT ON (constituency) * 
       FROM election_results 
       WHERE state = $1
       ORDER BY constituency, last_updated DESC`,
      [state]
    );
    
    if (results.length === 0) {
      return this._getMockStateResults(state);
    }
    
    return {
      state,
      totalConstituencies: results.length,
      constituencies: results.map(r => ({
        name: r.constituency,
        status: r.status,
        winner: r.winning_candidate ? {
          name: r.winning_candidate,
          party: r.winning_party
        } : null,
        turnout: r.turnout_percentage,
        lastUpdated: r.last_updated
      })),
      summary: {
        completed: results.filter(r => r.status === 'completed').length,
        counting: results.filter(r => r.status === 'counting').length,
        averageTurnout: Math.round(
          results.reduce((sum, r) => sum + (r.turnout_percentage || 0), 0) / results.length * 100
        ) / 100
      }
    };
  }
  
  // ==========================================
  // HISTORICAL RESULTS
  // ==========================================
  
  /**
   * Get historical results for constituency
   */
  async getHistoricalResults(state, constituency) {
    // Get past 3 elections
    const historical = await query(
      `SELECT * FROM election_results 
       WHERE state = $1 AND constituency = $2
       AND election_year < EXTRACT(YEAR FROM CURRENT_DATE)
       ORDER BY election_year DESC
       LIMIT 3`,
      [state, constituency]
    );
    
    if (historical.length === 0) {
      return this._getMockHistoricalResults(state, constituency);
    }
    
    return {
      state,
      constituency,
      elections: historical.map(h => ({
        year: h.election_year,
        winner: h.winning_candidate,
        winnerParty: h.winning_party,
        margin: h.winning_margin_percentage,
        turnout: h.turnout_percentage,
        totalVotes: h.total_votes
      })),
      trends: this._analyzeTrends(historical)
    };
  }
  
  /**
   * Compare with previous election
   */
  async compareWithPrevious(state, constituency) {
    const current = await this.getConstituencyResults(state, constituency);
    const historical = await this.getHistoricalResults(state, constituency);
    
    if (!historical.elections || historical.elections.length === 0) {
      return { comparison: null, message: 'No historical data available' };
    }
    
    const previous = historical.elections[0];
    
    return {
      comparison: {
        turnoutChange: current.turnout.percentage - previous.turnout,
        winnerChange: current.winner?.name !== previous.winner,
        partyChange: current.winner?.party !== previous.winnerParty,
        voteShareChange: null // Would need detailed vote counts
      },
      previousElection: previous,
      trend: historical.trends
    };
  }
  
  // ==========================================
  // PARTY PERFORMANCE
  // ==========================================
  
  /**
   * Get party-wise performance
   */
  async getPartyPerformance(state, year = null) {
    const electionYear = year || new Date().getFullYear();
    
    const results = await query(
      `SELECT winning_party, COUNT(*) as seats_won
       FROM election_results 
       WHERE state = $1 AND EXTRACT(YEAR FROM created_at) = $2
       AND status = 'completed'
       GROUP BY winning_party
       ORDER BY seats_won DESC`,
      [state, electionYear]
    );
    
    if (results.length === 0) {
      return this._getMockPartyPerformance(state);
    }
    
    const totalSeats = results.reduce((sum, r) => sum + parseInt(r.seats_won), 0);
    
    return {
      state,
      year: electionYear,
      totalSeats,
      parties: results.map(r => ({
        name: r.winning_party,
        seats: parseInt(r.seats_won),
        percentage: Math.round((r.seats_won / totalSeats) * 100 * 100) / 100
      }))
    };
  }
  
  // ==========================================
  // LEADERBOARD / WINNING MARGINS
  // ==========================================
  
  /**
   * Get closest contests
   */
  async getClosestContests(state, limit = 10) {
    const results = await query(
      `SELECT * FROM election_results 
       WHERE state = $1 AND status = 'completed'
       ORDER BY winning_margin_percentage ASC
       LIMIT $2`,
      [state, limit]
    );
    
    return {
      state,
      closestContests: results.map(r => ({
        constituency: r.constituency,
        winner: r.winning_candidate,
        winnerParty: r.winning_party,
        margin: r.winning_margin,
        marginPercentage: r.winning_margin_percentage
      }))
    };
  }
  
  /**
   * Get biggest victories
   */
  async getBiggestVictories(state, limit = 10) {
    const results = await query(
      `SELECT * FROM election_results 
       WHERE state = $1 AND status = 'completed'
       ORDER BY winning_margin_percentage DESC
       LIMIT $2`,
      [state, limit]
    );
    
    return {
      state,
      biggestVictories: results.map(r => ({
        constituency: r.constituency,
        winner: r.winning_candidate,
        winnerParty: r.winning_party,
        margin: r.winning_margin,
        marginPercentage: r.winning_margin_percentage
      }))
    };
  }
  
  // ==========================================
  // VOTE SHARE ANALYSIS
  // ==========================================
  
  /**
   * Get detailed vote share for constituency
   */
  async getVoteShare(state, constituency) {
    const result = await this.getConstituencyResults(state, constituency);
    
    if (!result.candidates || result.candidates.length === 0) {
      return this._getMockVoteShare(state, constituency);
    }
    
    const totalVotes = result.candidates.reduce((sum, c) => sum + (c.votesReceived || 0), 0);
    
    return {
      state,
      constituency,
      totalVotes,
      candidates: result.candidates.map(c => ({
        name: c.name,
        party: c.party,
        votes: c.votesReceived,
        voteShare: c.voteSharePercentage,
        position: c.position
      })),
      nota: {
        votes: result.candidates.find(c => c.name === 'NOTA')?.votesReceived || 0,
        percentage: result.candidates.find(c => c.name === 'NOTA')?.voteSharePercentage || 0
      }
    };
  }
  
  // ==========================================
  // ANALYTICS
  // ==========================================
  
  /**
   * Get turnout analysis
   */
  async getTurnoutAnalysis(state) {
    const results = await query(
      `SELECT constituency, turnout_percentage, registered_voters, votes_polled
       FROM election_results 
       WHERE state = $1 AND status = 'completed'`,
      [state]
    );
    
    if (results.length === 0) {
      return this._getMockTurnoutAnalysis(state);
    }
    
    const turnouts = results.map(r => parseFloat(r.turnout_percentage));
    const avgTurnout = turnouts.reduce((a, b) => a + b, 0) / turnouts.length;
    
    return {
      state,
      averageTurnout: Math.round(avgTurnout * 100) / 100,
      highestTurnout: {
        constituency: results.reduce((max, r) => parseFloat(r.turnout_percentage) > parseFloat(max.turnout_percentage) ? r : max).constituency,
        percentage: Math.max(...turnouts)
      },
      lowestTurnout: {
        constituency: results.reduce((min, r) => parseFloat(r.turnout_percentage) < parseFloat(min.turnout_percentage) ? r : min).constituency,
        percentage: Math.min(...turnouts)
      },
      totalVotesCast: results.reduce((sum, r) => sum + (r.votes_polled || 0), 0),
      totalRegistered: results.reduce((sum, r) => sum + (r.registered_voters || 0), 0)
    };
  }
  
  // ==========================================
  // MOCK DATA HELPERS
  // ==========================================
  
  _getMockResults(state, constituency) {
    const now = new Date();
    // Use seconds and minutes to simulate counting progress
    const minutes = now.getMinutes();
    const seconds = now.getSeconds();
    
    // Counting progress: 0% at min 0, 100% at min 59
    const progress = Math.min(100, (minutes / 60) * 100);
    const totalVotes = 985000;
    const votesPolled = Math.floor(totalVotes * (progress / 100));
    
    // Simulate candidate votes shifting slightly every second
    const seed = seconds % 10;
    const baseShareA = 43.1 + (seed * 0.1);
    const baseShareB = 40.4 - (seed * 0.1);
    
    return {
      state,
      constituency: constituency || 'New Delhi',
      status: progress < 100 ? 'counting' : 'completed',
      progress: progress.toFixed(1),
      winner: progress > 90 ? {
        name: 'Rajesh Kumar',
        party: 'Bhartiya Lok Party',
        margin: Math.floor(votesPolled * 0.02),
        marginPercentage: 2.7
      } : null,
      turnout: {
        registeredVoters: 1520000,
        votesPolled: votesPolled,
        percentage: 64.8,
        rejectedVotes: Math.floor(votesPolled * 0.001)
      },
      candidates: [
        { name: 'Rajesh Kumar', party: 'Bhartiya Lok Party', votesReceived: Math.floor(votesPolled * (baseShareA / 100)), voteSharePercentage: baseShareA.toFixed(1), position: 1, status: 'leading' },
        { name: 'Sanjay Singh', party: 'National Congress', votesReceived: Math.floor(votesPolled * (baseShareB / 100)), voteSharePercentage: baseShareB.toFixed(1), position: 2, status: 'trailing' },
        { name: 'Anita Devi', party: 'Socialist Union', votesReceived: Math.floor(votesPolled * 0.114), voteSharePercentage: 11.4, position: 3 },
        { name: 'Vikram Aditya', party: 'Independent', votesReceived: Math.floor(votesPolled * 0.025), voteSharePercentage: 2.5, position: 4 },
        { name: 'NOTA', party: 'None', votesReceived: Math.floor(votesPolled * 0.025), voteSharePercentage: 2.5, position: 5 },
      ],
      lastUpdated: now.toISOString(),
      historicalComparison: {
        previousWinner: 'Sanjay Singh',
        previousWinnerParty: 'National Congress',
        previousTurnout: 61.2
      },
      isSimulated: true
    };
  }
  
  _getMockStateResults(state) {
    return {
      state,
      totalConstituencies: 40,
      constituencies: [
        { name: 'Constituency 1', status: 'completed', winner: { name: 'Candidate A', party: 'Party A' }, turnout: 68.5 },
        { name: 'Constituency 2', status: 'counting', winner: null, turnout: 64.2 },
        { name: 'Constituency 3', status: 'completed', winner: { name: 'Candidate B', party: 'Party B' }, turnout: 71.3 },
      ],
      summary: {
        completed: 25,
        counting: 15,
        averageTurnout: 67.8
      },
      note: 'Demo data'
    };
  }
  
  _getMockHistoricalResults(state, constituency) {
    return {
      state,
      constituency,
      elections: [
        { year: 2019, winner: 'Candidate X', winnerParty: 'Party A', margin: 12.5, turnout: 65.3, totalVotes: 145000 },
        { year: 2014, winner: 'Candidate Y', winnerParty: 'Party B', margin: 8.2, turnout: 62.1, totalVotes: 138000 },
        { year: 2009, winner: 'Candidate Z', winnerParty: 'Party A', margin: 15.8, turnout: 58.7, totalVotes: 125000 },
      ],
      trends: {
        winnerPartyTrend: ['Party A', 'Party B', 'Party A'],
        turnoutTrend: 'increasing',
        competitiveness: 'moderate'
      },
      note: 'Demo data'
    };
  }
  
  _getMockPartyPerformance(state) {
    return {
      state: state || 'National',
      year: 2024,
      totalSeats: 543,
      parties: [
        { name: 'Bhartiya Lok Party', seats: 242, percentage: 44.5 },
        { name: 'National Congress', seats: 99, percentage: 18.2 },
        { name: 'Socialist Union', seats: 37, percentage: 6.8 },
        { name: 'Dravida Front', seats: 22, percentage: 4.1 },
        { name: 'Trinamool Bloc', seats: 29, percentage: 5.3 },
        { name: 'Others', seats: 114, percentage: 21.0 },
      ],
      note: 'Simulated seat share'
    };
  }
  
  _getMockVoteShare(state, constituency) {
    return {
      state,
      constituency,
      totalVotes: 98000,
      candidates: [
        { name: 'Candidate A', party: 'Party A', votes: 45000, voteShare: 45.9, position: 1 },
        { name: 'Candidate B', party: 'Party B', votes: 42000, voteShare: 42.9, position: 2 },
        { name: 'Candidate C', party: 'Party C', votes: 8000, voteShare: 8.2, position: 3 },
        { name: 'NOTA', party: 'None', votes: 3000, voteShare: 3.1, position: 4 },
      ],
      nota: { votes: 3000, percentage: 3.1 },
      note: 'Demo data'
    };
  }
  
  _getMockTurnoutAnalysis(state) {
    return {
      state,
      averageTurnout: 67.8,
      highestTurnout: { constituency: 'Urban Area North', percentage: 78.5 },
      lowestTurnout: { constituency: 'Remote Hills', percentage: 52.3 },
      totalVotesCast: 2800000,
      totalRegistered: 4100000,
      note: 'Demo data'
    };
  }
  
  // ==========================================
  // UTILITIES
  // ==========================================
  
  _formatCandidateResult(row) {
    return {
      id: row.id,
      candidateId: row.candidate_id,
      name: row.candidate_name,
      party: row.party,
      partySymbol: row.party_symbol,
      votesReceived: row.votes_received,
      voteSharePercentage: row.vote_share_percentage,
      position: row.position,
      status: row.status
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
  
  _analyzeTrends(historical) {
    if (historical.length < 2) return { trend: 'insufficient_data' };
    
    const parties = historical.map(h => h.winning_party);
    const uniqueParties = [...new Set(parties)];
    
    return {
      winnerPartyTrend: parties,
      partyChanges: parties.filter((party, i) => i > 0 && party !== parties[i-1]).length,
      dominantParty: uniqueParties.length === 1 ? parties[0] : null,
      competitiveness: uniqueParties.length > 2 ? 'high' : uniqueParties.length > 1 ? 'moderate' : 'low',
      turnoutTrend: historical[0].turnout_percentage > historical[historical.length-1].turnout_percentage ? 'increasing' : 'decreasing'
    };
  }
}

module.exports = new ElectionResultsService();
