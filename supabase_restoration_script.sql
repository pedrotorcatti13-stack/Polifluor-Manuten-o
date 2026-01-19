
/* 
   SGMI 2.0 - SCRIPT DE RESTAURAÇÃO MESTRA (PLANEJAMENTO 2026)
   ALVO: Tabela work_orders
   COMPATIBILIDADE: PostgreSQL / Supabase SQL Editor
*/

-- 1. LIMPEZA DE SEGURANÇA (Reset total para evitar violação de chave primária)
DELETE FROM work_orders;

-- 2. GERAÇÃO DINÂMICA DO CRONOGRAMA ANUAL
INSERT INTO work_orders (
    id, 
    equipment_id, 
    type, 
    requester, 
    status, 
    scheduled_date, 
    machine_stopped, 
    description, 
    checklist, 
    materials_used, 
    man_hours,
    observations,
    misc_notes,
    downtime_notes
)
WITH Months AS (
    -- Matriz de meses para o loop de periodicidade
    SELECT '01' as mm UNION ALL SELECT '02' UNION ALL SELECT '03' UNION ALL
    SELECT '04' UNION ALL SELECT '05' UNION ALL SELECT '06' UNION ALL
    SELECT '07' UNION ALL SELECT '08' UNION ALL SELECT '09' UNION ALL
    SELECT '10' UNION ALL SELECT '11' UNION ALL SELECT '12'
),
Regras AS (
    -- PRENSAS (PH): Trimestral (Jan/Abr/Jul/Out)
    SELECT 'PH' as prefix, 3 as freq, 1 as start_m, 'Revisão Trimestral: Hidráulica e Estrutural' as descr,
    '[{"action": "Verificar nível óleo ISO VG 68", "checked": false}, {"action": "Inspecionar vazamentos pistão", "checked": false}, {"action": "Reaperto estrutura/contatos", "checked": false}, {"action": "Limpeza filtros", "checked": false}, {"action": "Teste pressão trabalho", "checked": false}, {"action": "Check terminais elétricos", "checked": false}]'::jsonb as chk
    UNION ALL
    -- EXTRUSORAS (EX/AEX): Trimestral (Jan/Abr/Jul/Out)
    SELECT 'EX' as prefix, 3 as freq, 1 as start_m, 'Revisão Trimestral: Aquecimento e Mecânica' as descr,
    '[{"action": "Verificar resistências", "checked": false}, {"action": "Limpeza ventoinhas", "checked": false}, {"action": "Lubrificação mancais", "checked": false}]'::jsonb as chk
    UNION ALL
    -- ESMERIL (ES): Mensal (12 ordens)
    SELECT 'ES' as prefix, 1 as freq, 1 as start_m, 'Preventiva Mensal: Segurança e Desgaste' as descr,
    '[{"action": "Estado do rebolo", "checked": false}, {"action": "Proteção visual", "checked": false}, {"action": "Ajuste de apoio", "checked": false}, {"action": "Teste de aterramento", "checked": false}]'::jsonb as chk
    UNION ALL
    -- FORNOS (FO): Trimestral (Iniciando em Março)
    SELECT 'FO' as prefix, 3 as freq, 3 as start_m, 'Revisão Trimestral: Calibração e Elétrica' as descr,
    '[{"action": "Medição de corrente", "checked": false}, {"action": "Reaperto de bornes", "checked": false}, {"action": "Vedação da porta", "checked": false}, {"action": "Ajuste controlador", "checked": false}]'::jsonb as chk
    UNION ALL
    -- TORNOS CNC (TC): A cada 9 meses (Jan/Out)
    SELECT 'TC' as prefix, 9 as freq, 1 as start_m, 'Revisão Periódica (9m): Precisão e Fluidos' as descr,
    '[{"action": "Limpeza tanque refrigeração", "checked": false}, {"action": "Nível óleo barramento", "checked": false}]'::jsonb as chk
    UNION ALL
    -- TORNOS AUTO (TA): Semestral (Fev/Ago)
    SELECT 'TA' as prefix, 6 as freq, 2 as start_m, 'Revisão Semestral: Mecânica de Leva' as descr,
    '[{"action": "Lubrificação automática", "checked": false}, {"action": "Desgaste de correias", "checked": false}]'::jsonb as chk
    UNION ALL
    -- SOLDA (MS) / CORRUGADORAS (CR): Bimestral (Jan/Mar/Mai/Jul/Set/Nov)
    SELECT 'MS' as prefix, 2 as freq, 1 as start_m, 'Preventiva Bimestral: Limpeza Interna' as descr, '[]'::jsonb as chk UNION ALL
    SELECT 'CR' as prefix, 2 as freq, 1 as start_m, 'Preventiva Bimestral: Ajuste Corrugado' as descr, '[]'::jsonb as chk
    UNION ALL
    -- ANUAIS: CO (Set), GE (Jan), MI (Jul)
    SELECT 'CO' as prefix, 12 as freq, 9 as start_m, 'Preventiva Anual: Compressor' as descr, '[]'::jsonb as chk UNION ALL
    SELECT 'GE' as prefix, 12 as freq, 1 as start_m, 'Preventiva Anual: Gerador' as descr, '[]'::jsonb as chk UNION ALL
    SELECT 'MI' as prefix, 12 as freq, 7 as start_m, 'Preventiva Anual: Misturador' as descr, '[]'::jsonb as chk
)
SELECT 
    -- Regra de ID: 2026-EQUIP-MM
    '2026-' || e.id || '-' || m.mm as id,
    e.id as equipment_id,
    'Preventiva' as type,
    'PCM MASTER 2026' as requester,
    'Programado' as status,
    -- CAST para garantir tipo TIMESTAMPTZ
    CAST('2026-' || m.mm || '-01 08:00:00' AS TIMESTAMPTZ) as scheduled_date,
    true as machine_stopped,
    r.descr as description,
    r.chk as checklist,
    '[]'::jsonb as materials_used,
    '[]'::jsonb as man_hours,
    'Restauração Mestra: Planejamento Automático 2026.' as observations,
    '' as misc_notes,
    '' as downtime_notes
FROM equipment e
JOIN Regras r ON e.id LIKE r.prefix || '%'
JOIN Months m ON (
    CAST(m.mm AS INTEGER) >= r.start_m 
    AND (CAST(m.mm AS INTEGER) - r.start_m) % r.freq = 0
)
WHERE e.status = 'Ativo';

-- 3. REQUISITO CRÍTICO: AJUSTE ES-04 (O.S. #0009)
-- Primeiro removemos o ID gerado automaticamente para este mês
DELETE FROM work_orders WHERE id = '2026-ES-04-01';

-- Inserimos o registro específico com o ID fixo solicitado
INSERT INTO work_orders (id, equipment_id, type, requester, status, scheduled_date, machine_stopped, description, checklist, materials_used, man_hours, observations)
VALUES (
    '0009', 
    'ES-04', 
    'Preventiva', 
    'REQUISITO ESPECIAL', 
    'Programado', 
    '2026-01-01 08:00:00+00', 
    true, 
    'Preventiva Mensal: Segurança e Rebolo', 
    '[{"action": "Estado do rebolo", "checked": false}, {"action": "Proteção visual", "checked": false}, {"action": "Ajuste de apoio", "checked": false}, {"action": "Teste de aterramento", "checked": false}]'::jsonb,
    '[]'::jsonb,
    '[]'::jsonb,
    'ID #0009 forçado conforme solicitação técnica.'
);

-- FIM DO SCRIPT DE RESTAURAÇÃO MASTER
