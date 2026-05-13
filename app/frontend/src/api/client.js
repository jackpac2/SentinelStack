const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:5000";

const request = async (path, options = {}) => {
  const startedAt = performance.now();
  const response = await fetch(`${API_BASE_URL}${path}`, {
    headers: {
      "Content-Type": "application/json",
      ...(options.headers || {})
    },
    ...options
  });
  const elapsedMs = Math.round(performance.now() - startedAt);
  const payload = await response.json().catch(() => ({}));

  if (!response.ok) {
    const error = new Error(payload.message || `Request failed: ${response.status}`);
    error.status = response.status;
    error.elapsedMs = elapsedMs;
    error.payload = payload;
    throw error;
  }

  return {
    data: payload,
    elapsedMs
  };
};

export const apiClient = {
  getProducts: () => request("/products"),
  getOrders: () => request("/orders"),
  getHealth: () => request("/health"),
  createOrder: (payload) =>
    request("/orders", {
      method: "POST",
      body: JSON.stringify(payload)
    }),
  testSlowEndpoint: () => request("/slow"),
  triggerErrorEndpoint: () => request("/error")
};

export { API_BASE_URL };
