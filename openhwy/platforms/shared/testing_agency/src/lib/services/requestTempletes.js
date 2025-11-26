// src/lib/services/requestTemplates.js
// Pre-built request templates for common microservice patterns

export const REQUEST_TEMPLATES = {
    auth: {
        login: {
            name: 'Login',
            method: 'POST',
            endpoint: '/auth/login',
            body: JSON.stringify({ username: '', password: '' }, null, 2),
            bodyType: 'json',
            headers: { 'Content-Type': 'application/json' },
        },
        register: {
            name: 'Register User',
            method: 'POST',
            endpoint: '/auth/register',
            body: JSON.stringify(
                {
                    username: '',
                    email: '',
                    password: '',
                    firstName: '',
                    lastName: '',
                },
                null,
                2
            ),
            bodyType: 'json',
        },
        refresh: {
            name: 'Refresh Token',
            method: 'POST',
            endpoint: '/auth/refresh',
            body: JSON.stringify({ refreshToken: '' }, null, 2),
            bodyType: 'json',
        },
        logout: {
            name: 'Logout',
            method: 'POST',
            endpoint: '/auth/logout',
            bodyType: 'none',
        },
    },
    users: {
        getProfile: {
            name: 'Get User Profile',
            method: 'GET',
            endpoint: '/users/profile',
            bodyType: 'none',
        },
        updateProfile: {
            name: 'Update Profile',
            method: 'PUT',
            endpoint: '/users/profile',
            body: JSON.stringify(
                {
                    firstName: '',
                    lastName: '',
                    email: '',
                },
                null,
                2
            ),
            bodyType: 'json',
        },
        listUsers: {
            name: 'List Users',
            method: 'GET',
            endpoint: '/users',
            params: { page: '1', limit: '10' },
            bodyType: 'none',
        },
        deleteUser: {
            name: 'Delete User',
            method: 'DELETE',
            endpoint: '/users/{userId}',
            bodyType: 'none',
        },
    },
    payments: {
        processPayment: {
            name: 'Process Payment',
            method: 'POST',
            endpoint: '/payments/process',
            body: JSON.stringify(
                {
                    amount: 0,
                    currency: 'USD',
                    paymentMethod: '',
                    description: '',
                },
                null,
                2
            ),
            bodyType: 'json',
        },
        getPayments: {
            name: 'Get Payment History',
            method: 'GET',
            endpoint: '/payments',
            params: { page: '1', limit: '20' },
            bodyType: 'none',
        },
        refundPayment: {
            name: 'Refund Payment',
            method: 'POST',
            endpoint: '/payments/{paymentId}/refund',
            body: JSON.stringify(
                {
                    amount: 0,
                    reason: '',
                },
                null,
                2
            ),
            bodyType: 'json',
        },
    },
};
