require('dotenv').config({
  path: require('path').resolve(__dirname, '../.env'),
});

const app = require('./app');
const { connectDB } = require('./config/postgres');

const PORT = process.env.PORT || 5001;

// Connect DB and start server
connectDB().then(() => {
  app.listen(PORT, () => {
    console.log(`🚀 Server running on port ${PORT}`);
    console.log(`📚 API Documentation: http://localhost:${PORT}/api`);
  });
});