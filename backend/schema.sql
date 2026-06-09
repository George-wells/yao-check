-- ============================================================
-- 智能用药App - 数据库Schema设计
-- 数据库: PostgreSQL 14+
-- 创建时间: 2026-06-09
-- ============================================================

-- 启用UUID扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================
-- 1. 用户表 (users)
-- ============================================================
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) NOT NULL UNIQUE,
    name VARCHAR(100) NOT NULL,
    avatar_url VARCHAR(500),
    gender VARCHAR(10) CHECK (gender IN ('male', 'female', 'other')),
    birth_date DATE,
    age INTEGER GENERATED ALWAYS AS (
        CASE 
            WHEN birth_date IS NOT NULL THEN 
                EXTRACT(YEAR FROM AGE(birth_date))::INTEGER
            ELSE NULL 
        END
    ) STORED,
    -- 适老化偏好设置
    is_elderly_mode BOOLEAN NOT NULL DEFAULT FALSE,
    font_scale DECIMAL(3,2) NOT NULL DEFAULT 1.0,
    high_contrast BOOLEAN NOT NULL DEFAULT FALSE,
    enable_voice BOOLEAN NOT NULL DEFAULT FALSE,
    -- 通知偏好
    push_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    sms_enabled BOOLEAN NOT NULL DEFAULT FALSE,
    -- 安全字段
    password_hash VARCHAR(255),
    -- 时间戳
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    last_login_at TIMESTAMPTZ,
    deleted_at TIMESTAMPTZ
);

-- 用户索引
CREATE INDEX idx_users_phone ON users(phone) WHERE deleted_at IS NULL;
CREATE INDEX idx_users_created_at ON users(created_at);

-- ============================================================
-- 2. 验证码表 (verification_codes)
-- ============================================================
CREATE TABLE verification_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    phone VARCHAR(20) NOT NULL,
    code VARCHAR(6) NOT NULL,
    purpose VARCHAR(20) NOT NULL CHECK (purpose IN ('login', 'register', 'reset_password', 'bind_phone')),
    expires_at TIMESTAMPTZ NOT NULL,
    is_used BOOLEAN NOT NULL DEFAULT FALSE,
    used_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_verification_codes_phone ON verification_codes(phone, purpose);
CREATE INDEX idx_verification_codes_expires ON verification_codes(expires_at);

-- ============================================================
-- 3. 药品表 (medicines)
-- ============================================================
CREATE TABLE medicines (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(200) NOT NULL,
    generic_name VARCHAR(200),           -- 通用名/成分名
    english_name VARCHAR(200),
    category VARCHAR(100),               -- 药品分类
    category_code VARCHAR(50),           -- 分类编码
    dosage_form VARCHAR(50),             -- 剂型: 片剂/胶囊/液体/注射剂等
    specification VARCHAR(200),          -- 规格: 如 "0.5g*12片"
    package_unit VARCHAR(50),            -- 包装单位: 盒/瓶/袋
    manufacturer VARCHAR(300),           -- 生产厂家
    approval_number VARCHAR(100),        -- 批准文号
    barcode VARCHAR(100),                -- 商品条码
    -- 说明书结构化字段
    indications TEXT,                    -- 适应症
    usage_dosage TEXT,                   -- 用法用量
    contraindications TEXT,              -- 禁忌
    side_effects TEXT,                   -- 不良反应
    precautions TEXT,                    -- 注意事项
    drug_interactions TEXT,              -- 药物相互作用
    storage_conditions TEXT,             -- 贮藏条件
    ingredients TEXT,                    -- 主要成分
    pharmacology TEXT,                   -- 药理毒理
    -- 通俗解释
    plain_language_explanation TEXT,     -- 通俗解释
    -- 元数据
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    data_source VARCHAR(50) DEFAULT 'manual',  -- manual / nmpa / openfda
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 药品索引
CREATE INDEX idx_medicines_name ON medicines USING GIN (to_tsvector('simple', name));
CREATE INDEX idx_medicines_generic_name ON medicines(generic_name);
CREATE INDEX idx_medicines_barcode ON medicines(barcode);
CREATE INDEX idx_medicines_category ON medicines(category_code);
CREATE INDEX idx_medicines_active ON medicines(is_active);

-- 药品全文搜索索引
CREATE INDEX idx_medicines_search ON medicines USING GIN (
    to_tsvector('simple', coalesce(name, '') || ' ' || coalesce(generic_name, '') || ' ' || coalesce(english_name, ''))
);

-- ============================================================
-- 4. 药物相互作用表 (drug_interactions)
-- ============================================================
CREATE TABLE drug_interactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    medicine_a_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
    medicine_b_id UUID NOT NULL REFERENCES medicines(id) ON DELETE CASCADE,
    severity VARCHAR(10) NOT NULL CHECK (severity IN ('high', 'medium', 'low')),
    severity_level INTEGER NOT NULL CHECK (severity_level BETWEEN 1 AND 5),
    description TEXT NOT NULL,            -- 相互作用描述
    mechanism TEXT,                       -- 作用机制
    clinical_management TEXT,             -- 临床管理建议
    symptoms TEXT,                        -- 可能症状
    references TEXT,                      -- 参考文献
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_interaction_pair UNIQUE (medicine_a_id, medicine_b_id),
    CONSTRAINT interaction_order CHECK (medicine_a_id < medicine_b_id)
);

