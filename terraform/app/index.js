const express = require('express');
const fs = require('fs');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

// ============================================================================
// Middleware

app.use(express.json());

// Logging middleware
app.use((req, res, next) => {
  const log = `${new Date().toISOString()} - ${req.method} ${req.path}\n`;
  fs.appendFile(path.join(__dirname, 'app.log'), log, (err) => {
    if (err) console.error('Logging error:', err);
  });
  next();
});

// Routes

// Root endpoint
app.get('/', (req, res) => {
  res.json({
    message: 'Hello World!',
    timestamp: new Date().toISOString(),
    environment: process.env.NODE_ENV || 'development' //production
  });
});

// Health endpoint
app.get('/health', (req, res) => {
  res.status(200).json({
    status: 'healthy',
    uptime: process.uptime(),
    timestamp: new Date().toISOString()
  });
});

// API info endpoint
app.get('/api/info', (req, res) => {
  res.json({
    app: 'Node.js Web Application',
    version: '1.0.0',
    author: 'Wisdom',
    description: 'AWS CI/CD Demo Application'
  });
});

// Error Handlers
// ============================================================================

// 404 handler
app.use((req, res) => {
  res.status(404).json({ error: 'Route not found' });
});

// Global error handler
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Something went wrong!' });
});

// ============================================================================
// Server Start (Only when not in test mode)
// ============================================================================

let server;

if (require.main === module) {
  server = app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running at http://0.0.0.0:${PORT}`);
  });

  // Fix for AWS ALB 502 errors
  server.keepAliveTimeout = 65000; // 65 seconds (ALB timeout is 60s)
  server.headersTimeout = 66000;   // 66 seconds (must be > keepAliveTimeout)

  // Graceful shutdown
  process.on('SIGTERM', () => {
    console.log('SIGTERM received, closing server gracefully');
    server.close(() => {
      console.log('Server closed');
      process.exit(0);
    });
  });
}


module.exports = app;