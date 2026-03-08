import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
    ArrowLeft, FileCheck, FileX, ShieldCheck,
    ExternalLink, Search, Filter, AlertCircle
} from 'lucide-react';
import { fetchPendingCertificates, verifyCertificate, rejectCertificate } from '../services/api';
import SharedLayout from '../components/SharedLayout';
import '../App.css';

export default function VerifyCertificates() {
    const navigate = useNavigate();
    const [certificates, setCertificates] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    // Reject Modal State
    const [selectedCertId, setSelectedCertId] = useState(null);
    const [rejectReason, setRejectReason] = useState('');
    const [isRejectModalOpen, setIsRejectModalOpen] = useState(false);

    useEffect(() => {
        loadCertificates();
    }, []);

    const loadCertificates = async () => {
        try {
            setLoading(true);
            setError('');
            const data = await fetchPendingCertificates();
            setCertificates(data);
        } catch (err) {
            console.error("Failed to load certificates:", err);
            setError("Failed to load pending certificates. Please check your connection to the backend server.");
        } finally {
            setLoading(false);
        }
    };

    const handleVerify = async (id) => {
        if (!window.confirm("Are you sure you want to verify this certificate?")) return;

        try {
            await verifyCertificate(id);

            // Remove from list
            setCertificates(prev => prev.filter(c => c._id !== id));
            alert("Certificate verified successfully");
        } catch (err) {
            console.error("Error verifying certificate:", err);
            alert(err.response?.data?.message || "Error verifying certificate");
        }
    };

    const openRejectModal = (id) => {
        setSelectedCertId(id);
        setRejectReason('');
        setIsRejectModalOpen(true);
    };

    const submitReject = async () => {
        if (!rejectReason.trim()) {
            alert("Please provide a rejection reason.");
            return;
        }

        try {
            await rejectCertificate(selectedCertId, rejectReason);

            // Remove from list
            setCertificates(prev => prev.filter(c => c._id !== selectedCertId));
            setIsRejectModalOpen(false);
            alert("Certificate rejected");
        } catch (err) {
            console.error("Error rejecting certificate:", err);
            alert(err.response?.data?.message || "Error rejecting certificate");
        }
    };

    const formatDate = (dateString) => {
        if (!dateString) return 'N/A';
        return new Date(dateString).toLocaleDateString('en-US', {
            year: 'numeric', month: 'short', day: 'numeric'
        });
    };

    return (
        <SharedLayout
            sidebarHeaderIcon={<ShieldCheck size={24} color="#fff" />}
            sidebarTitle="Admin Portal"
            sidebarNav={
                <>
                    <div className="nav-item" onClick={() => navigate('/dashboard')} style={{ cursor: 'pointer' }}>
                        <ArrowLeft size={20} />
                        <span>Back to Dashboard</span>
                    </div>
                    <div className="nav-item active">
                        <FileCheck size={20} />
                        <span>Verify Certificates</span>
                    </div>
                </>
            }
        >
            <div className="dashboard-header">
                <div className="header-text">
                    <div className="greeting">Review Hub</div>
                    <h1>Pending Certificates</h1>
                </div>
            </div>

            <div className="content-pad">

                {loading ? (
                    <div className="loading-state">Loading pending records...</div>
                ) : error ? (
                    <div className="empty-state" style={{ borderColor: 'var(--error)' }}>
                        <AlertCircle size={48} color="var(--error)" />
                        <h3 style={{ color: 'var(--error)' }}>Connection Error</h3>
                        <p>{error}</p>
                    </div>
                ) : certificates.length === 0 ? (
                    <div className="empty-state">
                        <ShieldCheck size={48} color="var(--text-muted)" />
                        <h3>All Caught Up!</h3>
                        <p>There are no pending certificates to verify at the moment.</p>
                    </div>
                ) : (
                    <div className="cert-list">
                        {certificates.map(cert => (
                            <div key={cert._id} className="cert-card">
                                <div className="cert-header">
                                    <div className="cert-title-area">
                                        <h3>{cert.certificationType}</h3>
                                        <span className="cert-number">#{cert.certificateNumber}</span>
                                    </div>
                                    <span className="badge-pending">Pending Review</span>
                                </div>

                                <div className="cert-details">
                                    <div className="detail-item">
                                        <span className="detail-label">Farmer UID</span>
                                        <span className="detail-value">{cert.firebaseUid}</span>
                                    </div>
                                    <div className="detail-item">
                                        <span className="detail-label">Issuing Body</span>
                                        <span className="detail-value">{cert.issuingBody}</span>
                                    </div>
                                    <div className="detail-item">
                                        <span className="detail-label">Issue Date</span>
                                        <span className="detail-value">{formatDate(cert.issueDate)}</span>
                                    </div>
                                    <div className="detail-item">
                                        <span className="detail-label">Expiry Date</span>
                                        <span className="detail-value">{formatDate(cert.expiryDate)}</span>
                                    </div>
                                </div>

                                <div className="cert-actions">
                                    {cert.attachment?.url ? (
                                        <a
                                            href={cert.attachment.url}
                                            target="_blank"
                                            rel="noopener noreferrer"
                                            className="btn-outline view-doc-btn"
                                        >
                                            <ExternalLink size={16} />
                                            View Document
                                        </a>
                                    ) : (
                                        <div className="no-doc-note">
                                            <AlertCircle size={16} /> No attachment provided
                                        </div>
                                    )}

                                    <div className="action-buttons">
                                        <button
                                            className="btn-reject"
                                            onClick={() => openRejectModal(cert._id)}
                                        >
                                            <FileX size={18} /> Reject
                                        </button>
                                        <button
                                            className="btn-verify"
                                            onClick={() => handleVerify(cert._id)}
                                        >
                                            <FileCheck size={18} /> Verify
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

            </div>

            {/* Reject Modal */}
            {
                isRejectModalOpen && (
                    <div className="modal-overlay">
                        <div className="modal-content">
                            <h3>Reject Certificate</h3>
                            <p>Please provide a reason for rejecting this certification. This will be sent to the farmer.</p>

                            <textarea
                                value={rejectReason}
                                onChange={(e) => setRejectReason(e.target.value)}
                                placeholder="e.g. The uploaded document is blurry / Date is expired..."
                                rows={4}
                                className="reject-textarea"
                            />

                            <div className="modal-actions">
                                <button className="btn-cancel" onClick={() => setIsRejectModalOpen(false)}>
                                    Cancel
                                </button>
                                <button className="btn-submit-reject" onClick={submitReject}>
                                    Confirm Rejection
                                </button>
                            </div>
                        </div>
                    </div>
                )
            }

        </SharedLayout >
    );
}
