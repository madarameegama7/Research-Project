/**
 * gradingEngine.js
 * ─────────────────────────────────────────────────────────────────
 * Pepper Quality Grading Engine (Black Pepper — Phase 1)
 *
 * DESIGN PRINCIPLES (from IPC + your research doc):
 *  1. Each factor → 0–100 points (comparable & explainable).
 *  2. IPC thresholds are used as full-credit anchors for factors
 *     that have IPC definitions (density, extraneous, mold, broken).
 *  3. Piecewise-linear interpolation (lerp) between key thresholds
 *     avoids cliff-edge behaviour and is easy to defend in a viva.
 *  4. Hard-reject rules override the score for trade-critical violations
 *     (adulteration, extreme mold).
 *  5. Count-based % from the model is used as a proxy for IPC m/m%.
 *     This is documented as an approximation (stated in thesis):
 *     at low contamination levels, count% ≈ area% ≈ mass% for
 *     near-spherical objects of similar size.
 *  6. Piperine is estimated from variety (not lab-measured). This is
 *     valid for a practical mobile grading app; limitations are stated.
 *  7. Certifications give a small bonus — they don't replace quality.
 *
 * FACTORS SCORED (matches what your model currently outputs + IoT + metadata):
 *   • Bulk density        (IoT, g/L)
 *   • Adulteration %      (model: adulterant_seed_pct)
 *   • Extraneous matter % (model: extraneous_matter_pct)
 *   • Mold %              (model: mold_pct)
 *   • Broken/abnormal %   (model: abnormal_texture_pct — proxy for broken berries)
 *   • Variety/Piperine    (user-selected variety → literature piperine %)
 *   • Certification bonus (snapshot of verified certs at grading time)
 *
 * NOTE: Color uniformity, size/shape, and insect damage are planned
 * for future model versions. Weights will be redistributed when added.
 * ─────────────────────────────────────────────────────────────────
 */

"use strict";

// ─── Helpers ─────────────────────────────────────────────────────

/**
 * Piecewise linear interpolation.
 * Maps x in [x0, x1] → y in [y0, y1]. x outside range is clamped by caller.
 */
function lerp(x, x0, x1, y0, y1) {
  if (x1 === x0) return y0;
  return y0 + ((x - x0) / (x1 - x0)) * (y1 - y0);
}

/** Clamp n to [min, max]. */
function clamp(n, min, max) {
  return Math.max(min, Math.min(max, n));
}

// ─── Factor scoring functions (0–100 each) ───────────────────────

/**
 * 1. BULK DENSITY (IoT, g/L) — IPC anchors: T1=550 (Grade I), T2=500 (Grade II), T3=450 (Grade III)
 *
 * Rationale: IPC uses density as the primary physical grade indicator.
 * Full credit at Grade I. Linear partial credit between thresholds.
 * Below Grade III floor (450) density drops steeply toward 0.
 *
 * Reference: IPC Standard Specifications for Whole Black Pepper, Table 2.
 */
function scoreDensity(densityGperL) {
  if (densityGperL == null || Number.isNaN(Number(densityGperL))) return 0;
  const d = Number(densityGperL);

  const T1 = 550; // Grade I minimum  → 100 pts
  const T2 = 500; // Grade II minimum → 70 pts
  const T3 = 450; // Grade III minimum → 40 pts
  const FLOOR = 350; // Very poor floor  → 0 pts

  if (d >= T1) return 100;
  if (d >= T2) return clamp(lerp(d, T2, T1, 70, 100), 0, 100);
  if (d >= T3) return clamp(lerp(d, T3, T2, 40, 70), 0, 100);
  if (d >= FLOOR) return clamp(lerp(d, FLOOR, T3, 0, 40), 0, 100);
  return 0;
}

