const crypto = require("crypto");
const ActualPriceData = require("../../models/market_forecast/actual_price_data.model");
const User = require("../../models/user.models");

// Statuses
const STATUSES = {
  BATCH_CREATED: "BATCH_CREATED",
  MARKETPLACE_LISTED: "MARKETPLACE_LISTED",
  VERIFIED: "VERIFIED",
  RECEIVED: "RECEIVED",
};

// Roles
const ROLES = {
  FARMER: "FARMER",
  ADMIN: "ADMIN",
  EXPORTER: "EXPORTER",
};

// Normalize status to ensure consistent comparisons (e.g. "verified" -> "VERIFIED")
function normalizeStatus(s) {
  if (!s) return "";
  return String(s).trim().replaceAll(" ", "_").toUpperCase();
}

// For any role string, default to FARMER if not recognized
function normalizeRole(r) {
  if (!r) return ROLES.FARMER;
  return String(r).trim().toUpperCase();
}

// Simple SHA-256 hashing function for block integrity
function sha256(input) {
  return crypto.createHash("sha256").update(input).digest("hex");
}

// Get actor id and role
function getActor(req) {
  const actorId = req.user?.uid;
  const actorRole = normalizeRole(req.user?.role);
  return { actorId, actorRole };
}

// Create a new block for the status change
function makeBlock({
  recordId,
  nextIndex,
  status,
  actorId,
  actorRole,
  prevHash,
}) {
  const timestamp = new Date();

  const payload = JSON.stringify({
    recordId: String(recordId),
    index: nextIndex,
    status,
    timestamp: timestamp.toISOString(),
    actorId,
    actorRole,
    prevHash,
  });

  const hash = sha256(payload);

  return {
    index: nextIndex,
    status,
    timestamp,
    actorId,
    actorRole,
    prevHash,
    hash,
  };
}

// Append a new status block to the record's history and update current status
function appendStatusBlock(record, newStatus, actorId, actorRole) {
  const history = record.statusHistory || [];
  const prev = history.length ? history[history.length - 1] : null;

  const nextIndex = history.length + 1;
  const prevHash = prev ? prev.hash : "GENESIS";

  const block = makeBlock({
    recordId: record._id,
    nextIndex,
    status: newStatus,
    actorId,
    actorRole,
    prevHash,
  });

  record.statusHistory = [...history, block];
  record.currentStatus = newStatus;
}

// Check if a transition is allowed
function canTransition({ fromStatus, toStatus, actorRole }) {
  if (!fromStatus) return toStatus === STATUSES.BATCH_CREATED;
  if (fromStatus === STATUSES.RECEIVED) return false;

  if (
    fromStatus === STATUSES.BATCH_CREATED &&
    toStatus === STATUSES.MARKETPLACE_LISTED
  ) {
    return actorRole === ROLES.FARMER;
  }

  if (
    (fromStatus === STATUSES.BATCH_CREATED ||
      fromStatus === STATUSES.MARKETPLACE_LISTED) &&
    toStatus === STATUSES.VERIFIED
  ) {
    return actorRole === ROLES.ADMIN;
  }

  if (fromStatus === STATUSES.VERIFIED && toStatus === STATUSES.RECEIVED) {
    return actorRole === ROLES.EXPORTER || actorRole === ROLES.ADMIN;
  }

  return false;
}

// Check if a status is approved or locked
function isApprovedLocked(status) {
  const s = normalizeStatus(status);
  return s === STATUSES.VERIFIED || s === STATUSES.RECEIVED;
}

// Check if the record belongs to the actor
function isOwner(record, actorId) {
  // Handles ObjectId or string
  return String(record.userId) === String(actorId);
}

// -------------------- Controllers --------------------

