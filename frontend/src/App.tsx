import React, { useState, useEffect } from "react";
import {
  BrowserRouter as Router,
  Routes,
  Route,
  Navigate,
} from "react-router-dom";
import { Box, CircularProgress } from "@mui/material";
import { authService } from "./services/api";
import LoginForm from "./components/LoginForm";
import RegisterForm from "./components/RegisterForm";
import TodoList from "./components/TodoList";
import Header from "./components/Header";
import { ThemeProvider } from "./contexts/ThemeContext";

function App() {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setIsAuthenticated(authService.isAuthenticated());
    setLoading(false);
  }, []);

  const handleLogin = () => {
    setIsAuthenticated(true);
  };

  const handleLogout = () => {
    authService.logout();
    setIsAuthenticated(false);
  };

  if (loading) {
    return (
      <ThemeProvider>
        <Box
          sx={{
            display: "flex",
            justifyContent: "center",
            alignItems: "center",
            minHeight: "100vh",
            background: (theme) => theme.palette.gradient.background,
          }}
        >
          <CircularProgress size={60} thickness={4} />
        </Box>
      </ThemeProvider>
    );
  }

  return (
    <ThemeProvider>
      <Router>
        <Box
          sx={{
            minHeight: "100vh",
            background: (theme) => theme.palette.gradient.background,
            backgroundAttachment: "fixed",
          }}
        >
          <Header isAuthenticated={isAuthenticated} onLogout={handleLogout} />
          <Box component="main">
            <Routes>
              <Route
                path="/login"
                element={
                  !isAuthenticated ? (
                    <LoginForm onLogin={handleLogin} />
                  ) : (
                    <Navigate to="/todos" replace />
                  )
                }
              />
              <Route
                path="/register"
                element={
                  !isAuthenticated ? (
                    <RegisterForm onRegister={handleLogin} />
                  ) : (
                    <Navigate to="/todos" replace />
                  )
                }
              />
              <Route
                path="/todos"
                element={
                  isAuthenticated ? (
                    <TodoList />
                  ) : (
                    <Navigate to="/login" replace />
                  )
                }
              />
              <Route
                path="/"
                element={
                  <Navigate
                    to={isAuthenticated ? "/todos" : "/login"}
                    replace
                  />
                }
              />
            </Routes>
          </Box>
        </Box>
      </Router>
    </ThemeProvider>
  );
}

export default App;
