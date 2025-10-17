import React from "react";
import {
  AppBar,
  Toolbar,
  Typography,
  Button,
  Box,
  IconButton,
  Switch,
  FormControlLabel,
  Avatar,
  Chip,
} from "@mui/material";
import {
  ExitToApp,
  AccountCircle,
  DarkMode,
  LightMode,
  Dashboard,
} from "@mui/icons-material";
import { authService } from "../services/api";
import { useThemeContext } from "../contexts/ThemeContext";

interface HeaderProps {
  isAuthenticated: boolean;
  onLogout: () => void;
}

const Header: React.FC<HeaderProps> = ({ isAuthenticated, onLogout }) => {
  const user = authService.getCurrentUser();
  const { isDarkMode, toggleTheme } = useThemeContext();

  const handleLogout = () => {
    onLogout();
  };

  return (
    <AppBar
      position="static"
      sx={{
        mb: 3,
        background: (theme) => theme.palette.gradient.primary,
        backdropFilter: "blur(10px)",
        borderRadius: 0,
        boxShadow: "0 8px 32px rgba(0, 0, 0, 0.1)",
      }}
    >
      <Toolbar sx={{ py: 1 }}>
        <Dashboard sx={{ mr: 2, fontSize: 28, color: "#ffffff" }} />
        <Typography
          variant="h5"
          component="div"
          sx={{
            flexGrow: 1,
            fontWeight: 700,
            color: "#ffffff",
            textShadow: "2px 2px 4px rgba(0,0,0,0.3)",
            letterSpacing: "0.5px",
          }}
        >
          Todo Master
        </Typography>

        {/* Theme Toggle */}
        <Box sx={{ display: "flex", alignItems: "center", mr: 2 }}>
          <LightMode
            sx={{ mr: 1, opacity: isDarkMode ? 0.7 : 1, color: "#ffffff" }}
          />
          <Switch
            checked={isDarkMode}
            onChange={toggleTheme}
            sx={{
              "& .MuiSwitch-thumb": {
                background: "linear-gradient(45deg, #ff9f1c 30%, #ffbf69 90%)",
              },
            }}
          />
          <DarkMode
            sx={{ ml: 1, opacity: isDarkMode ? 1 : 0.7, color: "#ffffff" }}
          />
        </Box>

        {isAuthenticated && (
          <Box sx={{ display: "flex", alignItems: "center", gap: 2 }}>
            <Chip
              avatar={
                <Avatar sx={{ bgcolor: "rgba(255,255,255,0.2)" }}>
                  {user?.username?.[0]?.toUpperCase()}
                </Avatar>
              }
              label={`Welcome, ${user?.username}!`}
              variant="outlined"
              sx={{
                color: "white",
                borderColor: "rgba(255,255,255,0.3)",
                background: "rgba(255,255,255,0.1)",
                backdropFilter: "blur(10px)",
                "& .MuiChip-label": {
                  fontWeight: 600,
                },
              }}
            />
            <Button
              color="inherit"
              onClick={handleLogout}
              startIcon={<ExitToApp />}
              sx={{
                borderRadius: 3,
                px: 3,
                py: 1,
                background: "rgba(255,255,255,0.1)",
                backdropFilter: "blur(10px)",
                border: "1px solid rgba(255,255,255,0.2)",
                fontWeight: 600,
                "&:hover": {
                  background: "rgba(255,255,255,0.2)",
                },
              }}
            >
              Logout
            </Button>
          </Box>
        )}
      </Toolbar>
    </AppBar>
  );
};

export default Header;
