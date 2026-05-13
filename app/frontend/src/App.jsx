import { useEffect, useMemo, useState } from "react";
import Header from "./components/Header";
import Navbar from "./components/Navbar";
import CartPanel from "./components/CartPanel";
import Home from "./pages/Home";
import Products from "./pages/Products";
import Cart from "./pages/Cart";
import Orders from "./pages/Orders";
import SystemStatus from "./pages/SystemStatus";
import { apiClient } from "./api/client";

const fallbackProducts = [
  {
    id: "fallback-001",
    name: "CloudBuds Pro",
    description: "Wireless earbuds with clear everyday sound.",
    price: 59.99,
    category: "Electronics",
    stock: 28,
    imageUrl: ""
  },
  {
    id: "fallback-002",
    name: "Cloud Hoodie",
    description: "Soft cotton layer for relaxed comfort.",
    price: 49.99,
    category: "Fashion",
    stock: 34,
    imageUrl: ""
  },
  {
    id: "fallback-003",
    name: "CloudMist Humidifier",
    description: "Quiet room diffuser with a gentle mist.",
    price: 39.99,
    category: "Home & Living",
    stock: 19,
    imageUrl: ""
  },
  {
    id: "fallback-004",
    name: "CloudWatch Lite",
    description: "Slim fitness watch with simple daily tracking.",
    price: 89.99,
    category: "Electronics",
    stock: 22,
    imageUrl: ""
  },
  {
    id: "fallback-005",
    name: "CloudPack Backpack",
    description: "Water-resistant carry with organized storage.",
    price: 54.99,
    category: "Office",
    stock: 26,
    imageUrl: ""
  },
  {
    id: "fallback-006",
    name: "CloudStep Sneakers",
    description: "Lightweight shoes made for everyday movement.",
    price: 69.99,
    category: "Sports",
    stock: 31,
    imageUrl: ""
  }
];

function App() {
  const [activePage, setActivePage] = useState("home");
  const [activeNav, setActiveNav] = useState("home");
  const [cartItems, setCartItems] = useState([]);
  const [products, setProducts] = useState(fallbackProducts);
  const [productsState, setProductsState] = useState({
    loading: true,
    error: ""
  });
  const [searchTerm, setSearchTerm] = useState("");
  const [cartOpen, setCartOpen] = useState(false);

  useEffect(() => {
    let ignore = false;

    const loadProducts = async () => {
      try {
        const { data } = await apiClient.getProducts();
        if (!ignore && Array.isArray(data.products) && data.products.length > 0) {
          setProducts(data.products);
          setProductsState({ loading: false, error: "" });
        }
      } catch (error) {
        if (!ignore) {
          setProductsState({
            loading: false,
            error: "Live products are unavailable. Showing CloudStore samples instead."
          });
        }
      }
    };

    loadProducts();

    return () => {
      ignore = true;
    };
  }, []);

  const visibleProducts = useMemo(() => {
    const query = searchTerm.trim().toLowerCase();
    if (!query) {
      return products;
    }

    return products.filter((product) =>
      [product.name, product.description, product.category]
        .join(" ")
        .toLowerCase()
        .includes(query)
    );
  }, [products, searchTerm]);

  const cartCount = cartItems.reduce((total, item) => total + item.quantity, 0);
  const cartTotal = cartItems.reduce(
    (total, item) => total + item.price * item.quantity,
    0
  );

  const addToCart = (product) => {
    setCartItems((items) => {
      const existing = items.find((item) => item.id === product.id);
      if (existing) {
        return items.map((item) =>
          item.id === product.id
            ? { ...item, quantity: item.quantity + 1 }
            : item
        );
      }

      return [...items, { ...product, quantity: 1 }];
    });
    setCartOpen(true);
  };

  const removeFromCart = (productId) => {
    setCartItems((items) => items.filter((item) => item.id !== productId));
  };

  const updateQuantity = (productId, quantity) => {
    setCartItems((items) =>
      items
        .map((item) =>
          item.id === productId
            ? { ...item, quantity: Math.max(0, quantity) }
            : item
        )
        .filter((item) => item.quantity > 0)
    );
  };

  const clearCart = () => setCartItems([]);
  const navigateTo = (page, navId) => {
    setActivePage(page);
    if (navId) {
      setActiveNav(navId);
    }
  };

  const renderPage = () => {
    switch (activePage) {
      case "products":
        return (
          <Products
            products={visibleProducts}
            loading={productsState.loading}
            error={productsState.error}
            onAddToCart={addToCart}
          />
        );
      case "cart":
        return (
          <Cart
            items={cartItems}
            total={cartTotal}
            onRemove={removeFromCart}
            onQuantityChange={updateQuantity}
            onClearCart={clearCart}
            onNavigate={navigateTo}
          />
        );
      case "orders":
        return <Orders />;
      case "status":
        return <SystemStatus />;
      case "home":
      default:
        return (
          <Home
            products={visibleProducts}
            loading={productsState.loading}
            error={productsState.error}
            onAddToCart={addToCart}
            onNavigate={navigateTo}
          />
        );
    }
  };

  return (
    <div className="site-shell">
      <Header
        cartCount={cartCount}
        cartTotal={cartTotal}
        searchTerm={searchTerm}
        onSearchChange={setSearchTerm}
        onCartToggle={() => setCartOpen((open) => !open)}
        onAccountClick={() => navigateTo("orders", "track-order")}
      />
      <Navbar
        activeNav={activeNav}
        onNavigate={navigateTo}
      />
      <main className="page-shell">{renderPage()}</main>
      <CartPanel
        open={cartOpen}
        items={cartItems}
        total={cartTotal}
        onClose={() => setCartOpen(false)}
        onRemove={removeFromCart}
        onQuantityChange={updateQuantity}
        onViewCart={() => {
          navigateTo("cart");
          setCartOpen(false);
        }}
      />
    </div>
  );
}

export default App;
