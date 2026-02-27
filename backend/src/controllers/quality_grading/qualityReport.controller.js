const QualityCheck = require("../../models/quality_grading/qualityCheck.model");
const User = require("../../models/user.models");
const PDFDocument = require("pdfkit");

const findUserByFirebaseUid = async (uid) =>
  (await User.findOne({ firebaseUid: uid })) ||
  (await User.findOne({ uid })) ||
  null;

// ─── GET full report (JSON) ───────────────────────────────────────
// GET /api/quality-checks/:id/report
exports.getReport = async (req, res) => {
  try {
    const firebaseUid = req.user?.uid;
    if (!firebaseUid) return res.status(401).json({ message: "Unauthorized" });

    const dbUser = await findUserByFirebaseUid(firebaseUid);
    if (!dbUser) return res.status(404).json({ message: "User not found" });

    const qc = await QualityCheck.findOne({
      _id: req.params.id,
      userId: dbUser._id,
    });

    if (!qc)
      return res.status(404).json({ message: "Quality check not found" });
    if (qc.status !== "completed")
      return res.status(400).json({
        message: `Report not ready. Current status: ${qc.status}`,
      });

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
    console.error("getReport error:", err);
    return res.status(500).json({ message: "Server error" });
  }
};

// ─── GET PDF report (streamed, no Cloudinary needed) ─────────────
// GET /api/quality-checks/:id/report/pdf
exports.getPdfReport = async (req, res) => {
  try {
    const firebaseUid = req.user?.uid;
    if (!firebaseUid) return res.status(401).json({ message: "Unauthorized" });

    const dbUser = await findUserByFirebaseUid(firebaseUid);
    if (!dbUser) return res.status(404).json({ message: "User not found" });

    const qc = await QualityCheck.findOne({
      _id: req.params.id,
      userId: dbUser._id,
    });

    if (!qc)
      return res.status(404).json({ message: "Quality check not found" });
    if (qc.status !== "completed")
      return res.status(400).json({
        message: `Report not ready. Current status: ${qc.status}`,
      });

    // Stream PDF directly to response — no file storage needed
    res.setHeader("Content-Type", "application/pdf");
    res.setHeader(
      "Content-Disposition",
      `attachment; filename="pepper_report_${qc.batchId}.pdf"`,
    );

    const doc = new PDFDocument({ margin: 50, size: "A4" });
    doc.pipe(res);

    const DARK = "#1a1a2e";
    const GREEN = "#2d6a4f";
    const LIGHT_GREY = "#f4f4f4";
    const RED = "#c0392b";

    const gradeColor = (grade) => {
      const map = {
        "Grade 1 - Premium": "#1a6b3c",
        "Grade 2 - Gold": "#b8860b",
        "Grade 3 - Silver": "#607d8b",
        "Grade 4 - Basic": "#795548",
        Reject: RED,
      };
      return map[grade] || DARK;
    };

    // ── Header ──
    doc
      .fillColor(GREEN)
      .fontSize(22)
      .font("Helvetica-Bold")
      .text("Ceylon Pepper Quality Report", { align: "center" });

    doc
      .fillColor(DARK)
      .fontSize(10)
      .font("Helvetica")
      .text(
        `Batch ID: ${qc.batchId}   |   Generated: ${new Date().toLocaleDateString("en-GB")}`,
        {
          align: "center",
        },
      );

    doc.moveDown(0.5);
    doc.moveTo(50, doc.y).lineTo(545, doc.y).strokeColor(GREEN).stroke();
    doc.moveDown(1);

    // ── Grade box ──
    const grade = qc.results.grade || "N/A";
    const score = qc.results.overallScore ?? 0;
    doc
      .fillColor(gradeColor(grade))
      .fontSize(36)
      .font("Helvetica-Bold")
      .text(grade, { align: "center" });
    doc
      .fillColor(DARK)
      .fontSize(14)
      .font("Helvetica")
      .text(`Overall Score: ${score.toFixed(1)} / 100`, { align: "center" });

    if (qc.results.hardReject) {
      doc.moveDown(0.3);
      doc
        .fillColor(RED)
        .fontSize(10)
        .font("Helvetica-Bold")
        .text("⚠ HARD REJECT — see reasons below", { align: "center" });
      (qc.results.hardRejectReasons || []).forEach((r) => {
        doc.fillColor(RED).fontSize(9).font("Helvetica").text(`• ${r}`, {
          align: "center",
        });
      });
    }

    doc.moveDown(1);
    doc.moveTo(50, doc.y).lineTo(545, doc.y).strokeColor("#ccc").stroke();
    doc.moveDown(0.8);

    // ── Section helper ──
    const sectionTitle = (title) => {
      doc
        .fillColor(GREEN)
        .fontSize(13)
        .font("Helvetica-Bold")
        .text(title.toUpperCase());
      doc.moveDown(0.3);
    };

    const row = (label, value, valueColor = DARK) => {
      doc
        .fillColor("#555")
        .fontSize(10)
        .font("Helvetica")
        .text(label, 50, doc.y, { continued: true, width: 250 });
      doc
        .fillColor(valueColor)
        .font("Helvetica-Bold")
        .text(String(value), { align: "right" });
    };

    // ── Batch info ──
    sectionTitle("1. Batch Information");

    const b = qc.batch;
    row("Pepper Type", (b.pepperType || "").toUpperCase());
    row("Pepper Variety", (b.pepperVariety || "").replace(/_/g, " "));
    row("Drying Method", (b.dryingMethod || "").replace(/_/g, " "));
    row(
      "Harvest Date",
      b.harvestDate ? new Date(b.harvestDate).toLocaleDateString("en-GB") : "—",
    );
    row(
      "Batch Weight",
      b.batchWeightGrams ? `${(b.batchWeightGrams / 1000).toFixed(2)} kg` : "—",
    );
    doc.moveDown(0.8);

    // ── IoT density ──
    sectionTitle("2. Bulk Density (IoT)");
    row("Measured Density", `${qc.density?.value ?? "—"} g/L`);
    row(
      "Measured At",
      qc.density?.measuredAt
        ? new Date(qc.density.measuredAt).toLocaleString("en-GB")
        : "—",
    );
    doc.moveDown(0.8);

    // ── Factor scores ──
    sectionTitle("3. Factor Scores (0–100 each)");

    const factorLabels = {
      density: "Bulk Density",
      adulteration: "Adulteration",
      mold: "Mold Presence",
      extraneous: "Extraneous Matter",
      broken: "Broken / Abnormal Texture",
      varietyPiperine: "Variety / Piperine",
      healthyVisual: "Healthy Visual %",
      certBonus: "Certification Bonus",
    };

    const fs = qc.results.factorScores || {};
    Object.entries(factorLabels).forEach(([key, label]) => {
      const val = fs[key];
      const display = val != null ? val.toFixed(1) : "—";
      const color = val != null && val < 40 ? RED : DARK;
      row(label, display, color);
    });
    doc.moveDown(0.8);

    // ── Raw AI factors ──
    sectionTitle("4. Raw AI Measurements");
    const f = qc.results.factors || {};
    row("Adulterant Seeds", `${(f.adulterantPct ?? 0).toFixed(2)}%`);
    row("Extraneous Matter", `${(f.extraneousPct ?? 0).toFixed(2)}%`);
    row("Mold", `${(f.moldPct ?? 0).toFixed(2)}%`);
    row(
      "Abnormal Texture / Broken",
      `${(f.abnormalTexturePct ?? 0).toFixed(2)}%`,
    );
    row("Healthy Visual", `${(f.healthyVisualPct ?? 0).toFixed(2)}%`);
    doc.moveDown(0.8);

    // ── Certifications ──
    sectionTitle("5. Certifications at Grading Time");
    const snap = qc.certificatesSnapshot;
    if (!snap || snap.count === 0) {
      doc
        .fillColor(DARK)
        .fontSize(10)
        .font("Helvetica")
        .text("No verified certifications recorded.");
    } else {
      snap.items.forEach((c, i) => {
        doc
          .fillColor(DARK)
          .fontSize(10)
          .font("Helvetica-Bold")
          .text(
            `${i + 1}. ${c.certificationType || "—"} (${c.issuingBody || "—"})`,
          );
        doc
          .font("Helvetica")
          .text(
            `   Certificate No: ${c.certificateNumber || "—"}   Expires: ${c.expiryDate ? new Date(c.expiryDate).toLocaleDateString("en-GB") : "—"}`,
          );
      });
    }
    doc.moveDown(0.8);

    // ── Improvements ──
    if (qc.results.improvements?.length) {
      sectionTitle("6. Recommendations for Improvement");
      qc.results.improvements.forEach((tip, i) => {
        doc
          .fillColor(DARK)
          .fontSize(10)
          .font("Helvetica")
          .text(`${i + 1}. ${tip}`, { indent: 10 });
        doc.moveDown(0.2);
      });
      doc.moveDown(0.5);
    }

    // ── Footer ──
    doc.moveTo(50, doc.y).lineTo(545, doc.y).strokeColor("#ccc").stroke();
    doc.moveDown(0.4);
    doc
      .fillColor("#888")
      .fontSize(8)
      .font("Helvetica")
      .text(
        "This report was generated automatically by the Ceylon Pepper Quality Grading System. " +
          "Piperine scores are estimated from variety data (literature), not lab-measured. " +
          "AI factor percentages are count-based proxies for IPC m/m% values.",
        { align: "center" },
      );

    doc.end();
  } catch (err) {
    console.error("getPdfReport error:", err);
    if (!res.headersSent) {
      res.status(500).json({ message: "PDF generation failed" });
    }
  }
};
