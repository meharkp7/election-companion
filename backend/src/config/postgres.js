const { Pool } = require('pg');

// Debug ENV (remove later)
console.log("ENV CHECK:", {
  DB_HOST: process.env.DB_HOST,
  DB_PORT: process.env.DB_PORT,
  DB_USER: process.env.DB_USER,
  DB_PASSWORD_SET: !!process.env.DB_PASSWORD,
});

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