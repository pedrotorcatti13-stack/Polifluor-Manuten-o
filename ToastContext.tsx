import React, { createContext, useContext, useState, ReactNode, useCallback } from 'react';
import { CheckCircleIcon, ExclamationTriangleIcon, CloseIcon, InfoIcon } from '../components/icons';

type ToastType = 'success' | 'error' | 'info' | 'warning';

interface Toast {
    id: string;
    message: string;
    type: ToastType;
}

interface ToastContextType {
    showToast: (message: string, type?: ToastType) => void;
}

const ToastContext = createContext<ToastContextType | undefined>(undefined);

export const ToastProvider: React.FC<{ children: ReactNode }> = ({ children }) => {
    const [toasts, setToasts] = useState<Toast[]>([]);

    const showToast = useCallback((message: string, type: ToastType = 'info') => {
        const id = crypto.randomUUID();
        setToasts(prev => [...prev, { id, message, type }]);
        setTimeout(() => {
            setToasts(prev => prev.filter(t => t.id !== id));
        }, 3000); // Auto close after 3 seconds
    }, []);

    const removeToast = (id: string) => {
        setToasts(prev => prev.filter(t => t.id !== id));
    };

    return (
        <ToastContext.Provider value={{ showToast }}>
            {children}
            <div className="fixed top-4 right-4 z-[100] flex flex-col gap-2 pointer-events-none">
                {toasts.map(toast => (
                    <div 
                        key={toast.id}
                        className={`pointer-events-auto flex items-center p-4 min-w-[300px] rounded-lg shadow-lg border-l-4 transition-all animate-fade-in bg-white dark:bg-gray-800 ${
                            toast.type === 'success' ? 'border-green-500' :
                            toast.type === 'error' ? 'border-red-500' :
                            toast.type === 'warning' ? 'border-yellow-500' :
                            'border-blue-500'
                        }`}
                    >
                        <div className="flex-shrink-0 mr-3">
                            {toast.type === 'success' && <CheckCircleIcon className="w-6 h-6 text-green-500" />}
                            {toast.type === 'error' && <CloseIcon className="w-6 h-6 text-red-500" />}
                            {toast.type === 'warning' && <ExclamationTriangleIcon className="w-6 h-6 text-yellow-500" />}
                            {toast.type === 'info' && <InfoIcon className="w-6 h-6 text-blue-500" />}
                        </div>
                        <div className="flex-1 text-sm font-medium text-gray-800 dark:text-gray-100">
                            {toast.message}
                        </div>
                        <button onClick={() => removeToast(toast.id)} className="ml-4 text-gray-400 hover:text-gray-600 dark:hover:text-gray-200">
                            <CloseIcon className="w-4 h-4" />
                        </button>
                    </div>
                ))}
            </div>
        </ToastContext.Provider>
    );
};

export const useToast = (): ToastContextType => {
    const context = useContext(ToastContext);
    if (!context) {
        throw new Error('useToast must be used within a ToastProvider');
    }
    return context;
};