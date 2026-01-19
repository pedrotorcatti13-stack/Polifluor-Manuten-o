
-- SGMI 2.0 - SCRIPT DE INFRAESTRUTURA DE BANCO DE DADOS
-- PADRÃO: PostgreSQL / Supabase

-- 1. EXTENSÕES
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. TABELAS MESTRE
CREATE TABLE IF NOT EXISTS maintainers (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name TEXT NOT NULL,
    is_external BOOLEAN DEFAULT false,
    specialty TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS equipment (
    id TEXT PRIMARY KEY, -- Ex: PH-15, EX-01
    name TEXT NOT NULL,
    location TEXT, -- Setor
    category TEXT CHECK (category IN ('Industrial', 'Predial')),
    is_critical BOOLEAN DEFAULT false,
    status TEXT DEFAULT 'Ativo',
    manufacturer TEXT,
    model TEXT,
    year_of_manufacture INTEGER,
    schedule JSONB DEFAULT '[]'::jsonb, -- Cache do planejamento anual
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS spare_parts (
    id TEXT PRIMARY KEY, -- Part Number
    name TEXT NOT NULL,
    location TEXT, -- Gaveta/Prateleira
    unit TEXT DEFAULT 'PÇ',
    cost DECIMAL(12,2) DEFAULT 0,
    min_quantity DECIMAL(12,2) DEFAULT 0,
    current_quantity DECIMAL(12,2) DEFAULT 0,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. TABELA DE MOVIMENTAÇÃO DE ESTOQUE (AUDITORIA)
CREATE TABLE IF NOT EXISTS stock_movements (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    part_id TEXT REFERENCES spare_parts(id) ON DELETE CASCADE,
    quantity DECIMAL(12,2) NOT NULL,
    type TEXT CHECK (type IN ('Entrada', 'Saída')),
    work_order_id TEXT, -- Vínculo opcional com a O.S.
    reason TEXT,
    user_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. TABELA CENTRAL DE ORDENS DE SERVIÇO
CREATE TABLE IF NOT EXISTS work_orders (
    id TEXT PRIMARY KEY, -- OS Number (formatado)
    equipment_id TEXT REFERENCES equipment(id) ON DELETE SET NULL,
    maintainer_id UUID REFERENCES maintainers(id) ON DELETE SET NULL,
    type TEXT NOT NULL, -- Preventiva, Corretiva, Preditiva
    status TEXT NOT NULL DEFAULT 'Programado',
    priority TEXT DEFAULT 'Média',
    scheduled_date TIMESTAMPTZ NOT NULL,
    end_date TIMESTAMPTZ,
    machine_stopped BOOLEAN DEFAULT false,
    description TEXT NOT NULL,
    root_cause TEXT,
    checklist JSONB DEFAULT '[]'::jsonb, -- Itens de verificação
    materials_used JSONB DEFAULT '[]'::jsonb, -- Array de {part_id, quantity}
    man_hours JSONB DEFAULT '[]'::jsonb, -- Array de {maintainer, hours}
    technical_audit_comment TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TABELA DE LOGS DE ATIVIDADE (CONFORMIDADE IATF)
CREATE TABLE IF NOT EXISTS activity_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    action_type TEXT NOT NULL,
    target_id TEXT,
    description TEXT,
    old_value TEXT,
    new_value TEXT,
    user_name TEXT DEFAULT 'Sistema',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. LÓGICA DE AUTOMAÇÃO (TRIGGERS)

-- A. TRIGGER PARA BAIXA AUTOMÁTICA DE ESTOQUE AO CONCLUIR O.S.
CREATE OR REPLACE FUNCTION fn_process_inventory_on_completion()
RETURNS TRIGGER AS $$
DECLARE
    material_item RECORD;
BEGIN
    -- Verifica se o status mudou para 'Executado' (Concluído)
    IF (NEW.status = 'Executado' AND OLD.status != 'Executado') THEN
        -- Loop pelos materiais registrados no JSONB da O.S.
        -- Espera formato: [{"partId": "RO-01", "quantity": 2}, ...]
        FOR material_item IN SELECT * FROM jsonb_to_recordset(NEW.materials_used) AS x(partId text, quantity decimal)
        LOOP
            -- 1. Deduz do estoque principal
            UPDATE spare_parts 
            SET current_quantity = current_quantity - material_item.quantity,
                updated_at = NOW()
            WHERE id = material_item.partId;

            -- 2. Registra a movimentação oficial para auditoria
            INSERT INTO stock_movements (part_id, quantity, type, work_order_id, reason, user_name)
            VALUES (material_item.partId, material_item.quantity, 'Saída', NEW.id, 'Consumo Automático via O.S.', 'Trigger Sistema');
        END LOOP;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_os_completion_inventory
AFTER UPDATE ON work_orders
FOR EACH ROW
EXECUTE FUNCTION fn_process_inventory_on_completion();

-- B. TRIGGER PARA LOG DE HISTÓRICO DE STATUS
CREATE OR REPLACE FUNCTION fn_log_os_status_change()
RETURNS TRIGGER AS $$
BEGIN
    IF (OLD.status != NEW.status) THEN
        INSERT INTO activity_logs (action_type, target_id, description, old_value, new_value)
        VALUES ('UPDATE_STATUS', NEW.id, 'Mudança de status da Ordem de Serviço', OLD.status, NEW.status);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER tr_os_status_logger
AFTER UPDATE ON work_orders
FOR EACH ROW
EXECUTE FUNCTION fn_log_os_status_change();

-- 7. VIEWS DE PERFORMANCE (BI)
CREATE OR REPLACE VIEW view_maintenance_kpis AS
SELECT 
    equipment_id,
    COUNT(id) FILTER (WHERE type = 'Corretiva') as total_failures,
    AVG(EXTRACT(EPOCH FROM (end_date - scheduled_date))/3600) FILTER (WHERE type = 'Corretiva' AND status = 'Executado') as mttr_hours
FROM work_orders
GROUP BY equipment_id;
