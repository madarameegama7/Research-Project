import axios from 'axios';

// Create an instance of axios with standard setup
const api = axios.create({
    baseURL: 'https://research-backend-755295357792.us-central1.run.app/api',
    headers: {
        'Content-Type': 'application/json',
    },
});

// Add a request interceptor to include auth tokens if needed
api.interceptors.request.use(
    (config) => {
        const token = localStorage.getItem('token');
        if (token) {
            config.headers.Authorization = `Bearer ${token}`;
        }
        return config;
    },
    (error) => {
        return Promise.reject(error);
    }
);

// Add a response interceptor for universal error handling
api.interceptors.response.use(
    (response) => response,
    (error) => {
        if (error.response && error.response.status === 401) {
            // Handle unauthorized access (e.g., clear token, redirect to login)
            localStorage.removeItem('token');
            window.location.href = '/';
        }
        return Promise.reject(error);
    }
);

export default api;

export const fetchPendingCertificates = async () => {
    const response = await api.get('/certifications/admin/all?status=pending');
    return response.data;
};

export const verifyCertificate = async (id) => {
    const response = await api.patch(`/certifications/admin/${id}/verify`, {
        action: 'verify'
    });
    return response.data;
};

export const rejectCertificate = async (id, reason) => {
    const response = await api.patch(`/certifications/admin/${id}/verify`, {
        action: 'reject',
        reason: reason
    });
    return response.data;
};

// --- User Endpoints ---

export const getProfile = async () => {
    const response = await api.get('/users/me');
    return response.data;
};

export const updateProfile = async (data) => {
    const response = await api.put('/users/me', data);
    return response.data;
};

// --- Blockchain & Market Forecast Endpoints ---

export const fetchActualPriceData = async (params = {}) => {
    const response = await api.get('/market-forecast/actual-price-data', { params });
    return response.data;
};

export const verifyBatchRecord = async (recordId) => {
    const response = await api.put(`/market-forecast/actual-price-data/${recordId}`, {
        currentStatus: 'VERIFIED'
    });
    return response.data;
};

export const generateBatchQr = async (recordId) => {
    const response = await api.put(`/market-forecast/actual-price-data/${recordId}`, {
        currentStatus: 'QR_GENERATED'
    });
    return response.data;
};

export const getQualityChecksByBatch = async (batchId) => {
    const response = await api.get(`/quality-checks/batch/${batchId}`);
    return response.data;
};

