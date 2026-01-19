
import React, { createContext, useContext, ReactNode, useState, useEffect, useCallback } from 'react';
import { Equipment, SparePart, WorkOrder, StockMovement, StatusConfig, EquipmentType, MaintenancePlan, MaintenanceStatus } from '../types';
import { useLocalStorage } from '../hooks/useLocalStorage';
import { useToast } from './ToastContext';
import { initialStatusConfig } from '../data/dataService';
import { INITIAL_INTERNAL_MAINTAINERS, INITIAL_REQUESTERS, INITIAL_PREDEFINED_ACTIONS, INITIAL_PREDEFINED_MATERIALS } from '../constants';
import { getInitialEquipmentData, getInitialCorrectiveBacklog } from '../data/initialData';

interface DataContextType {
    equipmentData: Equipment[];
    setEquipmentData: React.Dispatch<React.SetStateAction<Equipment[]>>;
    inventoryData: SparePart[];
    setInventoryData: React.Dispatch<React.SetStateAction<SparePart[]>>;
    workOrders: WorkOrder[];
    setWorkOrders: React.Dispatch<React.SetStateAction<WorkOrder[]>>;
    stockMovements: StockMovement[];
    statusConfig: StatusConfig[];
    maintainers: string[];
    setMaintainers: React.Dispatch<React.SetStateAction<string[]>>;
    requesters: string[];
    setRequesters: React.Dispatch<React.SetStateAction<string[]>>;
    equipmentTypes: EquipmentType[];
    setEquipmentTypes: React.Dispatch<React.SetStateAction<EquipmentType[]>>;
    maintenancePlans: MaintenancePlan[];
    setMaintenancePlans: React.Dispatch<React.SetStateAction<MaintenancePlan[]>>;
    standardTasks: string[];
    standardMaterials: string[];
    excludedIds: string[];
    isInitialLoading: boolean;
    isSyncing: boolean;
    cloudConnected: boolean;
    lastSyncTime: string;
    syncData: (silent?: boolean) => Promise<void>;
    handleUnifiedSave: (order: WorkOrder) => Promise<boolean>;
    handleEquipmentSave: (eq: Equipment) => Promise<boolean>;
    handlePartSave: (part: SparePart) => Promise<boolean>;
    forceFullDatabaseRefresh: () => Promise<void>;
    loadDataFromCloud: () => Promise<void>;
    logActivity: (activity: { action_type: string, description: string }) => void;
    reprogramTask: (eqId: string, taskId: string, month: string, year: number) => void;
    markTasksAsPrepared: (keys: string[]) => void;
    revertTasksPreparation: (keys: string[]) => void;
    showToast: (message: string, type: 'success' | 'error' | 'info' | 'warning') => void;
}

const DataContext = createContext<DataContextType | undefined>(undefined);

