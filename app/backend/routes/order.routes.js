const express = require("express");
const {
  getOrders,
  createOrder
} = require("../controllers/order.controller");

const router = express.Router();

router.get("/orders", getOrders);
router.post("/orders", createOrder);

module.exports = router;
