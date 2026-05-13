const orders = require("../data/orders");

const getOrders = (req, res) => {
  res.json({
    count: orders.length,
    orders
  });
};

const createOrder = (req, res, next) => {
  const { customerName, items } = req.body || {};

  if (!customerName || typeof customerName !== "string") {
    const error = new Error("customerName is required and must be a string.");
    error.statusCode = 400;
    return next(error);
  }

  if (!Array.isArray(items) || items.length === 0) {
    const error = new Error("items is required and must be a non-empty array.");
    error.statusCode = 400;
    return next(error);
  }

  const order = {
    id: `ord-${String(orders.length + 1).padStart(3, "0")}`,
    customerName: customerName.trim(),
    items,
    status: "received",
    createdAt: new Date().toISOString()
  };

  orders.push(order);

  res.status(201).json({
    message: "Order created successfully.",
    order
  });
};

module.exports = {
  getOrders,
  createOrder
};
