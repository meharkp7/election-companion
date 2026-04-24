// services/socialFeatures.service.js
// Social Features - Carpool, I Voted, Share Booth, Family Sharing

const { query } = require('../config/postgres');

class SocialFeaturesService {
  
  // ==========================================
  // CARPOOL / RIDESHARE
  // ==========================================
  
  /**
   * Create a carpool offer/request
   */
  async createCarpool(firebaseUid, carpoolData) {
    const {
      boothName, constituency, state, meetingPoint,
      rideType, vehicleType, seatsAvailable,
      departureTime, returnTrip, returnTime, maxPassengers
    } = carpoolData;
    
    // Get user details
    const users = await query(
      'SELECT phone FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    const userPhone = users.length > 0 ? users[0].phone : null;
    
    const result = await query(
      `INSERT INTO booth_carpools 
       (creator_firebase_uid, creator_phone, booth_name, constituency, state, meeting_point,
        ride_type, vehicle_type, seats_available, departure_time, return_trip, return_time, max_passengers)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13)
       RETURNING *`,
      [firebaseUid, userPhone, boothName, constituency, state, meetingPoint,
       rideType, vehicleType, seatsAvailable || 3, departureTime, returnTrip || false, returnTime, maxPassengers || 3]
    );
    
    return {
      success: true,
      carpoolId: result[0].id,
      message: rideType === 'offer' ? 'Carpool offer created!' : 'Carpool request created!',
      carpool: this._formatCarpool(result[0])
    };
  }
  
  /**
   * Find carpools for a booth
   */
  async findCarpools(boothName, constituency, state) {
    const carpools = await query(
      `SELECT * FROM booth_carpools 
       WHERE (booth_name = $1 OR constituency = $2)
       AND state = $3
       AND status = 'active'
       AND departure_time > NOW()
       ORDER BY departure_time ASC`,
      [boothName, constituency, state]
    );

    if (carpools.length === 0) {
      return {
        carpools: this._getMockCarpools(boothName, constituency, state),
        count: 2,
        offers: 2,
        requests: 0,
        isSimulated: true
      };
    }
    
    return {
      carpools: carpools.map(c => this._formatCarpool(c)),
      count: carpools.length,
      offers: carpools.filter(c => c.ride_type === 'offer').length,
      requests: carpools.filter(c => c.ride_type === 'request').length
    };
  }

  _getMockCarpools(boothName, constituency, state) {
    const now = new Date();
    return [
      {
        id: 'mock-1',
        creatorPhone: '+91 98765 43210',
        boothName: boothName || 'Green Park Booth',
        rideType: 'offer',
        seatsAvailable: 3,
        departureTime: new Date(now.getTime() + 1000 * 60 * 45).toISOString(),
        formattedDepartureTime: 'In 45 mins',
        notes: 'Leaving from South Ext Part 2. Have space for 3 people.'
      },
      {
        id: 'mock-2',
        creatorPhone: '+91 88001 12233',
        boothName: boothName || 'Green Park Booth',
        rideType: 'offer',
        seatsAvailable: 2,
        departureTime: new Date(now.getTime() + 1000 * 60 * 120).toISOString(),
        formattedDepartureTime: 'In 2 hours',
        notes: 'Driving my SUV. Plenty of space.'
      }
    ];
  }
  
  /**
   * Join a carpool
   */
  async joinCarpool(carpoolId, firebaseUid) {
    const carpool = await query(
      'SELECT * FROM booth_carpools WHERE id = $1',
      [carpoolId]
    );
    
    if (carpool.length === 0) throw new Error('Carpool not found');
    
    const currentPassengers = carpool[0].passengers || [];
    const maxPassengers = carpool[0].max_passengers;
    
    if (currentPassengers.length >= maxPassengers) {
      throw new Error('Carpool is full');
    }
    
    if (currentPassengers.includes(firebaseUid)) {
      throw new Error('Already joined this carpool');
    }
    
    const updatedPassengers = [...currentPassengers, firebaseUid];
    const status = updatedPassengers.length >= maxPassengers ? 'full' : 'active';
    
    await query(
      `UPDATE booth_carpools 
       SET passengers = $1, status = $2, updated_at = NOW()
       WHERE id = $3`,
      [updatedPassengers, status, carpoolId]
    );
    
    return {
      success: true,
      message: 'Joined carpool successfully!',
      passengers: updatedPassengers.length,
      status
    };
  }
  
  /**
   * Get my carpools (created or joined)
   */
  async getMyCarpools(firebaseUid) {
    const created = await query(
      `SELECT * FROM booth_carpools WHERE creator_firebase_uid = $1 ORDER BY departure_time DESC`,
      [firebaseUid]
    );
    
    const joined = await query(
      `SELECT * FROM booth_carpools WHERE $1 = ANY(passengers) ORDER BY departure_time DESC`,
      [firebaseUid]
    );
    
    return {
      created: created.map(c => this._formatCarpool(c)),
      joined: joined.map(c => this._formatCarpool(c)),
      total: created.length + joined.length
    };
  }
  
  // ==========================================
  // I VOTED BADGE
  // ==========================================
  
  /**
   * Record "I Voted"
   */
  async recordIVoted(firebaseUid, voteData) {
    const { boothName, constituency, state, verifiedVia, sharePublicly, shareAnonymously } = voteData;
    
    // Get user ID
    const users = await query(
      'SELECT id, state, booth_name FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) throw new Error('User not found');
    const user = users[0];
    
    const finalBooth = boothName || user.booth_name;
    const finalConstituency = constituency || this._extractConstituency(finalBooth);
    const finalState = state || user.state;
    
    // Check if already recorded
    const existing = await query(
      'SELECT id FROM i_voted_records WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    let result;
    if (existing.length > 0) {
      // Update
      result = await query(
        `UPDATE i_voted_records 
         SET booth_name = $2, constituency = $3, state = $4, verified_via = $5,
             share_publicly = $6, share_anonymously = $7, updated_at = NOW()
         WHERE firebase_uid = $1
         RETURNING *`,
        [firebaseUid, finalBooth, finalConstituency, finalState, verifiedVia, 
         sharePublicly, shareAnonymously]
      );
    } else {
      // Create
      result = await query(
        `INSERT INTO i_voted_records 
         (user_id, firebase_uid, booth_name, constituency, state, verified_via,
          share_publicly, share_anonymously)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING *`,
        [user.id, firebaseUid, finalBooth, finalConstituency, finalState, verifiedVia,
         sharePublicly !== false, shareAnonymously === true]
      );
    }
    
    return {
      success: true,
      message: 'Congratulations! Your vote has been recorded.',
      record: this._formatIVoted(result[0]),
      badge: this._generateBadgeData(result[0]),
      shareLinks: this._generateShareLinks(result[0])
    };
  }
  
  /**
   * Get I Voted record for user
   */
  async getIVotedRecord(firebaseUid) {
    const records = await query(
      'SELECT * FROM i_voted_records WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (records.length === 0) {
      return null;
    }
    
    return {
      ...this._formatIVoted(records[0]),
      badge: this._generateBadgeData(records[0])
    };
  }
  
  /**
   * Get public feed of "I Voted" (anonymized or public)
   */
  async getIVotedFeed(constituency = null, state = null, limit = 50) {
    let sql = `SELECT * FROM i_voted_records WHERE share_publicly = TRUE`;
    const params = [];
    
    if (constituency) {
      sql += ` AND constituency = $${params.length + 1}`;
      params.push(constituency);
    }
    
    if (state) {
      sql += ` AND state = $${params.length + 1}`;
      params.push(state);
    }
    
    sql += ` ORDER BY voted_at DESC LIMIT $${params.length + 1}`;
    params.push(limit);
    
    const records = await query(sql, params);
    
    return {
      feed: records.map(r => ({
        id: r.id,
        constituency: r.share_anonymously ? null : r.constituency,
        state: r.state,
        votedAt: r.voted_at,
        displayName: r.share_anonymously ? 'Anonymous Voter' : 'Fellow Voter',
        badgeType: this._getBadgeType(r.voted_at)
      })),
      count: records.length,
      totalVoters: records.length
    };
  }
  
  /**
   * Share "I Voted" on social media
   */
  async shareIVoted(firebaseUid, platform) {
    const record = await this.getIVotedRecord(firebaseUid);
    
    if (!record) throw new Error('No voting record found');
    
    // Update share count
    await query(
      'UPDATE i_voted_records SET shared_count = shared_count + 1 WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    const shareText = `I exercised my democratic right today! 🇮🇳\n\nI voted in the Indian elections. Every vote counts. Have you voted yet?\n\n#IVoted #Democracy #IndiaVotes`;
    
    return {
      success: true,
      platform,
      shareText,
      badgeUrl: record.badge?.imageUrl || null,
      deepLink: `voteready://voted/${record.id}`
    };
  }
  
  // ==========================================
  // BOOTH SHARING
  // ==========================================
  
  /**
   * Share booth info with family/friends
   */
  async shareBoothInfo(firebaseUid, shareData) {
    const { recipientPhone, recipientName, message } = shareData;
    
    // Get user booth info
    const users = await query(
      'SELECT booth_name, booth_address, booth_lat, booth_lng FROM users WHERE firebase_uid = $1',
      [firebaseUid]
    );
    
    if (users.length === 0) throw new Error('User not found');
    
    const booth = users[0];
    
    const shareContent = {
      boothName: booth.booth_name,
      boothAddress: booth.booth_address,
      location: booth.booth_lat && booth.booth_lng ? {
        lat: parseFloat(booth.booth_lat),
        lng: parseFloat(booth.booth_lng)
      } : null,
      mapsLink: booth.booth_lat && booth.booth_lng 
        ? `https://www.google.com/maps?q=${booth.booth_lat},${booth.booth_lng}`
        : null,
      message: message || `Hey ${recipientName || ''}, here's my polling booth information!`,
      sharedBy: firebaseUid,
      sharedAt: new Date().toISOString()
    };
    
    // In real implementation, send SMS or notification
    // For now, just return the share content
    
    return {
      success: true,
      message: 'Booth info ready to share!',
      shareContent,
      shareMethods: ['whatsapp', 'sms', 'copy_link'],
      recipientPhone
    };
  }
  
  // ==========================================
  // COMMUNITY STATS
  // ==========================================
  
  /**
   * Get community voting stats
   */
  async getCommunityStats(constituency, state) {
    const votedCount = await query(
      `SELECT COUNT(*) as count FROM i_voted_records 
       WHERE constituency = $1 AND state = $2`,
      [constituency, state]
    );
    
    const carpoolCount = await query(
      `SELECT COUNT(*) as count FROM booth_carpools 
       WHERE constituency = $1 AND state = $2 AND status = 'active'`,
      [constituency, state]
    );
    
    return {
      constituency,
      state,
      votedCount: parseInt(votedCount[0].count),
      activeCarpools: parseInt(carpoolCount[0].count),
      message: `${votedCount[0].count} voters have marked "I Voted" in your constituency!`
    };
  }
  
  // ==========================================
  // HELPER METHODS
  // ==========================================
  
  _formatCarpool(row) {
    return {
      id: row.id,
      creatorFirebaseUid: row.creator_firebase_uid,
      creatorPhone: row.creator_phone,
      boothName: row.booth_name,
      constituency: row.constituency,
      state: row.state,
      meetingPoint: row.meeting_point,
      rideType: row.ride_type,
      vehicleType: row.vehicle_type,
      seatsAvailable: row.seats_available,
      departureTime: row.departure_time,
      returnTrip: row.return_trip,
      returnTime: row.return_time,
      passengers: row.passengers || [],
      maxPassengers: row.max_passengers,
      status: row.status,
      createdAt: row.created_at
    };
  }
  
  _formatIVoted(row) {
    return {
      id: row.id,
      firebaseUid: row.firebase_uid,
      boothName: row.booth_name,
      constituency: row.constituency,
      state: row.state,
      votedAt: row.voted_at,
      verifiedVia: row.verified_via,
      badgeGenerated: row.badge_generated,
      badgeImageUrl: row.badge_image_url,
      sharePublicly: row.share_publicly,
      shareAnonymously: row.share_anonymously,
      sharedCount: row.shared_count,
      likesCount: row.likes_count
    };
  }
  
  _generateBadgeData(record) {
    const voteDate = new Date(record.voted_at);
    const hours = voteDate.getHours();
    
    let badgeType = 'voter';
    let badgeTitle = 'Proud Voter';
    
    if (hours < 9) {
      badgeType = 'early_bird';
      badgeTitle = 'Early Bird Voter';
    } else if (hours > 15) {
      badgeType = 'dedicated';
      badgeTitle = 'Dedicated Voter';
    }
    
    return {
      type: badgeType,
      title: badgeTitle,
      votedAt: record.voted_at,
      constituency: record.constituency,
      message: `I voted in ${record.constituency}!`,
      colors: {
        early_bird: { bg: '#FFD700', text: '#000' },
        dedicated: { bg: '#FF6B6B', text: '#FFF' },
        voter: { bg: '#4ECDC4', text: '#FFF' }
      }[badgeType]
    };
  }
  
  _generateShareLinks(record) {
    const text = encodeURIComponent(`I voted! 🇮🇳 Exercise your right. Every vote counts! #IVoted #IndiaVotes`);
    
    return {
      whatsapp: `https://wa.me/?text=${text}`,
      twitter: `https://twitter.com/intent/tweet?text=${text}`,
      facebook: `https://www.facebook.com/sharer/sharer.php?u=voteready.app`,
      copyText: decodeURIComponent(text)
    };
  }
  
  _getBadgeType(votedAt) {
    const hours = new Date(votedAt).getHours();
    if (hours < 9) return 'early_bird';
    if (hours > 15) return 'dedicated';
    return 'regular';
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

module.exports = new SocialFeaturesService();
