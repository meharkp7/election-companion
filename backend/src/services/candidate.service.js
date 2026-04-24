// services/candidate.service.js
// Candidate Intelligence & Comparison System

const { query } = require('../config/postgres');
const { generateText } = require('../config/vertexai');

class CandidateService {
  
  /**
   * Get candidates for user's constituency
   */
  async getCandidatesForUser(firebaseUid) {
    // Get user's constituency
    const users = await query(
      'SELECT state, booth_name FROM users WHERE firebase_uid = $1 LIMIT 1',
      [firebaseUid]
    );
    
    if (users.length === 0) {
      throw new Error('User not found');
    }
    
    const user = users[0];
    
    // Extract constituency from booth_name or use user's state
    const constituency = this._extractConstituency(user.booth_name) || user.state;
    
    return this.getCandidatesByConstituency(user.state, constituency);
  }
  
  /**
   * Get candidates by constituency with AI summaries
   */
  async getCandidatesByConstituency(state, constituency) {
    // Get candidates from database
    const candidates = await query(
      `SELECT * FROM candidates 
       WHERE state = $1 AND constituency = $2
       ORDER BY party, name`,
      [state, constituency]
    );
    
    if (candidates.length === 0) {
      // Return mock candidates for demo
      return this._getMockCandidates(state, constituency);
    }
    
    // Enrich with AI summary if missing
    const enrichedCandidates = await Promise.all(
      candidates.map(async (candidate) => {
        if (!candidate.ai_summary) {
          candidate.ai_summary = await this._generateCandidateSummary(candidate);
        }
        return this._formatCandidate(candidate);
      })
    );
    
    return {
      state,
      constituency,
      candidateCount: enrichedCandidates.length,
      candidates: enrichedCandidates,
    };
  }
  
  /**
   * Compare multiple candidates side-by-side
   */
  async compareCandidates(candidateIds) {
    const candidates = await query(
      `SELECT * FROM candidates WHERE id = ANY($1::uuid[])`,
      [candidateIds]
    );
    
    if (candidates.length < 2) {
      throw new Error('Need at least 2 candidates to compare');
    }
    
    // Generate AI comparison
    const comparison = await this._generateComparison(candidates);
    
    return {
      candidates: candidates.map(c => this._formatCandidate(c)),
      comparison,
      keyDifferences: this._extractKeyDifferences(candidates),
    };
  }
  
  /**
   * Get candidate details with full profile
   */
  async getCandidateDetails(candidateId) {
    const candidates = await query(
      'SELECT * FROM candidates WHERE id = $1 LIMIT 1',
      [candidateId]
    );
    
    if (candidates.length === 0) {
      throw new Error('Candidate not found');
    }
    
    const candidate = candidates[0];
    
    // Generate detailed AI profile
    const detailedProfile = await this._generateDetailedProfile(candidate);
    
    return {
      ...this._formatCandidate(candidate),
      detailedProfile,
      parliamentaryRecord: {
        attendance: candidate.attendance_percentage,
        debates: candidate.debates_participated,
        questions: candidate.questions_asked,
        bills: candidate.private_bills,
      },
      financials: {
        assets: candidate.assets_declared,
        liabilities: candidate.liabilities_declared,
        netWorth: candidate.assets_declared - (candidate.liabilities_declared || 0),
      },
    };
  }
  
  /**
   * Get candidate recommendations based on user priorities
   */
  async getRecommendations(firebaseUid, priorities) {
    const { state, constituency } = await this._getUserLocation(firebaseUid);
    
    const candidates = await this.getCandidatesByConstituency(state, constituency);
    
    // Score candidates based on priorities
    const scored = candidates.candidates.map(candidate => {
      let score = 0;
      
      if (priorities.cleanRecord && candidate.criminal_cases === 0) {
        score += 30;
      }
      
      if (priorities.educated && candidate.education?.includes('Graduate')) {
        score += 20;
      }
      
      if (priorities.performance && candidate.attendance_percentage > 80) {
        score += 25;
      }
      
      if (priorities.accessible && candidate.social_media) {
        score += 15;
      }
      
      return { ...candidate, matchScore: score };
    });
    
    scored.sort((a, b) => b.matchScore - a.matchScore);
    
    return {
      recommendations: scored.slice(0, 3),
      allCandidates: scored,
      yourPriorities: priorities,
    };
  }
  
  /**
   * Search candidates by name (for user to find their candidates)
   */
  async searchCandidates(queryStr, state = null) {
    let sql = `SELECT * FROM candidates WHERE name ILIKE $1`;
    const params = [`%${queryStr}%`];
    
    if (state) {
      sql += ` AND state = $2`;
      params.push(state);
    }
    
    sql += ` ORDER BY name LIMIT 10`;
    
    const candidates = await query(sql, params);
    
    return candidates.map(c => this._formatCandidate(c));
  }
  
  // ==========================================
  // AI Generation Methods
  // ==========================================
  
  async _generateCandidateSummary(candidate) {
    const prompt = `
Generate a 2-3 sentence summary of this political candidate:

Name: ${candidate.name}
Party: ${candidate.party}
Constituency: ${candidate.constituency}
Age: ${candidate.age}
Education: ${candidate.education}
Profession: ${candidate.profession}
Criminal Cases: ${candidate.criminal_cases}
${candidate.serious_charges ? `Serious Charges: ${candidate.serious_charges}` : ''}

Provide an objective summary highlighting their background and any notable concerns.
`;
    
    try {
      return await generateText(prompt, { temperature: 0.3 });
    } catch (error) {
      return `${candidate.name} (${candidate.party}) is a candidate from ${candidate.constituency}.`;
    }
  }
  
