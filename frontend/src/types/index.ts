export interface Todo {
  id: string;
  title: string;
  description?: string;
  completed: boolean;
  // Backend uses snake_case
  user_id: string;
  created_at?: string | Date;
  updated_at?: string | Date;
  // Keep camelCase versions for frontend compatibility
  userId?: string;
  createdAt?: string | Date;
  updatedAt?: string | Date;
}

export interface User {
  id: string;
  username: string;
  email: string;
  createdAt: string;
}

export interface CreateTodoRequest {
  title: string;
  description?: string;
}

export interface UpdateTodoRequest {
  title?: string;
  description?: string;
  completed?: boolean;
}

export interface LoginRequest {
  username: string;
  password: string;
}

export interface RegisterRequest {
  username: string;
  email: string;
  password: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}
