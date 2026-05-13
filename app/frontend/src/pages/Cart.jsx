import { useState } from "react";
import { apiClient } from "../api/client";

function Cart({
  items,
  total,
  onRemove,
  onQuantityChange,
  onClearCart,
  onOrderCreated,
  onNavigate
}) {
  const [checkoutState, setCheckoutState] = useState({
    loading: false,
    success: "",
    error: ""
  });

  const placeOrder = async () => {
    if (!items.length) {
      return;
    }

    setCheckoutState({ loading: true, success: "", error: "" });

    try {
      const { data } = await apiClient.createOrder({
        customerName: "Demo Customer",
        items: items.map((item) => ({
          productId: item.id,
          quantity: item.quantity
        })),
        totalAmount: Number(total.toFixed(2))
      });

      setCheckoutState({
        loading: false,
        success: `Order ${data.order.id} placed successfully.`,
        error: ""
      });
      onClearCart();
      onOrderCreated();
    } catch (error) {
      setCheckoutState({
        loading: false,
        success: "",
        error: error.message || "Unable to place the demo order."
      });
    }
  };

  return (
    <section className="page-card cart-page">
      <div className="section-heading">
        <div>
          <p className="eyebrow">Cart</p>
          <h1>Ready for demo checkout</h1>
        </div>
        <button type="button" onClick={() => onNavigate("products", "categories")}>
          Continue shopping
        </button>
      </div>

      {items.length === 0 ? (
        <p className="empty-copy">Your cart is empty. Add products from the catalog.</p>
      ) : (
        <div className="cart-layout">
          <div className="cart-list">
            {items.map((item) => (
              <article className="cart-line" key={item.id}>
                <div>
                  <strong>{item.name}</strong>
                  <p>{item.description}</p>
                </div>
                <label>
                  Quantity
                  <input
                    min="1"
                    type="number"
                    value={item.quantity}
                    onChange={(event) =>
                      onQuantityChange(item.id, Number(event.target.value))
                    }
                  />
                </label>
                <b>${(item.price * item.quantity).toFixed(2)}</b>
                <button type="button" onClick={() => onRemove(item.id)}>
                  Remove
                </button>
              </article>
            ))}
          </div>

          <aside className="summary-card">
            <p className="eyebrow">Order summary</p>
            <strong>${total.toFixed(2)}</strong>
            <span>Customer: Demo Customer</span>
            <button type="button" disabled={checkoutState.loading} onClick={placeOrder}>
              {checkoutState.loading ? "Placing order..." : "Place Fake Order"}
            </button>
          </aside>
        </div>
      )}

      {checkoutState.success ? (
        <p className="success-banner">{checkoutState.success}</p>
      ) : null}
      {checkoutState.error ? <p className="notice-banner">{checkoutState.error}</p> : null}
    </section>
  );
}

export default Cart;