/**
 * 2. ADULTERATION (adulterant_seed_pct — count-based proxy for m/m%)
 *
 * Rationale: Adulteration is commercial fraud. Buyers expect near-zero.
 * IPC allows 0%; even small percentages strongly damage export value.
 * Hard reject at > 0.5%.
 *
 * Scoring:
 *   0%        → 100 pts
 *   0–0.1%    → 100–70 pts (linear)
 *   0.1–0.5%  → 70–0 pts  (steeper linear — severe penalty)
 *   > 0.5%    → 0 pts     (and triggers hard reject)
 */
function scoreAdulteration(pct) {
  const x = Number(pct ?? 0);
  if (x <= 0) return 100;
  if (x <= 0.1) return clamp(lerp(x, 0, 0.1, 100, 70), 0, 100);
  if (x <= 0.5) return clamp(lerp(x, 0.1, 0.5, 70, 0), 0, 100);
  return 0;
}

/**
 * 3. EXTRANEOUS MATTER (extraneous_matter_pct — count/area proxy for m/m%)
 *
 * IPC anchors (Black Pepper):
 *   Grade I  max 1.0% extraneous matter (m/m)
 *   Grade II max 2.0%
 *   Grade III max 2.0%
 *
 * Rationale: Model gives count-based %, which approximates area% and
 * mass% for sticks/stones mixed with berries at low contamination.
 * Stated as a visual estimate proxy in the thesis.
 *
 * Scoring:
 *   ≤ 1%   → 100 pts (Grade I compliant)
 *   1–2%   → 100–70 pts
 *   2–5%   → 70–40 pts
 *   5–10%  → 40–10 pts
 *   > 10%  → 0 pts
 */
function scoreExtraneous(pct) {
  const x = Number(pct ?? 0);
  if (x <= 1) return 100;
  if (x <= 2) return clamp(lerp(x, 1, 2, 100, 70), 0, 100);
  if (x <= 5) return clamp(lerp(x, 2, 5, 70, 40), 0, 100);
  if (x <= 10) return clamp(lerp(x, 5, 10, 40, 10), 0, 100);
  return 0;
}

/**
 * 4. MOLD (mold_pct — count-based, measured on pepper_berry crops only)
 *
 * IPC anchors (Black Pepper):
 *   Grade I  max 1.0% mouldy berries (m/m)
 *   Grade II max 3.0%
 *   Grade III max 3.0%
 *
 * Rationale: Mold affects safety, off-flavour, and is a health concern.
 * Steep penalty because 1% mold = Grade I limit already breached.
 *
 * Scoring:
 *   ≤ 1%  → 100 pts
 *   1–3%  → 100–70 pts (at Grade II limit)
 *   3–6%  → 70–30 pts
 *   6–10% → 30–5 pts
 *   > 10% → 0 pts (and triggers hard reject)
 */
function scoreMold(pct) {
  const x = Number(pct ?? 0);
  if (x <= 1) return 100;
  if (x <= 3) return clamp(lerp(x, 1, 3, 100, 70), 0, 100);
  if (x <= 6) return clamp(lerp(x, 3, 6, 70, 30), 0, 100);
  if (x <= 10) return clamp(lerp(x, 6, 10, 30, 5), 0, 100);
  return 0;
}

/**
 * 5. BROKEN / ABNORMAL TEXTURE (abnormal_texture_pct)
 *
 * Your model labels badly-textured berries as "abnormal_texture".
 * These map to "pinheads/broken berries" in IPC terminology.
 *
 * IPC anchors (Black Pepper):
 *   Grade I  max 1.0% pinheads/broken berries (m/m)
 *   Grade II max 2.0%
 *   Grade III max 4.0%
 *
 * Rationale: Broken/abnormal berries lower density, reduce appearance
 * grade, and are explicitly penalised in IPC. Used as a proxy here.
 *
 * Scoring:
 *   ≤ 1%   → 100 pts (Grade I compliant)
 *   1–2%   → 100–80 pts
 *   2–4%   → 80–60 pts (Grade III limit)
 *   4–10%  → 60–20 pts
 *   10–20% → 20–0 pts
 *   > 20%  → 0 pts
 */
