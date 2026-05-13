const orders = [
  {
    id: "ord-001",
    customerName: "Ava Daniels",
    items: [
      { productId: "prod-002", quantity: 1 },
      { productId: "prod-006", quantity: 1 }
    ],
    status: "processing",
    total: 139.98,
    createdAt: "2026-05-10T09:15:00.000Z"
  },
  {
    id: "ord-002",
    customerName: "Noah Patel",
    items: [
      { productId: "prod-003", quantity: 2 }
    ],
    status: "shipped",
    total: 499.98,
    createdAt: "2026-05-11T14:30:00.000Z"
  }
];

module.exports = orders;
