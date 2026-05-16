const {
  getAllOrders,
  createOrder: createDatabaseOrder
} = require("../models/orderModel");

const getOrders = async (req, res, next) => {
  try {
    const orders = await getAllOrders();
    res.json({
      count: orders.length,
      orders
    });
  } catch (error) {
    console.error("Failed to fetch orders:", error.message);
    next(error);
  }
};

const createOrder = async (req, res, next) => {
  const { customerName, items, totalAmount } = req.body || {};

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

  const invalidItem = items.find((item) => {
    const productId = Number(item.productId);
    const quantity = Number(item.quantity);

    return (
      !Number.isInteger(productId) ||
      productId <= 0 ||
      !Number.isInteger(quantity) ||
      quantity <= 0
    );
  });

  if (invalidItem) {
    const error = new Error(
      "Each item must include a valid numeric productId and positive quantity."
    );
    error.statusCode = 400;
    return next(error);
  }

  try {
    const order = await createDatabaseOrder({
      customerName: customerName.trim(),
      items,
      totalAmount
    });

    res.status(201).json({
      message: "Order created successfully.",
      order
    });
  } catch (error) {
    console.error("Failed to create order:", error.message);
    next(error);
  }
};

module.exports = {
  getOrders,
  createOrder
};
