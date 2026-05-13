const features = [
  ["Cloud", "Free Shipping", "On orders over $50"],
  ["Lock", "Secure Payments", "100% secure checkout"],
  ["Back", "Easy Returns", "30-day return policy"],
  ["Help", "24/7 Support", "We are here to help"]
];

function FeatureStrip() {
  return (
    <section className="feature-strip">
      {features.map(([icon, title, copy]) => (
        <article className="feature-item" key={title}>
          <span>{icon}</span>
          <div>
            <strong>{title}</strong>
            <p>{copy}</p>
          </div>
        </article>
      ))}
    </section>
  );
}

export default FeatureStrip;
