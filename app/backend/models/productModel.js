const pool = require("../config/db");

const mapProductRow = (row) => ({
  id: row.id,
  name: row.name,
  description: row.description,
  price: Number(row.price),
  category: row.category,
  stock: row.stock,
  imageUrl: row.image_url,
  rating: Number(row.rating),
  reviewCount: row.review_count,
  createdAt: row.created_at
});

const getAllProducts = async () => {
  const result = await pool.query(
    `SELECT
      id,
      name,
      description,
      price,
      category,
      stock,
      image_url,
      rating,
      review_count,
      created_at
    FROM products
    ORDER BY id ASC`
  );

  return result.rows.map(mapProductRow);
};

module.exports = {
  getAllProducts,
  mapProductRow
};
