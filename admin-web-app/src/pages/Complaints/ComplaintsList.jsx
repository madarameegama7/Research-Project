import { useEffect, useMemo, useState } from 'react';
import { useNavigate } from 'react-router-dom';
import {
  Activity,
  AlertCircle,
  ArrowLeft,
  ArrowRight,
  CheckCircle2,
  Clock,
  Filter,
  HelpCircle,
  MessageSquareMore,
  Wrench,
} from 'lucide-react';
import { COMPLAINT_STATUSES, subscribeComplaints } from '../../services/complaints';
import '../../App.css';

const statusConfig = {
  Pending: {
    icon: <Clock size={22} />,
    bgClass: 'status-icon-pending',
    badgeClass: 'complaint-badge-pending',
    label: 'Pending',
  },
  'In Progress': {
    icon: <Wrench size={22} />,
    bgClass: 'status-icon-progress',
    badgeClass: 'complaint-badge-progress',
    label: 'In Progress',
  },
  Resolved: {
    icon: <CheckCircle2 size={22} />,
    bgClass: 'status-icon-resolved',
    badgeClass: 'complaint-badge-resolved',
    label: 'Resolved',
  },
};

const getStatusConfig = (status) =>
  statusConfig[status] || {
    icon: <HelpCircle size={22} />,
    bgClass: 'status-icon-default',
    badgeClass: 'complaint-badge-default',
    label: status || 'Pending',
  };

const formatDate = (value) => {
  if (!value) return 'N/A';
  let date;
  if (typeof value.toDate === 'function') date = value.toDate();
  else if (typeof value.seconds === 'number') date = new Date(value.seconds * 1000);
  else date = new Date(value);
  if (Number.isNaN(date.getTime())) return 'N/A';
  return `${date.getDate()}/${date.getMonth() + 1}/${date.getFullYear()}`;
};

export default function ComplaintsList() {
  const navigate = useNavigate();
  const [complaints, setComplaints] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [statusFilter, setStatusFilter] = useState('All');
  const [showFilterModal, setShowFilterModal] = useState(false);

  useEffect(() => {
    const unsubscribe = subscribeComplaints(
      (rows) => {
        setComplaints(rows);
        setLoading(false);
      },
      (err) => {
        console.error('Failed to load complaints:', err);
        setError('Failed to load complaints. Please check your Firebase access.');
        setLoading(false);
      }
    );
    return () => unsubscribe();
  }, []);

  const visibleComplaints = useMemo(() => {
    if (statusFilter === 'All') return complaints;
    return complaints.filter((c) => c.status === statusFilter);
  }, [complaints, statusFilter]);

  return (
    <div className="dashboard-layout">
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
          <div className="nav-item active">
            <Activity size={20} />
            <span>Manage Complaints</span>
          </div>
        </nav>
      </aside>

      <main className="main-content">
        <div className="dashboard-header">
          <div className="header-text">
            <div className="greeting">Support Center</div>
            <h1>Complaints Management</h1>
          </div>
          <button
            type="button"
            className="complaints-filter-btn"
            onClick={() => setShowFilterModal(true)}
            title="Filter Complaints"
          >
            <Filter size={18} />
            Filter
          </button>
        </div>

        <div className="content-pad">
          {/* Active filter chip */}
          <div className="complaints-filter-row">
            <span className="complaints-filter-label-text">Filter:</span>
            <span className="complaints-active-chip">{statusFilter}</span>
          </div>

          {loading ? (
            <div className="loading-state">Loading complaints...</div>
          ) : error ? (
            <div className="empty-state" style={{ borderColor: 'var(--error)' }}>
              <AlertCircle size={48} color="var(--error)" />
              <h3 style={{ color: 'var(--error)' }}>Unable to Load Complaints</h3>
              <p>{error}</p>
            </div>
          ) : complaints.length === 0 ? (
            <div className="empty-state">
              <MessageSquareMore size={64} color="#9ca3af" />
              <h3>No Complaints Yet</h3>
              <p>All submitted complaints will appear here</p>
            </div>
          ) : visibleComplaints.length === 0 ? (
            <div className="empty-state">
              <Filter size={64} color="#9ca3af" />
              <h3>No {statusFilter} Complaints</h3>
              <p>Try changing the filter</p>
            </div>
          ) : (
            <div className="complaints-list">
              {visibleComplaints.map((complaint) => {
                const cfg = getStatusConfig(complaint.status);
                return (
                  <button
                    type="button"
                    key={complaint.id}
                    className="complaint-card"
                    onClick={() => navigate(`/complaints/${complaint.id}`)}
                  >
                    {/* Status Icon Circle */}
                    <div className={`complaint-status-icon ${cfg.bgClass}`}>
                      {cfg.icon}
                    </div>

                    {/* Content */}
                    <div className="complaint-card-body">
                      <p className="complaint-card-name">{complaint.name || 'Unknown'}</p>
                      <p className="complaint-card-id">ID: {complaint.idNumber || 'N/A'}</p>
                      <p className="complaint-card-message">{complaint.complaint || ''}</p>
                      <div className="complaint-card-footer">
                        <span className={`complaint-pill ${cfg.badgeClass}`}>{cfg.label}</span>
                        <span className="complaint-card-date">{formatDate(complaint.submittedAt)}</span>
                      </div>
                    </div>

                    {/* Arrow */}
                    <ArrowRight size={16} className="complaint-card-arrow" />
                  </button>
                );
              })}
            </div>
          )}
        </div>
      </main>

      {/* Filter Modal */}
      {showFilterModal && (
        <div className="modal-overlay" onClick={() => setShowFilterModal(false)}>
          <div className="modal-content" onClick={(e) => e.stopPropagation()}>
            <h3>Filter Complaints</h3>
            <div className="filter-options-list">
              {COMPLAINT_STATUSES.map((status) => (
                <label key={status} className="filter-option-row">
                  <input
                    type="radio"
                    name="filterStatus"
                    value={status}
                    checked={statusFilter === status}
                    onChange={() => {
                      setStatusFilter(status);
                      setShowFilterModal(false);
                    }}
                  />
                  <span>{status}</span>
                </label>
              ))}
            </div>
            <div className="modal-actions">
              <button className="btn-cancel" onClick={() => setShowFilterModal(false)}>
                Cancel
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
}
