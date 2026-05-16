const pool = require("../config/db");

const getHealth = async (req, res) => {
  try {
    await pool.query("SELECT 1");

    res.json({
      status: "healthy",
      database: "healthy",
      service: "cloudstore-backend",
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  } catch (error) {
    console.error("Database health check failed:", error.message);

    res.status(503).json({
      status: "degraded",
      database: "unhealthy",
      service: "cloudstore-backend",
      timestamp: new Date().toISOString(),
      uptime: process.uptime()
    });
  }
};

module.exports = {
  getHealth
};
