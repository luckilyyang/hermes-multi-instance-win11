-- 创建用户表
CREATE TABLE IF NOT EXISTS users (
    id SERIAL PRIMARY KEY,
    username VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL DEFAULT 'super_admin',
    status VARCHAR(50) NOT NULL DEFAULT 'active',
    avatar TEXT,
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    last_login_at BIGINT
);

-- 创建用户 profiles 关联表
CREATE TABLE IF NOT EXISTS user_profiles (
    user_id INT NOT NULL,
    profile_name VARCHAR(255) NOT NULL,
    is_default INT DEFAULT 0,
    created_at BIGINT NOT NULL,
    PRIMARY KEY (user_id, profile_name),
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 创建用户主题表
CREATE TABLE IF NOT EXISTS user_themes (
    user_id INT PRIMARY KEY,
    theme_payload TEXT,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- 创建会话表
CREATE TABLE IF NOT EXISTS sessions (
    id VARCHAR(255) PRIMARY KEY,
    profile VARCHAR(255) NOT NULL,
    user_id INT,
    model VARCHAR(255),
    provider VARCHAR(255),
    reasoning_effort VARCHAR(50),
    title VARCHAR(500),
    category_id VARCHAR(255),
    push_enabled INT DEFAULT 0,
    source VARCHAR(50),
    workspace VARCHAR(500),
    created_at BIGINT NOT NULL,
    updated_at BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- 创建消息表
CREATE TABLE IF NOT EXISTS messages (
    id SERIAL PRIMARY KEY,
    session_id VARCHAR(255) NOT NULL,
    role VARCHAR(50) NOT NULL,
    content TEXT,
    display_role VARCHAR(50),
    display_content TEXT,
    tool_calls TEXT,
    reasoning TEXT,
    timestamp BIGINT NOT NULL,
    FOREIGN KEY (session_id) REFERENCES sessions(id) ON DELETE CASCADE
);

-- 创建索引
CREATE INDEX IF NOT EXISTS idx_users_username ON users(username);
CREATE INDEX IF NOT EXISTS idx_sessions_user_id ON sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_sessions_profile ON sessions(profile);
CREATE INDEX IF NOT EXISTS idx_messages_session_id ON messages(session_id);

-- 创建初始超级管理员用户（密码: admin123）
INSERT INTO users (username, password_hash, role, status, created_at, updated_at)
VALUES (
    'admin',
    'scrypt:e8e6d15e17e0d55b:4f7a3c8b5f3e9d2c1a4b8f7e5d3c1b9a8f7e5d3c1b9a8f7e5d3c1b9a8f7e5d3c1b9a8f7e5d3c1b9a8f',
    'super_admin',
    'active',
    EXTRACT(EPOCH FROM NOW())::BIGINT * 1000,
    EXTRACT(EPOCH FROM NOW())::BIGINT * 1000
)
ON CONFLICT (username) DO NOTHING;

-- 关联默认 profile
INSERT INTO user_profiles (user_id, profile_name, is_default, created_at)
SELECT id, 'default', 1, EXTRACT(EPOCH FROM NOW())::BIGINT * 1000
FROM users WHERE username = 'admin'
ON CONFLICT (user_id, profile_name) DO NOTHING;
