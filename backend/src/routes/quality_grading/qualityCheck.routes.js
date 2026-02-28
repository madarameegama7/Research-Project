const router = require("express").Router();
const auth = require("../../middleware/auth.middleware");
const {
  uploadQualityImages,
} = require("../../middleware/quality_grading/qualityUpload.middleware");

const {
  createQualityCheck,
  updateDensity,
  analyzeQualityImages,
  getMyQualityChecks,
  getQualityCheckById,
  getQualityChecksByBatch,
  getDashboardStats,
} = require("../../controllers/quality_grading/qualityCheck.controller");

const {
  getReport,
  getPdfReport,
} = require("../../controllers/quality_grading/qualityReport.controller");

// Step 1: batch information
router.post("/", auth, createQualityCheck);

// Get quality checks for current user - Added by Ashika
router.get("/batchdetails", auth, getMyQualityChecks);

router.get("/dashboard-stats", auth, getDashboardStats);

router.get("/:id", auth, getQualityCheckById);

// Step 2: IoT density
router.put("/:id/density", auth, updateDensity);

// Step 3: upload images + AI + grade
router.post("/:id/analyze", auth, uploadQualityImages, analyzeQualityImages);

// Step 4: view report (JSON)
router.get("/:id/report", auth, getReport);

// Step 4b: download PDF
router.get("/:id/report/pdf", auth, getPdfReport);

// Fetch quality checks by batchId (no auth) - Added by Ashika
router.get("/batch/:batchId", getQualityChecksByBatch);

module.exports = router;