CREATE INDEX idx_drug_interactions_medicine_a ON drug_interactions(medicine_a_id);
CREATE INDEX idx_drug_interactions_medicine_b ON drug_interactions(medicine_b_id);
CREATE INDEX idx_drug_interactions_severity ON drug_interactions(severity);

-- ============================================================
-- 5. 用药计划表 (medication_plans)
-- ============================================================
CREATE TABLE medication_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    medicine_id UUID REFERENCES medicines(id) ON DELETE SET NULL,
    -- 药品信息（冗余存储，避免药品信息变更影响历史记录）
    medicine_name VARCHAR(200) NOT NULL,
    medicine_specification VARCHAR(200),
    dosage_form VARCHAR(50),
    -- 剂量信息
    dosage_value DECIMAL(10,2) NOT NULL,  -- 剂量数值
    dosage_unit VARCHAR(20) NOT NULL,     -- 剂量单位: 片/粒/ml/mg/g
    dosage_description VARCHAR(200),      -- 剂量描述: 如 "每次1片"
    -- 频率设置
    frequency_type VARCHAR(20) NOT NULL CHECK (frequency_type IN (
        'daily', 'every_n_hours', 'specific_days', 'as_needed'
    )),
    frequency_interval INTEGER,           -- 间隔小时数 (every_n_hours时使用)
    frequency_times_per_day INTEGER,      -- 每日次数
    -- 具体时间安排 (JSON数组: [{"time": "08:00", "days_of_week": [1,2,3,4,5,6,7]}])
    schedule JSONB NOT NULL DEFAULT '[]'::jsonb,
    -- 有效期
    start_date DATE NOT NULL DEFAULT CURRENT_DATE,
    end_date DATE,
    -- 库存管理
    stock_quantity DECIMAL(10,2),         -- 剩余数量
    stock_unit VARCHAR(20),               -- 库存单位
    -- 备注
    notes TEXT,
    -- 状态
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    -- 时间戳
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_medication_plans_user ON medication_plans(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_medication_plans_medicine ON medication_plans(medicine_id);
CREATE INDEX idx_medication_plans_active ON medication_plans(is_active);
CREATE INDEX idx_medication_plans_schedule ON medication_plans USING GIN (schedule);

-- ============================================================
-- 6. 用药记录表 (medication_logs)
-- ============================================================
CREATE TABLE medication_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    plan_id UUID NOT NULL REFERENCES medication_plans(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    medicine_id UUID REFERENCES medicines(id) ON DELETE SET NULL,
    -- 计划信息快照
    medicine_name VARCHAR(200) NOT NULL,
    dosage_description VARCHAR(200),
    -- 时间信息
    scheduled_time TIME NOT NULL,          -- 计划服药时间
    scheduled_date DATE NOT NULL,          -- 计划服药日期
    actual_time TIMESTAMPTZ,               -- 实际打卡时间
    -- 状态
    status VARCHAR(20) NOT NULL CHECK (status IN (
        'pending', 'taken', 'missed', 'skipped', 'late'
    )),
    -- 延迟信息
    delay_minutes INTEGER,                 -- 延迟分钟数 (late状态时)
    -- 备注
    note TEXT,
    -- 补服信息
    is_makeup BOOLEAN NOT NULL DEFAULT FALSE,
    makeup_note VARCHAR(200),
    -- 时间戳
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_medication_logs_user_date ON medication_logs(user_id, scheduled_date);
CREATE INDEX idx_medication_logs_plan ON medication_logs(plan_id);
CREATE INDEX idx_medication_logs_status ON medication_logs(status);
CREATE INDEX idx_medication_logs_date ON medication_logs(scheduled_date);
CREATE INDEX idx_medication_logs_user_status ON medication_logs(user_id, status);

-- 分区表建议: 按月份对medication_logs进行分区
-- 对于生产环境，建议使用表分区:
-- CREATE TABLE medication_logs (...) PARTITION BY RANGE (scheduled_date);

-- ============================================================
-- 7. 处方表 (prescriptions)
-- ============================================================
CREATE TABLE prescriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- 医生信息
    doctor_name VARCHAR(100),
    doctor_title VARCHAR(100),
    hospital_name VARCHAR(200),
    department VARCHAR(100),
    -- 处方信息
    prescription_number VARCHAR(100),      -- 处方编号
    issue_date DATE,                       -- 开具日期
    expiry_date DATE,                      -- 有效期
    diagnosis VARCHAR(500),                -- 诊断
    -- 处方药品 (JSON数组)
    medicines JSONB NOT NULL DEFAULT '[]'::jsonb,
    -- OCR信息
    image_url VARCHAR(500),                -- 处方照片URL
    ocr_raw_result TEXT,                   -- OCR原始识别结果
    ocr_confidence DECIMAL(5,2),           -- OCR置信度
    ocr_status VARCHAR(20) DEFAULT 'pending' CHECK (ocr_status IN (
        'pending', 'processing', 'completed', 'failed'
    )),
    -- 状态
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN (
        'active', 'expired', 'archived'
    )),
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at TIMESTAMPTZ
);

