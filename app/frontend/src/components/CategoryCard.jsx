function CategoryCard({ image, label }) {
  return (
    <article className="category-card">
      {image ? (
        <img src={image} alt="" loading="lazy" />
      ) : (
        <span>{label.slice(0, 2)}</span>
      )}
      <strong>{label}</strong>
    </article>
  );
}

export default CategoryCard;
