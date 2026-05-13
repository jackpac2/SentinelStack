import ProductCard from "../components/ProductCard";

function Products({ products, loading, error, onAddToCart }) {
  return (
    <section className="page-card">
      <div className="section-heading">
        <div>
          <p className="eyebrow">Catalog</p>
          <h1>CloudStore products</h1>
        </div>
      </div>

      {error ? <p className="notice-banner">{error}</p> : null}
      {loading ? <p className="loading-copy">Loading products...</p> : null}
      {!loading && products.length === 0 ? (
        <p className="empty-copy">No products match the current search.</p>
      ) : null}

      <div className="product-grid expanded">
        {products.map((product) => (
          <ProductCard product={product} onAddToCart={onAddToCart} key={product.id} />
        ))}
      </div>
    </section>
  );
}

export default Products;
