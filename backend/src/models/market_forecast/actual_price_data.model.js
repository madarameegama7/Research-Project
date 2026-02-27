const mongoose = require("mongoose");

const actualPriceDataSchema = new mongoose.Schema(
  {
    userId: { type: String, required: true, index: true },
    saleDate: { type: Date, required: true, index: true },
    pepperType: { type: String, required: true, index: true },
    batchId: { type: String, index: true },
    grade: { type: String, index: true },
    district: { type: String, index: true },
    pricePerKg: { type: Number, required: true },
    quantity: { type: Number, required: true },
    notes: { type: String },
    marketplaceProductId: { type: String },
    currentStatus: { type: String, index: true },
  },
  { timestamps: true },
);

module.exports = mongoose.model(
  "ActualPriceData",
  actualPriceDataSchema,
  "actual_price_data",
);