CREATE INDEX idx_prescriptions_user ON prescriptions(user_id) WHERE deleted_at IS NULL;
CREATE INDEX idx_prescriptions_status ON prescriptions(status);
CREATE INDEX idx_prescriptions_expiry ON prescriptions(expiry_date);

-- ============================================================
-- 8. 监护关系表 (guardians)
-- ============================================================
CREATE TABLE guardians (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    guardian_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    patient_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    relationship VARCHAR(50) NOT NULL CHECK (relationship IN (
        'spouse', 'child', 'parent', 'sibling', 'relative', 'caregiver', 'other'
    )),
    -- 权限设置
    can_view_medications BOOLEAN NOT NULL DEFAULT TRUE,
    can_view_checkins BOOLEAN NOT NULL DEFAULT TRUE,
    can_view_prescriptions BOOLEAN NOT NULL DEFAULT FALSE,
    can_receive_notifications BOOLEAN NOT NULL DEFAULT TRUE,
    -- 状态
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN (
        'pending', 'active', 'rejected', 'cancelled'
    )),
    -- 确认时间
    confirmed_at TIMESTAMPTZ,
    cancelled_at TIMESTAMPTZ,
    -- 备注
    notes TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    -- 唯一约束: 同一对监护关系只能有一条
    CONSTRAINT unique_guardian_patient UNIQUE (guardian_id, patient_id)
);

