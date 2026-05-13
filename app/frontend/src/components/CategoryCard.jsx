function CategoryCard({ icon, label }) {
  return (
    <article className="category-card">
      <span>{icon}</span>
      <strong>{label}</strong>
    </article>
  );
}

export default CategoryCard;
