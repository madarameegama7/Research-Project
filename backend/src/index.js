require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const morgan = require("morgan");
const connectDB = require("./config/db");
const userRoutes = require("./routes/user.routes");
const farmRoutes = require("./routes/farm.routes");
const farmDiaryRoutes = require("./routes/farm_diary.routes");
const marketRoutes = require("./routes/market.routes");
const exportDetailsByCountryRoutes = require("./routes/market_forecast/export_details_by_country.routes");
const pastExportPriceRoutes = require("./routes/market_forecast/past_export_price.routes");
const actualPriceDataRoutes = require("./routes/market_forecast/actual_price_data.routes");
const certificationRoutes = require("./routes/certification.routes");
const qualityCheckRoutes = require("./routes/quality_grading/qualityCheck.routes");

connectDB();
require("./config/firebaseAdmin");

const app = express();
app.use(helmet.crossOriginResourcePolicy({ policy: "cross-origin" }));
app.use(cors());
app.use(express.json());
app.use(morgan("dev"));

const limiter = rateLimit({ windowMs: 1 * 60 * 1000, max: 100 }); // simple rate limit
app.use(limiter);

app.use("/api/users", userRoutes);
app.use("/api/farm", farmRoutes);
app.use("/api/farm-diary", farmDiaryRoutes);
app.use("/api/market", marketRoutes);
app.use("/api/certifications", certificationRoutes);

// Routes for Market Forecast
app.use(
  "/api/market-forecast/export-details-by-country",
  exportDetailsByCountryRoutes,
);
app.use("/api/market-forecast/past-export-prices", pastExportPriceRoutes);
app.use("/api/market-forecast/actual-price-data", actualPriceDataRoutes);

// Routes for Quality Grading
app.use("/api/quality-checks", qualityCheckRoutes);

// app.listen(process.env.PORT || 5000, () => console.log("Server started"));
app.listen(process.env.PORT || 5000, "0.0.0.0", () =>
  console.log("Server started"),
);