CREATE INDEX idx_guardians_guardian ON guardians(guardian_id, status);
CREATE INDEX idx_guardians_patient ON guardians(patient_id, status);

-- ============================================================
-- 9. 推送通知表 (push_notifications)
-- ============================================================
CREATE TABLE push_notifications (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    -- 通知类型
    notification_type VARCHAR(50) NOT NULL CHECK (notification_type IN (
        'medication_reminder',       -- 用药提醒
        'missed_dose',               -- 漏服提醒
        'makeup_reminder',           -- 补服提醒
        'guardian_missed_dose',      -- 家人漏服通知
        'prescription_expiry',       -- 处方到期
        'refill_reminder',           -- 续方提醒
        'interaction_warning',       -- 相互作用警告
        'side_effect_tip',           -- 副作用提示
        'care_message',              -- 关怀提醒
        'system_notification'        -- 系统通知
    )),
    -- 通知内容
    title VARCHAR(200) NOT NULL,
    body TEXT NOT NULL,
    data JSONB,                          -- 附加数据(跳转路由等)
    -- 推送状态
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    is_sent BOOLEAN NOT NULL DEFAULT FALSE,
    sent_at TIMESTAMPTZ,
    read_at TIMESTAMPTZ,
    -- 关联
    related_plan_id UUID REFERENCES medication_plans(id) ON DELETE SET NULL,
    related_log_id UUID REFERENCES medication_logs(id) ON DELETE SET NULL,
    -- 时间戳
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_push_notifications_user ON push_notifications(user_id, is_read);
CREATE INDEX idx_push_notifications_type ON push_notifications(notification_type);
CREATE INDEX idx_push_notifications_created ON push_notifications(created_at);
CREATE INDEX idx_push_notifications_unread ON push_notifications(user_id, is_read, is_sent);

-- ============================================================
-- 10. 设备令牌表 (device_tokens)
-- ============================================================
CREATE TABLE device_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    device_token VARCHAR(500) NOT NULL,
    platform VARCHAR(20) NOT NULL CHECK (platform IN ('ios', 'android', 'web')),
    device_name VARCHAR(200),
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    last_used_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT unique_device_token UNIQUE (device_token)
);

CREATE INDEX idx_device_tokens_user ON device_tokens(user_id, is_active);

-- ============================================================
-- 11. 刷新令牌表 (refresh_tokens)
-- ============================================================
CREATE TABLE refresh_tokens (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash VARCHAR(255) NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
    device_info VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);
CREATE INDEX idx_refresh_tokens_hash ON refresh_tokens(token_hash);
CREATE INDEX idx_refresh_tokens_expires ON refresh_tokens(expires_at);

-- ============================================================
-- 12. 审计日志表 (audit_logs)
-- ============================================================
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID REFERENCES users(id) ON DELETE SET NULL,
    action VARCHAR(100) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    old_values JSONB,
    new_values JSONB,
    ip_address VARCHAR(45),
    user_agent VARCHAR(500),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_action ON audit_logs(action);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);

-- ============================================================
-- 视图: 今日用药进度
-- ============================================================
CREATE VIEW v_today_medication_progress AS
SELECT 
    mp.user_id,
    mp.id AS plan_id,
    mp.medicine_name,
    mp.dosage_description,
    mp.schedule,
    ml.id AS log_id,
    ml.scheduled_time,
    ml.status AS log_status,
    ml.actual_time,
    ml.delay_minutes,
    ml.is_makeup
FROM medication_plans mp
LEFT JOIN medication_logs ml ON 
    ml.plan_id = mp.id AND 
    ml.scheduled_date = CURRENT_DATE
WHERE mp.is_active = TRUE AND mp.deleted_at IS NULL
ORDER BY mp.user_id, ml.scheduled_time;

