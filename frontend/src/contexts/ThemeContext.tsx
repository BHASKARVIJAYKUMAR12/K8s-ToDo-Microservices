import React, { createContext, useContext, useState, useEffect } from "react";
import {
  ThemeProvider as MuiThemeProvider,
  createTheme,
  Theme,
} from "@mui/material/styles";
import { CssBaseline } from "@mui/material";

// Extend Material-UI theme interface
declare module "@mui/material/styles" {
  interface Palette {
    gradient: {
      primary: string;
      secondary: string;
      background: string;
      card: string;
    };
  }

  interface PaletteOptions {
    gradient?: {
      primary: string;
      secondary: string;
      background: string;
      card: string;
    };
  }
}

// Define custom theme interface
interface CustomTheme extends Theme {
  palette: Theme["palette"] & {
    gradient: {
      primary: string;
      secondary: string;
      background: string;
      card: string;
    };
  };
}

// Theme context type
interface ThemeContextType {
  isDarkMode: boolean;
  toggleTheme: () => void;
  theme: CustomTheme;
}

// Create context
const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

// Custom hook to use theme context
export const useThemeContext = () => {
  const context = useContext(ThemeContext);
  if (!context) {
    throw new Error("useThemeContext must be used within a ThemeProvider");
  }
  return context;
};

// Light theme configuration
const lightTheme = createTheme({
  palette: {
    mode: "light",
    primary: {
      main: "#2ec4b6", // Light sea green
      light: "#cbf3f0", // Mint green
      dark: "#1a7a70",
    },
    secondary: {
      main: "#ff9f1c", // Orange peel
      light: "#ffbf69", // Hunyadi yellow
      dark: "#cc7f16",
    },
    background: {
      default: "linear-gradient(135deg, #cbf3f0 0%, #ffffff 50%, #ffbf69 100%)",
      paper: "#ffffff",
    },
    success: {
      main: "#2ec4b6",
      light: "#cbf3f0",
    },
    warning: {
      main: "#ffbf69",
      light: "#fff2e1",
    },
    error: {
      main: "#ff6b6b",
      light: "#ffe0e0",
    },
    gradient: {
      primary: "linear-gradient(135deg, #2ec4b6 0%, #cbf3f0 100%)",
      secondary: "linear-gradient(135deg, #ff9f1c 0%, #ffbf69 100%)",
      background:
        "linear-gradient(135deg, #cbf3f0 0%, #ffffff 50%, #ffbf69 100%)",
      card: "linear-gradient(145deg, #ffffff 0%, #f4fcfc 100%)",
    },
  },
  shape: {
    borderRadius: 16,
  },
  components: {
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 16,
          background: "linear-gradient(145deg, #ffffff 0%, #f4fcfc 100%)",
          backdropFilter: "blur(10px)",
          border: "1px solid rgba(46, 196, 182, 0.1)",
          boxShadow: "0 8px 32px rgba(46, 196, 182, 0.15)",
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          textTransform: "none",
          fontWeight: 600,
        },
        contained: {
          background: "linear-gradient(135deg, #2ec4b6 0%, #cbf3f0 100%)",
          "&:hover": {
            background: "linear-gradient(135deg, #1a7a70 0%, #81e2db 100%)",
          },
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          "& .MuiOutlinedInput-root": {
            borderRadius: 12,
            background: "rgba(255, 255, 255, 0.9)",
            backdropFilter: "blur(10px)",
            "&:hover .MuiOutlinedInput-notchedOutline": {
              borderColor: "#2ec4b6",
            },
            "&.Mui-focused .MuiOutlinedInput-notchedOutline": {
              borderColor: "#2ec4b6",
            },
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 20,
          background: "linear-gradient(145deg, #ffffff 0%, #f4fcfc 100%)",
          backdropFilter: "blur(10px)",
          border: "1px solid rgba(46, 196, 182, 0.1)",
          boxShadow: "0 8px 32px rgba(46, 196, 182, 0.15)",
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: 16,
          backdropFilter: "blur(10px)",
        },
      },
    },
  },
}) as CustomTheme;

