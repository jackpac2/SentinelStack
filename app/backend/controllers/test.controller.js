const getSlowResponse = async (req, res) => {
  const delayMs = Math.floor(Math.random() * 3001) + 2000;

  await new Promise((resolve) => {
    setTimeout(resolve, delayMs);
  });

  res.json({
    message: "Slow response completed.",
    delayMs
  });
};

const getIntentionalError = (req, res, next) => {
  const error = new Error("Intentional test error for observability validation.");
  error.statusCode = 500;
  next(error);
};

module.exports = {
  getSlowResponse,
  getIntentionalError
};
