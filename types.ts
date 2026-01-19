
export enum MaintenanceStatus {
    Scheduled = 'Programado',
    InField = 'Em Campo',
    Executed = 'Executado',
    Delayed = 'Atrasado',
    Deactivated = 'Desativado',
    WaitingParts = 'Aguardando Peças',
    None = 'Nenhum',
}

export enum AssetCategory {
    Industrial = 'Industrial',
    Facility = 'Predial',
}

export enum MaintenanceType {
    Preventive = 'Preventiva',
    Predictive = 'Preditiva',
    Corrective = 'Corretiva',
    Overhaul = 'Revisão Geral',
    // Added missing types referenced in constants and components
    RevisaoPeriodica = 'Revisão Periódica',
    PrestacaoServicos = 'Prestação de Serviços',
    Predial = 'Predial',
    Melhoria = 'Melhoria'
}

export enum CorrectiveCategory {
    Mechanical = 'Mecânica',
    Electrical = 'Elétrica',
    Pneumatic = 'Pneumática',
    Hydraulic = 'Hidráulica',
    Other = 'Outros'
}

export interface TaskDetail {
  action: string;
  materials?: string;
  checked?: boolean;
}

export interface Maintainer {
    name: string;
    isExternal: boolean;
}

export interface PurchaseRequest {
    id: string;
    itemDescription: string;
    quantity: number;
    status: 'Pendente' | 'Comprado' | 'Entregue';
    requisitionDate: string;
    arrivalDate?: string;
    purchaseOrderNumber?: string;
}

export interface MaintenanceTask {
  id: string;
  year: number;
  month: string;
  status: MaintenanceStatus;
  type: MaintenanceType | null;
  description: string;
  details?: TaskDetail[];
  osNumber?: string;
  priority?: 'Alta' | 'Média' | 'Baixa';
  startDate?: string; 
  endDate?: string;   
  manHours?: number;
  planId?: string;
  isPrepared?: boolean;
  // Added missing fields for Corrective logic
  correctiveCategory?: CorrectiveCategory;
  rootCause?: string;
  requestDate?: string;
  maintainer?: Maintainer;
  requester?: string;
  waitingForParts?: boolean;
  purchaseRequests?: PurchaseRequest[];
}

export interface Equipment {
  id: string;
  name: string;
  location: string;
  category: AssetCategory; 
  status: 'Ativo' | 'Inativo';
  is_critical: boolean;
  schedule: MaintenanceTask[];
  manufacturer?: string;
  model?: string;
  // Added missing fields for Equipment modals
  yearOfManufacture?: string | number;
  preservationNotes?: string;
  customerSpecificRequirements?: string;
  customPlanId?: string;
}

export interface ManHourEntry {
    maintainer: string;
    hours: number;
}

export interface WorkOrder {
    id: string;
    equipmentId: string;
    type: MaintenanceType;
    status: MaintenanceStatus;
    scheduledDate: string;
    endDate?: string; 
    description: string;
    checklist?: TaskDetail[];
    materialsUsed: { partId: string; quantity: number }[];
    manHours: ManHourEntry[];
    technicalAuditComment?: string;
    requester: string;
    machineStopped: boolean;
    rootCause?: string;
    // Added missing fields for unified logic
    observations?: string;
    miscNotes?: string;
    downtimeNotes?: string;
    correctiveCategory?: CorrectiveCategory;
    isPrepared?: boolean;
    purchaseRequests?: PurchaseRequest[];
}

export interface SparePart {
  id: string;
  name: string;
  location: string;
  unit: string;
  cost: number;
  minStock: number;
  currentStock: number;
}

export interface StockMovement {
    id: string;
    partId: string;
    partName: string; // Added missing field
    quantity: number;
    type: 'Entrada' | 'Saída';
    reason: string;
    userName: string;
    user: string; // Added missing field used in logs
    date: string;
    workOrderId?: string;
}

export interface StatusConfig {
    id: string;
    label: MaintenanceStatus;
    color: string;
    symbol: string;
}

export interface SelectedTask {
    equipment: Equipment;
    monthIndex: number;
    year: number;
    task: MaintenanceTask;
}

export interface FlatTask {
    equipment: Equipment;
    task: MaintenanceTask;
    year: number;
    monthIndex: number;
    key: string;
}

export interface EquipmentType {
    id: string;
    description: string;
}

export interface MaintenancePlan {
    id: string;
    description: string;
    equipment_type_id: string;
    target_equipment_ids: string[];
    frequency: number;
    maintenance_type: MaintenanceType;
    default_maintainer: string;
    start_month: string;
    tasks: TaskDetail[];
}

export type Page = 'home' | 'dashboard' | 'work_center' | 'schedule' | 'work_orders' | 'equipment' | 'inventory' | 'inventory_logs' | 'purchasing' | 'history' | 'search_os' | 'quality' | 'information' | 'documentation' | 'settings' | 'advanced_reports';
export type Theme = 'light' | 'dark';

export interface ReliabilityMetrics {
    mtbf: number | null;
    mttr: number;
    availability: number;
    totalFailures: number;
    totalCorrectiveHours: number;
}
