// models/election.model.js
// PostgreSQL version

const { query } = require('../config/postgres');

const ElectionModel = {

  async findByState(state) {
    const rows = await query(
      `SELECT * FROM elections
       WHERE state = $1 AND is_active = TRUE
       ORDER BY election_date ASC
       LIMIT 1`,
      [state]
    );
    return rows[0] ? toCamel(rows[0]) : null;
  },

  async findAllActive() {
    const rows = await query(
      `SELECT * FROM elections
       WHERE is_active = TRUE
       ORDER BY election_date ASC`
    );
    return rows.map(toCamel);
  },

  async create({ name, state, electionDate, nominationDeadline, registrationDeadline, resultsDate, phases = [] }) {
    const rows = await query(
      `INSERT INTO elections
         (name, state, election_date, nomination_deadline, registration_deadline, results_date, phases)
       VALUES ($1, $2, $3, $4, $5, $6, $7)
       RETURNING *`,
      [name, state, electionDate, nominationDeadline, registrationDeadline, resultsDate, JSON.stringify(phases)]
    );
    return toCamel(rows[0]);
  },

};

function toCamel(row) {
  if (!row) return null;
  return {
    id: row.id,
    name: row.name,
    state: row.state,
    electionDate: row.election_date,
    nominationDeadline: row.nomination_deadline,
    registrationDeadline: row.registration_deadline,
    resultsDate: row.results_date,
    isActive: row.is_active,
    phases: row.phases ?? [],
    createdAt: row.created_at,
  };
}

module.exports = ElectionModel;