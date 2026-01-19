
/* 
   SGMI 2.0 - SCRIPT DE RECONSTRUÇÃO DE PLANEJAMENTO 2026
   ALVO: Tabela work_orders
   DATA: 2026-01-01 a 2026-12-31
*/

-- 1. Limpeza de rascunhos de 2026 (opcional, remova se quiser manter o que já existe)
DELETE FROM work_orders WHERE id LIKE '2026-%';

-- 2. Inserção Baseada em Regras de Categoria
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
    SELECT '01' as mm, 'Janeiro' as name UNION ALL SELECT '02', 'Fevereiro' UNION ALL SELECT '03', 'Março' UNION ALL
    SELECT '04', 'Abril' UNION ALL SELECT '05', 'Maio' UNION ALL SELECT '06', 'Junho' UNION ALL
    SELECT '07', 'Julho' UNION ALL SELECT '08', 'Agosto' UNION ALL SELECT '09', 'Setembro' UNION ALL
    SELECT '10', 'Outubro' UNION ALL SELECT '11', 'Novembro' UNION ALL SELECT '12', 'Dezembro'
),
Regras AS (
    -- FORNOS (FO) - Trimestral (Jan, Abr, Jul, Out)
    SELECT 'FO' as prefix, 3 as freq, 1 as start_m, 'Preventiva' as type, 
    'Revisão Trimestral: Elétrica e Calibração' as descr,
    '[{"action": "Reaperto de contatos", "checked": false}, {"action": "Medição de corrente", "checked": false}, {"action": "Vedação da porta", "checked": false}, {"action": "Calibração controlador", "checked": false}]'::jsonb as chk
    UNION ALL
    -- MISTURADORES (MI) - Semestral (Jan, Jul)
    SELECT 'MI' as prefix, 6 as freq, 1 as start_m, 'Preventiva' as type,
    'Revisão Semestral: Mecânica Redutora' as descr,
    '[{"action": "Nível de óleo redutor (Óleo 320)", "checked": false}, {"action": "Desgaste das pás", "checked": false}, {"action": "Reaperto base motor", "checked": false}]'::jsonb as chk
    UNION ALL
    -- PRENSAS (PH) - Trimestral (Jan, Abr, Jul, Out)
    SELECT 'PH' as prefix, 3 as freq, 1 as start_m, 'Preventiva' as type,
    'Revisão Trimestral: Hidráulica e Elétrica' as descr,
    '[{"action": "Nível óleo (ISO VG 68)", "checked": false}, {"action": "Corrente motor", "checked": false}, {"action": "Reaperto contatos", "checked": false}, {"action": "Terminais contatora", "checked": false}, {"action": "Limpeza interna", "checked": false}, {"action": "Sistema hidráulico", "checked": false}]'::jsonb as chk
    UNION ALL
    -- COMPRESSORES/GERADORES/TORRES - Mensal
    SELECT 'CO' as prefix, 1 as freq, 1 as start_m, 'Preventiva' as type, 'Preventiva Mensal' as descr, '[{"action": "Drenagem e Níveis", "checked": false}]'::jsonb as chk UNION ALL
    SELECT 'GE' as prefix, 1 as freq, 1 as start_m, 'Preventiva' as type, 'Preventiva Mensal' as descr, '[{"action": "Nível de Combustível/Bateria", "checked": false}]'::jsonb as chk UNION ALL
    SELECT 'TRA' as prefix, 1 as freq, 1 as start_m, 'Preventiva' as type, 'Preventiva Mensal' as descr, '[{"action": "Qualidade da água/Ventilação", "checked": false}]'::jsonb as chk UNION ALL
    SELECT 'TO' as prefix, 1 as freq, 1 as start_m, 'Preventiva' as type, 'Preventiva Mensal' as descr, '[{"action": "Limpeza de Colmeias", "checked": false}]'::jsonb as chk
    UNION ALL
    -- ESMERIL (ES) - Semestral
    SELECT 'ES' as prefix, 6 as freq, 1 as start_m, 'Preventiva' as type,
    'Revisão Semestral: Segurança e Desgaste' as descr,
    '[{"action": "Estado rebolos", "checked": false}, {"action": "Ajuste apoio", "checked": false}, {"action": "Proteção visual", "checked": false}, {"action": "Isolamento elétrico", "checked": false}]'::jsonb as chk
    UNION ALL
    -- EXTRUSORAS (EX) - Bimestral (6 ordens)
    SELECT 'EX' as prefix, 2 as freq, 1 as start_m, 'Preventiva' as type,
    'Revisão Bimestral: Aquecimento e Amperagem' as descr,
    '[{"action": "Verificar Resistências", "checked": false}, {"action": "Medição de Amperagem", "checked": false}]'::jsonb as chk
)
SELECT 
    -- ID Único: 2026-[EQUIP]-MM
    '2026-' || e.id || '-' || m.mm as id,
    e.id as equipment_id,
    r.type as type,
    'PCM Master' as requester,
    'Programado' as status,
    '2026-' || m.mm || '-01T08:00:00' as scheduled_date,
    true as machine_stopped,
    r.descr as description,
    r.chk as checklist,
    '[]'::jsonb as materials_used,
    '[]'::jsonb as man_hours,
    'Geração Automática via Script de Reconstrução' as observations,
    '' as misc_notes,
    '' as downtime_notes
FROM equipment e
JOIN Regras r ON e.id LIKE r.prefix || '-%'
JOIN Months m ON (CAST(m.mm AS INTEGER) - r.start_m) % r.freq = 0
WHERE e.status = 'Ativo';

-- 3. Caso Especial: Garantir que ES-04 tenha o ID OS #0009 na primeira preventiva
-- Nota: Como o sistema usa UUID ou strings compostas no ID, vamos atualizar o os_number (metadado)
UPDATE work_orders 
SET id = '0009' -- Forçando o ID conforme solicitado para este ativo específico
WHERE equipment_id = 'ES-04' 
AND scheduled_date LIKE '2026-01%';

-- FIM DO SCRIPT