function scoreBroken(pct) {
  const x = Number(pct ?? 0);
  if (x <= 1) return 100;
  if (x <= 2) return clamp(lerp(x, 1, 2, 100, 80), 0, 100);
  if (x <= 4) return clamp(lerp(x, 2, 4, 80, 60), 0, 100);
  if (x <= 10) return clamp(lerp(x, 4, 10, 60, 20), 0, 100);
  if (x <= 20) return clamp(lerp(x, 10, 20, 20, 0), 0, 100);
  return 0;
}

/**
 * 6. VARIETY / PIPERINE CONTENT (estimated from variety selection)
 *
 * Piperine is the key alkaloid responsible for pungency and health benefits.
 * Exact measurement requires HPLC (not practical for farm-level grading).
 * This function uses published literature values for each variety.
 *
 * Scoring bands (piperine % → 0–100):
 *   ≥ 10%     → 100 pts  (premium — Ceylon Pepper typical range)
 *   8.0–9.9%  → 85 pts
 *   6.0–7.9%  → 65 pts
 *   4.0–5.9%  → 40 pts
 *   < 4%      → 10 pts
 *   Unknown   → 60 pts   (neutral fallback)
 *
 * VARIETY TABLE (literature sources):
 *   Ceylon Pepper     7–15% (avg ~11%) [jnsfsl.sljol.info, EDB Sri Lanka]   → 100
 *   Panniyur-1        ~4.90%           [The Pharma Journal, HPLC study]       → 40
 *   Dingi Rala        5.6%             [SL DEA trial data — provisional]      → 40
 *   Kohukumbure Rala  6.0%             [SL DEA trial data — provisional]      → 65
 *   Bootawe Rala      6.3%             [SL DEA trial data — provisional]      → 65
 *   Malabar           4–7% (avg ~6%)   [grokipedia.com, multiple sources]     → 65
 *   Kuching           ~5% (assumed)    [no primary piperine data found —      → 40
 *                                       provisional; clusters with lower
 *                                       piperine Sarawak varieties]
 *   Unknown           —                neutral fallback                        → 60
 *
 * Note: Confidence is Low for SL hybrids and Kuching/Malabar.
 * Update this table when primary DEA or lab data becomes available.
 * Stated in thesis as: "variety-based piperine estimation, not lab measurement".
 */
function scoreVarietyPiperine(pepperVariety) {
  const v = (pepperVariety || "").toLowerCase().trim();

  const table = {
    ceylon_pepper: 100, // 10–12% typical (within 7–15 range) — Med confidence
    panniyur_1: 40, // ~4.90% — High confidence (HPLC study)
    dingi_rala: 40, // 5.6% — Low confidence (provisional)
    kohukumbure_rala: 65, // 6.0% — Low confidence (provisional)
    bootawe_rala: 65, // 6.3% — Low confidence (provisional)
    malabar: 65, // ~5–7% avg ~6% — Med confidence (multiple sources)
    kuching: 40, // ~5% assumed — Low confidence (no primary piperine data)
    unknown: 60, // neutral fallback
  };

  return table[v] ?? 60; // default neutral for any unrecognised variety
}

/**
 * 7. CERTIFICATION BONUS
 *
 * Farmers with verified, non-expired certificates (e.g., SL-GAP, GlobalGAP,
 * organic, rainforest alliance, etc.) demonstrate documented good practices.
 * This adds a small bonus — it does NOT substitute physical quality.
 *
 * Scoring:
 *   ≥ 1 verified cert → 100 pts (used with low weight = small bonus)
 *   0 certs           → 0 pts
 *
 * Weight in final score: 0.05 (5%) — intentionally small bonus.
 */
function scoreCertBonus(snapshotCount) {
  return Number(snapshotCount ?? 0) > 0 ? 100 : 0;
}

// ─── Grade bands ─────────────────────────────────────────────────

/**
 * Map final weighted score (0–100) to a grade label.
 * Custom labels are used (not IPC I/II/III) because this is a composite
 * multi-factor score, not a single-factor IPC measurement.
 *
 * Bands (tunable — adjust after validation with expert-labelled samples):
 *   ≥ 90  → PREMIUM
 *   ≥ 80  → GOLD
 *   ≥ 65  → SILVER
 *   ≥ 50  → BASIC
 *   < 50  → REJECT
 */
