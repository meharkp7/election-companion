// services/boothCrowdsource.service.js
// Real-Time Polling Booth Intelligence (Crowdsourced)

const { query } = require('../config/postgres');

class BoothCrowdsourceService {
  
  /**
   * Report booth status (crowdsourced from voters)
   */
  async reportBoothStatus(firebaseUid, reportData) {
    const {
      boothName,
      constituency,
      state,
      queueLength,
      waitTimeMinutes,
      evmWorking = true,
      waterAvailable = true,
      seatingAvailable = true,
      rampAccessible = true,
      parkingAvailable = true,
      issues = [],
      crowdLevel,
      bestTimeToVisit,
    } = reportData;
    
    // Get user ID
    const users = await query(
      'SELECT id FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) {
      throw new Error('User not found');
    }
    
    const userId = users[0].id;
    
    // Create report
    const result = await query(
      `INSERT INTO booth_status_reports 
       (reported_by, firebase_uid, booth_name, constituency, state,
        queue_length, wait_time_minutes, evm_working, water_available,
        seating_available, ramp_accessible, parking_available, issues,
        crowd_level, best_time_to_visit, reported_at, expires_at)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, NOW(), NOW() + INTERVAL '2 hours')
       RETURNING *`,
      [
        userId,
        firebaseUid,
        boothName,
        constituency,
        state,
        queueLength,
        waitTimeMinutes,
        evmWorking,
        waterAvailable,
        seatingAvailable,
        rampAccessible,
        parkingAvailable,
        JSON.stringify(issues),
        crowdLevel,
        bestTimeToVisit,
      ]
    );
    
    // Update verification count for similar reports
    await this._updateVerificationCount(boothName, constituency, state);
    
    return {
      success: true,
      reportId: result[0].id,
      message: 'Thank you for reporting! Your update helps other voters.',
      expiresAt: result[0].expires_at,
    };
  }
  
  /**
   * Get real-time status for a specific booth
   */
  async getBoothStatus(boothName, constituency, state) {
    // Get latest verified reports
    const reports = await query(
      `SELECT * FROM booth_status_reports 
       WHERE booth_name = $1 AND constituency = $2 AND state = $3
       AND expires_at > NOW()
       ORDER BY reported_at DESC
       LIMIT 5`,
      [boothName, constituency, state]
    );
    
    if (reports.length === 0) {
      return this._getPredictedStatus(boothName, constituency, state);
    }
    
    // Aggregate multiple reports
    const aggregated = this._aggregateReports(reports);
    
    return {
      boothName,
      constituency,
      state,
      lastUpdated: reports[0].reported_at,
      reportsCount: reports.length,
      verified: reports[0].verification_count >= 2,
      ...aggregated,
      predictions: this._generatePredictions(reports),
    };
  }
  
  /**
   * Get all booths in a constituency with status
   */
  async getConstituencyBooths(constituency, state) {
    // Get all booths with recent reports
    const boothsWithReports = await query(
      `SELECT DISTINCT ON (booth_name) 
        booth_name, queue_length, wait_time_minutes, crowd_level,
        reported_at, verification_count
       FROM booth_status_reports 
       WHERE constituency = $1 AND state = $2 AND expires_at > NOW()
       ORDER BY booth_name, reported_at DESC`,
      [constituency, state]
    );
    
    // Get historical booth list (would come from a reference table in production)
    const allBooths = await this._getAllBoothsInConstituency(constituency, state);
    
    // Merge with real-time data
    const merged = allBooths.map(booth => {
      const report = boothsWithReports.find(r => r.booth_name === booth.name);
      return {
        ...booth,
        status: report ? {
          queueLength: report.queue_length,
          waitTime: report.wait_time_minutes,
          crowdLevel: report.crowd_level,
          lastUpdated: report.reported_at,
          verified: report.verification_count >= 2,
        } : null,
        hasRealTimeData: !!report,
      };
    });
    
    // Sort by wait time (shortest first)
    merged.sort((a, b) => {
      const waitA = a.status?.waitTime || 999;
      const waitB = b.status?.waitTime || 999;
      return waitA - waitB;
    });
    
    return {
      constituency,
      state,
      totalBooths: merged.length,
      boothsWithData: boothsWithReports.length,
      booths: merged,
      recommendedBooth: merged.find(b => b.hasRealTimeData && b.status?.waitTime < 15) || merged[0],
    };
  }
  
  /**
   * Get best time to vote predictions
   */
  async getBestTimeToVote(boothName, constituency, state) {
    // Get historical data
    const historical = await query(
      `SELECT * FROM booth_historical_data 
       WHERE booth_name = $1 AND constituency = $2 AND state = $3
       ORDER BY election_date DESC LIMIT 3`,
      [boothName, constituency, state]
    );
    
    // Get current day reports
    const today = await query(
      `SELECT * FROM booth_status_reports 
       WHERE booth_name = $1 AND constituency = $2 AND state = $3
       AND reported_at > NOW() - INTERVAL '8 hours'
       ORDER BY reported_at`,
      [boothName, constituency, state]
    );
    
    // Analyze patterns
    const patterns = this._analyzePatterns(historical, today);
    
    return {
      currentTime: new Date(),
      recommendations: patterns.recommendations,
      peakHours: patterns.peakHours,
      quietHours: patterns.quietHours,
      predictedWaitTimes: patterns.predictedWaitTimes,
    };
  }
  
