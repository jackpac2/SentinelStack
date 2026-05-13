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
        <span>{order.createdAt ? new Date(order.createdAt).toLocaleString() : "Pending"}</span>
      </div>
      <ul>
        {(order.items || []).map((item, index) => (
          <li key={`${order.id}-${item.productId || index}`}>
            <span>{item.productId || "Product"}</span>
            <strong>x{item.quantity || 1}</strong>
          </li>
        ))}
      </ul>
    </article>
  );
}

export default OrderCard;
