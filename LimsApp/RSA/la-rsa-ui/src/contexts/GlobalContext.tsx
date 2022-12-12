import { createContext, useReducer, ReactNode, useContext } from 'react';
import { LocalRunModel, LocalRunStore, Viewport } from '../models';

interface GlobalContextState {
  runs?: LocalRunStore;
  selectedPlateId?: string;
  viewport?: Viewport;
  isOnline?: boolean;
  showHomeButton?: boolean;
  selectedRun?: LocalRunModel;
}

const initialState: GlobalContextState = {
  runs: {},
  viewport: { width: 0, height: 0 },
  isOnline: false,
  showHomeButton: true,
};

interface GlobalProviderContext {
  state: typeof initialState;
  dispatch: (action: GlobalContextState) => void;
}

const GlobalContextProvider: React.FC<{ children: ReactNode }> = ({
  children,
}: {
  children: ReactNode;
}) => {
  const [state, dispatch] = useReducer(
    (state: GlobalContextState, newValue: GlobalContextState) => {
      return { ...state, ...newValue };
    },
    initialState,
  );
  return <GlobalContext.Provider value={{ state, dispatch }}>{children}</GlobalContext.Provider>;
};

export const GlobalContext = createContext<GlobalProviderContext>({
  state: initialState,
  dispatch: () => console.log('No provider registered yet !'),
});

export default GlobalContextProvider;

export function useGlobalState(): GlobalProviderContext {
  const context = useContext(GlobalContext);
  if (!context) {
    throw new Error('No context available');
  }
  return context;
}
