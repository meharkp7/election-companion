// models/state.model.js
// Audit log for every state transition — PostgreSQL version

const { query } = require('../config/postgres');

const StateLogModel = {

  async create({ userId, fromState, toState, trigger = 'user_action', meta = {} }) {
    const rows = await query(
      `INSERT INTO state_logs (user_id, from_state, to_state, trigger, meta)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [userId, fromState ?? null, toState, trigger, JSON.stringify(meta)]
    );
    return rows[0];
  },

  async findByUserId(userId, limit = 20) {
    return query(
      `SELECT * FROM state_logs
       WHERE user_id = $1
       ORDER BY created_at DESC
       LIMIT $2`,
      [userId, limit]
    );
  },

};

module.exports = StateLogModel;