-- ============================================================
-- 视图: 用药依从率统计
-- ============================================================
CREATE VIEW v_medication_compliance AS
SELECT 
    user_id,
    scheduled_date,
    COUNT(*) AS total_doses,
    COUNT(*) FILTER (WHERE status IN ('taken', 'late')) AS completed_doses,
    COUNT(*) FILTER (WHERE status = 'missed') AS missed_doses,
    COUNT(*) FILTER (WHERE status = 'skipped') AS skipped_doses,
    ROUND(
        COUNT(*) FILTER (WHERE status IN ('taken', 'late'))::DECIMAL / 
        NULLIF(COUNT(*), 0) * 100, 2
    ) AS compliance_rate
FROM medication_logs
GROUP BY user_id, scheduled_date;

-- ============================================================
-- 函数: 自动生成用药记录
-- ============================================================
CREATE OR REPLACE FUNCTION generate_medication_logs()
RETURNS TRIGGER AS $$
DECLARE
    sched JSONB;
    day_of_week INTEGER;
    schedule_time TIME;
    schedule_days INTEGER[];
BEGIN
    -- 遍历 schedule JSON 数组
    FOR sched IN SELECT * FROM jsonb_array_elements(NEW.schedule)
    LOOP
        schedule_time := (sched->>'time')::TIME;
        schedule_days := ARRAY(
            SELECT jsonb_array_elements_text(sched->'days_of_week')::INTEGER
        );
        
        -- 从开始日期到结束日期（或未来30天）生成记录
        INSERT INTO medication_logs (
            plan_id, user_id, medicine_id, medicine_name,
            dosage_description, scheduled_time, scheduled_date, status
        )
        SELECT 
            NEW.id, NEW.user_id, NEW.medicine_id, NEW.medicine_name,
            NEW.dosage_description, schedule_time,
            generate_series::DATE, 'pending'
        FROM generate_series(
            NEW.start_date,
            COALESCE(NEW.end_date, CURRENT_DATE + INTERVAL '30 days'),
            '1 day'::INTERVAL
        ) AS gs
        WHERE 
            EXTRACT(DOW FROM gs) = ANY(schedule_days)
            AND NOT EXISTS (
                SELECT 1 FROM medication_logs ml 
                WHERE ml.plan_id = NEW.id 
                AND ml.scheduled_date = gs::DATE
                AND ml.scheduled_time = schedule_time
            );
    END LOOP;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 触发器: 创建用药计划时自动生成记录
CREATE TRIGGER trg_generate_medication_logs
AFTER INSERT ON medication_plans
FOR EACH ROW
WHEN (NEW.is_active = TRUE)
EXECUTE FUNCTION generate_medication_logs();

