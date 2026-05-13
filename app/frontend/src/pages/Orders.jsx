import { useEffect, useState } from "react";
import { apiClient } from "../api/client";
import OrderCard from "../components/OrderCard";

function Orders({ refreshKey = 0 }) {
  const [state, setState] = useState({
    loading: true,
    orders: [],
    error: ""
  });

  useEffect(() => {
    let ignore = false;

    const loadOrders = async () => {
      try {
        const { data } = await apiClient.getOrders();
        if (!ignore) {
          setState({
            loading: false,
            orders: data.orders || [],
            error: ""
          });
        }
      } catch (error) {
        if (!ignore) {
          setState({
            loading: false,
            orders: [],
            error: error.message || "Orders are currently unavailable."
          });
        }
      }
    };

    loadOrders();

    return () => {
      ignore = true;
    };
  }, [refreshKey]);

  return (
    <section className="page-card">
      <div className="section-heading">
        <div>
          <p className="eyebrow">Orders</p>
          <h1>Recent CloudStore orders</h1>
        </div>
      </div>

      {state.loading ? <p className="loading-copy">Loading orders...</p> : null}
      {state.error ? <p className="notice-banner">{state.error}</p> : null}
      {!state.loading && !state.error && state.orders.length === 0 ? (
        <p className="empty-copy">No orders are available yet.</p>
      ) : null}

      <div className="orders-grid">
        {state.orders.map((order) => (
          <OrderCard order={order} key={order.id} />
        ))}
      </div>
    </section>
  );
}

export default Orders;
