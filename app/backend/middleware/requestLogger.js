const requestLogger = (req, res, next) => {
  const startedAt = process.hrtime.bigint();

  res.on("finish", () => {
    const elapsedMs = Number(process.hrtime.bigint() - startedAt) / 1_000_000;

    console.log(
      `${req.method} ${req.originalUrl} ${res.statusCode} ${elapsedMs.toFixed(2)}ms`
    );
  });

  next();
};

module.exports = requestLogger;
