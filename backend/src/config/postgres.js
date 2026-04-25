const { Pool } = require('pg');

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST || 'localhost',
  port: parseInt(process.env.DB_PORT) || 5433,
  database: process.env.DB_NAME || 'voteready',
  user: process.env.DB_USER || 'appuser',
  password: String(process.env.DB_PASSWORD || ''),
});

// Connect DB
const connectDB = async () => {
  try {
    const client = await pool.connect();
    console.log('✅ PostgreSQL connected');
    client.release();
  } catch (err) {
    console.error('❌ PostgreSQL connection failed:', err.message);
  }
};

// Query helper
const query = async (text, params) => {
  try {
    const result = await pool.query(text, params);
    return result.rows;
  } catch (err) {
    console.error('❌ Database query error:', err.message);
    throw err;
  }
};

module.exports = { pool, connectDB, query };