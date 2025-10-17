export interface Todo {
  id: string;
  title: string;
  description: string;
  completed: boolean;
  user_id: string;
  created_at: Date;
  updated_at: Date;
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

export interface User {
  id: string;
  username: string;
  email: string;
}
