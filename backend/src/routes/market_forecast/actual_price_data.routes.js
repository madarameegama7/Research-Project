const express = require("express");
const verifyToken = require("../../middleware/auth.middleware");
const {
  getActualPriceData,
  createActualPriceData,
  updateActualPriceData,
  deleteActualPriceData,
} = require("../../controllers/market_forecast/actual_price_data.controller");

const router = express.Router();

router.get("/", verifyToken, getActualPriceData);
router.post("/", verifyToken, createActualPriceData);
router.put("/:id", verifyToken, updateActualPriceData);
router.delete("/:id", verifyToken, deleteActualPriceData);

module.exports = router;
