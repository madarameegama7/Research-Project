import { useState } from 'react';
import { Menu, X } from 'lucide-react';
import '../App.css';

export default function SharedLayout({
    sidebarHeaderIcon,
    sidebarTitle,
    sidebarNav,
    sidebarFooter,
    children
}) {
    const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false);

    return (
        <div className="dashboard-layout">
            {/* Mobile Menu Overlay */}
            {isMobileMenuOpen && (
                <div
                    className="mobile-overlay"
                    onClick={() => setIsMobileMenuOpen(false)}
                />
            )}

            <aside className={`sidebar ${isMobileMenuOpen ? 'open' : ''}`}>
                <div className="sidebar-header">
                    <div style={{ display: 'flex', alignItems: 'center', gap: '12px', flex: 1 }}>
                        <div className="brand-logo-small">
                            {sidebarHeaderIcon}
                        </div>
                        <h2>{sidebarTitle}</h2>
                    </div>
                    <button
                        className="mobile-close-btn"
                        onClick={() => setIsMobileMenuOpen(false)}
                        aria-label="Close menu"
                    >
                        <X size={24} />
                    </button>
                </div>

                <nav className="sidebar-nav">
                    {sidebarNav}
                </nav>

                {sidebarFooter && (
                    <div className="sidebar-footer">
                        {sidebarFooter}
                    </div>
                )}
            </aside>

            {/* Main Content Area */}
            <main className="main-content">
                {/* Mobile Header (Hidden on Desktop) */}
                <div className="mobile-top-bar">
                    <button
                        className="mobile-menu-btn"
                        onClick={() => setIsMobileMenuOpen(true)}
                        aria-label="Open menu"
                    >
                        <Menu size={24} />
                    </button>
                    <span className="mobile-top-title">{sidebarTitle}</span>
                </div>

                {children}
            </main>
        </div>
    );
}
