#!/usr/bin/env node
/**
 * Seed database with initial feature data
 * Run: node scripts/seed-feature-data.js
 */

require('dotenv').config();
const { pool } = require('../src/config/postgres');

async function seed() {
  console.log('🌱 Seeding feature data...\n');
  
  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // ==========================================
    // 1. ELECTION PHASES (2024 General Election)
    // ==========================================
    console.log('📅 Seeding election phases...');
    
    const phases = [
      { year: 2024, type: 'lok_sabha', state: null, phase: 1, polling: '2024-04-19', counting: '2024-06-04', seats: 102, status: 'completed' },
      { year: 2024, type: 'lok_sabha', state: null, phase: 2, polling: '2024-04-26', counting: '2024-06-04', seats: 89, status: 'completed' },
      { year: 2024, type: 'lok_sabha', state: null, phase: 3, polling: '2024-05-07', counting: '2024-06-04', seats: 94, status: 'completed' },
      { year: 2024, type: 'lok_sabha', state: null, phase: 4, polling: '2024-05-13', counting: '2024-06-04', seats: 96, status: 'completed' },
      { year: 2024, type: 'lok_sabha', state: null, phase: 5, polling: '2024-05-20', counting: '2024-06-04', seats: 49, status: 'completed' },
      { year: 2024, type: 'lok_sabha', state: null, phase: 6, polling: '2024-05-25', counting: '2024-06-04', seats: 57, status: 'completed' },
      { year: 2024, type: 'lok_sabha', state: null, phase: 7, polling: '2024-06-01', counting: '2024-06-04', seats: 57, status: 'completed' },
    ];
    
    for (const phase of phases) {
      await client.query(
        `INSERT INTO election_phases 
         (election_year, election_type, state, phase_number, polling_date, counting_date, total_seats, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT DO NOTHING`,
        [phase.year, phase.type, phase.state, phase.phase, phase.polling, phase.counting, phase.seats, phase.status]
      );
    }

    // ==========================================
    // 2. VOTER RIGHTS GUIDES
    // ==========================================
    console.log('📚 Seeding voter rights guides...');
    
    const guides = [
      {
        topic: 'missing_name',
        title: 'My Name is Missing from Voter List',
        content: `If your name is not found in the electoral roll at the polling station:

1. Stay calm and ask for the BLO (Booth Level Officer) at the helpdesk
2. Show your EPIC card and any voter slip you have
3. Request them to check the supplementary list (this contains recent additions)
4. If still not found, ask for the reason in writing
5. Demand Form 12 (Denied Voting Certificate)
6. Call 1950 immediately and report the issue

Remember: You have the legal right to vote if you have a valid EPIC and are in the correct constituency.`,
        steps: ['Ask for BLO', 'Check supplementary list', 'Call 1950', 'Demand Form 12'],
        category: 'emergency',
        priority: 100
      },
      {
        topic: 'evm_issue',
        title: 'EVM Not Working',
        content: `If the Electronic Voting Machine (EVM) is not working:

1. Do not panic - EVM malfunctions are handled promptly
2. Immediately inform the Presiding Officer
3. The technical team will be called
4. Your turn in queue is preserved
5. Alternative EVM may be arranged if needed

Your vote is important and ECI ensures everyone gets to vote.`,
        steps: ['Inform Presiding Officer', 'Wait for technical team', 'Your place is saved'],
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

At polling station:
- Right to enter with valid ID
- Right to check your name in voter list
- Right to cast vote without intimidation
- Right to assistance if needed
- Right to verify vote on VVPAT for 7 seconds`,
        steps: ['Valid ID', 'Check voter list', 'Secret ballot', 'VVPAT verification'],
        category: 'rights',
        priority: 80
      },
      {
        topic: 'accessibility',
        title: 'Accessibility for PWD Voters',
        content: `Persons with Disabilities have special rights:

**Facilities Available:**
- Ramps at all polling stations
- Wheelchairs (on request)
- Priority voting (no queue waiting)
- Volunteer assistance
- Companion allowed for help

**How to request:**
1. Contact BLO before election day
2. Call 1950 and mention PWD requirement
3. At booth, go to helpdesk

PWD voters include: Physically disabled, visually impaired, hearing impaired, senior citizens (65+), pregnant women.`,
        steps: ['Contact BLO', 'Request wheelchair', 'Priority queue', 'Volunteer help'],
        category: 'accessibility',
        priority: 85
      },
      {
        topic: 'queue_long',
        title: 'Queue is Too Long',
        content: `If the queue is too long at your polling station:

1. Look for priority queue signs (for senior citizens/PWD)
2. Ask polling officer about facility
3. Best time: 11 AM - 3 PM (usually less crowded)
4. Check app for live queue status

**Tip:** PWD, senior citizens (65+), and pregnant women get priority access.

**Note:** Polling hours are from 7 AM to 6 PM. Plan accordingly!`,
        steps: ['Check priority queue', 'Ask officer', 'Come at 11 AM - 3 PM', 'Use app for status'],
        category: 'emergency',
        priority: 70
      },
      {
        topic: 'wrong_booth',
        title: 'I am at Wrong Polling Station',
        content: `If you realize you are at the wrong polling station:

1. Check your voter slip for exact booth address
2. Ask for helpdesk at current location
3. They can guide you to correct booth
4. Call 1950 for booth location help
5. You have time - polling hours are 7 AM - 6 PM

**Tip:** Keep 2-3 hours buffer if you need to change booths.

**Note:** You can only vote at your assigned polling station.`,
        steps: ['Check voter slip', 'Ask helpdesk', 'Call 1950', 'Plan 2-3 hours buffer'],
        category: 'emergency',
        priority: 75
      }
    ];
    
    for (const guide of guides) {
      await client.query(
        `INSERT INTO voter_rights_guides 
         (topic, title, content, quick_steps, category, priority, language)
         VALUES ($1, $2, $3, $4, $5, $6, 'en')
         ON CONFLICT DO NOTHING`,
        [guide.topic, guide.title, guide.content, guide.steps, guide.category, guide.priority]
      );
    }

    // ==========================================
    // 3. HELPLINE CONTACTS
    // ==========================================
    console.log('☎️ Seeding helpline contacts...');
    
    const contacts = [
      { name: 'ECI Control Room', type: 'helpline', phone: '1950', email: null, state: null, purpose: '24/7 Election Helpline', primary: true, priority: 100 },
      { name: 'ECI Toll Free', type: 'helpline', phone: '1800-111-950', email: null, state: null, purpose: 'Toll Free Election Helpline', primary: true, priority: 95 },
      { name: 'National Voter Helpline', type: 'helpline', phone: '1950', email: 'complaints@eci.gov.in', state: null, purpose: 'Voter registration and complaints', primary: false, priority: 90 },
      { name: 'CEO Delhi', type: 'ceo_office', phone: '011-23052012', email: 'ceo.delhi@eci.gov.in', state: 'Delhi', purpose: 'Chief Electoral Officer Delhi', primary: true, priority: 100 },
      { name: 'CEO Maharashtra', type: 'ceo_office', phone: '022-23052013', email: 'ceo.maharashtra@eci.gov.in', state: 'Maharashtra', purpose: 'Chief Electoral Officer Maharashtra', primary: true, priority: 100 },
      { name: 'CEO Uttar Pradesh', type: 'ceo_office', phone: '0522-2625301', email: 'ceo.up@eci.gov.in', state: 'Uttar Pradesh', purpose: 'Chief Electoral Officer UP', primary: true, priority: 100 },
      { name: 'CEO Karnataka', type: 'ceo_office', phone: '080-22270022', email: 'ceo.karnataka@eci.gov.in', state: 'Karnataka', purpose: 'Chief Electoral Officer Karnataka', primary: true, priority: 100 },
      { name: 'CEO Tamil Nadu', type: 'ceo_office', phone: '044-2567012', email: 'ceo.tn@eci.gov.in', state: 'Tamil Nadu', purpose: 'Chief Electoral Officer Tamil Nadu', primary: true, priority: 100 },
      { name: 'SMS Complaint', type: 'sms', phone: '1950', email: null, state: null, purpose: 'Send SMS complaint to 1950', primary: false, priority: 80 },
    ];
    
    for (const contact of contacts) {
      await client.query(
        `INSERT INTO helpline_contacts 
         (name, contact_type, phone, email, state, purpose, is_primary, priority)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         ON CONFLICT DO NOTHING`,
        [contact.name, contact.type, contact.phone, contact.email, contact.state, contact.purpose, contact.primary, contact.priority]
      );
    }

    // ==========================================
    // 4. MOCK ELECTION RESULTS
    // ==========================================
    console.log('📊 Seeding mock election results...');
    
    // Get an election phase
    const phaseResult = await client.query(
      'SELECT id FROM election_phases WHERE election_year = 2024 LIMIT 1'
    );
    
    if (phaseResult.rows.length > 0) {
      const phaseId = phaseResult.rows[0].id;
      
      // Create mock results for Delhi
      const constituencies = [
        { name: 'New Delhi', winner: 'Candidate A', party: 'Party A', margin: 12500, turnout: 65.2 },
        { name: 'East Delhi', winner: 'Candidate B', party: 'Party B', margin: 8900, turnout: 62.8 },
        { name: 'South Delhi', winner: 'Candidate C', party: 'Party A', margin: 25600, turnout: 68.5 },
        { name: 'North Delhi', winner: 'Candidate D', party: 'Party C', margin: 4200, turnout: 59.3 },
      ];
      
      for (const c of constituencies) {
        const result = await client.query(
          `INSERT INTO election_results 
           (election_phase_id, state, constituency, status, winning_candidate, winning_party, winning_margin, turnout_percentage, registered_voters, votes_polled)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
           ON CONFLICT DO NOTHING
           RETURNING id`,
          [phaseId, 'Delhi', c.name, 'completed', c.winner, c.party, c.margin, c.turnout, 150000, Math.round(150000 * c.turnout / 100)]
        );
        
        if (result.rows.length > 0) {
          const resultId = result.rows[0].id;
          
          // Add candidate results
          const candidates = [
            { name: c.winner, party: c.party, votes: 45000, share: 45.9, pos: 1 },
            { name: 'Runner Up', party: c.party === 'Party A' ? 'Party B' : 'Party A', votes: 32000, share: 32.7, pos: 2 },
            { name: 'Third Candidate', party: 'Party C', votes: 15000, share: 15.3, pos: 3 },
            { name: 'NOTA', party: 'None', votes: 6000, share: 6.1, pos: 4 },
          ];
          
          for (const cand of candidates) {
            await client.query(
              `INSERT INTO candidate_results 
               (result_id, candidate_name, party, votes_received, vote_share_percentage, position, status)
               VALUES ($1, $2, $3, $4, $5, $6, $7)
               ON CONFLICT DO NOTHING`,
              [resultId, cand.name, cand.party, cand.votes, cand.share, cand.pos, cand.pos === 1 ? 'won' : 'lost']
            );
          }
        }
      }
    }

    // ==========================================
    // 5. LIVE TURNOUT DATA
    // ==========================================
    console.log('📈 Seeding live turnout data...');
    
    const turnoutData = [
      { state: 'Delhi', constituency: 'New Delhi', hour: '08:00', turnout: 8.2, prev: 7.5 },
      { state: 'Delhi', constituency: 'New Delhi', hour: '10:00', turnout: 22.5, prev: 20.1 },
      { state: 'Delhi', constituency: 'New Delhi', hour: '12:00', turnout: 38.7, prev: 35.2 },
      { state: 'Delhi', constituency: 'New Delhi', hour: '14:00', turnout: 52.3, prev: 48.9 },
      { state: 'Delhi', constituency: 'New Delhi', hour: '16:00', turnout: 61.8, prev: 58.4 },
      { state: 'Delhi', constituency: 'New Delhi', hour: '18:00', turnout: 65.2, prev: 62.1 },
    ];
    
    for (const t of turnoutData) {
      await client.query(
        `INSERT INTO live_turnout_data 
         (state, constituency, hour_interval, cumulative_percentage, previous_election_percentage, difference_from_previous)
         VALUES ($1, $2, $3, $4, $5, $6)
         ON CONFLICT DO NOTHING`,
        [t.state, t.constituency, t.hour, t.turnout, t.prev, t.turnout - t.prev]
      );
    }

    await client.query('COMMIT');
    
    console.log('\n✅ Feature data seeded successfully!');
    console.log('\n📊 Seeded data:');
    console.log('   • 7 Election phases (2024 General Election)');
    console.log('   • 6 Voter rights guides');
    console.log('   • 9 Helpline contacts (National + States)');
    console.log('   • 4 Mock election results (Delhi)');
    console.log('   • 6 Live turnout data points');
    
  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Seeding failed:', error.message);
    process.exit(1);
  } finally {
    client.release();
    await pool.end();
  }
}

if (require.main === module) {
  seed();
}

module.exports = { seed };
