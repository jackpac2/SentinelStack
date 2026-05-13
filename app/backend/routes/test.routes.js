const express = require("express");
const {
  getSlowResponse,
  getIntentionalError
} = require("../controllers/test.controller");

const router = express.Router();

router.get("/slow", getSlowResponse);
router.get("/error", getIntentionalError);

module.exports = router;
