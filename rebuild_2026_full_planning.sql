
/* 
   SGMI 2.0 - SCRIPT DE RESTAURAÇÃO MESTRA 2026
   ALVO: work_orders
   OBJETIVO: Reconstrução total do cronograma preventivo para 160 ativos.
*/

-- 1. LIMPEZA TOTAL (Reset de banco para evitar conflitos de ID)
DELETE FROM work_orders;

-- 2. GERAÇÃO DINÂMICA VIA MATRIZ DE REGRAS
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
    SELECT '01' as mm UNION ALL SELECT '02' UNION ALL SELECT '03' UNION ALL
    SELECT '04' UNION ALL SELECT '05' UNION ALL SELECT '06' UNION ALL
    SELECT '07' UNION ALL SELECT '08' UNION ALL SELECT '09' UNION ALL
    SELECT '10' UNION ALL SELECT '11' UNION ALL SELECT '12'
),
Regras AS (
    -- PRENSAS (PH) - Trimestral (Jan, Abr, Jul, Out)
    SELECT 'PH' as prefix, 3 as freq, 1 as start_m, 'Revisão Trimestral: Hidráulica e Estrutural' as descr,
    '[{"action": "Nível de óleo (ISO VG 68)", "checked": false}, {"action": "Vazamentos pistão", "checked": false}, {"action": "Reaperto estrutura", "checked": false}, {"action": "Terminais elétricos", "checked": false}, {"action": "Limpeza filtros", "checked": false}, {"action": "Pressão de trabalho", "checked": false}]'::jsonb as chk
    UNION ALL
    -- EXTRUSORAS (EX/AEX) - Trimestral (Jan, Abr, Jul, Out)
    SELECT 'EX' as prefix, 3 as freq, 1 as start_m, 'Revisão Trimestral: Aquecimento e Mecânica' as descr,
    '[{"action": "Verificar resistências", "checked": false}, {"action": "Limpeza de ventoinhas", "checked": false}, {"action": "Lubrificação mancais", "checked": false}]'::jsonb as chk
    UNION ALL
    SELECT 'AEX' as prefix, 3 as freq, 1 as start_m, 'Revisão Trimestral: Extrusora de PA' as descr,
    '[{"action": "Calibração temperatura", "checked": false}, {"action": "Estado da rosca", "checked": false}]'::jsonb as chk
    UNION ALL
    -- ESMERIL (ES) - Mensal (Todos os meses)
    SELECT 'ES' as prefix, 1 as freq, 1 as start_m, 'Preventiva Mensal: Segurança e Rebolo' as descr,
    '[{"action": "Estado do rebolo", "checked": false}, {"action": "Proteção visual", "checked": false}, {"action": "Ajuste de apoio", "checked": false}, {"action": "Teste de isolamento", "checked": false}]'::jsonb as chk
    UNION ALL
    -- FORNOS (FO) - Trimestral (Mar, Jun, Set, Dez)
    SELECT 'FO' as prefix, 3 as freq, 3 as start_m, 'Revisão Trimestral: Calibração e Elétrica' as descr,
    '[{"action": "Medição de corrente", "checked": false}, {"action": "Reaperto de bornes", "checked": false}, {"action": "Vedação da porta", "checked": false}, {"action": "Ajuste controlador", "checked": false}]'::jsonb as chk
    UNION ALL
    -- TORNOS CNC (TC) - A cada 9 meses (Jan, Out)
    SELECT 'TC' as prefix, 9 as freq, 1 as start_m, 'Revisão Periódica (9m): Precisão e Fluidos' as descr,
    '[{"action": "Limpeza tanque refrigeração", "checked": false}, {"action": "Nível óleo barramento", "checked": false}]'::jsonb as chk
    UNION ALL
    -- TORNOS AUTO (TA) - A cada 6 meses (Fev, Ago)
    SELECT 'TA' as prefix, 6 as freq, 2 as start_m, 'Revisão Semestral: Mecânica de Leva' as descr,
    '[{"action": "Lubrificação automática", "checked": false}, {"action": "Desgaste de correias", "checked": false}]'::jsonb as chk
    UNION ALL
    -- SOLDA (MS) / CORRUGADORAS (CR) - Bimestral (Jan, Mar, Mai, Jul, Set, Nov)
    SELECT 'MS' as prefix, 2 as freq, 1 as start_m, 'Preventiva Bimestral' as descr, '[]'::jsonb as chk UNION ALL
    SELECT 'CR' as prefix, 2 as freq, 1 as start_m, 'Preventiva Bimestral' as descr, '[]'::jsonb as chk
    UNION ALL
    -- ANUAIS: CO (Set), GE (Jan), MI (Jul)
    SELECT 'CO' as prefix, 12 as freq, 9 as start_m, 'Preventiva Anual: Compressor' as descr, '[]'::jsonb as chk UNION ALL
    SELECT 'GE' as prefix, 12 as freq, 1 as start_m, 'Preventiva Anual: Gerador' as descr, '[]'::jsonb as chk UNION ALL
    SELECT 'MI' as prefix, 12 as freq, 7 as start_m, 'Preventiva Anual: Misturador' as descr, '[]'::jsonb as chk
)
SELECT 
    '2026-' || e.id || '-' || m.mm as id,
    e.id as equipment_id,
    'Preventiva' as type,
    'PCM Master' as requester,
    'Programado' as status,
    CAST('2026-' || m.mm || '-01 08:00:00' AS TIMESTAMPTZ) as scheduled_date,
    true as machine_stopped,
    r.descr as description,
    r.chk as checklist,
    '[]'::jsonb as materials_used,
    '[]'::jsonb as man_hours,
    'Geração Automática: Planejamento 2026.' as observations,
    '' as misc_notes,
    '' as downtime_notes
FROM equipment e
JOIN Regras r ON e.id LIKE r.prefix || '%'
JOIN Months m ON (CAST(m.mm AS INTEGER) >= r.start_m AND (CAST(m.mm AS INTEGER) - r.start_m) % r.freq = 0)
WHERE e.status = 'Ativo';

-- 3. AJUSTE DE REQUISITO CRÍTICO: ES-04 (ID #0009)
UPDATE work_orders 
SET id = '0009' 
WHERE equipment_id = 'ES-04' 
AND scheduled_date >= '2026-01-01' AND scheduled_date < '2026-02-01';

-- FIM DO SCRIPT MASTER
