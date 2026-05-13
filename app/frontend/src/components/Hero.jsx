function Hero({ onShopNow }) {
  return (
    <section className="hero-banner">
      <div className="hero-copy">
        <p className="eyebrow">CloudStore collection</p>
        <h1>Elevate your everyday</h1>
        <p>Discover products that make life simpler.</p>
        <button type="button" onClick={onShopNow}>
          Shop Now
        </button>
      </div>

      <div className="hero-scene" aria-hidden="true">
        <span className="cloud puff-one" />
        <span className="cloud puff-two" />
        <span className="device laptop">
          <i />
        </span>
        <span className="device headset" />
        <span className="device speaker">
          <i />
        </span>
        <span className="device watch" />
      </div>
    </section>
  );
}

export default Hero;
