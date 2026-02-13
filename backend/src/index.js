require("dotenv").config();
const express = require("express");
const cors = require("cors");
const helmet = require("helmet");
const rateLimit = require("express-rate-limit");
const morgan = require("morgan");
const connectDB = require("./config/db");
const userRoutes = require("./routes/user.routes");
const farmRoutes = require("./routes/farm.routes");
const marketRoutes = require("./routes/market.routes");

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
app.use("/api/market", marketRoutes);

// app.listen(process.env.PORT || 5000, () => console.log("Server started"));
app.listen(process.env.PORT || 5000, '0.0.0.0', () => console.log("Server started"));

