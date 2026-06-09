# 智能用药App - 后端API服务

## 技术栈

- **运行环境**: Node.js 22+
- **Web框架**: Express 4.x
- **数据库**: PostgreSQL 14+
- **缓存**: Redis 7
- **认证**: JWT (JSON Web Token)
- **部署**: Docker / Docker Compose

## 项目结构

```
backend/
├── src/
│   ├── server.js              # 应用入口
│   ├── config/
│   │   ├── index.js           # 配置管理
│   │   ├── database.js        # PostgreSQL连接池
│   │   └── redis.js           # Redis缓存客户端
│   ├── middleware/
│   │   ├── auth.js            # JWT认证中间件
│   │   ├── errorHandler.js    # 全局错误处理
│   │   └── rateLimiter.js     # 请求频率限制
│   ├── routes/
│   │   ├── index.js           # 路由汇总
│   │   ├── auth.js            # 认证接口
│   │   ├── users.js           # 用户接口
│   │   ├── medicines.js       # 药品接口
│   │   ├── plans.js           # 用药计划接口
│   │   ├── checkins.js        # 打卡接口
│   │   ├── prescriptions.js   # 处方接口
│   │   ├── guardians.js       # 家人监护接口
│   │   └── notifications.js   # 通知接口
│   ├── services/
│   │   ├── authService.js     # 认证服务
│   │   ├── userService.js     # 用户服务
│   │   ├── medicineService.js # 药品服务
│   │   ├── planService.js     # 用药计划服务
│   │   ├── checkinService.js  # 打卡服务
│   │   ├── prescriptionService.js # 处方服务
│   │   ├── guardianService.js # 监护服务
│   │   └── notificationService.js # 通知服务
│   └── utils/
│       ├── logger.js          # 日志工具
│       ├── response.js        # 响应格式工具
│       ├── errors.js          # 自定义错误类
│       └── validators.js      # 请求参数验证
├── migrations/
│   └── run.js                 # 数据库迁移脚本
├── schema.sql                 # 数据库Schema
├── openapi.yaml               # API文档 (OpenAPI 3.0)
├── Dockerfile                 # Docker构建文件
├── docker-compose.yml         # Docker编排配置
├── package.json
└── .env.example               # 环境变量模板
```

## 快速开始

### 前置条件

- Node.js 22+
- PostgreSQL 14+
- Redis 7+ (可选，用于缓存)

### 本地开发

1. 安装依赖

```bash
npm install
```

2. 配置环境变量

```bash
cp .env.example .env
# 编辑 .env 文件，填入数据库配置
```

3. 初始化数据库

```bash
# 创建数据库
createdb smart_medication

# 运行迁移
npm run migrate
```

4. 启动开发服务器

```bash
npm run dev
```

### Docker部署

```bash
# 启动所有服务
docker-compose up -d

# 查看日志
docker-compose logs -f api
```

## API接口概览

| 模块 | 方法 | 路径 | 说明 |
|------|------|------|------|
| 认证 | POST | /api/auth/send-code | 发送验证码 |
| 认证 | POST | /api/auth/login | 登录 |
| 认证 | POST | /api/auth/refresh | 刷新令牌 |
| 认证 | POST | /api/auth/logout | 退出登录 |
| 用户 | GET | /api/users/profile | 获取个人信息 |
| 用户 | PUT | /api/users/profile | 更新个人信息 |
| 用户 | PUT | /api/users/elderly-preferences | 更新适老化偏好 |
| 用户 | GET | /api/users/stats | 获取用药统计 |
| 药品 | GET | /api/medicines | 搜索药品 |
| 药品 | GET | /api/medicines/:id | 药品详情 |
| 药品 | GET | /api/medicines/barcode/:code | 条码查询 |
| 药品 | POST | /api/medicines/interactions | 相互作用检查 |
| 计划 | GET | /api/plans | 用药计划列表 |
| 计划 | GET | /api/plans/today | 今日安排 |
| 计划 | POST | /api/plans | 创建计划 |
| 计划 | PUT | /api/plans/:id | 更新计划 |
| 计划 | DELETE | /api/plans/:id | 删除计划 |
| 打卡 | POST | /api/checkins | 服药打卡 |
| 打卡 | POST | /api/checkins/:id/undo | 撤销打卡 |
| 打卡 | GET | /api/checkins | 打卡记录 |
| 打卡 | GET | /api/checkins/calendar | 日历视图 |
| 处方 | GET | /api/prescriptions | 处方列表 |
| 处方 | POST | /api/prescriptions | 创建处方 |
| 处方 | POST | /api/prescriptions/:id/ocr | OCR识别 |
| 监护 | POST | /api/guardians | 发送监护邀请 |
| 监护 | GET | /api/guardians/patients | 被监护人列表 |
| 监护 | GET | /api/guardians/:id/report | 监护报告 |
| 通知 | GET | /api/notifications | 通知列表 |
| 通知 | PUT | /api/notifications/:id/read | 标记已读 |
| 通知 | POST | /api/notifications/device | 注册设备 |

完整API文档请参考 `openapi.yaml` 文件。

## 数据库表

| 表名 | 说明 |
|------|------|
| users | 用户表（含适老化偏好） |
| verification_codes | 验证码表 |
| medicines | 药品表（含说明书） |
| drug_interactions | 药物相互作用表 |
| medication_plans | 用药计划表 |
| medication_logs | 用药记录表 |
| prescriptions | 处方表 |
| guardians | 监护关系表 |
| push_notifications | 推送通知表 |
| device_tokens | 设备令牌表 |
| refresh_tokens | 刷新令牌表 |
| audit_logs | 审计日志表 |

## 核心功能

### 药物相互作用检查
- 支持2-20种药品同时检查
- 返回风险等级（高/中/低）和具体说明
- 包含作用机制、临床管理建议和可能症状

### 用药提醒与打卡
- 自动生成用药记录（基于计划和频率）
- 5分钟内可撤销打卡
- 漏服检测（30分钟超时）
- 连续漏服3天自动发送关怀提醒

### 家人远程监护
- 双向确认的监护关系
- 实时查看用药进度
- 漏服通知自动推送给家人
- 用药依从率报告

### 适老化支持
- 一键切换适老化模式
- 字体缩放、高对比度
- 语音交互支持
