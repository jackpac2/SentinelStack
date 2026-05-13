const ratings = {
  "fallback-001": [5, 128],
  "fallback-002": [5, 86],
  "fallback-003": [4, 64],
  "fallback-004": [5, 95],
  "fallback-005": [4, 72],
  "fallback-006": [5, 110]
};

function ProductCard({ product, onAddToCart }) {
  const [rating, reviews] = ratings[product.id] || [5, 48];

  return (
    <article className="product-card">
      <div className="product-visual">
        <span className="favorite">Heart</span>
        <span className="product-art">{product.name.split(" ")[0]}</span>
      </div>
      <div className="product-body">
        <strong>{product.name}</strong>
        <p>{product.description}</p>
        <div className="price-row">
          <b>${Number(product.price).toFixed(2)}</b>
          <span>Stock {product.stock}</span>
        </div>
        <div className="rating-row">
          <span>{"★".repeat(rating)}{"☆".repeat(5 - rating)}</span>
          <small>({reviews})</small>
        </div>
        <button type="button" onClick={() => onAddToCart(product)}>
          Add to Cart
        </button>
      </div>
    </article>
  );
}

export default ProductCard;
