import express from "express";
import Joi from "joi";
import { v4 as uuidv4 } from "uuid";
import pool from "../database/connection";
import { authenticateToken, AuthenticatedRequest } from "../middleware/auth";
import { Todo, CreateTodoRequest, UpdateTodoRequest } from "../models";

const router = express.Router();

// Validation schemas
const createTodoSchema = Joi.object({
  title: Joi.string().min(1).max(255).required(),
  description: Joi.string().max(1000).optional().allow(""),
});

const updateTodoSchema = Joi.object({
  title: Joi.string().min(1).max(255).optional(),
  description: Joi.string().max(1000).optional().allow(""),
  completed: Joi.boolean().optional(),
});

// GET /api/todos - Get all todos for authenticated user
router.get("/", authenticateToken, async (req: AuthenticatedRequest, res) => {
  try {
    const userId = req.user!.id;

    const result = await pool.query(
      "SELECT * FROM todos WHERE user_id = $1 ORDER BY created_at DESC",
      [userId]
    );

    res.json(result.rows);
  } catch (error) {
    console.error("Error fetching todos:", error);
    res.status(500).json({
      error: "Internal Server Error",
      message: "Failed to fetch todos",
    });
  }
});

// GET /api/todos/:id - Get specific todo
router.get(
  "/:id",
  authenticateToken,
  async (req: AuthenticatedRequest, res) => {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      const result = await pool.query(
        "SELECT * FROM todos WHERE id = $1 AND user_id = $2",
        [id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          error: "Not Found",
          message: "Todo not found",
        });
      }

      res.json(result.rows[0]);
    } catch (error) {
      console.error("Error fetching todo:", error);
      res.status(500).json({
        error: "Internal Server Error",
        message: "Failed to fetch todo",
      });
    }
  }
);

// POST /api/todos - Create new todo
router.post("/", authenticateToken, async (req: AuthenticatedRequest, res) => {
  try {
    const { error, value } = createTodoSchema.validate(req.body);
    if (error) {
      return res.status(400).json({
        error: "Validation Error",
        message: error.details[0].message,
      });
    }

    const { title, description = "" } = value as CreateTodoRequest;
    const userId = req.user!.id;
    const todoId = uuidv4();

    const result = await pool.query(
      `INSERT INTO todos (id, title, description, user_id) 
       VALUES ($1, $2, $3, $4) 
       RETURNING *`,
      [todoId, title, description, userId]
    );

    res.status(201).json(result.rows[0]);
  } catch (error) {
    console.error("Error creating todo:", error);
    res.status(500).json({
      error: "Internal Server Error",
      message: "Failed to create todo",
    });
  }
});

// PUT /api/todos/:id - Update todo
router.put(
  "/:id",
  authenticateToken,
  async (req: AuthenticatedRequest, res) => {
    try {
      const { error, value } = updateTodoSchema.validate(req.body);
      if (error) {
        return res.status(400).json({
          error: "Validation Error",
          message: error.details[0].message,
        });
      }

      const { id } = req.params;
      const userId = req.user!.id;
      const updates = value as UpdateTodoRequest;

      // Check if todo exists and belongs to user
      const existingTodo = await pool.query(
        "SELECT * FROM todos WHERE id = $1 AND user_id = $2",
        [id, userId]
      );

      if (existingTodo.rows.length === 0) {
        return res.status(404).json({
          error: "Not Found",
          message: "Todo not found",
        });
      }

      // Build update query dynamically
      const setClause = [];
      const values = [];
      let paramCount = 1;

      if (updates.title !== undefined) {
        setClause.push(`title = $${paramCount++}`);
        values.push(updates.title);
      }

      if (updates.description !== undefined) {
        setClause.push(`description = $${paramCount++}`);
        values.push(updates.description);
      }

      if (updates.completed !== undefined) {
        setClause.push(`completed = $${paramCount++}`);
        values.push(updates.completed);
      }

      if (setClause.length === 0) {
        return res.status(400).json({
          error: "Bad Request",
          message: "No valid fields to update",
        });
      }

      setClause.push(`updated_at = CURRENT_TIMESTAMP`);
      values.push(id, userId);

      const query = `
      UPDATE todos 
      SET ${setClause.join(", ")} 
      WHERE id = $${paramCount++} AND user_id = $${paramCount++}
      RETURNING *
    `;

      const result = await pool.query(query, values);
      res.json(result.rows[0]);
    } catch (error) {
      console.error("Error updating todo:", error);
      res.status(500).json({
        error: "Internal Server Error",
        message: "Failed to update todo",
      });
    }
  }
);

// PATCH /api/todos/:id/toggle - Toggle todo completion status
router.patch(
  "/:id/toggle",
  authenticateToken,
  async (req: AuthenticatedRequest, res) => {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      const result = await pool.query(
        `UPDATE todos 
       SET completed = NOT completed, updated_at = CURRENT_TIMESTAMP 
       WHERE id = $1 AND user_id = $2 
       RETURNING *`,
        [id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          error: "Not Found",
          message: "Todo not found",
        });
      }

      res.json(result.rows[0]);
    } catch (error) {
      console.error("Error toggling todo:", error);
      res.status(500).json({
        error: "Internal Server Error",
        message: "Failed to toggle todo",
      });
    }
  }
);

// DELETE /api/todos/:id - Delete todo
router.delete(
  "/:id",
  authenticateToken,
  async (req: AuthenticatedRequest, res) => {
    try {
      const { id } = req.params;
      const userId = req.user!.id;

      const result = await pool.query(
        "DELETE FROM todos WHERE id = $1 AND user_id = $2 RETURNING *",
        [id, userId]
      );

      if (result.rows.length === 0) {
        return res.status(404).json({
          error: "Not Found",
          message: "Todo not found",
        });
      }

      res.status(204).send();
    } catch (error) {
      console.error("Error deleting todo:", error);
      res.status(500).json({
        error: "Internal Server Error",
        message: "Failed to delete todo",
      });
    }
  }
);

export default router;
