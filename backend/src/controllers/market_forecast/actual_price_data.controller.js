const ActualPriceData = require("../../models/market_forecast/actual_price_data.model");

// Get all records
const getActualPriceData = async (req, res) => {
  try {
    const { pepperType, grade, district, limit } = req.query;
    const filter = { userId: req.user?.uid };

    if (!filter.userId) {
      return res.status(401).json({ message: "No user id" });
    }

    if (pepperType) filter.pepperType = pepperType;
    if (grade) filter.grade = grade;
    if (district) filter.district = district;

    const query = ActualPriceData.find(filter).sort({ saleDate: -1 }).lean();

    if (limit) {
      const parsedLimit = parseInt(limit, 10);
      if (parsedLimit > 0) query.limit(parsedLimit);
    }

    const records = await query.exec();
    return res.json(records);
  } catch (err) {
    console.error("Error fetching data:", err);
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

// Create a new record
const createActualPriceData = async (req, res) => {
  try {
    if (!req.user?.uid) {
      return res.status(401).json({ message: "No user id" });
    }

    const {
      saleDate,
      pepperType,
      grade,
      district,
      pricePerKg,
      quantity,
      notes,
      batchId,
      currentStatus,
    } = req.body;

    const parsedDate = new Date(saleDate);
    if (Number.isNaN(parsedDate.getTime())) {
      return res.status(400).json({ message: "Invalid saleDate" });
    }

    let parsedPrice;
    let parsedQuantity;
    const invalidNumeric = [];
    if (pricePerKg !== undefined && pricePerKg !== null && pricePerKg !== "") {
      parsedPrice = Number(pricePerKg);
      if (!Number.isFinite(parsedPrice)) invalidNumeric.push("pricePerKg");
    }
    if (quantity !== undefined && quantity !== null && quantity !== "") {
      parsedQuantity = Number(quantity);
      if (!Number.isFinite(parsedQuantity)) invalidNumeric.push("quantity");
    }
    if (invalidNumeric.length > 0) {
      return res.status(400).json({ message: "Invalid numeric fields" });
    }

    // If marketplaceProductId is present, set status to 'N/A', else 'created'
    let statusToSet = "created";
    if (req.body.marketplaceProductId) {
      statusToSet = "N/A";
    } else if (currentStatus) {
      statusToSet = currentStatus;
    }
    const record = new ActualPriceData({
      userId: req.user?.uid,
      saleDate: parsedDate,
      pepperType: pepperType || undefined,
      grade: grade || undefined,
      district: district || undefined,
      pricePerKg: parsedPrice,
      quantity: parsedQuantity,
      notes: notes || undefined,
      batchId: batchId || undefined,
      marketplaceProductId: req.body.marketplaceProductId || undefined,
      currentStatus: statusToSet,
    });

    await record.save();
    return res.status(201).json(record);
  } catch (err) {
    console.error("Error while saving data:", err);
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

// Update an existing record
const updateActualPriceData = async (req, res) => {
  try {
    if (!req.user?.uid) {
      return res.status(401).json({ message: "No user id" });
    }

    const { id } = req.params;
    const {
      saleDate,
      pepperType,
      grade,
      district,
      pricePerKg,
      quantity,
      notes,
      marketplaceProductId,
    } = req.body;

    // Find the record and verify ownership
    const record = await ActualPriceData.findById(id);
    if (!record) {
      return res.status(404).json({ message: "Record not found" });
    }

    if (record.userId !== req.user?.uid) {
      return res
        .status(403)
        .json({ message: "Not authorized to update this record" });
    }

    if (pepperType) record.pepperType = pepperType;
    if (grade !== undefined) record.grade = grade;
    if (district) record.district = district;

    // Validate numeric fields
    const invalidUpdateNumeric = [];
    if (pricePerKg !== undefined) {
      const parsedPrice = Number(pricePerKg);
      if (!Number.isFinite(parsedPrice))
        invalidUpdateNumeric.push("pricePerKg");
      else record.pricePerKg = parsedPrice;
    }
    if (quantity !== undefined) {
      const parsedQuantity = Number(quantity);
      if (!Number.isFinite(parsedQuantity))
        invalidUpdateNumeric.push("quantity");
      else record.quantity = parsedQuantity;
    }
    if (invalidUpdateNumeric.length > 0) {
      return res.status(400).json({ message: "Invalid numeric fields" });
    }

    if (notes !== undefined) record.notes = notes;

    if (marketplaceProductId !== undefined) {
      record.marketplaceProductId = marketplaceProductId;
      // Set status to 'N/A' if marketplaceProductId is present
      record.currentStatus = "N/A";
    }

    await record.save();
    return res.json(record);
  } catch (err) {
    console.error("Error while updating data:", err);
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

// Delete a record
const deleteActualPriceData = async (req, res) => {
  try {
    if (!req.user?.uid) {
      return res.status(401).json({ message: "No user id" });
    }

    const { id } = req.params;

    // Find the record and verify ownership
    const record = await ActualPriceData.findById(id);
    if (!record) {
      return res.status(404).json({ message: "Record not found" });
    }

    if (record.userId !== req.user?.uid) {
      return res
        .status(403)
        .json({ message: "Not authorized to delete this record" });
    }

    await ActualPriceData.findByIdAndDelete(id);
    return res.json({ message: "Record deleted successfully" });
  } catch (err) {
    console.error("Error while deleting data:", err);
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

module.exports = {
  getActualPriceData,
  createActualPriceData,
  updateActualPriceData,
  deleteActualPriceData,
};
