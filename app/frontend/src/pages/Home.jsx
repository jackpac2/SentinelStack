import Hero from "../components/Hero";
import FeatureStrip from "../components/FeatureStrip";
import CategoryCard from "../components/CategoryCard";
import ProductCard from "../components/ProductCard";

const categories = [
  { label: "Electronics", image: "/images/categories/electronics.png" },
  { label: "Fashion", image: "/images/categories/fashion.png" },
  { label: "Home & Living", image: "/images/categories/home-living.png" },
  { label: "Beauty", image: "/images/categories/beauty.png" },
  { label: "Sports", image: "/images/categories/sports.png" },
  { label: "Toys & Games", image: "/images/categories/toys-games.png" },
  { label: "Office", image: "/images/categories/office.png" },
  { label: "Automotive", image: "/images/categories/automotive.png" }
];

function Home({ products, loading, error, onAddToCart, onNavigate }) {
  return (
    <>
      <Hero onShopNow={() => onNavigate("products", "categories")} />
      <FeatureStrip />

      <section className="content-section">
        <div className="section-heading">
          <h2>Shop by Category</h2>
          <button type="button" onClick={() => onNavigate("products", "categories")}>
            View all categories
          </button>
        </div>
        <div className="category-grid">
          {categories.map((category) => (
            <CategoryCard
              image={category.image}
              label={category.label}
              key={category.label}
            />
          ))}
        </div>
      </section>

      <section className="content-section">
        <div className="section-heading">
          <h2>Featured Products</h2>
          <button type="button" onClick={() => onNavigate("products", "categories")}>
            View all products
          </button>
        </div>
        {error ? <p className="notice-banner">{error}</p> : null}
        {loading ? <p className="loading-copy">Loading live products...</p> : null}
        <div className="product-grid">
          {products.slice(0, 6).map((product) => (
            <ProductCard product={product} onAddToCart={onAddToCart} key={product.id} />
          ))}
        </div>
      </section>
    </>
  );
}

export default Home;
