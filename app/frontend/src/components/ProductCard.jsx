function ProductCard({ product, onAddToCart }) {
  const rating = Number(product.rating || 0);
  const reviewCount = Number(product.reviewCount || 0);
  const roundedRating = Math.max(0, Math.min(5, Math.round(rating)));
  const imageUrl = product.imageUrl || "";
  const showImage =
    typeof imageUrl === "string" && imageUrl.trim().length > 0;
  const resolvedImageUrl =
    imageUrl.startsWith("http") ||
    imageUrl.startsWith("/") ||
    imageUrl.startsWith("data:")
      ? imageUrl
      : `/images/products/${imageUrl}.png`;

  return (
    <article className="product-card">
      <div className="product-visual">
        <span className="favorite">Heart</span>
        {showImage ? (
          <img src={resolvedImageUrl} alt={product.name} />
        ) : (
          <span className="product-art">{product.name.split(" ")[0]}</span>
        )}
      </div>
      <div className="product-body">
        <span className="category-pill">{product.category}</span>
        <strong>{product.name}</strong>
        <p>{product.description}</p>
        <div className="price-row">
          <b>${Number(product.price).toFixed(2)}</b>
          <span>Stock {product.stock}</span>
        </div>
        <div className="rating-row">
          <span>{"*".repeat(roundedRating)}{"-".repeat(5 - roundedRating)}</span>
          <small>{rating.toFixed(1)} ({reviewCount})</small>
        </div>
        <button type="button" onClick={() => onAddToCart(product)}>
          Add to Cart
        </button>
      </div>
    </article>
  );
}

export default ProductCard;
