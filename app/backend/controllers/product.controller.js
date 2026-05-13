const products = require("../data/products");

const getProducts = (req, res) => {
  res.json({
    count: products.length,
    products
  });
};

module.exports = {
  getProducts
};
