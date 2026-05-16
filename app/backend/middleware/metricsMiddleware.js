const {
  httpRequestDurationSeconds,
  httpRequestsTotal
} = require("../metrics/registry");

const getRouteLabel = (req) => {
  if (req.route && req.route.path) {
    return `${req.baseUrl || ""}${req.route.path}`;
  }

  return "unmatched";
};

const metricsMiddleware = (req, res, next) => {
  if (req.path === "/metrics") {
    return next();
  }

  const startedAt = process.hrtime.bigint();

  res.on("finish", () => {
    const durationSeconds =
      Number(process.hrtime.bigint() - startedAt) / 1_000_000_000;

    const labels = {
      method: req.method,
      route: getRouteLabel(req),
      status_code: String(res.statusCode)
    };

    httpRequestsTotal.inc(labels);
    httpRequestDurationSeconds.observe(labels, durationSeconds);
  });

  return next();
};

module.exports = metricsMiddleware;