-- ============================================================
-- 函数: 自动更新 updated_at
-- ============================================================
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- 应用 updated_at 触发器
CREATE TRIGGER trg_users_updated_at BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_medicines_updated_at BEFORE UPDATE ON medicines
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_drug_interactions_updated_at BEFORE UPDATE ON drug_interactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_medication_plans_updated_at BEFORE UPDATE ON medication_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_medication_logs_updated_at BEFORE UPDATE ON medication_logs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_prescriptions_updated_at BEFORE UPDATE ON prescriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_guardians_updated_at BEFORE UPDATE ON guardians
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();
CREATE TRIGGER trg_device_tokens_updated_at BEFORE UPDATE ON device_tokens
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================================
-- 种子数据: 示例药品
-- ============================================================
INSERT INTO medicines (name, generic_name, category, dosage_form, specification, manufacturer, barcode, indications, usage_dosage, contraindications, side_effects, precautions, drug_interactions, plain_language_explanation) VALUES
('阿莫西林胶囊', '阿莫西林', '抗生素', '胶囊剂', '0.5g*24粒', '华北制药股份有限公司', '6901234567890', '适用于敏感菌引起的呼吸道感染、泌尿道感染等', '成人一次0.5g，每6-8小时一次', '对青霉素过敏者禁用', '恶心、呕吐、腹泻等胃肠道反应', '用药前需做青霉素皮试', '与丙磺舒合用可提高血药浓度', '阿莫西林是一种常用的抗生素，用于治疗细菌感染，需按医嘱完成整个疗程'),
('硝苯地平缓释片', '硝苯地平', '降压药', '缓释片', '30mg*30片', '拜耳医药保健有限公司', '6901234567891', '高血压、冠心病', '一次30mg，一日一次', '心源性休克禁用', '头痛、面部潮红、踝部水肿', '不可与葡萄柚汁同服', '与β受体阻滞剂合用需监测血压', '硝苯地平是降压药，通过扩张血管降低血压，缓释片需整片吞服'),
('二甲双胍片', '二甲双胍', '降糖药', '片剂', '0.5g*60片', '中美上海施贵宝制药有限公司', '6901234567892', '2型糖尿病', '起始剂量一次0.5g，一日2次，随餐服用', '严重肾功能不全禁用', '胃肠道不适、腹泻', '定期监测肾功能', '与碘造影剂合用需暂停用药', '二甲双胍是降糖药，帮助控制血糖水平，需随餐服用减少胃肠道刺激'),
('布洛芬缓释胶囊', '布洛芬', '解热镇痛药', '缓释胶囊', '0.3g*20粒', '中美天津史克制药有限公司', '6901234567893', '缓解各种疼痛及退热', '一次0.3g，一日2次', '活动性消化道溃疡禁用', '胃肠道不适、头晕', '不宜长期使用', '与阿司匹林合用增加出血风险', '布洛芬是止痛退热药，用于缓解头痛、牙痛、关节痛等'),
('阿托伐他汀钙片', '阿托伐他汀', '降脂药', '片剂', '10mg*28片', '辉瑞制药有限公司', '6901234567894', '高胆固醇血症、冠心病', '起始剂量一次10mg，一日一次', '活动性肝病禁用', '肌肉疼痛、肝功能异常', '定期监测肝功能和肌酸激酶', '与克拉霉素合用增加肌病风险', '阿托伐他汀是降脂药，降低血液中的胆固醇水平，保护心血管健康'),
('氯沙坦钾片', '氯沙坦', '降压药', '片剂', '50mg*28片', '默沙东制药有限公司', '6901234567895', '原发性高血压', '一次50mg，一日一次', '妊娠期禁用', '头晕、低血压', '监测血钾水平', '与保钾利尿剂合用增加高钾血症风险', '氯沙坦是降压药，通过阻断血管紧张素II降低血压'),
('格列美脲片', '格列美脲', '降糖药', '片剂', '2mg*30片', '赛诺菲制药有限公司', '6901234567896', '2型糖尿病', '起始剂量一次1mg，一日一次', '1型糖尿病禁用', '低血糖', '定期监测血糖', '与胰岛素合用增加低血糖风险', '格列美脲是降糖药，刺激胰岛分泌更多胰岛素来控制血糖'),
('头孢克肟分散片', '头孢克肟', '抗生素', '分散片', '50mg*12片', '广州白云山制药股份有限公司', '6901234567897', '呼吸道感染、泌尿系统感染', '一次50-100mg，一日2次', '对头孢类过敏者禁用', '腹泻、皮疹', '有青霉素过敏史者慎用', '与华法林合用增加出血风险', '头孢克肟是抗生素，用于治疗多种细菌感染'),
('华法林钠片', '华法林', '抗凝药', '片剂', '2.5mg*60片', '上海信谊药厂有限公司', '6901234567898', '预防和治疗血栓栓塞性疾病', '根据INR调整剂量', '出血倾向者禁用', '出血风险增加', '定期监测INR', '与多种药物有相互作用，需密切监测', '华法林是抗凝药，防止血液凝固形成血栓，需定期抽血监测'),
('氨氯地平片', '氨氯地平', '降压药', '片剂', '5mg*28片', '辉瑞制药有限公司', '6901234567899', '高血压、冠心病', '一次5mg，一日一次', '严重低血压禁用', '头痛、水肿、疲劳', '不可突然停药', '与CYP3A4抑制剂合用需调整剂量', '氨氯地平是降压药，每日一次服用，帮助平稳控制血压');

