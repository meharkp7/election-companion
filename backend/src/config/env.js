require('dotenv').config({ path: require('path').resolve(__dirname, '../../.env') });
module.exports = {
  PORT: process.env.PORT || 5000,
  NODE_ENV: process.env.NODE_ENV || 'development',
};