function scoreToGrade(score) {
  if (score >= 90) return "Grade 1 - Premium";
  if (score >= 80) return "Grade 2 - Gold";
  if (score >= 65) return "Grade 3 - Silver";
  if (score >= 50) return "Grade 4 - Basic";
  return "Reject";
}

// ─── Improvement tips ────────────────────────────────────────────

/**
 * Generate actionable improvement tips based on raw measurements.
 * Helps farmers understand what they should fix for the next batch.
 */
function buildImprovements(raw, factorScores) {
  const tips = [];

  if (raw.adulterantPct > 0)
    tips.push(
      "Remove adulterant seeds by careful sorting and sieving before packaging.",
    );

  if (raw.extraneousPct > 2)
    tips.push(
      "Improve cleaning: remove stones, stems, and foreign matter using sieving and winnowing before packing.",
    );

  if (raw.moldPct > 1)
    tips.push(
      "Reduce mold risk: dry pepper faster to reach safe moisture levels, store in dry ventilated conditions, and avoid damp jute bags.",
    );

  if (raw.abnormalTexturePct > 4)
    tips.push(
      "Reduce broken/abnormal berries: improve threshing technique and post-harvest handling. Use a sieve to remove pinheads and broken pieces.",
    );

  if (raw.density < 500)
    tips.push(
      "Improve bulk density: harvest at full maturity and ensure thorough drying and cleaning. Under-ripe or poorly-dried pepper has lower density.",
    );

  if (factorScores.varietyPiperine < 65)
    tips.push(
      "Consider growing high-piperine Ceylon Pepper varieties where soil and climate are suitable. Higher piperine content commands better market prices.",
    );

  if (raw.healthyVisualPct < 70)
    tips.push(
      "A significant portion of berries show quality issues. Improve post-harvest drying and sorting to increase the proportion of healthy berries.",
    );

  // Return at most 5 tips (keep report concise)
  return tips.slice(0, 5);
}

// ─── Main grading function ────────────────────────────────────────

/**
 * gradeBatch()
 * ─────────────────────────────────────────────────────────────────
 * Computes a final quality grade for one pepper batch.
 *
 * @param {object} params
 * @param {string}  params.pepperType         "black" | "white"
 * @param {string}  params.pepperVariety       e.g. "ceylon_pepper"
 * @param {number}  params.density             bulk density in g/L (from IoT)
 * @param {object}  params.factors             from AI model:
 *   @param {number}  factors.adulterantPct      adulterant_seed_pct
 *   @param {number}  factors.extraneousPct      extraneous_matter_pct
 *   @param {number}  factors.moldPct            mold_pct
 *   @param {number}  factors.abnormalTexturePct abnormal_texture_pct
 *   @param {number}  factors.healthyVisualPct   healthy_visual_pct
 * @param {number}  params.certSnapshotCount   number of verified, non-expired certs
 *
 * @returns {object} grading result
 */