  /**
   * Verify a report (another user confirms)
   */
  async verifyReport(reportId, firebaseUid) {
    // Check if user already verified
    const existing = await query(
      `SELECT 1 FROM booth_report_verifications 
       WHERE report_id = $1 AND firebase_uid = $2`,
      [reportId, firebaseUid]
    );
    
    if (existing.length > 0) {
      throw new Error('You have already verified this report');
    }
    
    // Add verification
    await query(
      `INSERT INTO booth_report_verifications (report_id, firebase_uid, verified_at)
       VALUES ($1, $2, NOW())`,
      [reportId, firebaseUid]
    );
    
    // Update verification count
    await query(
      `UPDATE booth_status_reports 
       SET verification_count = verification_count + 1,
           is_verified = CASE WHEN verification_count + 1 >= 2 THEN TRUE ELSE is_verified END
       WHERE id = $1`,
      [reportId]
    );
    
    return { success: true, message: 'Verification recorded. Thank you!' };
  }
  
  /**
   * Get nearby booths with good conditions
   */
  async getAlternativeBooths(currentBoothName, constituency, state, maxDistance = 5) {
    const allBooths = await this.getConstituencyBooths(constituency, state);
    
    // Filter for booths with short wait times
    const alternatives = allBooths.booths.filter(b => 
      b.name !== currentBoothName &&
      b.hasRealTimeData &&
      b.status?.waitTime < 20
    );
    
    return {
      currentBooth: currentBoothName,
      alternatives: alternatives.slice(0, 3),
      message: alternatives.length > 0 
        ? 'Found nearby booths with shorter queues!'
        : 'All nearby booths have similar wait times.',
    };
  }
  
  /**
   * Get reporting leaderboard (gamification)
   */
  async getReporterLeaderboard(constituency, state, limit = 10) {
    const leaders = await query(
      `SELECT 
        firebase_uid,
        COUNT(*) as reports_count,
        COUNT(CASE WHEN verification_count >= 2 THEN 1 END) as verified_reports
       FROM booth_status_reports 
       WHERE constituency = $1 AND state = $2
       AND reported_at > NOW() - INTERVAL '24 hours'
       GROUP BY firebase_uid
       ORDER BY verified_reports DESC, reports_count DESC
       LIMIT $3`,
      [constituency, state, limit]
    );
    
    return leaders.map((l, index) => ({
      rank: index + 1,
      reportsCount: parseInt(l.reports_count),
      verifiedReports: parseInt(l.verified_reports),
      accuracy: Math.round((l.verified_reports / l.reports_count) * 100),
    }));
  }
  
  // ==========================================
  // Private Helper Methods
  // ==========================================
  
  async _updateVerificationCount(boothName, constituency, state) {
    // Auto-verify if multiple similar reports come in
    const similarReports = await query(
      `SELECT id FROM booth_status_reports 
       WHERE booth_name = $1 AND constituency = $2 AND state = $3
       AND reported_at > NOW() - INTERVAL '30 minutes'
       ORDER BY reported_at DESC`,
      [boothName, constituency, state]
    );
    
    if (similarReports.length >= 2) {
      await query(
        `UPDATE booth_status_reports 
         SET verification_count = LEAST(verification_count + 1, 5),
             is_verified = TRUE
         WHERE id = $1`,
        [similarReports[0].id]
      );
    }
  }
  
  _aggregateReports(reports) {
    // Calculate averages and most common values
    const avgWaitTime = Math.round(
      reports.reduce((sum, r) => sum + (r.wait_time_minutes || 0), 0) / reports.length
    );
    
    const avgCrowdLevel = Math.round(
      reports.reduce((sum, r) => sum + (r.crowd_level || 3), 0) / reports.length
    );
    
    // Most common queue length
    const queueCounts = {};
    reports.forEach(r => {
      queueCounts[r.queue_length] = (queueCounts[r.queue_length] || 0) + 1;
    });
    const queueLength = Object.entries(queueCounts)
      .sort((a, b) => b[1] - a[1])[0]?.[0] || 'medium';
    
    // Aggregate issues
    const allIssues = reports.flatMap(r => r.issues || []);
    const issueCounts = {};
    allIssues.forEach(issue => {
      issueCounts[issue] = (issueCounts[issue] || 0) + 1;
    });
    const commonIssues = Object.entries(issueCounts)
      .filter(([_, count]) => count >= 2)
      .map(([issue, _]) => issue);
    
    // Check facilities
    const facilities = {
      evmWorking: reports.every(r => r.evm_working),
      waterAvailable: reports.every(r => r.water_available),
      seatingAvailable: reports.some(r => r.seating_available),
      rampAccessible: reports.every(r => r.ramp_accessible),
      parkingAvailable: reports.some(r => r.parking_available),
    };
    
    return {
      queueLength,
      waitTimeMinutes: avgWaitTime,
      crowdLevel: avgCrowdLevel,
      facilities,
      issues: commonIssues,
    };
  }
  
