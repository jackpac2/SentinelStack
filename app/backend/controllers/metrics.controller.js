const { register } = require("../metrics/registry");

const getMetrics = async (req, res, next) => {
  try {
    res.set("Content-Type", register.contentType);
    res.send(await register.metrics());
  } catch (error) {
    next(error);
  }
};

module.exports = {
  getMetrics
};
