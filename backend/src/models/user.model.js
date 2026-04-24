// models/user.model.js
// PostgreSQL-backed user model (replaces Mongoose version)

const { query } = require('../config/postgres');

const UserModel = {

  // ─── Find by Firebase UID ──────────────────────────────────────────────────
  async findByFirebaseUid(firebaseUid) {
    const rows = await query(
      'SELECT * FROM users WHERE firebase_uid = $1 LIMIT 1',
      [firebaseUid]
    );
    return rows[0] ? toCamel(rows[0]) : null;
  },

  // ─── Find by internal UUID ─────────────────────────────────────────────────
  async findById(id) {
    const rows = await query(
      'SELECT * FROM users WHERE id = $1 LIMIT 1',
      [id]
    );
    return rows[0] ? toCamel(rows[0]) : null;
  },

  // ─── Create new user ───────────────────────────────────────────────────────
  async create({ firebaseUid, phone, age, state, isFirstTimeVoter }) {
    const rows = await query(
      `INSERT INTO users
         (firebase_uid, phone, age, state, is_first_time_voter, current_state)
       VALUES ($1, $2, $3, $4, $5, 'START')
       RETURNING *`,
      [firebaseUid, phone ?? null, age ?? null, state ?? null, isFirstTimeVoter ?? false]
    );
    return toCamel(rows[0]);
  },

  // ─── Update arbitrary fields ───────────────────────────────────────────────
  async update(id, fields) {
    const allowed = [
      'age', 'state', 'is_first_time_voter', 'current_state',
      'registration_status', 'verification_status',
      'booth_known', 'booth_name', 'booth_address', 'booth_lat', 'booth_lng',
      'readiness_score', 'notifications_enabled', 'issue_type',
    ];

    // Map camelCase keys to snake_case DB columns
    const snakeMap = {
      age: 'age',
      state: 'state',
      isFirstTimeVoter: 'is_first_time_voter',
      currentState: 'current_state',
      registrationStatus: 'registration_status',
      verificationStatus: 'verification_status',
      boothKnown: 'booth_known',
      boothName: 'booth_name',
      boothAddress: 'booth_address',
      boothLat: 'booth_lat',
      boothLng: 'booth_lng',
      readinessScore: 'readiness_score',
      notificationsEnabled: 'notifications_enabled',
      issueType: 'issue_type',
    };

    const setClauses = [];
    const values = [];
    let i = 1;

    for (const [camelKey, value] of Object.entries(fields)) {
      const col = snakeMap[camelKey];
      if (col && allowed.includes(col)) {
        setClauses.push(`${col} = $${i}`);
        values.push(value);
        i++;
      }
    }

    if (setClauses.length === 0) throw new Error('No valid fields to update');

    values.push(id);
    const rows = await query(
      `UPDATE users SET ${setClauses.join(', ')}, updated_at = NOW()
       WHERE id = $${i} RETURNING *`,
      values
    );
    return rows[0] ? toCamel(rows[0]) : null;
  },

  // ─── Update booth details ──────────────────────────────────────────────────
  async updateBooth(firebaseUid, boothDetails) {
    const rows = await query(
      `UPDATE users SET
         booth_known = TRUE,
         booth_name = $2,
         booth_address = $3,
         booth_lat = $4,
         booth_lng = $5,
         updated_at = NOW()
       WHERE firebase_uid = $1 RETURNING *`,
      [
        firebaseUid,
        boothDetails.boothName ?? null,
        boothDetails.address ?? null,
        boothDetails.lat ?? null,
        boothDetails.lng ?? null,
      ]
    );
    return rows[0] ? toCamel(rows[0]) : null;
  },

  // ─── Count by current_state (for stats) ───────────────────────────────────
  async countByState() {
    return query(
      `SELECT current_state AS state, COUNT(*)::INTEGER AS count
       FROM users GROUP BY current_state`
    );
  },

  // ─── Avg readiness score ───────────────────────────────────────────────────
  async readinessStats() {
    const rows = await query(
      `SELECT
         AVG(readiness_score)::NUMERIC(5,1) AS avg,
         MAX(readiness_score) AS max,
         COUNT(*) AS total
       FROM users`
    );
    return rows[0];
  },

  // ─── Users with incomplete steps for reminder job ─────────────────────────
  async findIncompleteWithNotifications() {
    return query(
      `SELECT firebase_uid, current_state
       FROM users
       WHERE notifications_enabled = TRUE
         AND current_state IN ('REGISTRATION', 'CHECK_STATUS', 'VERIFICATION')`
    );
  },
};

// ─── snake_case → camelCase mapper ─────────────────────────────────────────
function toCamel(row) {
  if (!row) return null;
  return {
    id: row.id,
    firebaseUid: row.firebase_uid,
    phone: row.phone,
    age: row.age,
    state: row.state,
    isFirstTimeVoter: row.is_first_time_voter,
    currentState: row.current_state,
    registrationStatus: row.registration_status,
    verificationStatus: row.verification_status,
    boothKnown: row.booth_known,
    boothDetails: row.booth_name ? {
      boothName: row.booth_name,
      address: row.booth_address,
      lat: row.booth_lat ? parseFloat(row.booth_lat) : null,
      lng: row.booth_lng ? parseFloat(row.booth_lng) : null,
    } : null,
    readinessScore: row.readiness_score,
    notificationsEnabled: row.notifications_enabled,
    issueType: row.issue_type,
    createdAt: row.created_at,
    updatedAt: row.updated_at,
  };
}

module.exports = UserModel;