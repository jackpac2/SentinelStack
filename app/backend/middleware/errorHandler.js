const errorHandler = (error, req, res, next) => {
  const statusCode = error.statusCode || 500;

  console.error(`${req.method} ${req.originalUrl} failed:`, error.message);

  res.status(statusCode).json({
    status: "error",
    message: error.message || "Internal Server Error"
  });
};

module.exports = errorHandler;
