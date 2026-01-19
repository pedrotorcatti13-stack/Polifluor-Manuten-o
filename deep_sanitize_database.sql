
/* 
   SGMI 2.0 - SCRIPT DE SANEAMENTO PROFUNDO E INTEGRIDADE
   OBJETIVO: Eliminar loop de cache, registros órfãos e resetar contadores de OS.
*/

-- 1. IDENTIFICAÇÃO E ELIMINAÇÃO DE REGISTROS ÓRFÃOS (DEAD CODES)
-- Remove ordens de serviço cujo equipamento pai foi deletado
DELETE FROM work_orders 
WHERE equipment_id NOT IN (SELECT id FROM equipment);

-- Remove planos de manutenção vazios ou sem vínculo (IATF Compliance)
DELETE FROM maintenance_plans 
WHERE target_equipment_ids IS NULL 
   OR target_equipment_ids::text = '[]'
   OR target_equipment_ids::text = 'null';

-- 2. ELIMINAÇÃO DE DUPLICIDADES (KEEP LATEST)
-- Mantém apenas a versão mais recente de uma OS caso o ID tenha duplicado por erro de sync
DELETE FROM work_orders a
USING work_orders b
WHERE a.ctid < b.ctid 
  AND a.id = b.id;

-- 3. RESET SELETIVO (PRESERVAÇÃO DE ATIVOS / LIMPEZA DE OPERAÇÃO)
-- Limpa tabelas de transação para resetar o fluxo de "Próxima OS"
-- MANTÉM: equipment (162) e spare_parts (81)
TRUNCATE TABLE work_orders RESTART IDENTITY CASCADE;
TRUNCATE TABLE activity_logs RESTART IDENTITY CASCADE;
-- TRUNCATE TABLE notifications RESTART IDENTITY CASCADE; -- Se existir a tabela

-- 4. GARANTIA DE CONSISTÊNCIA DE TIPOS (PREVENÇÃO DE CRASH REACT)
-- Garante que colunas críticas não contenham lixo que quebre o JSON.parse ou renderização de data
UPDATE equipment SET schedule = '[]'::jsonb WHERE schedule IS NULL;
UPDATE equipment SET is_critical = false WHERE is_critical IS NULL;

-- 5. OTIMIZAÇÃO E RE-INDEXAÇÃO (SUPABASE/POSTGRES)
-- Força o banco a reconstruir os mapas de busca para evitar erros de ponteiro no frontend
REINDEX TABLE work_orders;
REINDEX TABLE equipment;
ANALYZE work_orders;
ANALYZE equipment;

-- 6. VERIFICAÇÃO DE SAÚDE PÓS-LIMPEZA
SELECT 
    (SELECT COUNT(*) FROM equipment) as ativos_preservados,
    (SELECT COUNT(*) FROM spare_parts) as itens_estoque_preservados,
    (SELECT COUNT(*) FROM work_orders) as ordens_resetadas;