function gradeBatch({
  pepperType,
  pepperVariety,
  density,
  factors,
  certSnapshotCount,
}) {
  // ── Phase 1: black pepper only ──
  const type = (pepperType || "").toLowerCase().trim();
  if (type !== "black") {
    return {
      overallScore: 0,
      grade: "Reject",
      hardReject: true,
      hardRejectReasons: [
        "Only black pepper grading is implemented in Phase 1. White pepper grading will be added in a future release.",
      ],
      factorScores: {},
      weights: {},
      improvements: [
        "Re-submit as black pepper, or wait for the white pepper grading module.",
      ],
    };
  }

  // ── Normalise raw inputs ──
  const raw = {
    density: Number(density ?? 0),
    adulterantPct: Number(factors?.adulterantPct ?? 0),
    extraneousPct: Number(factors?.extraneousPct ?? 0),
    moldPct: Number(factors?.moldPct ?? 0),
    abnormalTexturePct: Number(factors?.abnormalTexturePct ?? 0),
    healthyVisualPct: Number(factors?.healthyVisualPct ?? 0),
  };

  // ── Hard reject rules ──
  // These override the final grade regardless of score.
  // Adulteration > 0.5% → automatic reject (commercial fraud threshold).
  // Mold > 10%          → automatic reject (safety concern).
  const hardRejectReasons = [];

  if (raw.adulterantPct > 0.5)
    hardRejectReasons.push(
      `Adulterant seeds detected at ${raw.adulterantPct.toFixed(2)}% (limit: 0.5%). Batch rejected — adulteration is a commercial fraud issue.`,
    );

  if (raw.moldPct > 10)
    hardRejectReasons.push(
      `Mold detected at ${raw.moldPct.toFixed(2)}% (limit: 10%). Batch rejected — high mold level poses safety and health concerns.`,
    );

  const hardReject = hardRejectReasons.length > 0;

  // ── Compute per-factor scores (0–100) ──
  const factorScores = {
    density: scoreDensity(raw.density),
    adulteration: scoreAdulteration(raw.adulterantPct),
    extraneous: scoreExtraneous(raw.extraneousPct),
    mold: scoreMold(raw.moldPct),
    broken: scoreBroken(raw.abnormalTexturePct),
    varietyPiperine: scoreVarietyPiperine(pepperVariety),
    certBonus: scoreCertBonus(certSnapshotCount),
  };

  // Healthy visual % is already 0–100, use directly as a soft quality indicator.
  // It captures the overall proportion of good berries and complements the
  // individual defect factors above.
  const healthyVisualScore = clamp(raw.healthyVisualPct, 0, 100);

  // ── Weights (must sum to 1.0) ──
  // Design rationale:
  //   • Density (0.20): IPC's primary physical indicator → highest weight.
  //   • Adulteration (0.18): Trade-critical / legal issue → high weight.
  //   • Mold (0.12): Safety + quality → high weight.
  //   • Extraneous (0.12): IPC-defined, image-detectable.
  //   • Broken/abnormal (0.10): IPC pinheads proxy.
  //   • Variety/Piperine (0.09): Chemical quality proxy (literature-based).
  //   • Healthy visual (0.09): Overall visual health of the batch.
  //   • Cert bonus (0.05): Small bonus for documented good practices.
  //   • Reserved (0.05): For future factors (color, size, insect damage).
  //     For now, add to healthy visual to keep weights summing to 1.
  const weights = {
    density: 0.2,
    adulteration: 0.18,
    mold: 0.12,
    extraneous: 0.12,
    broken: 0.1,
    varietyPiperine: 0.09,
    healthyVisual: 0.14, // 0.09 + 0.05 reserved for future factors
    certBonus: 0.05,
  };

  // Verify weights sum to 1.0 (sanity check — remove in production)
  const weightSum = Object.values(weights).reduce((a, b) => a + b, 0);
  if (Math.abs(weightSum - 1.0) > 0.001) {
    console.warn(
      `[gradingEngine] Weights do not sum to 1.0 (sum = ${weightSum.toFixed(4)})`,
    );
  }

  // ── Weighted score ──
  let score =
    factorScores.density * weights.density +
    factorScores.adulteration * weights.adulteration +
    factorScores.mold * weights.mold +
    factorScores.extraneous * weights.extraneous +
    factorScores.broken * weights.broken +
    factorScores.varietyPiperine * weights.varietyPiperine +
    healthyVisualScore * weights.healthyVisual +
    factorScores.certBonus * weights.certBonus;

  score = clamp(score, 0, 100);

  // ── Apply hard reject override ──
  const finalGrade = hardReject ? "Reject" : scoreToGrade(score);

  // ── Generate improvement tips ──
  const improvements = buildImprovements(raw, factorScores);

  return {
    overallScore: Number(score.toFixed(2)),
    grade: finalGrade,
    hardReject,
    hardRejectReasons,
    factorScores: {
      density: Number(factorScores.density.toFixed(2)),
      adulteration: Number(factorScores.adulteration.toFixed(2)),
      mold: Number(factorScores.mold.toFixed(2)),
      extraneous: Number(factorScores.extraneous.toFixed(2)),
      broken: Number(factorScores.broken.toFixed(2)),
      varietyPiperine: Number(factorScores.varietyPiperine.toFixed(2)),
      healthyVisual: Number(healthyVisualScore.toFixed(2)),
      certBonus: Number(factorScores.certBonus.toFixed(2)),
    },
    weights,
    improvements,
    // Transparency metadata — useful for displaying to farmer and for thesis defence
    meta: {
      piperineNote:
        "Piperine score is a variety-based estimate from published literature, not a lab measurement. Results may vary within a variety depending on soil, climate, and post-harvest handling.",
      countVsMassNote:
        "Extraneous matter, mold, and adulteration percentages are count-based (from image detection), used as a proxy for IPC m/m% values. This approximation is valid at low contamination levels for near-spherical objects of similar size.",
      hardRejectThresholds: {
        adulteration_pct: 0.5,
        mold_pct: 10,
      },
      gradeBands: {
        "Grade 1 - Premium": "≥ 90",
        "Grade 2 - Gold": "80–89",
        "Grade 3 - Silver": "65–79",
        "Grade 4 - Basic": "50–64",
        Reject: "< 50 or hard reject",
      },
    },
  };
}

