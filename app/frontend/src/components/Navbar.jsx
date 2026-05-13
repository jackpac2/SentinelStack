const navItems = [
  { id: "home", page: "home", label: "Home" },
  { id: "categories", page: "products", label: "Categories" },
  { id: "deals", page: "products", label: "Deals" },
  { id: "arrivals", page: "products", label: "New Arrivals" },
  { id: "best-sellers", page: "products", label: "Best Sellers" },
  { id: "track-order", page: "orders", label: "Track Order" },
  { id: "system-status", page: "status", label: "System Status" }
];

function Navbar({ activeNav, onNavigate }) {
  return (
    <nav className="nav-strip" aria-label="Primary navigation">
      {navItems.map((item) => (
        <button
          className={`nav-link ${activeNav === item.id ? "active" : ""}`}
          key={item.label}
          type="button"
          onClick={() => onNavigate(item.page, item.id)}
        >
          {item.label}
        </button>
      ))}
    </nav>
  );
}

export default Navbar;
