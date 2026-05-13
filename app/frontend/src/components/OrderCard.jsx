function OrderCard({ order }) {
  return (
    <article className="order-card">
      <div className="order-head">
        <div>
          <p className="eyebrow">Order {order.id}</p>
          <h3>{order.customerName}</h3>
        </div>
        <span>{order.status || "received"}</span>
      </div>
      <div className="order-meta">
        <span>{order.items?.length || 0} line items</span>
        <span>${Number(order.totalAmount || 0).toFixed(2)}</span>
        <span>{order.createdAt ? new Date(order.createdAt).toLocaleString() : "Pending"}</span>
      </div>
      <ul>
        {(order.items || []).map((item, index) => (
          <li key={`${order.id}-${item.productId || index}`}>
            <span>{item.productName || `Product ${item.productId || ""}`}</span>
            <strong>
              x{item.quantity || 1}
              {item.unitPrice ? ` @ $${Number(item.unitPrice).toFixed(2)}` : ""}
            </strong>
          </li>
        ))}
      </ul>
    </article>
  );
}

export default OrderCard;
