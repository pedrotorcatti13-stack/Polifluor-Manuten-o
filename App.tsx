
import React, { useEffect, useState, useCallback } from 'react';
import { useAppContext } from './contexts/AppContext';
import { useDataContext } from './contexts/DataContext';
import { useToast } from './contexts/ToastContext';

// Import Pages
import { LoginPage } from './pages/LoginPage';
import { HomePage } from './pages/HomePage';
import { SchedulePage } from './pages/SchedulePage';
import { InventoryPage } from './pages/InventoryPage';
import { InventoryLogsPage } from './pages/InventoryLogsPage';
import { SettingsPage } from './pages/SettingsPage';
import { EquipmentPage } from './pages/EquipmentPage';
import { WorkCenterPage } from './pages/WorkCenterPage';
import { DashboardPage } from './pages/DashboardPage';
import { WorkOrderPage } from './pages/WorkOrderPage';
import { HistoryPage } from './pages/HistoryPage';
import { AdvancedReportsPage } from './pages/AdvancedReportsPage';
import { WorkOrderSearchPage } from './pages/WorkOrderSearchPage';
import { QualityPage } from './pages/QualityPage';
import { InformationPage } from './pages/InformationPage';
import { DocumentationPage } from './pages/DocumentationPage';
import { PurchasingPage } from './pages/PurchasingPage';

// Import Components
import { AppHeader } from './components/AppHeader';
import { Sidebar } from './components/Sidebar';
import { WorkOrderControlModal } from './components/WorkOrderControlModal';
import { CorrectiveRequestModal } from './components/CorrectiveRequestModal';
import { MaintenanceStatus, WorkOrder, MaintenanceType, CorrectiveCategory } from './types';
import { getNextOSNumber } from './utils/osGenerator';

const AppContent: React.FC = () => {
    const { isLoggedIn, currentPage, theme, handleLogin, isOSModalOpen, setIsOSModalOpen, editingOrder, setEditingOrder } = useAppContext();
    const { equipmentData, workOrders, inventoryData, maintainers, requesters, handleUnifiedSave } = useDataContext();
    const { showToast } = useToast();
    
    // isSidebarOpen: true = Expandida (256px), false = Mini (80px)
    const [isSidebarOpen, setIsSidebarOpen] = useState(false);
    const [isCorrectiveRequestOpen, setIsCorrectiveRequestOpen] = useState(false);

    useEffect(() => {
        if (theme === 'dark') document.documentElement.classList.add('dark');
        else document.documentElement.classList.remove('dark');
    }, [theme]);

    // Auto-hide ao navegar para garantir foco no conteúdo
    useEffect(() => {
        setIsSidebarOpen(false);
    }, [currentPage]);
    
    const handleSaveUnifiedOS = (updatedOrder: WorkOrder) => {
        handleUnifiedSave(updatedOrder);
        setIsOSModalOpen(false);
        setEditingOrder(null);
    };

    const handleCreateQuickCorrective = (equipmentId: string, description: string, requester: string, priority: 'Alta' | 'Média' | 'Baixa', osNumber: string, category?: CorrectiveCategory, failureDateTime?: string) => {
        const nextId = osNumber || getNextOSNumber(equipmentData, workOrders);
        const newOrder: WorkOrder = {
            id: nextId,
            equipmentId,
            type: MaintenanceType.Corrective,
            status: priority === 'Alta' ? MaintenanceStatus.Delayed : MaintenanceStatus.Scheduled,
            description,
            scheduledDate: failureDateTime || new Date().toISOString().slice(0, 16),
            requester,
            machineStopped: priority === 'Alta',
            manHours: [],
            materialsUsed: [],
            observations: '',
            miscNotes: '',
            downtimeNotes: '',
            correctiveCategory: category,
            rootCause: ''
        };
        
        handleUnifiedSave(newOrder);
        setIsCorrectiveRequestOpen(false);
    };

    const toggleSidebar = useCallback(() => {
        setIsSidebarOpen(prev => !prev);
    }, []);

    const handleMainContentClick = () => {
        // Se a sidebar estiver expandida e o usuário clicar na área principal, recolhe.
        if (isSidebarOpen) {
            setIsSidebarOpen(false);
        }
    };

    const renderPage = () => {
        switch (currentPage) {
            case 'home': return <HomePage />;
            case 'dashboard': return <DashboardPage />;
            case 'work_center': return <WorkCenterPage />;
            case 'schedule': return <SchedulePage />;
            case 'work_orders': return <WorkOrderPage />;
            case 'equipment': return <EquipmentPage />;
            case 'inventory': return <InventoryPage />;
            case 'inventory_logs': return <InventoryLogsPage />;
            case 'purchasing': return <PurchasingPage />;
            case 'history': return <HistoryPage />;
            case 'advanced_reports': return <AdvancedReportsPage />;
            case 'search_os': return <WorkOrderSearchPage />;
            case 'quality': return <QualityPage />;
            case 'information': return <InformationPage />;
            case 'documentation': return <DocumentationPage />;
            case 'settings': return <SettingsPage />;
            default: return <HomePage />;
        }
    };
    
    if (!isLoggedIn) return <LoginPage onLogin={handleLogin} />;
    
    return (
        <div className={`min-h-screen font-sans ${theme === 'dark' ? 'dark' : ''} flex overflow-hidden`}>
            {/* Sidebar Reativa: Clique para expandir */}
            <div 
                className={`fixed inset-y-0 left-0 z-50 transition-all duration-300 ease-in-out transform bg-white dark:bg-gray-900 border-r border-slate-200 dark:border-gray-800 shadow-2xl 
                ${isSidebarOpen ? 'translate-x-0 w-64' : 'translate-x-0 w-20'}`}
                onClick={() => !isSidebarOpen && setIsSidebarOpen(true)}
            >
                <Sidebar 
                    isCollapsed={!isSidebarOpen} 
                    onCloseMobile={() => setIsSidebarOpen(false)} 
                />
            </div>

            {/* Main Content: Clique para recolher */}
            <main 
                className={`flex-1 flex flex-col h-screen overflow-hidden bg-gray-100 dark:bg-gray-950 text-gray-900 dark:text-white transition-all duration-300 ${isSidebarOpen ? 'pl-64' : 'pl-20'}`}
                onClick={handleMainContentClick}
            >
                <AppHeader 
                    onOpenCorrectiveRequest={() => setIsCorrectiveRequestOpen(true)} 
                    onToggleSidebar={toggleSidebar}
                />
                <div className="flex-1 overflow-y-auto p-4 sm:p-6 md:p-8 bg-gray-50 dark:bg-gray-900/50 scroll-smooth">
                    {renderPage()}
                </div>
            </main>

            {isOSModalOpen && (
                <WorkOrderControlModal
                    isOpen={isOSModalOpen}
                    onClose={() => { setIsOSModalOpen(false); setEditingOrder(null); }}
                    onSave={handleSaveUnifiedOS}
                    equipmentData={equipmentData}
                    inventoryData={inventoryData}
                    existingOrder={editingOrder}
                    nextOSNumber={getNextOSNumber(equipmentData, workOrders)}
                    maintainers={maintainers}
                    requesters={requesters}
                />
            )}

            {isCorrectiveRequestOpen && (
                <CorrectiveRequestModal 
                    isOpen={isCorrectiveRequestOpen}
                    onClose={() => setIsCorrectiveRequestOpen(false)}
                    onCreate={handleCreateQuickCorrective}
                    equipmentList={equipmentData}
                    requesters={requesters}
                />
            )}
        </div>
    );
};

const App: React.FC = () => <AppContent />;
export default App;
