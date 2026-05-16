const { getAllProducts } = require("../models/productModel");

const getProducts = async (req, res, next) => {
  try {
    const products = await getAllProducts();
    res.json(products);
  } catch (error) {
    console.error("Failed to fetch products:", error.message);
    next(error);
  }
};

module.exports = {
  getProducts
};
