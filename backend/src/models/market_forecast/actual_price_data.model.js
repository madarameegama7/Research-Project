const mongoose = require("mongoose");

const statusBlockSchema = new mongoose.Schema(
  {
    index: { type: Number, required: true },
    status: { type: String, required: true }, // BATCH_CREATED, MARKETPLACE_LISTED, VERIFIED, RECEIVED
    timestamp: { type: Date, required: true },
    actorId: { type: String, required: true }, // user/admin/exporter
    actorRole: { type: String, required: true }, // "USER" | "ADMIN" | "EXPORTER"
    prevHash: { type: String, required: true },
    hash: { type: String, required: true },
  },
  { _id: false },
);

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

    // Current status for UI quick display
    currentStatus: { type: String, index: true },

    // Blockchain history
    statusHistory: { type: [statusBlockSchema], default: [] },
  },
  { timestamps: true },
);

module.exports = mongoose.model(
  "ActualPriceData",
  actualPriceDataSchema,
  "actual_price_data",
);
