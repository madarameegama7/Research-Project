import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { fetchActualPriceData, generateBatchQr } from "../../services/api";
import {
  ArrowLeft,
  Search,
  RefreshCw,
  QrCode,
  Inbox,
  X,
  ShieldCheck,
  CheckCircle,
  AlertTriangle,
} from "lucide-react";
import "../../App.css";

export default function QRGeneration() {
  const navigate = useNavigate();
  const [batches, setBatches] = useState([]);
  const [filteredBatches, setFilteredBatches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [actionLoading, setActionLoading] = useState(false);
  const [searchQuery, setSearchQuery] = useState("");

  // Confirm & Toast state
  const [confirmOpen, setConfirmOpen] = useState(false);
  const [confirmBatch, setConfirmBatch] = useState(null);
  const [toast, setToast] = useState(null); // { type: 'success'|'error', title, message }

  const showToast = (payload) => {
    setToast(payload);
    window.clearTimeout(showToast._t);
    showToast._t = window.setTimeout(() => setToast(null), 3200);
  };

  const loadBatches = async (silent = false) => {
    if (!silent) setLoading(true);
    try {
      const data = await fetchActualPriceData();
      const verified = data.filter(
        (r) => (r.currentStatus || "").toUpperCase() === "VERIFIED",
      );
      setBatches(verified);
      applyFilter(verified, searchQuery);
    } catch (err) {
      console.error("Failed to load batches:", err);
      showToast({
        type: "error",
        title: "Couldn’t load batches",
        message: err?.message || "Please check your connection and try again.",
      });
    } finally {
      if (!silent) setLoading(false);
    }
  };

  useEffect(() => {
    loadBatches();
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const applyFilter = (data, search) => {
    if (!search) {
      setFilteredBatches(data);
      return;
    }
    const lower = search.toLowerCase();
    setFilteredBatches(
      data.filter((b) => (b.batchId || "").toLowerCase().includes(lower)),
    );
  };

  const handleSearchChange = (e) => {
    const val = e.target.value;
    setSearchQuery(val);
    applyFilter(batches, val);
  };

  const clearSearch = () => {
    setSearchQuery("");
    applyFilter(batches, "");
  };

  // Open confirm modal
  const requestGenerate = (batch) => {
    if (actionLoading) return;
    setConfirmBatch(batch);
    setConfirmOpen(true);
  };

  // Confirm and generate QR
  const confirmGenerate = async () => {
    if (!confirmBatch || actionLoading) return;

    setConfirmOpen(false);
    setActionLoading(true);

    try {
      await generateBatchQr(confirmBatch._id);

      const updated = batches.filter((r) => r._id !== confirmBatch._id);
      setBatches(updated);
      applyFilter(updated, searchQuery);

      showToast({
        type: "success",
        title: "QR generated successfully",
      });
    } catch (err) {
      showToast({
        type: "error",
        title: "QR generation failed",
        message: err?.message || "Something went wrong. Please try again.",
      });
    } finally {
      setActionLoading(false);
      setConfirmBatch(null);
    }
  };

  const formatDate = (dateString) => {
    if (!dateString) return "-";
    const d = new Date(dateString);
    const day = String(d.getDate()).padStart(2, "0");
    const month = String(d.getMonth() + 1).padStart(2, "0");
    const year = d.getFullYear();
    return `${day}/${month}/${year}`;
  };

  return (
    <div className="dashboard-layout" style={{ position: "relative" }}>
      {/* Sidebar */}
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="brand-logo-small">
            <ShieldCheck size={24} color="#fff" />
          </div>
          <h2>Admin Portal</h2>
        </div>

        <nav className="sidebar-nav">
          <div
            className="nav-item"
            onClick={() => navigate("/dashboard")}
            style={{ cursor: "pointer" }}
          >
            <ArrowLeft size={20} />
            <span>Back to Dashboard</span>
          </div>

          <div
            className="nav-item"
            onClick={() => navigate("/blockchain")}
            style={{ cursor: "pointer" }}
          >
            <CheckCircle size={20} />
            <span>Blockchain System</span>
          </div>

          <div className="nav-item active">
            <QrCode size={20} />
            <span>Generate QR</span>
          </div>

          <div
            className="nav-item"
            onClick={() => navigate("/blockchain/verify-batches")}
            style={{ cursor: "pointer" }}
          >
            <CheckCircle size={20} />
            <span>Verify Batches</span>
          </div>
        </nav>
      </aside>

      {/* Main */}
      <main className="main-content">
        <header
          className="dashboard-header"
          style={{ marginBottom: "1.25rem" }}
        >
          <div
            className="header-text"
            style={{ display: "flex", alignItems: "center", gap: "1rem" }}
          >
            <button
              onClick={() => navigate("/blockchain")}
              className="btn btn-outline"
              style={{
                padding: "0.6rem",
                borderRadius: "14px",
                background: "white",
                border: "1px solid #e5e7eb",
                boxShadow: "0 6px 16px rgba(0,0,0,0.06)",
              }}
              title="Back"
            >
              <ArrowLeft size={22} />
            </button>
            <div>
              <p className="greeting" style={{ marginBottom: 2 }}>
                QR Sub-System
              </p>
              <h1 style={{ margin: 0 }}>Generate QR Code</h1>
            </div>
          </div>
        </header>

        <div className="content-pad" style={{ maxWidth: "900px" }}>
          {/* Info */}
          <div
            className="notice-card"
            style={{
              backgroundColor: "#ffffff",
              border: "1px solid #e2e8f0",
              marginBottom: "1.25rem",
              display: "flex",
              alignItems: "flex-start",
              gap: "0.9rem",
              padding: "1.1rem 1.15rem",
              borderRadius: "12px",
              boxShadow: "0 2px 6px rgba(0,0,0,0.03)",
            }}
          >
            <div
              style={{
                width: 40,
                height: 40,
                borderRadius: 12,
                border: "1px solid #e2e8f0",
                background: "#f8fafc",
                display: "flex",
                alignItems: "center",
                justifyContent: "center",
                flexShrink: 0,
              }}
            >
              <QrCode size={20} color="#0f172a" />
            </div>

            <p style={{ color: "#0f172a", margin: 0, lineHeight: 1.5 }}>
              Only <strong>verified batches</strong> are shown here. Generate QR
              codes for exporters to scan into their supply chain systems.
            </p>
          </div>

          {/* Search */}
          <div style={{ marginBottom: "1rem" }}>
            <div
              style={{
                background: "white",
                border: "1px solid #e5e7eb",
                borderRadius: "14px",
                padding: "0.85rem 1rem",
                boxShadow: "0 10px 22px rgba(0,0,0,0.07)",
                display: "flex",
                alignItems: "center",
                gap: "0.75rem",
              }}
            >
              <Search size={20} color="#64748b" />
              <input
                type="text"
                placeholder="Search by Batch No."
                value={searchQuery}
                onChange={handleSearchChange}
                style={{
                  flex: 1,
                  border: "none",
                  outline: "none",
                  fontSize: "0.95rem",
                  color: "#0f172a",
                  background: "transparent",
                }}
              />
              {searchQuery && (
                <button
                  onClick={clearSearch}
                  title="Clear"
                  style={{
                    border: "none",
                    background: "#f1f5f9",
                    width: 34,
                    height: 34,
                    borderRadius: 10,
                    display: "flex",
                    alignItems: "center",
                    justifyContent: "center",
                    cursor: "pointer",
                  }}
                >
                  <X size={18} color="#475569" />
                </button>
              )}
            </div>
          </div>

          {/* Refresh + count */}
          <div
            style={{
              marginBottom: "1.5rem",
              display: "flex",
              justifyContent: "space-between",
              alignItems: "center",
              gap: "1rem",
              flexWrap: "wrap",
            }}
          >
            <div style={{ color: "#64748b", fontSize: "0.9rem" }}>
              Showing <b>{filteredBatches.length}</b> of <b>{batches.length}</b>{" "}
              verified batches
            </div>

            <button
              className="btn btn-outline"
              onClick={() => loadBatches()}
              disabled={loading || actionLoading}
              style={{
                display: "flex",
                alignItems: "center",
                gap: "0.5rem",
                background: "white",
                border: "1px solid #e5e7eb",
                boxShadow: "0 6px 16px rgba(0,0,0,0.06)",
                borderRadius: "14px",
                padding: "0.65rem 1rem",
                cursor: loading || actionLoading ? "not-allowed" : "pointer",
              }}
            >
              <RefreshCw size={18} className={loading ? "spin" : ""} />
              Refresh
            </button>
          </div>

          {/* Results */}
          {loading ? (
            <div className="loading-screen" style={{ minHeight: "300px" }}>
              Scanning Registry...
            </div>
          ) : batches.length === 0 ? (
            <div
              style={{
                textAlign: "center",
                padding: "4rem 2rem",
                backgroundColor: "#f8fafc",
                borderRadius: "12px",
                border: "1px dashed #cbd5e1",
              }}
            >
              <Inbox
                size={48}
                color="#94a3b8"
                style={{ marginBottom: "1rem" }}
              />
              <h3>No verified batches found</h3>
              <p style={{ color: "#64748b" }}>
                Approve pending batches before generating QRs.
              </p>
            </div>
          ) : filteredBatches.length === 0 ? (
            <div style={{ textAlign: "center", padding: "3rem 2rem" }}>
              <p style={{ color: "#64748b" }}>
                No batches match "{searchQuery}"
              </p>
            </div>
          ) : (
            <div
              style={{ display: "flex", flexDirection: "column", gap: "1rem" }}
            >
              {filteredBatches.map((batch) => (
                <div
                  key={batch._id}
                  style={{
                    backgroundColor: "white",
                    borderRadius: "12px",
                    padding: "1.25rem",
                    border: "1px solid #e2e8f0",
                    display: "flex",
                    alignItems: "center",
                    gap: "1.25rem",
                    boxShadow: "0 2px 6px rgba(0,0,0,0.03)",
                  }}
                >
                  <div
                    style={{
                      width: "6px",
                      height: "40px",
                      backgroundColor: "#2E7D32",
                      borderRadius: "4px",
                    }}
                  />

                  <div style={{ flex: 1, minWidth: 0 }}>
                    <h3
                      style={{
                        margin: "0 0 0.25rem 0",
                        fontSize: "1.05rem",
                        fontWeight: 600,
                        color: "#0f172a",
                        whiteSpace: "nowrap",
                        overflow: "hidden",
                        textOverflow: "ellipsis",
                      }}
                      title={batch.batchId}
                    >
                      {batch.batchId}
                    </h3>
                    <span style={{ fontSize: "0.85rem", color: "#64748b" }}>
                      Verified on: {formatDate(batch.saleDate)}
                    </span>
                  </div>

                  <button
                    className="btn btn-primary"
                    onClick={() => requestGenerate(batch)}
                    disabled={actionLoading}
                    style={{
                      display: "flex",
                      alignItems: "center",
                      gap: "0.5rem",
                      backgroundColor: "#475569",
                      borderRadius: "10px",
                      padding: "0.65rem 0.95rem",
                      cursor: actionLoading ? "not-allowed" : "pointer",
                    }}
                  >
                    <QrCode size={18} />
                    Generate
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>
      </main>

      {/* Confirm Modal */}
      {confirmOpen && confirmBatch && (
        <div className="modal-overlay" onClick={() => setConfirmOpen(false)}>
          <div
            className="modal-content"
            onClick={(e) => e.stopPropagation()}
            style={{ maxWidth: 520 }}
          >
            <div className="modal-header">
              <h2
                style={{ display: "flex", alignItems: "center", gap: "0.6rem" }}
              >
                Generate QR Code
              </h2>
            </div>

            <div style={{ paddingTop: "0.25rem" }}>
              <p
                style={{
                  margin: "0 0 0.75rem 0",
                  color: "#334155",
                  lineHeight: 1.6,
                }}
              >
                You’re about to generate a QR code for:
              </p>

              <div
                style={{
                  border: "1px solid #e2e8f0",
                  background: "#f8fafc",
                  borderRadius: 12,
                  padding: "0.9rem",
                }}
              >
                <div style={{ color: "#64748b", fontSize: "0.85rem" }}>
                  Batch ID
                </div>
                <div style={{ color: "#0f172a", fontWeight: 600 }}>
                  {confirmBatch.batchId || "-"}
                </div>
                <div
                  style={{
                    marginTop: 8,
                    color: "#64748b",
                    fontSize: "0.85rem",
                  }}
                >
                  Verified on
                </div>
                <div style={{ color: "#0f172a", fontWeight: 600 }}>
                  {formatDate(confirmBatch.saleDate)}
                </div>
              </div>

              <p
                style={{
                  margin: "0.9rem 0 0 0",
                  color: "#334155",
                  lineHeight: 1.6,
                }}
              >
                This will mark the batch as ready for exporters to scan.
                Continue?
              </p>
            </div>

            <div
              className="modal-footer"
              style={{
                marginTop: "1.25rem",
                display: "flex",
                justifyContent: "flex-end",
                gap: "0.75rem",
              }}
            >
              <button
                className="btn btn-outline"
                onClick={() => setConfirmOpen(false)}
              >
                Cancel
              </button>
              <button
                className="btn btn-primary"
                onClick={confirmGenerate}
                style={{
                  backgroundColor: "#475569",
                  borderRadius: "10px",
                  padding: "0.65rem 0.95rem",
                }}
              >
                Yes, Generate
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Toast message */}
      {toast && (
        <div
          style={{
            position: "fixed",
            right: 18,
            bottom: 18,
            zIndex: 2000,
            width: "min(420px, calc(100vw - 36px))",
            background: "#fff",
            border: "1px solid #e5e7eb",
            borderRadius: 14,
            boxShadow: "0 18px 40px rgba(0,0,0,0.16)",
            padding: "0.9rem 1rem",
            display: "flex",
            gap: "0.75rem",
            alignItems: "flex-start",
          }}
        >
          <div
            style={{
              width: 36,
              height: 36,
              borderRadius: 12,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              background: toast.type === "success" ? "#ecfdf5" : "#fef2f2",
              border: `1px solid ${toast.type === "success" ? "#bbf7d0" : "#fecaca"}`,
              flexShrink: 0,
            }}
          >
            {toast.type === "success" ? (
              <CheckCircle size={18} color="#16a34a" />
            ) : (
              <AlertTriangle size={18} color="#dc2626" />
            )}
          </div>

          <div style={{ minWidth: 0, flex: 1 }}>
            <div style={{ color: "#0f172a", fontWeight: 600 }}>
              {toast.title}
            </div>
            <div style={{ marginTop: 2, color: "#475569", lineHeight: 1.45 }}>
              {toast.message}
            </div>
          </div>

          <button
            onClick={() => setToast(null)}
            style={{
              border: "none",
              background: "#f1f5f9",
              width: 34,
              height: 34,
              borderRadius: 10,
              display: "flex",
              alignItems: "center",
              justifyContent: "center",
              cursor: "pointer",
              flexShrink: 0,
            }}
            title="Close"
          >
            <X size={18} color="#475569" />
          </button>
        </div>
      )}

      {/* Loading Overlay */}
      {actionLoading && (
        <div
          style={{
            position: "absolute",
            top: 0,
            left: 0,
            right: 0,
            bottom: 0,
            backgroundColor: "rgba(255,255,255,0.7)",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            zIndex: 1000,
          }}
        >
          <RefreshCw size={32} className="spin" color="var(--primary)" />
        </div>
      )}
    </div>
  );
}
