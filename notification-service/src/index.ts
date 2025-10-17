import express from "express";
import cors from "cors";
import helmet from "helmet";
import morgan from "morgan";
import dotenv from "dotenv";
import { createClient } from "redis";

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3003;

// Redis client setup
const redisClient = createClient({
  url: `redis://${process.env.REDIS_HOST || "localhost"}:${
    process.env.REDIS_PORT || 6379
  }`,
});

// Middleware
app.use(helmet());
app.use(cors());
app.use(morgan("combined"));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));

// Health check endpoint
app.get("/health", (req, res) => {
  res.status(200).json({
    status: "healthy",
    timestamp: new Date().toISOString(),
    service: "notification-service",
    redis: redisClient.isOpen ? "connected" : "disconnected",
  });
});

// Notification endpoints
app.post("/api/notifications/send", async (req, res) => {
  try {
    const { userId, message, type = "info" } = req.body;

    if (!userId || !message) {
      return res.status(400).json({
        error: "Bad Request",
        message: "userId and message are required",
      });
    }

    // Store notification in Redis
    const notification = {
      id: Date.now().toString(),
      userId,
      message,
      type,
      timestamp: new Date().toISOString(),
      read: false,
    };

    // Store in Redis list for the user
    await redisClient.lPush(
      `notifications:${userId}`,
      JSON.stringify(notification)
    );

    // Publish to Redis pub/sub for real-time updates
    await redisClient.publish(
      `user:${userId}:notifications`,
      JSON.stringify(notification)
    );

    res.status(201).json({
      success: true,
      notification,
    });
  } catch (error) {
    console.error("Error sending notification:", error);
    res.status(500).json({
      error: "Internal Server Error",
      message: "Failed to send notification",
    });
  }
});

// Get notifications for a user
app.get("/api/notifications/:userId", async (req, res) => {
  try {
    const { userId } = req.params;
    const limit = parseInt(req.query.limit as string) || 10;

    // Get notifications from Redis
    const notifications = await redisClient.lRange(
      `notifications:${userId}`,
      0,
      limit - 1
    );

    const parsedNotifications = notifications.map((notification) =>
      JSON.parse(notification)
    );

    res.json(parsedNotifications);
  } catch (error) {
    console.error("Error fetching notifications:", error);
    res.status(500).json({
      error: "Internal Server Error",
      message: "Failed to fetch notifications",
    });
  }
});

// Mark notification as read
app.patch("/api/notifications/:notificationId/read", async (req, res) => {
  try {
    const { notificationId } = req.params;
    const { userId } = req.body;

    if (!userId) {
      return res.status(400).json({
        error: "Bad Request",
        message: "userId is required",
      });
    }

    // This is a simplified implementation
    // In a real app, you'd want to update the specific notification
    res.json({
      success: true,
      message: "Notification marked as read",
    });
  } catch (error) {
    console.error("Error marking notification as read:", error);
    res.status(500).json({
      error: "Internal Server Error",
      message: "Failed to mark notification as read",
    });
  }
});

// 404 handler
app.use("*", (req, res) => {
  res.status(404).json({
    error: "Not Found",
    message: `Route ${req.originalUrl} not found`,
    availableRoutes: [
      "GET /health",
      "POST /api/notifications/send",
      "GET /api/notifications/:userId",
      "PATCH /api/notifications/:notificationId/read",
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
      message: "Something went wrong",
    });
  }
);

// Initialize Redis and start server
const startServer = async () => {
  try {
    // Connect to Redis
    await redisClient.connect();
    console.log("✅ Connected to Redis");

    app.listen(PORT, () => {
      console.log(`🚀 Notification Service running on port ${PORT}`);
      console.log(`📊 Health check: http://localhost:${PORT}/health`);
      console.log(
        `📢 Notifications API: http://localhost:${PORT}/api/notifications`
      );
    });
  } catch (error) {
    console.error("❌ Failed to start server:", error);
    process.exit(1);
  }
};

// Handle Redis connection errors
redisClient.on("error", (err) => {
  console.error("❌ Redis connection error:", err);
});

redisClient.on("connect", () => {
  console.log("✅ Redis client connected");
});

startServer();

export default app;