  async _generateComparison(candidates) {
    const candidateInfo = candidates.map((c, i) => `
Candidate ${i + 1}: ${c.name} (${c.party})
- Age: ${c.age}, Education: ${c.education}
- Criminal Cases: ${c.criminal_cases}
- Attendance: ${c.attendance_percentage}%
- Assets: ₹${c.assets_declared}
`).join('\n');
    
    const prompt = `
Compare these candidates objectively. Highlight:
1. Key strengths of each
2. Major concerns (if any)
3. Who might be better for development vs who has better track record

${candidateInfo}
`;
    
    try {
      return await generateText(prompt, { temperature: 0.3, maxOutputTokens: 800 });
    } catch (error) {
      return 'Comparison analysis temporarily unavailable.';
    }
  }
  
  async _generateDetailedProfile(candidate) {
    const prompt = `
Provide a detailed political profile for:

Name: ${candidate.name}
Party: ${candidate.party}
Constituency: ${candidate.constituency}, ${candidate.state}
Age: ${candidate.age}
Education: ${candidate.education}
Profession: ${candidate.profession}
Assets: ₹${candidate.assets_declared}
Liabilities: ₹${candidate.liabilities_declared}
Criminal Cases: ${candidate.criminal_cases}
Parliamentary Performance:
- Attendance: ${candidate.attendance_percentage}%
- Debates: ${candidate.debates_participated}
- Questions: ${candidate.questions_asked}
- Private Bills: ${candidate.private_bills}

Include:
1. Background and political journey
2. Performance assessment
3. Pros and cons for voters
4. Verdict: Suitable for vote?
`;
    
    try {
      return await generateText(prompt, { temperature: 0.3, maxOutputTokens: 1000 });
    } catch (error) {
      return 'Detailed profile temporarily unavailable.';
    }
  }
  
  // ==========================================
  // Helper Methods
  // ==========================================
  
  _formatCandidate(candidate) {
    return {
      id: candidate.id,
      name: candidate.name,
      party: candidate.party,
      partySymbol: candidate.party_symbol,
      constituency: candidate.constituency,
      state: candidate.state,
      age: candidate.age,
      education: candidate.education,
      profession: candidate.profession,
      criminalCases: candidate.criminal_cases,
      seriousCharges: candidate.serious_charges,
      assetsDeclared: candidate.assets_declared,
      attendancePercentage: candidate.attendance_percentage,
      debatesParticipated: candidate.debates_participated,
      questionsAsked: candidate.questions_asked,
      aiSummary: candidate.ai_summary,
      keyHighlights: candidate.key_highlights,
      contact: {
        email: candidate.email,
        phone: candidate.phone,
        socialMedia: candidate.social_media,
      },
    };
  }
  
  _extractKeyDifferences(candidates) {
    return {
      experience: candidates.map(c => ({
        name: c.name,
        attendance: c.attendance_percentage,
        debates: c.debates_participated,
      })),
      background: candidates.map(c => ({
        name: c.name,
        education: c.education,
        profession: c.profession,
      })),
      integrity: candidates.map(c => ({
        name: c.name,
        criminalCases: c.criminal_cases,
        seriousCharges: c.serious_charges,
      })),
    };
  }
  
  _extractConstituency(boothName) {
    if (!boothName) return null;
    // Extract constituency from booth name (booth names usually contain constituency)
    const parts = boothName.split(',');
    if (parts.length >= 2) {
      return parts[parts.length - 2].trim();
    }
    return null;
  }
  
  async _getUserLocation(firebaseUid) {
    const users = await query(
      'SELECT state, booth_name FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) {
      throw new Error('User not found');
    }
    
    return {
      state: users[0].state,
      constituency: this._extractConstituency(users[0].booth_name) || users[0].state,
    };
  }
  
  _getMockCandidates(state, constituency) {
    // Mock candidates for demo purposes
    return {
      state,
      constituency,
      candidateCount: 3,
      candidates: [
        {
          id: 'mock-1',
          name: 'Rajesh Kumar',
          party: 'Party A',
          partySymbol: '🌸',
          constituency,
          state,
          age: 45,
          education: 'Graduate',
          profession: 'Business',
          criminalCases: 0,
          seriousCharges: null,
          assetsDeclared: 5000000,
          attendancePercentage: 85,
          debatesParticipated: 12,
          questionsAsked: 45,
          aiSummary: 'Rajesh Kumar is a first-time candidate with a clean record and business background. He has promised to focus on local infrastructure development.',
        },
        {
          id: 'mock-2',
          name: 'Sunita Devi',
          party: 'Party B',
          partySymbol: '🔥',
          constituency,
          state,
          age: 52,
          education: 'Post Graduate',
          profession: 'Lawyer',
          criminalCases: 2,
          seriousCharges: 'Case pending for alleged property dispute',
          assetsDeclared: 12000000,
          attendancePercentage: 78,
          debatesParticipated: 25,
          questionsAsked: 120,
          aiSummary: 'Sunita Devi is an experienced politician with strong parliamentary attendance. However, she has 2 criminal cases pending, primarily related to property disputes.',
        },
        {
          id: 'mock-3',
          name: 'Mohammed Ali',
          party: 'Party C',
          partySymbol: '🌟',
          constituency,
          state,
          age: 38,
          education: 'Graduate',
          profession: 'Social Worker',
          criminalCases: 0,
          seriousCharges: null,
          assetsDeclared: 2000000,
          attendancePercentage: null, // First time candidate
          debatesParticipated: 0,
          questionsAsked: 0,
          aiSummary: 'Mohammed Ali is a young social worker making his political debut. He has a clean record and focuses on education and youth empowerment.',
        },
      ],
    };
  }
}

module.exports = new CandidateService();
