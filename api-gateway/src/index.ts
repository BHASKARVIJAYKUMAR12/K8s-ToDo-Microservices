import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import rateLimit from "express-rate-limit";
import { createProxyMiddleware } from "http-proxy-middleware";
import dotenv from "dotenv";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 8080;

// Security middleware
app.use(helmet());

// CORS configuration - simplified and environment-aware
const allowedOrigins = process.env.ALLOWED_ORIGINS
  ? process.env.ALLOWED_ORIGINS.split(",")
  : [
      "http://localhost:3000", // Local React dev server
      "http://frontend-service", // Kubernetes service name
      "http://frontend-service:80", // Kubernetes service with port
    ];

app.use(
  cors({
    origin: function (origin, callback) {
      // Allow requests with no origin (like mobile apps, curl, or Postman)
      if (!origin) return callback(null, true);

      // In development mode, allow all origins
      if (process.env.NODE_ENV === "development") {
        return callback(null, true);
      }

      // Check if origin is in allowed list
      if (allowedOrigins.includes(origin)) {
        callback(null, true);
      } else {
        console.warn(`CORS blocked origin: ${origin}`);
        callback(new Error("Not allowed by CORS"));
      }
    },
    credentials: true,
    methods: ["GET", "POST", "PUT", "DELETE", "PATCH", "OPTIONS"],
    allowedHeaders: ["Content-Type", "Authorization"],
    exposedHeaders: ["Content-Range", "X-Content-Range"],
    maxAge: 600, // Cache preflight for 10 minutes
  })
);

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: "Too many requests from this IP, please try again later.",
});
app.use(limiter);

// Logging
app.use(morgan("combined"));

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    service: "api-gateway",
  });
});

// Service URLs from environment variables
const TODO_SERVICE_URL =
  process.env.TODO_SERVICE_URL || "http://localhost:3001";
const USER_SERVICE_URL =
  process.env.USER_SERVICE_URL || "http://localhost:3002";
const NOTIFICATION_SERVICE_URL =
  process.env.NOTIFICATION_SERVICE_URL || "http://localhost:3003";

// Proxy configuration for microservices
const createProxy = (target: string, pathRewrite?: any) => {
  return createProxyMiddleware({
    target,
    changeOrigin: true,
    pathRewrite,
    timeout: 30000, // 30 second timeout
    proxyTimeout: 30000,
    onProxyReq: (proxyReq, req, res) => {
      // Forward authorization header
      if (req.headers.authorization) {
        proxyReq.setHeader("authorization", req.headers.authorization);
      }

      // Log proxy requests
      console.log(`[PROXY] ${req.method} ${req.path} -> ${target}${req.path}`);
    },
    onProxyRes: (proxyRes, req, res) => {
      console.log(
        `[PROXY RESPONSE] ${req.method} ${req.path} -> ${proxyRes.statusCode}`
      );
    },
    onError: (err, req, res) => {
      console.error(`[PROXY ERROR] ${req.method} ${req.path}:`, err.message);
      if (!res.headersSent) {
        res.status(500).json({
          error: "Service unavailable",
          message: "Unable to connect to the requested service",
        });
      }
    },
  });
};

// Route to Todo Service
app.use(
  "/api/todos",
  createProxy(TODO_SERVICE_URL, {
    "^/api/todos": "/api/todos",
  })
);

// Route to User Service (Auth)
app.use(
  "/api/auth",
  createProxy(USER_SERVICE_URL, {
    "^/api/auth": "/api/auth",
  })
);

app.use(
  "/api/users",
  createProxy(USER_SERVICE_URL, {
    "^/api/users": "/api/users",
  })
);

// Route to Notification Service
app.use(
  "/api/notifications",
  createProxy(NOTIFICATION_SERVICE_URL, {
    "^/api/notifications": "/api/notifications",
  })
);

// Body parsing (only for non-proxied routes)
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));

// Catch-all route for undefined endpoints
app.use("*", (req, res) => {
  res.status(404).json({
    error: "Not Found",
    message: `Route ${req.originalUrl} not found`,
    availableRoutes: [
      "GET /health",
      "POST /api/auth/login",
      "POST /api/auth/register",
      "GET /api/todos",
      "POST /api/todos",
      "PUT /api/todos/:id",
      "DELETE /api/todos/:id",
      "GET /api/notifications",
    ],
  });
});

// Global error handler
app.use(
  (
    err: any,
    req: express.Request,
    res: express.Response,
    next: express.NextFunction
  ) => {
    console.error("Unhandled error:", err);
    res.status(500).json({
      error: "Internal Server Error",
      message: "Something went wrong on our end",
    });
  }
);

app.listen(PORT, () => {
  console.log(`🚀 API Gateway running on port ${PORT}`);
  console.log(`📋 Todo Service: ${TODO_SERVICE_URL}`);
  console.log(`👤 User Service: ${USER_SERVICE_URL}`);
  console.log(`📢 Notification Service: ${NOTIFICATION_SERVICE_URL}`);
  console.log(
    `🌐 Frontend URL: ${
      process.env.FRONTEND_URL ||
      "http://localhost:3000" ||
      "http://localhost:32396"
    }`
  );
});

export default app;