-- 药物相互作用数据
INSERT INTO drug_interactions (medicine_a_id, medicine_b_id, severity, severity_level, description, mechanism, clinical_management, symptoms) 
SELECT 
    a.id, b.id,
    'high', 5,
    '华法林与阿莫西林合用增加出血风险',
    '阿莫西林可能影响肠道菌群，减少维生素K的合成，增强华法林的抗凝作用',
    '合用期间应增加INR监测频率，必要时调整华法林剂量',
    '瘀伤、牙龈出血、鼻出血、血尿'
FROM medicines a, medicines b
WHERE a.name = '华法林钠片' AND b.name = '阿莫西林胶囊';

INSERT INTO drug_interactions (medicine_a_id, medicine_b_id, severity, severity_level, description, mechanism, clinical_management, symptoms)
SELECT 
    a.id, b.id,
    'medium', 3,
    '布洛芬与华法林合用增加出血风险',
    '布洛芬抑制血小板聚集，与华法林产生协同抗凝作用',
    '避免合用，如需使用建议选择对凝血影响较小的止痛药',
    '胃肠道出血、瘀伤'
FROM medicines a, medicines b
WHERE a.name = '布洛芬缓释胶囊' AND b.name = '华法林钠片';

INSERT INTO drug_interactions (medicine_a_id, medicine_b_id, severity, severity_level, description, mechanism, clinical_management, symptoms)
SELECT 
    a.id, b.id,
    'high', 4,
    '格列美脲与二甲双胍合用增加低血糖风险',
    '两种降糖药作用机制不同，协同降糖作用增强',
    '合用时应监测血糖，初始剂量宜小，逐步调整',
    '头晕、出汗、心慌、乏力、意识模糊'
FROM medicines a, medicines b
WHERE a.name = '格列美脲片' AND b.name = '二甲双胍片';

INSERT INTO drug_interactions (medicine_a_id, medicine_b_id, severity, severity_level, description, mechanism, clinical_management, symptoms)
SELECT 
    a.id, b.id,
    'medium', 3,
    '氯沙坦与氨氯地平合用增加降压效果',
    '两种降压药通过不同机制协同降压',
    '合用有效但需监测血压，防止低血压',
    '头晕、乏力、低血压'
FROM medicines a, medicines b
WHERE a.name = '氯沙坦钾片' AND b.name = '氨氯地平片';

INSERT INTO drug_interactions (medicine_a_id, medicine_b_id, severity, severity_level, description, mechanism, clinical_management, symptoms)
SELECT 
    a.id, b.id,
    'medium', 3,
    '阿托伐他汀与克拉霉素（大环内酯类抗生素）合用增加肌病风险',
    '克拉霉素抑制CYP3A4代谢酶，增加阿托伐他汀血药浓度',
    '合用期间监测肌肉症状，考虑暂停他汀或换用其他抗生素',
    '肌肉疼痛、肌无力、深色尿'
FROM medicines a, medicines b
WHERE a.name = '阿托伐他汀钙片' AND b.name = '阿莫西林胶囊';

INSERT INTO drug_interactions (medicine_a_id, medicine_b_id, severity, severity_level, description, mechanism, clinical_management, symptoms)
SELECT 
    a.id, b.id,
    'low', 2,
    '硝苯地平与氨氯地平合用增加血管扩张作用',
    '两种钙通道阻滞剂作用机制相同',
    '一般不建议合用，选择其中一种即可',
    '头痛、面部潮红、踝部水肿加重'
FROM medicines a, medicines b
WHERE a.name = '硝苯地平缓释片' AND b.name = '氨氯地平片';

-- ============================================================
-- 结束
-- ============================================================
