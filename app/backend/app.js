const express = require("express");
const cors = require("cors");

const healthRoutes = require("./routes/health.routes");
const productRoutes = require("./routes/product.routes");
const orderRoutes = require("./routes/order.routes");
const testRoutes = require("./routes/test.routes");
const metricsRoutes = require("./routes/metrics.routes");
const requestLogger = require("./middleware/requestLogger");
const metricsMiddleware = require("./middleware/metricsMiddleware");
const notFoundHandler = require("./middleware/notFoundHandler");
const errorHandler = require("./middleware/errorHandler");

const app = express();

app.use(cors());
app.use(express.json());
app.use(requestLogger);
app.use(metricsMiddleware);

app.use(healthRoutes);
app.use(productRoutes);
app.use(orderRoutes);
app.use(testRoutes);
app.use(metricsRoutes);

app.use(notFoundHandler);
app.use(errorHandler);

module.exports = app;
