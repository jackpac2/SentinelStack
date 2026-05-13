const getHealth = (req, res) => {
  res.json({
    status: "healthy",
    service: "cloudstore-backend",
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
};

module.exports = {
  getHealth
};