// Dark theme configuration
const darkTheme = createTheme({
  palette: {
    mode: "dark",
    primary: {
      main: "#2ec4b6", // Light sea green
      light: "#50d6c9",
      dark: "#124e48",
    },
    secondary: {
      main: "#ffbf69", // Hunyadi yellow
      light: "#ffd9a6",
      dark: "#915200",
    },
    background: {
      default: "linear-gradient(135deg, #124e48 0%, #1a1a1a 50%, #382100 100%)",
      paper: "#1e1e1e",
    },
    success: {
      main: "#2ec4b6",
      light: "#50d6c9",
    },
    warning: {
      main: "#ffbf69",
      light: "#ffd9a6",
    },
    error: {
      main: "#ff6b6b",
      light: "#ff9999",
    },
    gradient: {
      primary: "linear-gradient(135deg, #2ec4b6 0%, #124e48 100%)",
      secondary: "linear-gradient(135deg, #ffbf69 0%, #ff9f1c 100%)",
      background:
        "linear-gradient(135deg, #124e48 0%, #1a1a1a 50%, #382100 100%)",
      card: "linear-gradient(145deg, #1e1e1e 0%, #2a2a2a 100%)",
    },
  },
  shape: {
    borderRadius: 16,
  },
  components: {
    MuiPaper: {
      styleOverrides: {
        root: {
          borderRadius: 16,
          background: "linear-gradient(145deg, #1e1e1e 0%, #2a2a2a 100%)",
          backdropFilter: "blur(10px)",
          border: "1px solid rgba(46, 196, 182, 0.2)",
          boxShadow: "0 8px 32px rgba(0, 0, 0, 0.3)",
        },
      },
    },
    MuiButton: {
      styleOverrides: {
        root: {
          borderRadius: 12,
          textTransform: "none",
          fontWeight: 600,
        },
        contained: {
          background: "linear-gradient(135deg, #2ec4b6 0%, #124e48 100%)",
          "&:hover": {
            background: "linear-gradient(135deg, #50d6c9 0%, #229088 100%)",
          },
        },
      },
    },
    MuiTextField: {
      styleOverrides: {
        root: {
          "& .MuiOutlinedInput-root": {
            borderRadius: 12,
            background: "rgba(30, 30, 30, 0.8)",
            backdropFilter: "blur(10px)",
            "&:hover .MuiOutlinedInput-notchedOutline": {
              borderColor: "#2ec4b6",
            },
            "&.Mui-focused .MuiOutlinedInput-notchedOutline": {
              borderColor: "#2ec4b6",
            },
          },
        },
      },
    },
    MuiCard: {
      styleOverrides: {
        root: {
          borderRadius: 20,
          background: "linear-gradient(145deg, #1e1e1e 0%, #2a2a2a 100%)",
          backdropFilter: "blur(10px)",
          border: "1px solid rgba(46, 196, 182, 0.2)",
          boxShadow: "0 8px 32px rgba(0, 0, 0, 0.3)",
        },
      },
    },
    MuiChip: {
      styleOverrides: {
        root: {
          borderRadius: 16,
          backdropFilter: "blur(10px)",
        },
      },
    },
  },
}) as CustomTheme;

// Theme provider component
interface ThemeProviderProps {
  children: React.ReactNode;
}

export const ThemeProvider: React.FC<ThemeProviderProps> = ({ children }) => {
  const [isDarkMode, setIsDarkMode] = useState(() => {
    const savedMode = localStorage.getItem("darkMode");
    return savedMode ? JSON.parse(savedMode) : false;
  });

  const theme = isDarkMode ? darkTheme : lightTheme;

  const toggleTheme = () => {
    setIsDarkMode(!isDarkMode);
  };

  useEffect(() => {
    localStorage.setItem("darkMode", JSON.stringify(isDarkMode));
  }, [isDarkMode]);

  const contextValue: ThemeContextType = {
    isDarkMode,
    toggleTheme,
    theme,
  };

  return (
    <ThemeContext.Provider value={contextValue}>
      <MuiThemeProvider theme={theme}>
        <CssBaseline />
        {children}
      </MuiThemeProvider>
    </ThemeContext.Provider>
  );
};
