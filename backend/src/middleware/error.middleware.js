const fs = require('fs');
const path = require('path');

const errorMiddleware = (err, req, res, next) => {
  console.error('❌', err.stack);
  
  // Log to file for debugging
  const logMessage = `[${new Date().toISOString()}] ${req.method} ${req.url}\n${err.stack}\n\n`;
  fs.appendFileSync(path.join(__dirname, '../../error.log'), logMessage);

  const status = err.status || 500;
  res.status(status).json({
    error: {
      message: err.message || 'Internal server error',
      ...(process.env.NODE_ENV === 'development' && { stack: err.stack }),
    },
  });
};

module.exports = { errorMiddleware };