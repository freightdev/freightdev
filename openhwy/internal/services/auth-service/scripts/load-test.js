// scripts/load-test.js
import { check, sleep } from "k6";
import http from "k6/http";
import { Rate } from "k6/metrics";

// Custom metrics
const errorRate = new Rate("errors");

export const options = {
    stages: [
        { duration: "2m", target: 10 }, // Ramp-up
        { duration: "5m", target: 50 }, // Stay at 50 users
        { duration: "2m", target: 100 }, // Ramp-up to 100 users
        { duration: "5m", target: 100 }, // Stay at 100 users
        { duration: "2m", target: 0 }, // Ramp-down
    ],
    thresholds: {
        http_req_duration: ["p(95)<500"], // 95% of requests should be below 500ms
        http_req_failed: ["rate<0.1"], // Error rate should be less than 10%
        errors: ["rate<0.1"],
    },
};

const BASE_URL = __ENV.BASE_URL || "http://localhost:8080";

export function setup() {
    // Register a test user
    const registerPayload = {
        email: `testuser-${Date.now()}@example.com`,
        password: "TestPassword123!",
        first_name: "Test",
        last_name: "User",
    };

    const registerRes = http.post(
        `${BASE_URL}/api/v1/auth/register`,
        JSON.stringify(registerPayload),
        {
            headers: { "Content-Type": "application/json" },
        },
    );

    return {
        email: registerPayload.email,
        password: registerPayload.password,
    };
}

export default function (data) {
    // Health check
    let res = http.get(`${BASE_URL}/health`);
    check(res, {
        "health check status is 200": (r) => r.status === 200,
    }) || errorRate.add(1);

    sleep(1);

    // Login
    const loginPayload = {
        email: data.email,
        password: data.password,
    };

    res = http.post(
        `${BASE_URL}/api/v1/auth/login`,
        JSON.stringify(loginPayload),
        {
            headers: { "Content-Type": "application/json" },
        },
    );

    const loginSuccess = check(res, {
        "login status is 200": (r) => r.status === 200,
        "login response has access_token": (r) =>
            JSON.parse(r.body).access_token !== undefined,
    });

    if (!loginSuccess) {
        errorRate.add(1);
        return;
    }

    const authData = JSON.parse(res.body);
    const token = authData.access_token;

    sleep(1);

    // Get profile
    res = http.get(`${BASE_URL}/api/v1/profile`, {
        headers: {
            Authorization: `Bearer ${token}`,
            "Content-Type": "application/json",
        },
    });

    check(res, {
        "profile status is 200": (r) => r.status === 200,
        "profile response has email": (r) =>
            JSON.parse(r.body).email !== undefined,
    }) || errorRate.add(1);

    sleep(2);
}

export function teardown(data) {
    console.log("Load test completed");
}
