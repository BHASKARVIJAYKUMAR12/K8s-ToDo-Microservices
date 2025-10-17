import React, { useState, useEffect } from "react";
import {
  Container,
  Paper,
  Typography,
  TextField,
  Button,
  List,
  ListItem,
  ListItemText,
  ListItemSecondaryAction,
  IconButton,
  Checkbox,
  Box,
  Chip,
  Alert,
  CircularProgress,
} from "@mui/material";
import {
  Add as AddIcon,
  Edit as EditIcon,
  Delete as DeleteIcon,
  Save as SaveIcon,
  Cancel as CancelIcon,
  CheckCircle,
  RadioButtonUnchecked,
} from "@mui/icons-material";
import { todoService } from "../services/api";
import { Todo, CreateTodoRequest, UpdateTodoRequest } from "../types";

function TodoList() {
  const [todos, setTodos] = useState<Todo[]>([]);
  const [newTodo, setNewTodo] = useState<CreateTodoRequest>({
    title: "",
    description: "",
  });
  const [editingTodo, setEditingTodo] = useState<string | null>(null);
  const [editForm, setEditForm] = useState<UpdateTodoRequest>({});
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState("");

  // Format date helper function - Fixed to handle various date formats
  const formatDate = (dateInput: string | Date | undefined): string => {
    try {
      // Handle undefined or null values
      if (!dateInput) {
        return "Date not available";
      }

      let date: Date;

      if (typeof dateInput === "string") {
        // Handle different string formats
        date = new Date(dateInput);

        // If the date is invalid, try parsing as ISO string
        if (isNaN(date.getTime())) {
          // Remove any timezone info and parse
          const cleanDate = dateInput.replace(/\.\d{3}Z?$/, "");
          date = new Date(cleanDate);
        }
      } else if (dateInput instanceof Date) {
        date = dateInput;
      } else {
        return "Invalid date format";
      }

      if (isNaN(date.getTime())) {
        return "Invalid Date";
      }

      // Check if the date is today
      const today = new Date();
      const isToday = date.toDateString() === today.toDateString();

      if (isToday) {
        return `Today, ${date.toLocaleTimeString("en-US", {
          hour: "2-digit",
          minute: "2-digit",
        })}`;
      }

      // Check if the date is yesterday
      const yesterday = new Date(today);
      yesterday.setDate(yesterday.getDate() - 1);
      const isYesterday = date.toDateString() === yesterday.toDateString();

      if (isYesterday) {
        return `Yesterday, ${date.toLocaleTimeString("en-US", {
          hour: "2-digit",
          minute: "2-digit",
        })}`;
      }

      // For other dates, show full date
      return date.toLocaleDateString("en-US", {
        year: "numeric",
        month: "short",
        day: "numeric",
        hour: "2-digit",
        minute: "2-digit",
      });
    } catch (error) {
      console.error("Date formatting error:", error, "Input:", dateInput);
      return "Date unavailable";
    }
  };

  useEffect(() => {
    loadTodos();
  }, []);

  const loadTodos = async () => {
    try {
      const todosData = await todoService.getTodos();
      setTodos(todosData);
    } catch (err: any) {
      setError("Failed to load todos");
    } finally {
      setLoading(false);
    }
  };

  const handleAddTodo = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!newTodo.title.trim()) return;

    try {
      const currentTime = new Date().toISOString();
      // Only send fields that backend validation expects
      const todoData = {
        title: newTodo.title,
        description: newTodo.description || "",
      };

      const createdTodo = await todoService.createTodo(todoData);

      // Ensure the created todo has timestamps (use backend timestamps or fallback to client-side)
      const todoWithClientTimestamps = {
        ...createdTodo,
        createdAt:
          createdTodo.createdAt || createdTodo.created_at || currentTime,
        updatedAt:
          createdTodo.updatedAt || createdTodo.updated_at || currentTime,
      };

      setTodos([...todos, todoWithClientTimestamps]);
      setNewTodo({ title: "", description: "" });
    } catch (err: any) {
      setError("Failed to create todo");
    }
  };

  const handleToggleTodo = async (id: string) => {
    try {
      const currentTime = new Date().toISOString();
      const updatedTodo = await todoService.toggleTodo(id);

      // Ensure the toggled todo has updated timestamp
      const todoWithTimestamp = {
        ...updatedTodo,
        updatedAt: updatedTodo.updatedAt || currentTime,
      };

      setTodos(
        todos.map((todo) => (todo.id === id ? todoWithTimestamp : todo))
      );
    } catch (err: any) {
      setError("Failed to update todo");
    }
  };

  const handleDeleteTodo = async (id: string) => {
    try {
      await todoService.deleteTodo(id);
      setTodos(todos.filter((todo) => todo.id !== id));
    } catch (err: any) {
      setError("Failed to delete todo");
    }
  };

  const handleEditTodo = (todo: Todo) => {
    setEditingTodo(todo.id);
    setEditForm({
      title: todo.title,
      description: todo.description,
    });
  };

  const handleUpdateTodo = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!editingTodo || !editForm.title?.trim()) return;

    try {
      const currentTime = new Date().toISOString();
      // Only send fields that backend validation expects
      const updates = {
        title: editForm.title,
        description: editForm.description,
      };

      const updatedTodo = await todoService.updateTodo(editingTodo, updates);

      // Ensure the updated todo has timestamp (use backend timestamp or fallback to client-side)
      const todoWithClientTimestamp = {
        ...updatedTodo,
        updatedAt:
          updatedTodo.updatedAt || updatedTodo.updated_at || currentTime,
      };

      setTodos(
        todos.map((todo) =>
          todo.id === editingTodo ? todoWithClientTimestamp : todo
        )
      );
      setEditingTodo(null);
      setEditForm({});
    } catch (err: any) {
      setError("Failed to update todo");
    }
  };

  const handleCancelEdit = () => {
    setEditingTodo(null);
    setEditForm({});
  };

  if (loading) {
    return (
      <Container maxWidth="md" sx={{ mt: 4, mb: 4 }}>
        <Box sx={{ display: "flex", justifyContent: "center", p: 3 }}>
          <CircularProgress />
        </Box>
      </Container>
    );
  }

  return (
    <Container maxWidth="lg" sx={{ mt: 4, mb: 4 }}>
      {/* Main Header */}
      <Box sx={{ textAlign: "center", mb: 4 }}>
        <Typography
          variant="h3"
          component="h1"
          sx={{
            fontWeight: 800,
            background: (theme) => theme.palette.gradient.primary,
            backgroundClip: "text",
            WebkitBackgroundClip: "text",
            WebkitTextFillColor: "transparent",
            mb: 1,
          }}
        >
          My Todo Dashboard
        </Typography>
        <Typography variant="h6" color="text.secondary">
          Stay organized and get things done!
        </Typography>
      </Box>

      {error && (
        <Alert
          severity="error"
          sx={{
            mb: 3,
            borderRadius: 3,
            backdropFilter: "blur(10px)",
            background: (theme) =>
              theme.palette.mode === "dark"
                ? "rgba(211, 47, 47, 0.1)"
                : "rgba(211, 47, 47, 0.05)",
          }}
        >
          {error}
        </Alert>
      )}

      {/* Add Todo Form */}
      <Paper
        elevation={0}
        sx={{
          p: 4,
          mb: 4,
          background: (theme) => theme.palette.gradient.card,
          backdropFilter: "blur(20px)",
          border: (theme) =>
            `1px solid ${
              theme.palette.mode === "dark"
                ? "rgba(255,255,255,0.1)"
                : "rgba(255,255,255,0.2)"
            }`,
          borderRadius: 4,
        }}
      >
        <Box sx={{ display: "flex", alignItems: "center", mb: 3 }}>
          <AddIcon
            sx={{
              mr: 2,
              fontSize: 28,
              background: (theme) => theme.palette.gradient.secondary,
              borderRadius: "50%",
              p: 0.5,
              color: "white",
            }}
          />
          <Typography variant="h5" sx={{ fontWeight: 600 }}>
            Create New Todo
          </Typography>
        </Box>

        <Box component="form" onSubmit={handleAddTodo}>
          <TextField
            fullWidth
            label="What needs to be done?"
            value={newTodo.title}
            onChange={(e) => setNewTodo({ ...newTodo, title: e.target.value })}
            required
            sx={{ mb: 3 }}
            InputProps={{
              sx: {
                borderRadius: 3,
              },
            }}
          />
          <TextField
            fullWidth
            label="Add some details (optional)"
            multiline
            rows={3}
            value={newTodo.description}
            onChange={(e) =>
              setNewTodo({ ...newTodo, description: e.target.value })
            }
            sx={{ mb: 3 }}
            InputProps={{
              sx: {
                borderRadius: 3,
              },
            }}
          />
          <Button
            type="submit"
            variant="contained"
            size="large"
            startIcon={<AddIcon />}
            disabled={!newTodo.title.trim()}
            sx={{
              px: 4,
              py: 1.5,
              borderRadius: 3,
              fontSize: "1.1rem",
              fontWeight: 600,
              background: (theme) => theme.palette.gradient.secondary,
              "&:hover": {
                transform: "translateY(-2px)",
                boxShadow: "0 8px 25px rgba(0,0,0,0.15)",
              },
              transition: "all 0.3s ease",
            }}
          >
            Add Todo
          </Button>
        </Box>
      </Paper>

      {/* Todo Statistics */}
      <Box sx={{ display: "flex", gap: 2, mb: 4 }}>
        <Paper
          sx={{
            p: 2,
            flex: 1,
            textAlign: "center",
            background: (theme) => theme.palette.gradient.card,
            borderRadius: 3,
            border: (theme) =>
              `1px solid ${
                theme.palette.mode === "dark"
                  ? "rgba(255,255,255,0.1)"
                  : "rgba(255,255,255,0.2)"
              }`,
          }}
        >
          <Typography
            variant="h4"
            sx={{ fontWeight: 700, color: "primary.main" }}
          >
            {todos.length}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Total Tasks
          </Typography>
        </Paper>
        <Paper
          sx={{
            p: 2,
            flex: 1,
            textAlign: "center",
            background: (theme) => theme.palette.gradient.card,
            borderRadius: 3,
            border: (theme) =>
              `1px solid ${
                theme.palette.mode === "dark"
                  ? "rgba(255,255,255,0.1)"
                  : "rgba(255,255,255,0.2)"
              }`,
          }}
        >
          <Typography
            variant="h4"
            sx={{ fontWeight: 700, color: "success.main" }}
          >
            {todos.filter((todo) => todo.completed).length}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Completed
          </Typography>
        </Paper>
        <Paper
          sx={{
            p: 2,
            flex: 1,
            textAlign: "center",
            background: (theme) => theme.palette.gradient.card,
            borderRadius: 3,
            border: (theme) =>
              `1px solid ${
                theme.palette.mode === "dark"
                  ? "rgba(255,255,255,0.1)"
                  : "rgba(255,255,255,0.2)"
              }`,
          }}
        >
          <Typography
            variant="h4"
            sx={{ fontWeight: 700, color: "warning.main" }}
          >
            {todos.filter((todo) => !todo.completed).length}
          </Typography>
          <Typography variant="body2" color="text.secondary">
            Pending
          </Typography>
        </Paper>
      </Box>

      {/* Todos List */}
      <Paper
        elevation={0}
        sx={{
          background: (theme) => theme.palette.gradient.card,
          backdropFilter: "blur(20px)",
          border: (theme) =>
            `1px solid ${
              theme.palette.mode === "dark"
                ? "rgba(255,255,255,0.1)"
                : "rgba(255,255,255,0.2)"
            }`,
          borderRadius: 4,
          overflow: "hidden",
        }}
      >
        {todos.length === 0 ? (
          <Box sx={{ textAlign: "center", py: 6 }}>
            <CheckCircle
              sx={{ fontSize: 64, color: "text.secondary", mb: 2 }}
            />
            <Typography variant="h5" sx={{ mb: 1, fontWeight: 600 }}>
              No todos yet!
            </Typography>
            <Typography variant="body1" color="text.secondary">
              Create your first todo above to get started on your productivity
              journey.
            </Typography>
          </Box>
        ) : (
          <List sx={{ p: 0 }}>
            {todos.map((todo, index) => (
              <ListItem
                key={todo.id}
                divider={index < todos.length - 1}
                sx={{
                  py: 3,
                  px: 3,
                  background: todo.completed
                    ? (theme) =>
                        theme.palette.mode === "dark"
                          ? "rgba(76, 175, 80, 0.1)"
                          : "rgba(76, 175, 80, 0.05)"
                    : "transparent",
                  borderRadius: todo.completed ? 2 : 0,
                  margin: todo.completed ? 1 : 0,
                  transition: "all 0.3s ease",
                  "&:hover": {
                    background: (theme) =>
                      theme.palette.mode === "dark"
                        ? "rgba(255, 255, 255, 0.05)"
                        : "rgba(0, 0, 0, 0.02)",
                  },
                }}
              >
                {editingTodo === todo.id ? (
                  <Box
                    sx={{ width: "100%" }}
                    component="form"
                    onSubmit={handleUpdateTodo}
                  >
                    <TextField
                      fullWidth
                      value={editForm.title || ""}
                      onChange={(e) =>
                        setEditForm({ ...editForm, title: e.target.value })
                      }
                      required
                      sx={{ mb: 2 }}
                      InputProps={{
                        sx: { borderRadius: 2 },
                      }}
                    />
                    <TextField
                      fullWidth
                      multiline
                      rows={3}
                      value={editForm.description || ""}
                      onChange={(e) =>
                        setEditForm({
                          ...editForm,
                          description: e.target.value,
                        })
                      }
                      sx={{ mb: 2 }}
                      InputProps={{
                        sx: { borderRadius: 2 },
                      }}
                    />
                    <Box sx={{ display: "flex", gap: 2 }}>
                      <Button
                        type="submit"
                        size="small"
                        variant="contained"
                        startIcon={<SaveIcon />}
                        sx={{ borderRadius: 2 }}
                      >
                        Save
                      </Button>
                      <Button
                        type="button"
                        size="small"
                        variant="outlined"
                        startIcon={<CancelIcon />}
                        onClick={handleCancelEdit}
                        sx={{ borderRadius: 2 }}
                      >
                        Cancel
                      </Button>
                    </Box>
                  </Box>
                ) : (
                  <>
                    <IconButton
                      edge="start"
                      onClick={() => handleToggleTodo(todo.id)}
                      sx={{
                        mr: 2,
                        background: todo.completed
                          ? "linear-gradient(45deg, #2ec4b6 30%, #cbf3f0 90%)"
                          : (theme) =>
                              theme.palette.mode === "dark"
                                ? "rgba(46, 196, 182, 0.2)"
                                : "rgba(203, 243, 240, 0.3)",
                        "&:hover": {
                          background: todo.completed
                            ? "linear-gradient(45deg, #1a7a70 30%, #81e2db 90%)"
                            : (theme) =>
                                theme.palette.mode === "dark"
                                  ? "rgba(46, 196, 182, 0.3)"
                                  : "rgba(203, 243, 240, 0.5)",
                        },
                      }}
                    >
                      {todo.completed ? (
                        <CheckCircle sx={{ color: "white" }} />
                      ) : (
                        <RadioButtonUnchecked />
                      )}
                    </IconButton>

                    <ListItemText
                      primary={
                        <Typography
                          variant="h6"
                          sx={{
                            textDecoration: todo.completed
                              ? "line-through"
                              : "none",
                            color: todo.completed
                              ? "text.secondary"
                              : "text.primary",
                            fontWeight: 600,
                            mb: 1,
                          }}
                        >
                          {todo.title}
                        </Typography>
                      }
                      secondary={
                        <Box>
                          {todo.description && (
                            <Typography
                              variant="body2"
                              sx={{
                                mb: 2,
                                color: "text.secondary",
                                fontStyle: todo.completed ? "italic" : "normal",
                              }}
                            >
                              {todo.description}
                            </Typography>
                          )}
                          <Box
                            sx={{
                              display: "flex",
                              gap: 1,
                              flexWrap: "wrap",
                              alignItems: "center",
                            }}
                          >
                            <Chip
                              label={
                                todo.completed ? "✓ Completed" : "⏳ Pending"
                              }
                              size="small"
                              sx={{
                                background: todo.completed
                                  ? "linear-gradient(45deg, #2ec4b6 30%, #cbf3f0 90%)"
                                  : "linear-gradient(45deg, #ff9f1c 30%, #ffbf69 90%)",
                                color: "white",
                                fontWeight: 600,
                                borderRadius: 2,
                              }}
                            />
                            {todo.createdAt && (
                              <Chip
                                label={`Created: ${formatDate(todo.createdAt)}`}
                                size="small"
                                variant="outlined"
                                sx={{ borderRadius: 2 }}
                              />
                            )}
                            {todo.updatedAt &&
                              todo.updatedAt !== todo.createdAt && (
                                <Chip
                                  label={`Updated: ${formatDate(
                                    todo.updatedAt
                                  )}`}
                                  size="small"
                                  variant="outlined"
                                  sx={{ borderRadius: 2 }}
                                />
                              )}
                          </Box>
                        </Box>
                      }
                    />

                    <ListItemSecondaryAction>
                      <Box sx={{ display: "flex", gap: 1 }}>
                        <IconButton
                          onClick={() => handleEditTodo(todo)}
                          sx={{
                            background: (theme) =>
                              theme.palette.mode === "dark"
                                ? "rgba(46, 196, 182, 0.2)"
                                : "rgba(203, 243, 240, 0.3)",
                            "&:hover": {
                              background: (theme) =>
                                theme.palette.mode === "dark"
                                  ? "rgba(46, 196, 182, 0.3)"
                                  : "rgba(203, 243, 240, 0.5)",
                            },
                          }}
                        >
                          <EditIcon sx={{ color: "#2ec4b6" }} />
                        </IconButton>
                        <IconButton
                          onClick={() => handleDeleteTodo(todo.id)}
                          sx={{
                            background: (theme) =>
                              theme.palette.mode === "dark"
                                ? "rgba(255, 159, 28, 0.2)"
                                : "rgba(255, 191, 105, 0.3)",
                            "&:hover": {
                              background: (theme) =>
                                theme.palette.mode === "dark"
                                  ? "rgba(255, 159, 28, 0.3)"
                                  : "rgba(255, 191, 105, 0.5)",
                            },
                          }}
                        >
                          <DeleteIcon sx={{ color: "#ff9f1c" }} />
                        </IconButton>
                      </Box>
                    </ListItemSecondaryAction>
                  </>
                )}
              </ListItem>
            ))}
          </List>
        )}
      </Paper>
    </Container>
  );
}

export default TodoList;
