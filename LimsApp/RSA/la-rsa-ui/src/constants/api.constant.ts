// For Binod dev mock http://10.0.1.207:5001/api/v1
// For internal client mock 'http://localhost:3000/api'
// REMEMBER to uncomment the development server line in App.tsx for iternal client mock
export const BASE_URL =
  process.env.NODE_ENV === 'production'
    ? `${window.serviceEndpoint}/api/v1`
    : 'http://10.0.1.207:5001/api/v1';