// Get records
// FARMER can get only their own records
// ADMIN can get all records
const getActualPriceData = async (req, res) => {
  try {
    const { pepperType, grade, district, limit } = req.query;
    const filter = {};
    const firebaseUid = req.user?.uid;

    if (!firebaseUid) {
      return res.status(401).json({ message: "No user id" });
    }

    // Fetch user role from users collection
    const user = await User.findOne({ firebaseUid });
    const userRole = user?.role || "farmer";

    // Only 'admin' can view all records, others see their own
    if (userRole !== "admin") {
      filter.userId = firebaseUid;
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

    // Attach farmer name from users collection
    if (records && records.length) {
      const uids = Array.from(
        new Set(records.map((r) => r.userId).filter(Boolean)),
      );
      if (uids.length) {
        try {
          const users = await User.find({ firebaseUid: { $in: uids } }).lean();
          const userMap = {};
          users.forEach((u) => {
            const name = `${u.firstName || ""} ${u.lastName || ""}`.trim();
            userMap[u.firebaseUid] = name || u.email || "";
          });

          // mutate records (they are plain objects due to .lean())
          records.forEach((rec) => {
            rec.farmerName = userMap[rec.userId] || "";
          });
        } catch (e) {
          console.error("Failed to lookup users for actual price records:", e);
        }
      }
    }

    return res.json(records);
  } catch (err) {
    console.error("Error fetching data:", err);
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

// Create record (Block #1)
const createActualPriceData = async (req, res) => {
  try {
    const { actorId, actorRole } = getActor(req);
    if (!actorId) return res.status(401).json({ message: "No user id" });

    const {
      saleDate,
      pepperType,
      grade,
      district,
      pricePerKg,
      quantity,
      notes,
      batchId,
    } = req.body;

    const parsedDate = new Date(saleDate);
    if (Number.isNaN(parsedDate.getTime())) {
      return res.status(400).json({ message: "Invalid saleDate" });
    }

    const parsedPrice = Number(pricePerKg);
    const parsedQuantity = Number(quantity);

    if (!Number.isFinite(parsedPrice) || !Number.isFinite(parsedQuantity)) {
      return res.status(400).json({ message: "Invalid numeric fields" });
    }

    const record = new ActualPriceData({
      userId: actorId,
      saleDate: parsedDate,
      pepperType,
      grade: grade || undefined,
      district: district || undefined,
      pricePerKg: parsedPrice,
      quantity: parsedQuantity,
      notes: notes || undefined,
      batchId: batchId || undefined,
      currentStatus: STATUSES.BATCH_CREATED,
      statusHistory: [],
    });

    // Block 1 created by the acting user (use actorRole from token/user)
    appendStatusBlock(record, STATUSES.BATCH_CREATED, actorId, actorRole);

    await record.save();
    return res.status(201).json(record);
  } catch (err) {
    console.error("Error while saving data:", err);
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

// Update record
const updateActualPriceData = async (req, res) => {
  try {
    const { actorId, actorRole } = getActor(req);
    if (!actorId) return res.status(401).json({ message: "No user id" });

    const { id } = req.params;

    const record = await ActualPriceData.findById(id);
    if (!record) return res.status(404).json({ message: "Record not found" });

    const owner = isOwner(record, actorId);

    const existingStatus = normalizeStatus(record.currentStatus);
    const incomingStatus = normalizeStatus(req.body.currentStatus);
    const wantsStatusChange = Boolean(incomingStatus);

    // Field updates by FARMER only if owner + not locked
    if (!wantsStatusChange) {
      if (actorRole === ROLES.USER && !owner) {
        return res.status(403).json({ message: "Not authorized" });
      }
      if (actorRole === ROLES.USER && isApprovedLocked(existingStatus)) {
        return res
          .status(400)
          .json({ message: "Record is locked after verification" });
      }
    }

    // Status change path (admin/exporter can do even if not owner)
    if (wantsStatusChange) {
      if (actorRole === ROLES.FARMER && !owner) {
        return res.status(403).json({ message: "Not authorized" });
      }

      const ok = canTransition({
        fromStatus: existingStatus,
        toStatus: incomingStatus,
        actorRole,
      });

      if (!ok) {
        return res.status(400).json({
          message: `Invalid status transition: ${existingStatus} -> ${incomingStatus} for role ${actorRole}`,
        });
      }

      appendStatusBlock(record, incomingStatus, actorId, actorRole);
      await record.save();
      return res.json(record);
    }

    // Normal field updates
    const {
      saleDate,
      pepperType,
      grade,
      district,
      pricePerKg,
      quantity,
      notes,
      batchId,
    } = req.body;

    if (saleDate !== undefined) {
      const parsedDate = new Date(saleDate);
      if (Number.isNaN(parsedDate.getTime())) {
        return res.status(400).json({ message: "Invalid saleDate" });
      }
      record.saleDate = parsedDate;
    }

    if (pepperType !== undefined) record.pepperType = pepperType;
    if (grade !== undefined) record.grade = grade;
    if (district !== undefined) record.district = district;
    if (batchId !== undefined) record.batchId = batchId;

    if (pricePerKg !== undefined) {
      const parsedPrice = Number(pricePerKg);
      if (!Number.isFinite(parsedPrice))
        return res.status(400).json({ message: "Invalid pricePerKg" });
      record.pricePerKg = parsedPrice;
    }

    if (quantity !== undefined) {
      const parsedQuantity = Number(quantity);
      if (!Number.isFinite(parsedQuantity))
        return res.status(400).json({ message: "Invalid quantity" });
      record.quantity = parsedQuantity;
    }

    if (notes !== undefined) record.notes = notes;

    await record.save();
    return res.json(record);
  } catch (err) {
    console.error("Error while updating data:", err);
    return res
      .status(500)
      .json({ message: "Server error", error: err.message });
  }
};

// Delete record
// Farmer can delete only before VERIFIED
const deleteActualPriceData = async (req, res) => {
  try {
    const { actorId, actorRole } = getActor(req);
    if (!actorId) return res.status(401).json({ message: "No user id" });

    const { id } = req.params;

    const record = await ActualPriceData.findById(id);
    if (!record) return res.status(404).json({ message: "Record not found" });

    const owner = isOwner(record, actorId);

    // Owner can delete
    if (!owner) {
      return res
        .status(403)
        .json({ message: "Not authorized to delete this record" });
    }

    const existingStatus = normalizeStatus(record.currentStatus);
    if (isApprovedLocked(existingStatus)) {
      return res
        .status(400)
        .json({ message: "Cannot delete after verification" });
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