// ─── Demo / quick test ───────────────────────────────────────────
// Remove or comment out before deploying. This runs when you call
//   node gradingEngine.js
// directly, to verify it's working correctly.

if (require.main === module) {
  const testCases = [
    {
      label: "Good batch — Ceylon Pepper, high density, very clean",
      input: {
        pepperType: "black",
        pepperVariety: "ceylon_pepper",
        density: 565,
        factors: {
          adulterantPct: 0,
          extraneousPct: 0.5,
          moldPct: 0.3,
          abnormalTexturePct: 0.8,
          healthyVisualPct: 94,
        },
        certSnapshotCount: 1,
      },
    },
    {
      label: "Mixed batch — Panniyur-1, medium density, some mold",
      input: {
        pepperType: "black",
        pepperVariety: "panniyur_1",
        density: 490,
        factors: {
          adulterantPct: 0,
          extraneousPct: 3.5,
          moldPct: 2.5,
          abnormalTexturePct: 15,
          healthyVisualPct: 68,
        },
        certSnapshotCount: 0,
      },
    },
    {
      label: "Poor batch — high adulteration → hard reject",
      input: {
        pepperType: "black",
        pepperVariety: "unknown",
        density: 460,
        factors: {
          adulterantPct: 1.2,
          extraneousPct: 8,
          moldPct: 4,
          abnormalTexturePct: 30,
          healthyVisualPct: 35,
        },
        certSnapshotCount: 0,
      },
    },
    {
      label: "FINAL BATCH AVG from your sample output",
      input: {
        pepperType: "black",
        pepperVariety: "ceylon_pepper",
        density: 520,
        factors: {
          adulterantPct: 0.0,
          extraneousPct: 12.27,
          moldPct: 2.51,
          abnormalTexturePct: 29.42,
          healthyVisualPct: 68.08,
        },
        certSnapshotCount: 0,
      },
    },
  ];

  testCases.forEach(({ label, input }) => {
    const result = gradeBatch(input);
    console.log("\n" + "=".repeat(60));
    console.log("TEST:", label);
    console.log("─".repeat(60));
    console.log("Grade      :", result.grade);
    console.log("Score      :", result.overallScore, "/ 100");
    console.log("Hard Reject:", result.hardReject);
    if (result.hardRejectReasons.length)
      console.log("Reasons    :", result.hardRejectReasons);
    console.log("Factor Scores:");
    Object.entries(result.factorScores).forEach(([k, v]) =>
      console.log(`  ${k.padEnd(18)}: ${v}`),
    );
    console.log("Improvements:");
    result.improvements.forEach((tip, i) => console.log(`  ${i + 1}. ${tip}`));
  });
}

module.exports = { gradeBatch };
