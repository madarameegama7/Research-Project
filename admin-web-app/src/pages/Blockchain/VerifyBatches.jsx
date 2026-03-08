import { useState, useEffect } from "react";
import { useNavigate } from "react-router-dom";
import { fetchActualPriceData } from "../../services/api";
import {
  ArrowLeft,
  Search,
  RefreshCw,
  Filter,
  Inbox,
  X,
  ChevronRight,
  ShieldCheck,
  CheckCircle,
  QrCode,
  User,
  MapPin,
  Leaf,
  Calendar,
  Tag,
} from "lucide-react";
import "../../App.css";

export default function VerifyBatches() {
  const navigate = useNavigate();
  const [batches, setBatches] = useState([]);
  const [filteredBatches, setFilteredBatches] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");
  const [searchQuery, setSearchQuery] = useState("");
  // default to showing batches that need verification
  const [statusFilter, setStatusFilter] = useState("NOT_VERIFIED");

  const loadBatches = async () => {
    setLoading(true);
    setError("");
    try {
      const data = await fetchActualPriceData();
      setBatches(data);
      applyFilters(data, searchQuery, statusFilter);
    } catch (err) {
      setError(err.message || "Failed to load pepper batches.");
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadBatches();
  }, []);

  // Filter data based on search query and status filter
  const applyFilters = (data, search, status) => {
    // Exclude QR_GENERATED records — they are considered already verified
    let filtered = (data || []).filter(
      (b) => (b.currentStatus || "").toUpperCase() !== "QR_GENERATED",
    );
    const searchLower = (search || "").toLowerCase();

    if (status && status !== "ALL") {
      if (status === "NOT_VERIFIED") {
        // include statuses that still require verification
        filtered = filtered.filter((b) =>
          ["BATCH_CREATED", "MARKETPLACE_LISTED"].includes(
            (b.currentStatus || "").toUpperCase(),
          ),
        );
      } else if (status === "VERIFIED") {
        filtered = filtered.filter(
          (b) => (b.currentStatus || "").toUpperCase() === "VERIFIED",
        );
      }
    }
    // Apply search filter across multiple fields
    if (searchLower) {
      filtered = filtered.filter(
        (b) =>
          (b.batchId && b.batchId.toLowerCase().includes(searchLower)) ||
          (b.district && b.district.toLowerCase().includes(searchLower)) ||
          (b.farmerName && b.farmerName.toLowerCase().includes(searchLower)) ||
          (b.pepperType && b.pepperType.toLowerCase().includes(searchLower)) ||
          (b.grade && String(b.grade).toLowerCase().includes(searchLower)),
      );
    }

    setFilteredBatches(filtered);
  };

  useEffect(() => {
    applyFilters(batches, searchQuery, statusFilter);
  }, [searchQuery, statusFilter]);

  // Total records
  const totalAvailable = (batches || []).filter(
    (b) => (b.currentStatus || "").toUpperCase() !== "QR_GENERATED",
  ).length;

  // Helper to get color based on status
  const getStatusColor = (status) => {
    switch ((status || "").toUpperCase()) {
      case "BATCH_CREATED":
        return "#05388a";
      case "MARKETPLACE_LISTED":
        return "#655193";
      case "VERIFIED":
        return "#2E7D32";
      case "NOT_VERIFIED":
        return "#e4b643";
      default:
        return "#64748b";
    }
  };

  // Function to format the status
  const formatStatus = (status) => {
    switch ((status || "").toUpperCase()) {
      case "BATCH_CREATED":
        return "Batch Created";
      case "MARKETPLACE_LISTED":
        return "Listed";
      case "VERIFIED":
        return "Verified";
      default:
        return status || "Unknown";
    }
  };

  // Function to format the date as dd/mm/yyyy
  const formatDate = (dateString) => {
    if (!dateString) return "-";

    const d = new Date(dateString);

    const day = String(d.getDate()).padStart(2, "0");
    const month = String(d.getMonth() + 1).padStart(2, "0"); // Months are 0-based
    const year = d.getFullYear();

    return `${day}/${month}/${year}`;
  };

  const handleSearchChange = (e) => setSearchQuery(e.target.value); // Update search query state on input change
  const clearSearch = () => setSearchQuery(""); // Clear search input and reset query

  return (
    <div className="dashboard-layout">
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
            <CheckCircle size={20} />
            <span>Verify Batches</span>
          </div>

          <div
            className="nav-item"
            onClick={() => navigate("/blockchain/generate-qr")}
            style={{ cursor: "pointer" }}
          >
            <QrCode size={20} />
            <span>Generate QR</span>
          </div>
        </nav>
      </aside>

      {/* Main */}
      <main className="main-content">
        <header className="dashboard-header">
          <div style={{ display: "flex", alignItems: "center", gap: "1rem" }}>
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
              <h1 style={{ margin: "0.25rem 0 0 0" }}>Verify Pepper Batches</h1>
            </div>
          </div>
        </header>

        <div className="content-pad">
          {/* Search + Filters */}
          <div style={{ marginBottom: "1.5rem" }}>
            {/* Search Bar */}
            <div style={{ display: "flex", gap: "1rem", flexWrap: "wrap" }}>
              <div style={{ flex: "1 1 320px" }}>
                <div
                  style={{
                    background: "white",
                    border: "1px solid #e5e7eb",
                    borderRadius: "16px",
                    padding: "0.9rem 1rem",
                    boxShadow: "0 10px 22px rgba(0,0,0,0.08)",
                    display: "flex",
                    alignItems: "center",
                    gap: "0.75rem",
                  }}
                >
                  <Search size={20} color="#64748b" />
                  <input
                    type="text"
                    placeholder="Search here..."
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
                        width: "34px",
                        height: "34px",
                        borderRadius: "10px",
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
            </div>

            {/* Filter Chips */}
            <div
              style={{
                marginTop: "1rem",
                display: "flex",
                gap: "0.75rem",
                flexWrap: "wrap",
              }}
            >
              {["VERIFIED", "NOT_VERIFIED"].map((status) => (
                <button
                  key={status}
                  onClick={() => setStatusFilter(status)}
                  style={{
                    padding: "0.5rem 1rem",
                    borderRadius: "999px",
                    border: `1px solid ${
                      statusFilter === status
                        ? getStatusColor(status)
                        : "#e2e8f0"
                    }`,
                    backgroundColor:
                      statusFilter === status
                        ? `${getStatusColor(status)}18`
                        : "white",
                    color:
                      statusFilter === status
                        ? getStatusColor(status)
                        : "#0f172a",
                    fontWeight: statusFilter === status ? "800" : "600",
                    cursor: "pointer",
                    transition: "all 0.2s",
                  }}
                >
                  {status === "VERIFIED" ? "Verified" : "Not Verified"}
                </button>
              ))}
            </div>

            {/* Refresh Button */}
            <div
              style={{
                marginTop: "1rem",
                display: "flex",
                justifyContent: "space-between",
                alignItems: "center",
                gap: "1rem",
                flexWrap: "wrap",
              }}
            >
              <div style={{ color: "#64748b", fontSize: "0.9rem" }}>
                Showing <b>{filteredBatches.length}</b> of{" "}
                <b>{totalAvailable}</b> batches
              </div>

              <button
                onClick={loadBatches}
                disabled={loading}
                className="btn btn-outline"
                style={{
                  display: "flex",
                  alignItems: "center",
                  gap: "0.5rem",
                  background: "white",
                  border: "1px solid #e5e7eb",
                  boxShadow: "0 6px 16px rgba(0,0,0,0.06)",
                  borderRadius: "14px",
                  padding: "0.65rem 1rem",
                  cursor: loading ? "not-allowed" : "pointer",
                }}
              >
                <RefreshCw size={18} className={loading ? "spin" : ""} />
                Refresh
              </button>
            </div>
          </div>

          {/* Results */}
          {loading ? (
            <div className="loading-screen" style={{ minHeight: "260px" }}>
              Loading Batches...
            </div>
          ) : error ? (
            <div className="notice-card error">
              <Filter size={20} />
              <span>{error}</span>
            </div>
          ) : filteredBatches.length === 0 ? (
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
              <h3>No batches found</h3>
              <p style={{ color: "#64748b" }}>
                Try adjusting your filters or search keywords.
              </p>
            </div>
          ) : (
            <div
              className="batch-grid"
              style={{
                display: "grid",
                gridTemplateColumns: "repeat(3, minmax(0, 1fr))",
                gap: "1rem",
              }}
            >
              {filteredBatches.map((batch) => {
                const statusColor = getStatusColor(batch.currentStatus);

                return (
                  <div
                    key={batch._id}
                    onClick={() =>
                      navigate(`/blockchain/verify-batches/${batch._id}`, {
                        state: { batch },
                      })
                    }
                    style={{
                      background: "white",
                      borderRadius: "16px",
                      padding: "1rem 1rem",
                      boxShadow: "0 8px 18px rgba(0,0,0,0.06)",
                      border: "1px solid #eef2f7",
                      cursor: "pointer",
                      transition: "transform 0.2s, box-shadow 0.2s",
                      display: "flex",
                      flexDirection: "column",
                      gap: "0.85rem",
                      position: "relative",
                      overflow: "hidden",
                      minHeight: "190px",
                    }}
                    onMouseOver={(e) => {
                      e.currentTarget.style.transform = "translateY(-2px)";
                      e.currentTarget.style.boxShadow =
                        "0 14px 26px rgba(0,0,0,0.10)";
                    }}
                    onMouseOut={(e) => {
                      e.currentTarget.style.transform = "none";
                      e.currentTarget.style.boxShadow =
                        "0 8px 18px rgba(0,0,0,0.06)";
                    }}
                  >
                    {/* Accent bar */}
                    <div
                      style={{
                        position: "absolute",
                        top: 0,
                        left: 0,
                        right: 0,
                        height: "5px",
                        background: statusColor,
                      }}
                    />

                    {/* Header */}
                    <div
                      style={{
                        display: "flex",
                        justifyContent: "space-between",
                        gap: "0.75rem",
                        alignItems: "flex-start",
                      }}
                    >
                      <div style={{ minWidth: 0 }}>
                        <div
                          style={{
                            fontSize: "0.78rem",
                            color: "#64748b",
                            display: "flex",
                            alignItems: "center",
                            gap: "0.35rem",
                          }}
                        >
                          <Tag size={14} color="#94a3b8" />
                          Batch ID
                        </div>

                        <div
                          style={{
                            marginTop: "0.2rem",
                            fontSize: "1.05rem",
                            fontWeight: "800",
                            color: "#0f172a",
                            whiteSpace: "nowrap",
                            overflow: "hidden",
                            textOverflow: "ellipsis",
                          }}
                          title={batch.batchId || ""}
                        >
                          {batch.batchId || "Unknown Batch"}
                        </div>
                      </div>

                      <ChevronRight size={20} color="#94a3b8" />
                    </div>

                    {/* Status + Date row */}
                    <div
                      style={{
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "space-between",
                        gap: "0.75rem",
                      }}
                    >
                      <span
                        style={{
                          padding: "0.28rem 0.75rem",
                          borderRadius: "999px",
                          fontSize: "0.74rem",
                          fontWeight: "800",
                          background: `${statusColor}14`,
                          color: statusColor,
                          border: `1px solid ${statusColor}35`,
                        }}
                      >
                        {formatStatus(batch.currentStatus)}
                      </span>

                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: "0.4rem",
                          fontSize: "0.82rem",
                          color: "#64748b",
                          whiteSpace: "nowrap",
                        }}
                      >
                        <Calendar size={15} color="#94a3b8" />
                        {formatDate(batch.saleDate)}
                      </div>
                    </div>

                    {/* Details  */}
                    <div
                      style={{
                        display: "grid",
                        gridTemplateColumns: "1fr",
                        gap: "0.55rem",
                        color: "#475569",
                        fontSize: "0.92rem",
                      }}
                    >
                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: "0.55rem",
                        }}
                      >
                        <User size={18} color="#94a3b8" />
                        <div style={{ minWidth: 0 }}>
                          <div
                            style={{ fontSize: "0.76rem", color: "#94a3b8" }}
                          >
                            Farmer
                          </div>
                          <div
                            style={{
                              color: "#0f172a",
                              fontWeight: 700,
                              whiteSpace: "nowrap",
                              overflow: "hidden",
                              textOverflow: "ellipsis",
                            }}
                            title={batch.farmerName || "-"}
                          >
                            {batch.farmerName || "-"}
                          </div>
                        </div>
                      </div>

                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: "0.55rem",
                        }}
                      >
                        <Leaf size={18} color="#94a3b8" />
                        <div style={{ minWidth: 0 }}>
                          <div
                            style={{ fontSize: "0.76rem", color: "#94a3b8" }}
                          >
                            Pepper Type
                          </div>
                          <div
                            style={{
                              color: "#0f172a",
                              fontWeight: 700,
                              whiteSpace: "nowrap",
                              overflow: "hidden",
                              textOverflow: "ellipsis",
                            }}
                            title={batch.pepperType || "-"}
                          >
                            {batch.pepperType || "-"}
                          </div>
                        </div>
                      </div>

                      <div
                        style={{
                          display: "flex",
                          alignItems: "center",
                          gap: "0.55rem",
                        }}
                      >
                        <MapPin size={18} color="#94a3b8" />
                        <div style={{ minWidth: 0 }}>
                          <div
                            style={{ fontSize: "0.76rem", color: "#94a3b8" }}
                          >
                            District
                          </div>
                          <div
                            style={{
                              color: "#0f172a",
                              fontWeight: 700,
                              whiteSpace: "nowrap",
                              overflow: "hidden",
                              textOverflow: "ellipsis",
                            }}
                            title={batch.district || "-"}
                          >
                            {batch.district || "-"}
                          </div>
                        </div>
                      </div>
                    </div>
                  </div>
                );
              })}
            </div>
          )}

          <style>
            {`
              @media (max-width: 720px) {
                .batch-grid {
                  grid-template-columns: 1fr !important;
                }
              }
            `}
          </style>
        </div>
      </main>
    </div>
  );
}
