
import { MaintenanceType } from './types';

export const MONTHS = [
  'Janeiro', 'Fevereiro', 'Março', 'Abril', 'Maio', 'Junho',
  'Julho', 'Agosto', 'Setembro', 'Outubro', 'Novembro', 'Dezembro'
];

export const getHoursInYear = (year: number): number => {
    const isLeap = (year % 4 === 0 && year % 100 !== 0) || (year % 400 === 0);
    return isLeap ? 366 * 24 : 365 * 24;
};

export const INITIAL_INTERNAL_MAINTAINERS = [
    'João Silva',
    'Carlos Pereira',
    'Ana Souza',
    'Marcos Lima',
    'Equipe Externa A',
    'Fornecedor B',
    'Sampred',
];

export const INITIAL_REQUESTERS = [
    'Produção',
    'Qualidade',
    'Engenharia',
    'Segurança',
    'Manutenção',
];

export const INITIAL_PREDEFINED_ACTIONS: string[] = [
    'Analisar condições gerais',
    'Análise de vibração',
    'Análise termográfica',
    'Limpeza do equipamento',
    'Lubrificar guias e barramentos',
    'Medição de corrente do motor',
    'Reaperto de contatos elétricos',
    'Substituição de Óleo e Filtro do Óleo',
    'Verificação de vazamentos',
    'Verificação do nível de óleo',
].sort((a, b) => a.localeCompare(b));

export const INITIAL_PREDEFINED_MATERIALS: string[] = [
    'Graxa à base de lítio',
    'Óleo hidráulico ISO VG 46',
    'ÓLEO ISO VG 68',
    'Rolamento 6202 zz',
].sort((a, b) => a.localeCompare(b));

export const MAINTENANCE_TYPE_CONFIG: { [key in MaintenanceType]: { label: string; color: string; textColor: string } } = {
    [MaintenanceType.Preventive]: { label: 'Preventiva', color: 'bg-blue-600', textColor: 'text-white' },
    [MaintenanceType.Predictive]: { label: 'Preditiva', color: 'bg-amber-400', textColor: 'text-amber-950' },
    [MaintenanceType.Corrective]: { label: 'Corretiva', color: 'bg-rose-600', textColor: 'text-white' },
    [MaintenanceType.Overhaul]: { label: 'Revisão Geral', color: 'bg-purple-600', textColor: 'text-white' },
    [MaintenanceType.RevisaoPeriodica]: { label: 'Preventiva', color: 'bg-blue-600', textColor: 'text-white' },
    [MaintenanceType.PrestacaoServicos]: { label: 'Serviços', color: 'bg-indigo-600', textColor: 'text-white' },
    [MaintenanceType.Predial]: { label: 'Predial', color: 'bg-stone-600', textColor: 'text-white' },
    [MaintenanceType.Melhoria]: { label: 'Melhoria', color: 'bg-sky-500', textColor: 'text-white' },
};
