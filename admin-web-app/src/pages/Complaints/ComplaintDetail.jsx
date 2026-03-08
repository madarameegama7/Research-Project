import { useEffect, useMemo, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import {
  AlertCircle,
  ArrowLeft,
  CheckCircle2,
  Clock,
  HelpCircle,
  MessageSquareMore,
  MoreVertical,
  Trash2,
  Wrench,
} from 'lucide-react';
import {
  COMPLAINT_STATUSES,
  addReplyToComplaint,
  deleteComplaint,
  subscribeComplaintById,
  updateComplaintStatus,
} from '../../services/complaints';
import '../../App.css';

const statusConfig = {
  Pending: { color: '#f97316', badgeClass: 'complaint-badge-pending' },
  'In Progress': { color: '#3b82f6', badgeClass: 'complaint-badge-progress' },
  Resolved: { color: '#22c55e', badgeClass: 'complaint-badge-resolved' },
};

const getStatusBadgeClass = (status) =>
  statusConfig[status]?.badgeClass || 'complaint-badge-default';

const formatTimestamp = (value) => {
  if (!value) return 'N/A';
  let date;
  if (typeof value.toDate === 'function') date = value.toDate();
  else if (typeof value.seconds === 'number') date = new Date(value.seconds * 1000);
  else date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'N/A';
  const h = date.getHours();
  const m = String(date.getMinutes()).padStart(2, '0');
  return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()} ${h}:${m}`;
};

const toMillis = (value) => {
  if (!value) return 0;
  if (typeof value.toMillis === 'function') return value.toMillis();
  if (typeof value.seconds === 'number') return value.seconds * 1000;
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? 0 : d.getTime();
};

const isImageUrl = (url = '') =>
  /\.(jpg|jpeg|png|gif|webp|bmp|svg)(\?.*)?$/i.test(url);

export default function ComplaintDetail() {
  const navigate = useNavigate();
  const { complaintId } = useParams();

  const [complaint, setComplaint] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const [reply, setReply] = useState('');
  const [isSendingReply, setIsSendingReply] = useState(false);

  const [showMenuDropdown, setShowMenuDropdown] = useState(false);
  const [showStatusDialog, setShowStatusDialog] = useState(false);
  const [showDeleteDialog, setShowDeleteDialog] = useState(false);
  const [dialogStatus, setDialogStatus] = useState('Pending');
  const [isUpdatingStatus, setIsUpdatingStatus] = useState(false);
  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    if (!complaintId) {
      setError('Complaint ID is missing.');
      setLoading(false);
      return;
    }
    const unsubscribe = subscribeComplaintById(
      complaintId,
      (data) => {
        setComplaint(data);
        setDialogStatus(data?.status || 'Pending');
        setLoading(false);
      },
      (err) => {
        console.error('Failed to load complaint:', err);
        setError('Failed to load complaint details.');
        setLoading(false);
      }
    );
    return () => unsubscribe();
  }, [complaintId]);

  const sortedReplies = useMemo(() => {
    const arr = Array.isArray(complaint?.replies) ? [...complaint.replies] : [];
    arr.sort((a, b) => toMillis(a?.repliedAt) - toMillis(b?.repliedAt));
    return arr;
  }, [complaint?.replies]);

  const openStatusDialog = () => {
    setDialogStatus(complaint?.status || 'Pending');
    setShowMenuDropdown(false);
    setShowStatusDialog(true);
  };

  const confirmStatusUpdate = async () => {
    try {
      setIsUpdatingStatus(true);
      await updateComplaintStatus(complaintId, dialogStatus);
      setShowStatusDialog(false);
    } catch (err) {
      console.error('Failed to update status:', err);
      alert('Failed to update complaint status.');
    } finally {
      setIsUpdatingStatus(false);
    }
  };

  const handleReplySubmit = async () => {
    if (!reply.trim()) {
      alert('Please enter a reply message');
      return;
    }
    try {
      setIsSendingReply(true);
      await addReplyToComplaint(complaintId, reply.trim(), 'Admin');
      setReply('');
    } catch (err) {
      console.error('Failed to add reply:', err);
      alert('Failed to add reply.');
    } finally {
      setIsSendingReply(false);
    }
  };

  const confirmDelete = async () => {
    try {
      setIsDeleting(true);
      await deleteComplaint(complaintId);
      navigate('/complaints');
    } catch (err) {
      console.error('Failed to delete complaint:', err);
      alert('Failed to delete complaint.');
      setIsDeleting(false);
    }
  };

  return (
    <div className="dashboard-layout" onClick={() => setShowMenuDropdown(false)}>
      <aside className="sidebar">
        <div className="sidebar-header">
          <div className="brand-logo-small">
            <MessageSquareMore size={24} color="#fff" />
          </div>
          <h2>Admin Portal</h2>
        </div>
        <nav className="sidebar-nav">
          <div className="nav-item" onClick={() => navigate('/dashboard')} style={{ cursor: 'pointer' }}>
            <ArrowLeft size={20} />
            <span>Back to Dashboard</span>
          </div>
          <div className="nav-item" onClick={() => navigate('/complaints')} style={{ cursor: 'pointer' }}>
            <MessageSquareMore size={20} />
            <span>Complaints List</span>
          </div>
          <div className="nav-item active">
            <Clock size={20} />
            <span>Complaint Details</span>
          </div>
        </nav>
      </aside>

      <main className="main-content">
        <div className="dashboard-header" style={{ position: 'relative' }}>
          <div className="header-text">
            <div className="greeting">Complaint Review</div>
            <h1>Complaint Details</h1>
          </div>

          {/* Action buttons like mobile app's AppBar actions */}
          {complaint && (
            <div className="detail-header-actions">
              <button
                type="button"
                className="detail-icon-btn"
                onClick={(e) => { e.stopPropagation(); setShowDeleteDialog(true); }}
                title="Delete Complaint"
              >
                <Trash2 size={20} />
              </button>
              <div style={{ position: 'relative' }}>
                <button
                  type="button"
                  className="detail-icon-btn"
                  onClick={(e) => { e.stopPropagation(); setShowMenuDropdown((p) => !p); }}
                  title="More options"
                >
                  <MoreVertical size={20} />
                </button>
                {showMenuDropdown && (
                  <div className="detail-dropdown-menu" onClick={(e) => e.stopPropagation()}>
                    <button type="button" onClick={openStatusDialog}>
                      <Wrench size={16} /> Update Status
                    </button>
                    <button type="button" className="menu-delete" onClick={() => { setShowMenuDropdown(false); setShowDeleteDialog(true); }}>
                      <Trash2 size={16} /> Delete Complaint
                    </button>
                  </div>
                )}
              </div>
            </div>
          )}
        </div>

        <div className="content-pad">
          {loading ? (
            <div className="loading-state">Loading complaint details...</div>
          ) : error ? (
            <div className="empty-state" style={{ borderColor: 'var(--error)' }}>
              <AlertCircle size={48} color="var(--error)" />
              <h3 style={{ color: 'var(--error)' }}>Unable to Load Complaint</h3>
              <p>{error}</p>
            </div>
          ) : !complaint ? (
            <div className="empty-state">
              <AlertCircle size={48} color="var(--text-muted)" />
              <h3>Complaint Not Found</h3>
              <p>This complaint may have been deleted.</p>
            </div>
          ) : (
            <div className="detail-page-body">
              {/* Complaint Header Card */}
              <div className="detail-card">
                <div className="detail-card-header-row">
                  <div>
                    <h2 className="detail-complainant-name">{complaint.name || 'Unknown'}</h2>
                    <p className="detail-complainant-id">ID: {complaint.idNumber || 'N/A'}</p>
                  </div>
                  <span className={`complaint-pill complaint-pill-lg ${getStatusBadgeClass(complaint.status)}`}>
                    {complaint.status || 'Pending'}
                  </span>
                </div>

                <div className="detail-section-label">Complaint Details</div>
                <p className="detail-complaint-text">{complaint.complaint || ''}</p>

                {complaint.attachmentUrl ? (
                  <div className="detail-attachment-section">
                    <div className="detail-section-label">Attachment</div>
                    {isImageUrl(complaint.attachmentUrl) ? (
                      <img
                        src={complaint.attachmentUrl}
                        alt="Complaint attachment"
                        className="detail-attachment-img"
                        onError={(e) => { e.currentTarget.style.display = 'none'; }}
                      />
                    ) : (
                      <div className="detail-attachment-error">
                        <HelpCircle size={40} color="#9ca3af" />
                      </div>
                    )}
                    <a href={complaint.attachmentUrl} target="_blank" rel="noreferrer" className="attachment-link">
                      Open Attachment ↗
                    </a>
                  </div>
                ) : null}

                <div className="detail-timestamps">
                  <p>Submitted: {formatTimestamp(complaint.submittedAt)}</p>
                  {complaint.updatedAt && (
                    <p>Last Updated: {formatTimestamp(complaint.updatedAt)}</p>
                  )}
                </div>
              </div>

              {/* Replies & Updates Section */}
              <h3 className="detail-section-heading">Replies &amp; Updates</h3>

              {sortedReplies.length === 0 ? (
                <div className="detail-no-replies">No replies yet</div>
              ) : (
                <div className="replies-stack">
                  {sortedReplies.map((item, i) => (
                    <div className="reply-card" key={`reply-${i}`}>
                      <div className="reply-card-top">
                        <strong>{item.repliedBy || 'Admin'}</strong>
                        <span>{formatTimestamp(item.repliedAt)}</span>
                      </div>
                      <p>{item.message || ''}</p>
                    </div>
                  ))}
                </div>
              )}

              {/* Add Reply Card */}
              <div className="detail-card">
                <h4 className="detail-add-reply-heading">Add Reply</h4>
                <textarea
                  className="complaint-reply-input"
                  rows={3}
                  value={reply}
                  onChange={(e) => setReply(e.target.value)}
                  placeholder="Type your reply here..."
                />
                <div style={{ display: 'flex', justifyContent: 'flex-end' }}>
                  <button
                    type="button"
                    className="btn-send-reply"
                    onClick={handleReplySubmit}
                    disabled={isSendingReply}
                  >
                    {isSendingReply ? 'Sending...' : 'Send Reply'}
                  </button>
                </div>
              </div>
            </div>
          )}
        </div>
      </main>

      {/* Status Update Dialog */}
      {showStatusDialog && (
        <div className="modal-overlay" onClick={() => setShowStatusDialog(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h3>Update Status</h3>
            <div className="filter-options-list">
              {COMPLAINT_STATUSES.filter((s) => s !== 'All').map((status) => (
                <label key={status} className="filter-option-row">
                  <input
                    type="radio"
                    name="dialogStatus"
                    value={status}
                    checked={dialogStatus === status}
                    onChange={() => setDialogStatus(status)}
                  />
                  <span>{status}</span>
                </label>
              ))}
            </div>
            <div className="modal-actions">
              <button className="btn-cancel" onClick={() => setShowStatusDialog(false)}>Cancel</button>
              <button className="btn-primary" onClick={confirmStatusUpdate} disabled={isUpdatingStatus}>
                {isUpdatingStatus ? 'Updating...' : 'Update'}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Delete Confirmation Dialog */}
      {showDeleteDialog && (
        <div className="modal-overlay" onClick={() => setShowDeleteDialog(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h3>Delete Complaint</h3>
            <p>Are you sure you want to delete this complaint? This action cannot be undone.</p>
            <div className="modal-actions">
              <button className="btn-cancel" onClick={() => setShowDeleteDialog(false)}>Cancel</button>
              <button className="btn-submit-reject" onClick={confirmDelete} disabled={isDeleting}>
                {isDeleting ? 'Deleting...' : 'Delete'}
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}

