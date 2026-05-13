const getMetricsPlaceholder = (req, res) => {
  res.json({
    message: "Metrics will be added in the next phase."
  });
};

module.exports = {
  getMetricsPlaceholder
};
