import React, { createContext, useState, useContext, ReactNode } from 'react';
import { Page, Theme, WorkOrder } from '../types';

interface AppContextType {
    isLoggedIn: boolean;
    handleLogin: (success: boolean) => void;
    handleLogout: () => void;
    currentPage: Page;
    setCurrentPage: (page: Page) => void;
    theme: Theme;
    setTheme: (theme: Theme) => void;
    isOSModalOpen: boolean;
    setIsOSModalOpen: (isOpen: boolean) => void;
    editingOrder: WorkOrder | null;
    setEditingOrder: (order: WorkOrder | null) => void;
}

const AppContext = createContext<AppContextType | undefined>(undefined);

export const AppProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    // Transição para Memory-State (Fim do Single Point of Failure no LocalStorage)
    const [isLoggedIn, setIsLoggedIn] = useState(false);
    const [currentPage, setCurrentPage] = useState<Page>('home');
    const [theme, setTheme] = useState<Theme>('light');
    
    const [isOSModalOpen, setIsOSModalOpen] = useState(false);
    const [editingOrder, setEditingOrder] = useState<WorkOrder | null>(null);

    const handleLogin = (success: boolean) => {
        setIsLoggedIn(success);
        if (success) setCurrentPage('home');
    };

    const handleLogout = () => {
        setIsLoggedIn(false);
        setCurrentPage('home');
    };

    return (
        <AppContext.Provider value={{
            isLoggedIn, handleLogin, handleLogout,
            currentPage, setCurrentPage,
            theme, setTheme,
            isOSModalOpen, setIsOSModalOpen,
            editingOrder, setEditingOrder
        }}>
            {children}
        </AppContext.Provider>
    );
};

export const useAppContext = (): AppContextType => {
    const context = useContext(AppContext);
    if (!context) throw new Error('useAppContext Provider Error');
    return context;
};
