const axios = require("axios");
const FormData = require("form-data");

const QualityCheck = require("../../models/quality_grading/qualityCheck.model");
const User = require("../../models/user.models");
const {
  EXPECTED_FIELDS,
} = require("../../middleware/quality_grading/qualityUpload.middleware");
const Certification = require("../../models/certification.models");
const { gradeBatch } = require("./gradingEngine");

// ─── Helpers ─────────────────────────────────────────────────────

/** Convert kg + g fields to total grams. Returns null on invalid input. */
const toGrams = (kg, g) => {
  const kgNum = Number(kg || 0);
  const gNum = Number(g || 0);
  if (Number.isNaN(kgNum) || Number.isNaN(gNum)) return null;
  const total = Math.round(kgNum * 1000 + gNum);
  return total > 0 ? total : null;
};

/** Generate the next sequential batch ID (e.g. "BATCH-0042"). */
const generateBatchId = async () => {
  const last = await QualityCheck.findOne()
    .sort({ createdAt: -1 })
    .select("batchId");

  if (!last) return "BATCH-0001";

  const lastNumber = parseInt(last.batchId.split("-")[1], 10);
  const nextNumber = lastNumber + 1;
  return `BATCH-${nextNumber.toString().padStart(4, "0")}`;
};

/** Midnight of today (used to filter non-expired certificates). */
const startOfToday = () => {
  const now = new Date();
  return new Date(now.getFullYear(), now.getMonth(), now.getDate());
};

/**
 * Find the MongoDB user by Firebase UID.
 * Supports both 'firebaseUid' and 'uid' field names for safety.
 */
const findUserByFirebaseUid = async (firebaseUid) => {
  return (
    (await User.findOne({ firebaseUid })) ||
    (await User.findOne({ uid: firebaseUid })) ||
    null
  );
};

// ─── Step 1: Create quality check (Batch Information) ────────────

