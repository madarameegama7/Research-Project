import { useNavigate } from "react-router-dom";
import {
  CheckCircle,
  QrCode,
  ArrowLeft,
  Info,
  ShieldCheck,
  ChevronRight,
} from "lucide-react";
import SharedLayout from "../../components/SharedLayout";
import "../../App.css";

export default function BlockchainDashboard() {
  const navigate = useNavigate();

  // Theme colors
  const colors = {
    verify: {
      accent: "#16a34a",
      soft: "#dcfce7",
      border: "#86efac",
    },
    qr: {
      accent: "#8da0d2",
      soft: "#dbeafe",
      border: "#93c5fd",
    },
    info: {
      accent: "#d97706",
      soft: "#ffffff",
      border: "#fcd34d",
    },
  };

  const cardBase = {
    backgroundColor: "#ffffff",
    borderRadius: "16px",
    padding: "1.5rem 1.75rem",
    display: "flex",
    alignItems: "center",
    gap: "1.25rem",
    cursor: "pointer",
    boxShadow: "0 10px 26px rgba(0,0,0,0.10)",
    transition: "transform 0.18s ease, box-shadow 0.18s ease",
    position: "relative",
    overflow: "hidden",
  };

  const iconWrapBase = {
    width: "56px",
    height: "56px",
    borderRadius: "14px",
    display: "flex",
    alignItems: "center",
    justifyContent: "center",
    flexShrink: 0,
    border: "1px solid #e5e7eb",
  };

  const onCardEnter = (e, accent) => {
    e.currentTarget.style.transform = "translateY(-3px)";
    e.currentTarget.style.boxShadow = `0 18px 38px rgba(0,0,0,0.14), 0 0 0 4px ${accent}22`;
  };

  const onCardLeave = (e) => {
    e.currentTarget.style.transform = "translateY(0px)";
    e.currentTarget.style.boxShadow = "0 10px 26px rgba(0,0,0,0.10)";
  };

  return (
    <SharedLayout
      sidebarHeaderIcon={<ShieldCheck size={24} color="#fff" />}
      sidebarTitle="Admin Portal"
      sidebarNav={
        <>
          <div
            className="nav-item"
            onClick={() => navigate("/dashboard")}
            style={{ cursor: "pointer" }}
          >
            <ArrowLeft size={20} />
            <span>Back to Dashboard</span>
          </div>
          <div className="nav-item active">
            <CheckCircle size={20} />
            <span>Blockchain System</span>
          </div>
          <div
            className="nav-item"
            onClick={() => navigate("/blockchain/verify-batches")}
            style={{ cursor: "pointer" }}
          >
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
        </>
      }
    >
      <header
        className="dashboard-header"
        style={{ marginBottom: "1.75rem" }}
      >
        <div className="header-text">
          <div className="greeting">Blockchain System</div>
          <h1>Verification Process</h1>
        </div>
      </header>

      <div className="content-pad" style={{ maxWidth: "900px" }}>
        {/* Info banner */}
        <div
          className="notice-card"
          style={{
            backgroundColor: colors.info.soft,
            border: `1px solid ${colors.info.border}`,
            marginBottom: "1.5rem",
            display: "flex",
            alignItems: "flex-start",
            gap: "1rem",
            padding: "1.25rem",
            borderRadius: "16px",
            boxShadow: "0 8px 20px rgba(0,0,0,0.08)",
          }}
        >
          <div
            style={{
              ...iconWrapBase,
              width: 44,
              height: 44,
              borderRadius: 12,
              background: "#fff",
              border: `1px solid ${colors.info.border}`,
            }}
          >
            <Info size={22} color={colors.info.accent} />
          </div>

          <p style={{ color: "#111827", margin: 0, lineHeight: 1.5 }}>
            Please verify pepper batches to ensure QR codes represent{" "}
            <b>approved products</b>. Tap <b>“Verify Pepper Batches”</b> to
            proceed.
          </p>
        </div>

        {/* Navigation cards */}
        <div
          className="feature-grid"
          style={{
            display: "grid",
            gridTemplateColumns: "repeat(2, minmax(0, 1fr))",
            gap: "1.25rem",
          }}
        >
          {/* Verify Batches */}
          <div
            role="button"
            tabIndex={0}
            style={{
              ...cardBase,
              border: `1px solid ${colors.verify.border}`,
            }}
            onClick={() => navigate("/blockchain/verify-batches")}
            onKeyDown={(e) =>
              e.key === "Enter" && navigate("/blockchain/verify-batches")
            }
            onMouseEnter={(e) => onCardEnter(e, colors.verify.accent)}
            onMouseLeave={onCardLeave}
          >
            {/* left accent bar */}
            <div
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                bottom: 0,
                width: "6px",
                background: colors.verify.accent,
              }}
            />

            <div
              style={{
                ...iconWrapBase,
                background: colors.verify.soft,
                border: `1px solid ${colors.verify.border}`,
              }}
            >
              <CheckCircle size={28} color={colors.verify.accent} />
            </div>

            <div style={{ flex: 1, minWidth: 0 }}>
              <h3
                style={{ margin: 0, color: "#111827", fontSize: "1.15rem" }}
              >
                Verify Pepper Batches
              </h3>
              <p style={{ margin: "0.35rem 0 0 0", color: "#6b7280" }}>
                Review submitted batches and mark them as verified
              </p>
            </div>

            <ChevronRight size={22} color={colors.verify.accent} />
          </div>

          {/* Generate QR */}
          <div
            role="button"
            tabIndex={0}
            style={{
              ...cardBase,
              border: `1px solid ${colors.qr.border}`,
            }}
            onClick={() => navigate("/blockchain/generate-qr")}
            onKeyDown={(e) =>
              e.key === "Enter" && navigate("/blockchain/generate-qr")
            }
            onMouseEnter={(e) => onCardEnter(e, colors.qr.accent)}
            onMouseLeave={onCardLeave}
          >
            {/* left accent bar */}
            <div
              style={{
                position: "absolute",
                left: 0,
                top: 0,
                bottom: 0,
                width: "6px",
                background: colors.qr.accent,
              }}
            />

            <div
              style={{
                ...iconWrapBase,
                background: colors.qr.soft,
                border: `1px solid ${colors.qr.border}`,
              }}
            >
              <QrCode size={28} color={colors.qr.accent} />
            </div>

            <div style={{ flex: 1, minWidth: 0 }}>
              <h3
                style={{ margin: 0, color: "#111827", fontSize: "1.15rem" }}
              >
                Generate QR Code
              </h3>
              <p style={{ margin: "0.35rem 0 0 0", color: "#6b7280" }}>
                Create QR codes for admin-verified batches
              </p>
            </div>

            <ChevronRight size={22} color={colors.qr.accent} />
          </div>
        </div>

        <style>
          {`
              @media (max-width: 900px) {
                .feature-grid {
                  grid-template-columns: 1fr !important;
                }
              }
            `}
        </style>
      </div>
    </SharedLayout>
  );
}
