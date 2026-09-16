// 连接到 admin 数据库并创建超级管理员用户
const adminDb = db.getSiblingDB('admin');

// 创建 admin 用户
if (!adminDb.getUser('admin')) {
  adminDb.createUser({
    user: 'admin',
    pwd: 'admin123',
    roles: ['root']
  });
  print('[MongoDB] Admin 用户已创建');
}

// 切换到 hermes_central 数据库
const centralDb = db.getSiblingDB('hermes_central');

// 创建全局超级管理员
if (centralDb.users.findOne({ username: 'superadmin' }) === null) {
  centralDb.users.insertOne({
    username: 'superadmin',
    email: 'superadmin@xx.local',
    password_hash: 'admin123', // 实际应使用 bcrypt
    instances: {
      super: {
        local_user_id: 1,
        role: 'super_admin',
        tokens_limit: 5000000,
        tokens_used: 0,
        created_at: Date.now()
      },
      ls: {
        local_user_id: 1,
        role: 'super_admin',
        tokens_limit: 5000000,
        tokens_used: 0,
        created_at: Date.now()
      },
      zs: {
        local_user_id: 1,
        role: 'super_admin',
        tokens_limit: 5000000,
        tokens_used: 0,
        created_at: Date.now()
      }
    },
    global_role: 'super_admin',
    created_at: Date.now(),
    updated_at: Date.now()
  });
  print('[MongoDB] 全局超级管理员已创建: superadmin');
}

// 创建索引
if (!centralDb.users.getIndexes().some(idx => idx.name === 'username_1')) {
  centralDb.users.createIndex({ username: 1 }, { unique: true });
  print('[MongoDB] 创建 username 索引');
}

if (!centralDb.token_usage.getIndexes().some(idx => idx.name === 'user_id_1_timestamp_-1')) {
  centralDb.token_usage.createIndex({ user_id: 1, timestamp: -1 });
  print('[MongoDB] 创建 token_usage 索引');
}

if (!centralDb.token_usage.getIndexes().some(idx => idx.name === 'instance_1_timestamp_-1')) {
  centralDb.token_usage.createIndex({ instance: 1, timestamp: -1 });
  print('[MongoDB] 创建 token_usage instance 索引');
}

if (!centralDb.operations.getIndexes().some(idx => idx.name === 'user_id_1_timestamp_-1')) {
  centralDb.operations.createIndex({ user_id: 1, timestamp: -1 });
  print('[MongoDB] 创建 operations 索引');
}

if (!centralDb.operations.getIndexes().some(idx => idx.name === 'instance_1_timestamp_-1')) {
  centralDb.operations.createIndex({ instance: 1, timestamp: -1 });
  print('[MongoDB] 创建 operations instance 索引');
}

print('[MongoDB] 数据库初始化完成！');
