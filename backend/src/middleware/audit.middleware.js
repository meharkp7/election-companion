// middleware/audit.middleware.js
// Security audit logging for government compliance

const { query } = require('../config/postgres');

/**
 * Log audit event to database
 */
async function logAudit(userId, action, details = {}) {
  try {
    await query(
      `INSERT INTO audit_logs 
       (user_id, action, request_data, success)
       VALUES ($1, $2, $3, $4)`,
      [
        userId,
        action,
        JSON.stringify(details),
        details.success !== false,
      ]
    );
  } catch (error) {
    console.error('Audit logging failed:', error);
    // Don't throw - audit logging should not break the app
  }
}

/**
 * Middleware to log all requests
 */
function auditMiddleware(req, res, next) {
  // Store start time
  req.startTime = Date.now();
  
  // Capture original end function
  const originalEnd = res.end;
  
  // Override end to log after response
  res.end = function(chunk, encoding) {
    // Restore original end
    res.end = originalEnd;
    res.end(chunk, encoding);
    
    // Log the request
    const duration = Date.now() - req.startTime;
    const userId = req.user?.id || req.body?.userId || req.params?.userId;
    
    if (userId) {
      logAudit(userId, `api_${req.method.toLowerCase()}`, {
        path: req.path,
        method: req.method,
        statusCode: res.statusCode,
        duration,
        ip: req.ip,
      }).catch(console.error);
    }
  };
  
  next();
}

module.exports = {
  logAudit,
  auditMiddleware,
};
