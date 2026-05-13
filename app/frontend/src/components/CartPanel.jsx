function CartPanel({
  open,
  items,
  total,
  onClose,
  onRemove,
  onQuantityChange,
  onViewCart
}) {
  return (
    <aside className={`cart-panel ${open ? "open" : ""}`} aria-hidden={!open}>
      <div className="panel-head">
        <div>
          <p className="eyebrow">CloudStore cart</p>
          <h2>{items.length ? "Selected items" : "Your cart is empty"}</h2>
        </div>
        <button type="button" className="icon-button" onClick={onClose}>
          Close
        </button>
      </div>

      <div className="panel-list">
        {items.length === 0 ? (
          <p className="empty-copy">Add a product to stage a demo order.</p>
        ) : (
          items.map((item) => (
            <article className="mini-cart-item" key={item.id}>
              <div>
                <strong>{item.name}</strong>
                <small>${Number(item.price).toFixed(2)}</small>
              </div>
              <label>
                Qty
                <input
                  min="1"
                  type="number"
                  value={item.quantity}
                  onChange={(event) =>
                    onQuantityChange(item.id, Number(event.target.value))
                  }
                />
              </label>
              <button type="button" onClick={() => onRemove(item.id)}>
                Remove
              </button>
            </article>
          ))
        )}
      </div>

      <div className="panel-footer">
        <div>
          <span>Total</span>
          <strong>${total.toFixed(2)}</strong>
        </div>
        <button type="button" disabled={!items.length} onClick={onViewCart}>
          Review Cart
        </button>
      </div>
    </aside>
  );
}

export default CartPanel;
