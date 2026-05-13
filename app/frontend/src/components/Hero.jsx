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
        <img
          src="/images/hero/cloudstore-hero.png"
          alt=""
          loading="eager"
        />
      </div>
    </section>
  );
}

export default Hero;
