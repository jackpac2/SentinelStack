const express = require("express");
const { getMetricsPlaceholder } = require("../controllers/metrics.controller");

const router = express.Router();

router.get("/metrics", getMetricsPlaceholder);

module.exports = router;