  _generatePredictions(reports) {
    const hour = new Date().getHours();
    
    // Simple prediction based on typical patterns
    let prediction = 'moderate';
    
    if (hour >= 8 && hour <= 10) {
      prediction = 'high';
    } else if (hour >= 12 && hour <= 14) {
      prediction = 'low';
    } else if (hour >= 17 && hour <= 19) {
      prediction = 'high';
    }
    
    return {
      nextHour: prediction,
      trend: reports.length > 1 && reports[0].crowd_level > reports[reports.length - 1].crowd_level
        ? 'increasing'
        : 'stable',
    };
  }
  
  async _getPredictedStatus(boothName, constituency, state) {
    // Get historical data for predictions
    const historical = await query(
      `SELECT * FROM booth_historical_data 
       WHERE booth_name = $1 AND constituency = $2 AND state = $3
       ORDER BY election_date DESC LIMIT 1`,
      [boothName, constituency, state]
    );
    
    if (historical.length > 0) {
      return {
        boothName,
        constituency,
        state,
        lastUpdated: null,
        reportsCount: 0,
        verified: false,
        queueLength: historical[0].avg_queue_length,
        waitTimeMinutes: historical[0].avg_wait_time,
        crowdLevel: 3,
        facilities: {
          evmWorking: true,
          waterAvailable: true,
          seatingAvailable: true,
          rampAccessible: true,
          parkingAvailable: false,
        },
        issues: [],
        predictions: {
          source: 'historical_data',
          nextHour: 'moderate',
          trend: 'unknown',
        },
        isPrediction: true,
        message: 'No live reports yet. Showing estimated wait time based on historical data.',
      };
    }
    
    return {
      boothName,
      constituency,
      state,
      lastUpdated: null,
      reportsCount: 0,
      verified: false,
      queueLength: 'unknown',
      waitTimeMinutes: null,
      crowdLevel: null,
      facilities: null,
      issues: [],
      predictions: null,
      isPrediction: false,
      message: 'No data available yet. Be the first to report!',
    };
  }
  
  _analyzePatterns(historical, today) {
    const recommendations = [];
    
    // Based on historical quiet hours
    const historicalQuiet = historical.flatMap(h => h.quiet_hours || []);
    if (historicalQuiet.length > 0) {
      recommendations.push({
        timeRange: historicalQuiet[0],
        reason: 'Historically less crowded',
        confidence: 'high',
      });
    }
    
    // Based on today's trend
    if (today.length > 2) {
      const recentTrend = today[today.length - 1].crowd_level - today[0].crowd_level;
      if (recentTrend > 0) {
        recommendations.push({
          timeRange: 'Wait 1-2 hours',
          reason: 'Crowd increasing',
          confidence: 'medium',
        });
      }
    }
    
    // Default recommendation
    if (recommendations.length === 0) {
      recommendations.push({
        timeRange: '2 PM - 4 PM',
        reason: 'Typically less crowded',
        confidence: 'medium',
      });
    }
    
    return {
      recommendations,
      peakHours: ['9 AM - 11 AM', '5 PM - 7 PM'],
      quietHours: ['2 PM - 4 PM'],
      predictedWaitTimes: {
        morning: '30-45 min',
        afternoon: '15-25 min',
        evening: '45-60 min',
      },
    };
  }
  
  async _getAllBoothsInConstituency(constituency, state) {
    // In production, this would come from ECI database
    // For now, generate mock booths based on reports or return empty
    const reportedBooths = await query(
      `SELECT DISTINCT booth_name FROM booth_status_reports 
       WHERE constituency = $1 AND state = $2`,
      [constituency, state]
    );
    
    if (reportedBooths.length > 0) {
      return reportedBooths.map((b, i) => ({
        id: `booth-${i}`,
        name: b.booth_name,
        number: i + 1,
        address: `${b.booth_name}, ${constituency}`,
      }));
    }
    
    // Mock data for demo
    return [
      { id: 'booth-1', name: `${constituency} Primary School`, number: 1, address: `Primary School, ${constituency}` },
      { id: 'booth-2', name: `${constituency} Community Center`, number: 2, address: `Community Center, ${constituency}` },
      { id: 'booth-3', name: `${constituency} Government Office`, number: 3, address: `Govt Office, ${constituency}` },
    ];
  }
}

module.exports = new BoothCrowdsourceService();
