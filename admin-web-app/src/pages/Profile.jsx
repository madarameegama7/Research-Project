import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import {
    LayoutDashboard, LogOut, User, Settings,
    Badge, Phone, MapPin, Camera, Edit2, ShieldCheck
} from 'lucide-react';
import { getProfile, updateProfile } from '../services/api';
import '../App.css';

export default function Profile() {
    const navigate = useNavigate();
    const [user, setUser] = useState(null);
    const [loading, setLoading] = useState(true);
    const [pageError, setPageError] = useState('');

    // Edit Modal State
    const [isEditModalOpen, setIsEditModalOpen] = useState(false);
    const [editForm, setEditForm] = useState({
        firstName: '',
        lastName: '',
        contact: '',
        location: ''
    });
    const [isSaving, setIsSaving] = useState(false);

    useEffect(() => {
        loadProfile();
    }, []);

    const loadProfile = async () => {
        try {
            setLoading(true);
            setPageError('');
            const data = await getProfile();
            setUser(data);
        } catch (err) {
            console.error("Error loading profile:", err);
            setPageError("Failed to fetch profile data. Please try again.");
        } finally {
            setLoading(false);
        }
    };

    const handleLogout = () => {
        if (window.confirm("Are you sure you want to sign out?")) {
            localStorage.removeItem('token');
            navigate('/');
        }
    };

    const openEditModal = () => {
        if (user) {
            setEditForm({
                firstName: user.firstName || '',
                lastName: user.lastName || '',
                contact: user.contact || '',
                location: user.location || ''
            });
            setIsEditModalOpen(true);
        }
    };

    const handleEditSave = async (e) => {
        e.preventDefault();

        if (!editForm.firstName.trim()) {
            alert("First Name is required.");
            return;
        }

        try {
            setIsSaving(true);
            const updatedProfile = await updateProfile(editForm);
            setUser(updatedProfile);
            setIsEditModalOpen(false);
        } catch (err) {
            console.error("Error updating profile:", err);
            alert("Failed to update profile. Please try again.");
        } finally {
            setIsSaving(false);
        }
    };

    const getInitials = () => {
        if (!user || (!user.firstName && !user.lastName)) return "A";
        return (user.firstName?.[0] || "") + (user.lastName?.[0] || "");
    };

    const getFullName = () => {
        if (!user) return "Admin";
        return `${user.firstName || ''} ${user.lastName || ''}`.trim() || "Admin Mode";
    };

    if (loading) {
        return <div className="loading-screen">Loading Profile...</div>;
    }

    if (pageError) {
        return (
            <div className="dashboard-layout" style={{ justifyContent: 'center', alignItems: 'center' }}>
                <div className="empty-state" style={{ borderColor: 'var(--error)' }}>
                    <ShieldCheck size={48} color="var(--error)" />
                    <h3 style={{ color: 'var(--error)' }}>Cannot Load Profile</h3>
                    <p>{pageError}</p>
                    <button style={{ marginTop: '1rem' }} className="btn-primary" onClick={loadProfile}>Retry</button>
                </div>
            </div>
        );
    }

    return (
        <div className="dashboard-layout">

            {/* Sidebar Navigation */}
            <aside className="sidebar">
                <div className="sidebar-header">
                    <div className="brand-logo-small">
                        <LayoutDashboard size={24} color="#fff" />
                    </div>
                    <h2>Farm Admin</h2>
                </div>

                <nav className="sidebar-nav">
                    <div className="nav-item" onClick={() => navigate('/dashboard')} style={{ cursor: 'pointer' }}>
                        <LayoutDashboard size={20} />
                        <span>Dashboard</span>
                    </div>
                    <div className="nav-item active" style={{ cursor: 'default' }}>
                        <User size={20} />
                        <span>Profile</span>
                    </div>
                    <div className="nav-item inactive">
                        <Settings size={20} />
                        <span>Settings</span>
                    </div>
                </nav>

                <div className="sidebar-footer">
                    <button className="logout-btn" onClick={handleLogout}>
                        <LogOut size={20} />
                        <span>Logout</span>
                    </button>
                </div>
            </aside>

            {/* Main Content Area */}
            <main className="main-content">

                {/* Profile Header Banner matching mobile-app _buildHeader */}
                <header className="profile-banner">
                    <div className="profile-banner-top">
                        <h2>My Profile</h2>
                        <div className="role-badge">
                            <Badge size={16} />
                            <span>{user?.role ? user.role.charAt(0).toUpperCase() + user.role.slice(1) : 'Admin'}</span>
                        </div>
                    </div>

                    <div className="profile-identity">

                        <div className="avatar-container">
                            <div className="avatar-circle">
                                {user?.imageUrl ? (
                                    <img src={user.imageUrl} alt="Profile" />
                                ) : (
                                    <span className="avatar-initials">{getInitials().toUpperCase()}</span>
                                )}
                            </div>
                            {/* Disabled avatar upload ring for Admin layout currently. 
                                We represent the camera icon structurally, but omit the upload logic 
                                as it usually requires configuring Firebase Storage on Web specifically.
                            */}
                            <div className="avatar-edit-icon" title="Editing Avatar not supported in Web Demo">
                                <Camera size={14} />
                            </div>
                        </div>

                        <div className="profile-info">
                            <h1 className="profile-name">{getFullName()}</h1>

                            <div className="profile-meta-row">
                                <span className="material-icon">@</span>
                                <span>{user?.email || 'admin@example.com'}</span>
                            </div>

                            {user?.location && (
                                <div className="profile-meta-row">
                                    <MapPin size={14} />
                                    <span>{user.location}</span>
                                </div>
                            )}
                        </div>
                    </div>
                </header>

                <div className="content-pad" style={{ marginTop: '2rem' }}>

                    <div className="section-title">
                        <div className="title-marker" style={{ backgroundColor: 'var(--primary)' }}></div>
                        <h2>Profile Information</h2>
                    </div>

                    <div className="info-cards-grid">
                        <div className="info-card">
                            <div className="info-icon-wrapper">
                                <Badge size={22} color="var(--primary)" />
                            </div>
                            <div className="info-content">
                                <h4>Role</h4>
                                <p>{user?.role ? user.role.charAt(0).toUpperCase() + user.role.slice(1) : 'Not set'}</p>
                            </div>
                        </div>

                        <div className="info-card">
                            <div className="info-icon-wrapper">
                                <Phone size={22} color="var(--primary)" />
                            </div>
                            <div className="info-content">
                                <h4>Contact</h4>
                                <p>{user?.contact || 'Not set'}</p>
                            </div>
                        </div>

                        <div className="info-card">
                            <div className="info-icon-wrapper">
                                <MapPin size={22} color="var(--primary)" />
                            </div>
                            <div className="info-content">
                                <h4>Location</h4>
                                <p>{user?.location || 'Not set'}</p>
                            </div>
                        </div>
                    </div>

                    <div className="section-title" style={{ marginTop: '3rem' }}>
                        <div className="title-marker" style={{ backgroundColor: 'var(--text-muted)' }}></div>
                        <h2>Account Actions</h2>
                    </div>

                    <div className="account-actions-container">
                        <button className="btn-outline edit-profile-btn" onClick={openEditModal}>
                            <Edit2 size={18} />
                            Edit Profile Details
                        </button>
                    </div>

                </div>
            </main>

            {/* Edit Profile Modal */}
            {isEditModalOpen && (
                <div className="modal-overlay">
                    <div className="modal-content" style={{ maxWidth: '500px' }}>
                        <div style={{ display: 'flex', alignItems: 'center', marginBottom: '1.5rem' }}>
                            <div className="icon-circle" style={{ margin: '0', marginRight: '1rem', width: '40px', height: '40px' }}>
                                <Edit2 size={20} color="var(--primary)" />
                            </div>
                            <h3>Edit Profile</h3>
                        </div>

                        <form onSubmit={handleEditSave} className="login-form">

                            <div style={{ display: 'flex', gap: '1rem' }}>
                                <div className="form-group" style={{ flex: 1 }}>
                                    <label>First Name</label>
                                    <div className="input-wrapper">
                                        <input
                                            type="text"
                                            value={editForm.firstName}
                                            onChange={(e) => setEditForm({ ...editForm, firstName: e.target.value })}
                                            required
                                        />
                                    </div>
                                </div>
                                <div className="form-group" style={{ flex: 1 }}>
                                    <label>Last Name</label>
                                    <div className="input-wrapper">
                                        <input
                                            type="text"
                                            value={editForm.lastName}
                                            onChange={(e) => setEditForm({ ...editForm, lastName: e.target.value })}
                                        />
                                    </div>
                                </div>
                            </div>

                            <div className="form-group">
                                <label>Contact Number</label>
                                <div className="input-wrapper">
                                    <Phone className="input-icon" size={20} />
                                    <input
                                        type="tel"
                                        value={editForm.contact}
                                        onChange={(e) => setEditForm({ ...editForm, contact: e.target.value })}
                                    />
                                </div>
                            </div>

                            <div className="form-group">
                                <label>Location</label>
                                <div className="input-wrapper">
                                    <MapPin className="input-icon" size={20} />
                                    <input
                                        type="text"
                                        value={editForm.location}
                                        onChange={(e) => setEditForm({ ...editForm, location: e.target.value })}
                                    />
                                </div>
                            </div>

                            <div className="modal-actions" style={{ marginTop: '2rem' }}>
                                <button type="button" className="btn-cancel" onClick={() => setIsEditModalOpen(false)}>
                                    Cancel
                                </button>
                                <button type="submit" className="btn-primary" disabled={isSaving}>
                                    {isSaving ? 'Saving...' : 'Save Changes'}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}

        </div>
    );
}