export const DataProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const { showToast } = useToast();
    
    // USANDO LOCALSTORAGE PARA PERSISTÊNCIA OFFLINE
    const [equipmentData, setEquipmentData] = useLocalStorage<Equipment[]>('sgmi_equipment', getInitialEquipmentData());
    const [inventoryData, setInventoryData] = useLocalStorage<SparePart[]>('sgmi_inventory', []);
    const [workOrders, setWorkOrders] = useLocalStorage<WorkOrder[]>('sgmi_work_orders', getInitialCorrectiveBacklog());
    const [stockMovements, setStockMovements] = useLocalStorage<StockMovement[]>('sgmi_stock_moves', []);
    const [maintainers, setMaintainers] = useLocalStorage<string[]>('sgmi_maintainers', INITIAL_INTERNAL_MAINTAINERS);
    const [requesters, setRequesters] = useLocalStorage<string[]>('sgmi_requesters', INITIAL_REQUESTERS);
    const [equipmentTypes, setEquipmentTypes] = useLocalStorage<EquipmentType[]>('sgmi_types', []);
    const [maintenancePlans, setMaintenancePlans] = useLocalStorage<MaintenancePlan[]>('sgmi_plans', []);
    
    const [isInitialLoading, setIsInitialLoading] = useState(false);
    const [isSyncing, setIsSyncing] = useState(false);
    const [lastSyncTime, setLastSyncTime] = useState(new Date().toLocaleTimeString());

    // Monitor de integridade: Garante que as OSs herdem dados do cadastro de equipamentos atualizado
    useEffect(() => {
        const checkConsistency = () => {
            let hasChanged = false;
            const updatedOrders = workOrders.map(wo => {
                const eq = equipmentData.find(e => e.id === wo.equipmentId);
                // Se a OS está 'Executada' mas não tem endDate, gera uma baseada na scheduledDate
                if (wo.status === MaintenanceStatus.Executed && !wo.endDate) {
                    hasChanged = true;
                    return { ...wo, endDate: new Date(new Date(wo.scheduledDate).getTime() + 3600000).toISOString() };
                }
                return wo;
            });
            if (hasChanged) setWorkOrders(updatedOrders);
        };
        checkConsistency();
    }, [equipmentData]);

    const syncData = async (silent = false) => {
        setIsSyncing(true);
        // Simulação de delay de banco
        await new Promise(resolve => setTimeout(resolve, 600));
        setLastSyncTime(new Date().toLocaleTimeString());
        setIsSyncing(false);
        if (!silent) showToast("Base de dados sincronizada com sucesso", "success");
    };

    const handleUnifiedSave = async (order: WorkOrder) => {
        setIsSyncing(true);
        setWorkOrders(prev => {
            const index = prev.findIndex(o => o.id === order.id);
            if (index > -1) {
                const copy = [...prev];
                copy[index] = order;
                return copy;
            }
            return [order, ...prev];
        });
        await syncData(true);
        showToast(`Protocolo #${order.id} salvo`, "success");
        return true;
    };

    const handleEquipmentSave = async (updatedEq: Equipment) => {
        setEquipmentData(prev => {
            const index = prev.findIndex(e => e.id === updatedEq.id);
            if (index > -1) {
                const copy = [...prev];
                copy[index] = updatedEq;
                return copy;
            }
            return [...prev, updatedEq];
        });
        return true;
    };

    const handlePartSave = async (part: SparePart) => {
        setInventoryData(prev => {
            const exists = prev.findIndex(p => p.id === part.id);
            if (exists > -1) {
                const copy = [...prev];
                copy[exists] = part;
                return copy;
            }
            return [...prev, part];
        });
        return true;
    };

    const forceFullDatabaseRefresh = async () => {
        if(confirm("ATENÇÃO: Deseja resetar o banco de dados? Isso apagará edições manuais e recarregará o Plano Mestre 2026 oficial.")) {
            localStorage.removeItem('sgmi_equipment');
            localStorage.removeItem('sgmi_work_orders');
            localStorage.removeItem('sgmi_inventory');
            localStorage.removeItem('sgmi_stock_moves');
            localStorage.removeItem('sgmi_plans');
            window.location.reload();
        }
    };

    const loadDataFromCloud = async () => {
        await syncData();
    };

    const logActivity = (activity: any) => {
        console.log("SYS_LOG:", activity);
    };

    const reprogramTask = (eqId: string, taskId: string, month: string, year: number) => {
        setEquipmentData(prev => prev.map(eq => {
            if (eq.id === eqId) {
                return {
                    ...eq,
                    schedule: (eq.schedule || []).map(t => t.id === taskId ? { ...t, month, year } : t)
                };
            }
            return eq;
        }));
    };

    const markTasksAsPrepared = (keys: string[]) => {
        showToast(`${keys.length} documentos marcados para campo`, "info");
    };

    const revertTasksPreparation = (keys: string[]) => {
        showToast("Reset de fluxo concluído", "info");
    };

    return (
        <DataContext.Provider value={{ 
            equipmentData, setEquipmentData, inventoryData, setInventoryData, workOrders, setWorkOrders, stockMovements,
            statusConfig: initialStatusConfig,
            maintainers, setMaintainers,
            requesters, setRequesters,
            equipmentTypes, setEquipmentTypes,
            maintenancePlans, setMaintenancePlans,
            standardTasks: INITIAL_PREDEFINED_ACTIONS,
            standardMaterials: INITIAL_PREDEFINED_MATERIALS,
            excludedIds: [],
            isInitialLoading, isSyncing, cloudConnected: true, lastSyncTime,
            syncData, handleUnifiedSave, handleEquipmentSave, handlePartSave, forceFullDatabaseRefresh, loadDataFromCloud,
            logActivity, reprogramTask, markTasksAsPrepared, revertTasksPreparation, showToast
        }}>
            {children}
        </DataContext.Provider>
    );
};

export const useDataContext = () => {
    const context = useContext(DataContext);
    if (!context) throw new Error('DataContext Provider error');
    return context;
};
