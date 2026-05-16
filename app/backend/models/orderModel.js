const pool = require("../config/db");

const mapOrderRow = (row) => ({
  id: row.id,
  customerName: row.customer_name,
  totalAmount: Number(row.total_amount),
  status: row.status,
  createdAt: row.created_at,
  items: row.items || []
});

const getAllOrders = async () => {
  const result = await pool.query(
    `SELECT
      o.id,
      o.customer_name,
      o.total_amount,
      o.status,
      o.created_at,
      COALESCE(
        json_agg(
          json_build_object(
            'id', oi.id,
            'productId', oi.product_id,
            'productName', p.name,
            'quantity', oi.quantity,
            'unitPrice', oi.unit_price
          )
          ORDER BY oi.id
        ) FILTER (WHERE oi.id IS NOT NULL),
        '[]'
      ) AS items
    FROM orders o
    LEFT JOIN order_items oi ON oi.order_id = o.id
    LEFT JOIN products p ON p.id = oi.product_id
    GROUP BY o.id
    ORDER BY o.created_at DESC, o.id DESC`
  );

  return result.rows.map(mapOrderRow);
};

const createOrder = async ({ customerName, items, totalAmount }) => {
  const client = await pool.connect();

  try {
    await client.query("BEGIN");

    const productIds = items.map((item) => Number(item.productId));
    const productsResult = await client.query(
      `SELECT id, name, price
      FROM products
      WHERE id = ANY($1::int[])`,
      [productIds]
    );

    if (productsResult.rows.length !== productIds.length) {
      const error = new Error("One or more products were not found.");
      error.statusCode = 400;
      throw error;
    }

    const productsById = new Map(
      productsResult.rows.map((product) => [product.id, product])
    );

    const calculatedTotal = items.reduce((sum, item) => {
      const product = productsById.get(Number(item.productId));
      return sum + Number(product.price) * Number(item.quantity);
    }, 0);

    const finalTotal = Number.isFinite(Number(totalAmount))
      ? Number(totalAmount)
      : calculatedTotal;

    const orderResult = await client.query(
      `INSERT INTO orders (customer_name, total_amount, status)
      VALUES ($1, $2, $3)
      RETURNING id, customer_name, total_amount, status, created_at`,
      [customerName, finalTotal, "received"]
    );

    const order = mapOrderRow({ ...orderResult.rows[0], items: [] });

    const createdItems = [];

    for (const item of items) {
      const product = productsById.get(Number(item.productId));
      const itemResult = await client.query(
        `INSERT INTO order_items (order_id, product_id, quantity, unit_price)
        VALUES ($1, $2, $3, $4)
        RETURNING id, product_id, quantity, unit_price`,
        [
          order.id,
          Number(item.productId),
          Number(item.quantity),
          Number(product.price)
        ]
      );

      const createdItem = itemResult.rows[0];
      createdItems.push({
        id: createdItem.id,
        productId: createdItem.product_id,
        productName: product.name,
        quantity: createdItem.quantity,
        unitPrice: Number(createdItem.unit_price)
      });
    }

    await client.query("COMMIT");

    return {
      ...order,
      totalAmount: finalTotal,
      items: createdItems
    };
  } catch (error) {
    await client.query("ROLLBACK");
    throw error;
  } finally {
    client.release();
  }
};

module.exports = {
  getAllOrders,
  createOrder
};
