import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import Login from './pages/Login';
import Dashboard from './pages/Dashboard';
import ForgotPassword from './pages/ForgotPassword';
import VerifyCertificates from './pages/VerifyCertificates';
import Profile from './pages/Profile';
import BlockchainDashboard from './pages/Blockchain/BlockchainDashboard';
import VerifyBatches from './pages/Blockchain/VerifyBatches';
import VerifyBatchDetails from './pages/Blockchain/VerifyBatchDetails';
import QRGeneration from './pages/Blockchain/QRGeneration';
import ComplaintsList from './pages/Complaints/ComplaintsList';
import ComplaintDetail from './pages/Complaints/ComplaintDetail';
import './App.css';

function App() {
  return (
    <Router>
      <Routes>
        <Route path="/" element={<Login />} />
        <Route path="/dashboard" element={<Dashboard />} />
        <Route path="/forgot-password" element={<ForgotPassword />} />
        <Route path="/verify-certificates" element={<VerifyCertificates />} />
        <Route path="/profile" element={<Profile />} />

        {/* Complaints Feature Routes */}
        <Route path="/complaints" element={<ComplaintsList />} />
        <Route path="/complaints/:complaintId" element={<ComplaintDetail />} />

        {/* Blockchain Feature Routes */}
        <Route path="/blockchain" element={<BlockchainDashboard />} />
        <Route path="/blockchain/verify-batches" element={<VerifyBatches />} />
        <Route path="/blockchain/verify-batches/:batchId" element={<VerifyBatchDetails />} />
        <Route path="/blockchain/generate-qr" element={<QRGeneration />} />

        {/* Fallback route */}
        <Route path="*" element={<Navigate to="/" replace />} />
      </Routes>
    </Router>
  );
}

export default App;
