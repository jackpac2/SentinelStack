function CloudMark() {
  return (
    <span className="cloud-mark" aria-hidden="true">
      <span />
    </span>
  );
}

function Header({
  cartCount,
  cartTotal,
  searchTerm,
  onSearchChange,
  onCartToggle,
  onAccountClick
}) {
  return (
    <header className="topbar">
      <button className="brand" type="button" onClick={() => window.scrollTo(0, 0)}>
        <CloudMark />
        <span>cloudstore</span>
      </button>

      <label className="search-field">
        <span className="sr-only">Search products</span>
        <input
          type="search"
          value={searchTerm}
          onChange={(event) => onSearchChange(event.target.value)}
          placeholder="Search for products, brands and more..."
        />
        <span className="search-button" aria-hidden="true">
          Search
        </span>
      </label>

      <div className="service-points">
        <div className="mini-point">
          <span className="mini-icon">Ship</span>
          <span>
            <strong>Free Shipping</strong>
            <small>On orders over $50</small>
          </span>
        </div>
        <div className="mini-point">
          <span className="mini-icon">30</span>
          <span>
            <strong>Returns</strong>
            <small>30-day return</small>
          </span>
        </div>
      </div>

      <button className="account-chip" type="button" onClick={onAccountClick}>
        <span className="account-glyph">ID</span>
        <span>
          <strong>Sign In</strong>
          <small>My Account</small>
        </span>
      </button>

      <button className="cart-chip" type="button" onClick={onCartToggle}>
        <span className="cart-glyph">Bag</span>
        <span>
          <strong>Cart</strong>
          <small>${cartTotal.toFixed(2)}</small>
        </span>
        <b>{cartCount}</b>
      </button>
    </header>
  );
}

export default Header;