exports.createQualityCheck = async (req, res) => {
  try {
    const firebaseUid = req.user?.uid;
    if (!firebaseUid) {
      return res.status(401).json({ message: "Unauthorized (missing uid)" });
    }

    const dbUser = await findUserByFirebaseUid(firebaseUid);
    if (!dbUser) {
      return res
        .status(404)
        .json({ message: "User not found in DB for this Firebase account" });
    }

    const {
      pepperType,
      pepperVariety,
      harvestDate,
      dryingMethod,
      batchWeightKg,
      batchWeightG,
    } = req.body;

    const batchWeightGrams = toGrams(batchWeightKg, batchWeightG);
    if (!batchWeightGrams) {
      return res.status(400).json({ message: "Invalid batch weight" });
    }

    const harvest = new Date(harvestDate);
    if (Number.isNaN(harvest.getTime())) {
      return res.status(400).json({ message: "Invalid harvest date" });
    }

    const batchId = await generateBatchId();

    const qc = await QualityCheck.create({
      batchId,
      userId: dbUser._id,
      firebaseUid,
      status: "waiting_density",
      batch: {
        pepperType,
        pepperVariety,
        harvestDate: harvest,
        dryingMethod,
        batchWeightGrams,
      },
      density: {
        value: null,
        source: "bluetooth",
        measuredAt: null,
      },
    });

    return res.status(201).json({
      qualityCheckId: qc._id,
      batchId: qc.batchId,
      status: qc.status,
    });
  } catch (err) {
    console.error("createQualityCheck error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ─── Step 2: Update density (from IoT Bluetooth reading) ─────────

exports.updateDensity = async (req, res) => {
  try {
    const firebaseUid = req.user?.uid;
    if (!firebaseUid) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const dbUser = await findUserByFirebaseUid(firebaseUid);
    if (!dbUser) {
      return res.status(404).json({ message: "User not found in DB" });
    }

    const { id } = req.params;
    const { value } = req.body;

    const densityValue = Number(value);
    if (Number.isNaN(densityValue) || densityValue <= 0) {
      return res.status(400).json({ message: "Invalid density value" });
    }

    const qc = await QualityCheck.findOneAndUpdate(
      { _id: id, userId: dbUser._id },
      {
        $set: {
          "density.value": densityValue,
          "density.source": "bluetooth",
          "density.measuredAt": new Date(),
          status: "waiting_images",
        },
      },
      { new: true },
    );

    if (!qc) {
      return res.status(404).json({ message: "Quality check not found" });
    }

    return res.status(200).json({
      qualityCheckId: qc._id,
      status: qc.status,
      density: qc.density,
    });
  } catch (err) {
    console.error("updateDensity error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ─── Step 3: Analyse images + compute grade ───────────────────────

exports.analyzeQualityImages = async (req, res) => {
  const { id } = req.params;

  try {
    const firebaseUid = req.user?.uid;
    if (!firebaseUid) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const dbUser = await findUserByFirebaseUid(firebaseUid);
    if (!dbUser) {
      return res.status(404).json({ message: "User not found in DB" });
    }

    // Load the quality check document
    const qc = await QualityCheck.findOne({ _id: id, userId: dbUser._id });
    if (!qc) {
      return res.status(404).json({ message: "Quality check not found" });
    }

    // Density must exist before images can be analysed
    if (!qc.density?.value) {
      return res
        .status(400)
        .json({ message: "Density not recorded. Complete Step 2 first." });
    }

    // Validate that all 9 required image fields are present
    const files = req.files || {};
    const missing = EXPECTED_FIELDS.filter(
      (k) => !files[k] || files[k].length === 0,
    );
    if (missing.length > 0) {
      return res.status(400).json({
        message: "Missing required images",
        missing,
      });
    }

    // Mark as processing so the client can show a spinner
    qc.status = "processing";
    await qc.save();

    // ── Build multipart form for FastAPI ──
    const form = new FormData();
    for (const field of EXPECTED_FIELDS) {
      const f = files[field][0];
      form.append(field, f.buffer, {
        filename: f.originalname || `${field}.jpg`,
        contentType: f.mimetype || "image/jpeg",
      });
    }
    form.append("texture_first", "true");

    // ── Call FastAPI inference endpoint ──
    let fastapiResponse;
    try {
      fastapiResponse = await axios.post(
        `${process.env.FASTAPI_BASE_URL}/infer/quality`,
        form,
        {
          headers: { ...form.getHeaders() },
          maxBodyLength: Infinity,
          maxContentLength: Infinity,
          timeout: 120_000, // 2 minutes
        },
      );
    } catch (fastapiErr) {
      // FastAPI call itself failed — mark as failed and return 502
      qc.status = "failed";
      await qc.save();
      console.error(
        "analyzeQualityImages — FastAPI error:",
        fastapiErr?.response?.data || fastapiErr.message,
      );
      return res.status(502).json({
        message: "AI inference service error",
        error: fastapiErr.message,
        fastapiStatus: fastapiErr.response?.status,
        fastapiData: fastapiErr.response?.data,
      });
    }

    // Validate FastAPI response
    const finalAvg = fastapiResponse.data?.final;
    if (!finalAvg) {
      qc.status = "failed";
      await qc.save();
      return res
        .status(502)
        .json({ message: "FastAPI response missing 'final' results" });
    }

    // ── Map FastAPI field names → Mongo field names ──
    const mappedFactors = {
      adulterantPct: Number(finalAvg.adulterant_seed_pct ?? 0),
      extraneousPct: Number(finalAvg.extraneous_matter_pct ?? 0),
      moldPct: Number(finalAvg.mold_pct ?? 0),
      abnormalTexturePct: Number(finalAvg.abnormal_texture_pct ?? 0),
      healthyVisualPct: Number(finalAvg.healthy_visual_pct ?? 0),
    };

    // ── Capture certificate snapshot at grading time ──
    // Only verified certs that have not yet expired count.
    const today = startOfToday();
    const certs = await Certification.find({
      firebaseUid,
      status: "verified",
      expiryDate: { $gte: today },
    })
      .sort({ createdAt: -1 })
      .select(
        "certificationType certificateNumber issuingBody issueDate expiryDate attachment",
      );

    qc.certificatesSnapshot = {
      items: certs.map((c) => ({
        certId: c._id,
        certificationType: c.certificationType,
        certificateNumber: c.certificateNumber,
        issuingBody: c.issuingBody,
        issueDate: c.issueDate,
        expiryDate: c.expiryDate,
        attachmentUrl: c.attachment?.url || null,
      })),
      count: certs.length,
      capturedAt: new Date(),
    };

    // ── Run grading engine ──
    const grading = gradeBatch({
      pepperType: qc.batch.pepperType,
      pepperVariety: qc.batch.pepperVariety,
      density: qc.density.value,
      factors: mappedFactors,
      certSnapshotCount: qc.certificatesSnapshot.count,
    });

    // ── Persist results ──
    qc.results = {
      overallScore: grading.overallScore,
      grade: grading.grade,
      factorScores: grading.factorScores,
      hardReject: grading.hardReject,
      hardRejectReasons: grading.hardRejectReasons,
      factors: mappedFactors,
      improvements: grading.improvements,
      processedAt: new Date(),
    };
    qc.status = "completed";
    await qc.save();

    return res.status(200).json({
      qualityCheckId: qc._id,
      batchId: qc.batchId,
      status: qc.status,
      overallScore: qc.results.overallScore,
      grade: qc.results.grade,
      hardReject: qc.results.hardReject,
      hardRejectReasons: qc.results.hardRejectReasons,
      factorScores: qc.results.factorScores,
      factors: qc.results.factors,
      certificatesSnapshot: qc.certificatesSnapshot,
      improvements: qc.results.improvements,
      meta: grading.meta,
    });
  } catch (err) {
    // ── Outer catch: any unhandled error ──
    // Mark the quality check as failed so the client knows to retry.
    console.error(
      "analyzeQualityImages — unhandled error:",
      err?.response?.data || err.message,
    );
    try {
      if (id) {
        await QualityCheck.findByIdAndUpdate(id, { status: "failed" });
      }
    } catch (markFailedErr) {
      console.error(
        "analyzeQualityImages — could not mark as failed:",
        markFailedErr.message,
      );
    }

    return res.status(500).json({
      message: "Server error during image analysis",
      error: err.message,
    });
  }
};

// Get quality checks for the authenticated user - Added by Ashika
exports.getMyQualityChecks = async (req, res) => {
  try {
    const firebaseUid = req.user?.uid;
    if (!firebaseUid) return res.status(401).json({ message: "Unauthorized" });

    const dbUser =
      (await User.findOne({ firebaseUid })) ||
      (await User.findOne({ uid: firebaseUid }));

    if (!dbUser)
      return res.status(404).json({ message: "User not found in DB" });

    const checks = await QualityCheck.find({ userId: dbUser._id }).select(
      "batchId batch results.grade",
    );

    const payload = checks.map((c) => ({
      _id: c._id,
      batchId: c.batchId,
      batch: c.batch,
      grade: c.results?.grade ?? null,
    }));

    return res.status(200).json(payload);
  } catch (err) {
    console.error(err && err.stack ? err.stack : err);
    return res
      .status(500)
      .json({ message: "Server error", error: err?.message });
  }
};

// GET /api/quality-checks/:id  — fetch a single quality check by ID
exports.getQualityCheckById = async (req, res) => {
  try {
    const firebaseUid = req.user?.uid;
    if (!firebaseUid) {
      return res.status(401).json({ message: "Unauthorized" });
    }

    const dbUser = await findUserByFirebaseUid(firebaseUid);
    if (!dbUser) {
      return res.status(404).json({ message: "User not found in DB" });
    }

    const qc = await QualityCheck.findOne({
      _id: req.params.id,
      userId: dbUser._id,
    });

    if (!qc) {
      return res.status(404).json({ message: "Quality check not found" });
    }

    return res.status(200).json({
      qualityCheckId: qc._id,
      batchId: qc.batchId,
      status: qc.status,
      createdAt: qc.createdAt,
      batch: qc.batch,
      density: qc.density,
      certificatesSnapshot: qc.certificatesSnapshot,
      results: qc.results,
    });
  } catch (err) {
    console.error("getQualityCheckById error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// Get quality checks by batchId (no auth required) - Added by Ashika
exports.getQualityChecksByBatch = async (req, res) => {
  try {
    const batchId = (req.params.batchId || req.query.batchId || "")
      .toString()
      .trim();
    if (!batchId) {
      return res.status(400).json({ message: "Missing batchId" });
    }

    const checks = await QualityCheck.find({ batchId }).select(
      "batchId batch results density certificatesSnapshot createdAt updatedAt status",
    );

    if (!checks || checks.length === 0) {
      return res
        .status(404)
        .json({ message: "No quality checks found for batchId" });
    }

    const payload = checks.map((c) => ({
      _id: c._id,
      batchId: c.batchId,
      batch: c.batch,
      grade: c.results?.grade ?? null,
      results: c.results ?? null,
      density: c.density ?? null,
      certificatesSnapshot: c.certificatesSnapshot ?? null,
      status: c.status,
      createdAt: c.createdAt,
      updatedAt: c.updatedAt,
    }));

    return res.status(200).json(payload);
  } catch (err) {
    console.error(
      "getQualityChecksByBatch error:",
      err && err.stack ? err.stack : err,
    );
    return res
      .status(500)
      .json({ message: "Server error", error: err?.message });
  }
};

// GET /api/quality-checks/dashboard-stats
// Returns: { totalReports, premiumGrades }
exports.getDashboardStats = async (req, res) => {
  try {
    const firebaseUid = req.user?.uid;
    if (!firebaseUid) return res.status(401).json({ message: "Unauthorized" });

    const dbUser = await findUserByFirebaseUid(firebaseUid);
    if (!dbUser)
      return res.status(404).json({ message: "User not found in DB" });

    const totalReports = await QualityCheck.countDocuments({
      userId: dbUser._id,
      status: "completed",
    });

    const premiumGrades = await QualityCheck.countDocuments({
      userId: dbUser._id,
      status: "completed",
      "results.grade": "Grade 1 - Premium",
    });

    return res.status(200).json({ totalReports, premiumGrades });
  } catch (err) {
    console.error("getDashboardStats error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// POST /api/quality-checks/validate-image  — validate a single image (used in Step 3 before final submission)
exports.validateQualityImage = async (req, res) => {
  try {
    const firebaseUid = req.user?.uid;
    if (!firebaseUid) return res.status(401).json({ message: "Unauthorized" });

    const file = req.file;
    if (!file) return res.status(400).json({ message: "Missing image" });

    const FormData = require("form-data");
    const axios = require("axios");

    const form = new FormData();
    form.append("file", file.buffer, {
      filename: file.originalname || "image.jpg",
      contentType: file.mimetype || "image/jpeg",
    });

    const fastapiRes = await axios.post(
      `${process.env.FASTAPI_BASE_URL}/infer/validate`,
      form,
      { headers: { ...form.getHeaders() }, timeout: 30_000 },
    );

    return res.status(200).json(fastapiRes.data);
  } catch (err) {
    // If FastAPI returned 400 with our "not pepper" reason
    const status = err?.response?.status || 500;
    const data = err?.response?.data;

    if (status === 400) {
      return res.status(400).json({
        message: data?.detail || "Invalid pepper image",
      });
    }

    return res.status(500).json({
      message: "Validation service error",
      error: err.message,
    });
  }
};
