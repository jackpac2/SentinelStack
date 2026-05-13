function StatusCard({ title, tone = "neutral", children }) {
  return (
    <article className={`status-card ${tone}`}>
      <p className="eyebrow">{title}</p>
      <div>{children}</div>
    </article>
  );
}

export default StatusCard;
