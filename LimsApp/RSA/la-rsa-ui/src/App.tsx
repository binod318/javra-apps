import './styles/index.less';
import React, { useEffect, useState } from 'react';
import { Switch } from 'react-router-dom';
import { Spin } from 'antd';
import MainLayout from './layouts/MainLayout';
import { Runs } from './pages/Runs';
import { RunDetails } from './pages/RunDetails';
import { Score } from './pages/Score';
import { withAdalLoginApi } from './config/adal';
import Fallback from './components/Fallback';
import AuthError from './components/AuthError';
import loadingIcon from './components/Loading';
import { useGlobalState } from './contexts/GlobalContext';
import { runsService } from './services';
import { getViewport } from './utils';
import AuthRoute from './components/AuthRoute';
import { AppInsightsContext } from '@microsoft/applicationinsights-react-js';
import { reactPlugin } from './config/app-insights.service';
// import { makeMockServer } from './mock-server';

// It creates the mock server only in development mode
// if (process.env.NODE_ENV === 'development') {
//   makeMockServer({ environment: 'development' });
// }

function App(): JSX.Element {
  const [loading, setLoading] = useState(0);
  const { state, dispatch } = useGlobalState();
  let resizeTracker: number;

  useEffect(() => {
    // set runs from local storage, early hydration
    dispatch({ runs: runsService.getRunsLocalStore(), selectedRun: runsService.getSelectedRun() });
  }, []);

  useEffect(() => {
    window.addEventListener('resize', resizeHandler, false);
    resizeHandler();
    return function cleanup() {
      window.removeEventListener('resize', resizeHandler, false);
    };
  }, []);

  function resizeHandler() {
    clearTimeout(resizeTracker);
    resizeTracker = window.setTimeout(function updateViewportDimension() {
      dispatch({ viewport: getViewport() });
    }, 16);
  }

  function updateConnectionStatus() {
    const isOnline = window.navigator.onLine;
    if (isOnline) {
      document.body.classList.remove('offline');
    } else {
      document.body.classList.add('offline');
    }
    dispatch({ isOnline });
  }

  useEffect(() => {
    updateConnectionStatus();
    window.addEventListener('online', updateConnectionStatus, false);
    window.addEventListener('offline', updateConnectionStatus, false);
    resizeHandler();
    return function cleanup() {
      window.removeEventListener('online', updateConnectionStatus, false);
      window.removeEventListener('offline', updateConnectionStatus, false);
    };
  }, []);

  useEffect(() => {
    async function fetchRuns() {
      setLoading((loading) => loading + 1);
      const runs = await runsService.getRunList();
      setLoading((loading) => loading - 1);
      dispatch({ runs });
    }
    fetchRuns();
  }, []);

  useEffect(() => {
    async function syncRuns() {
      if (state.isOnline) {
        await runsService.syncRuns();
        dispatch({
          runs: runsService.getRunsLocalStore(),
          selectedRun: runsService.getSelectedRun(),
        });
      }
    }
    syncRuns();
  }, [state.isOnline]);

  return (
    <AppInsightsContext.Provider value={reactPlugin}>
      <Spin spinning={loading > 0} indicator={loadingIcon()}>
        <MainLayout>
          <Switch>
            <AuthRoute path='/' component={Runs} exact={true} />
            <AuthRoute path='/:runId/detail' component={RunDetails} exact={true} />
            <AuthRoute path='/:inventoryId/score' component={Score} exact={true} />
          </Switch>
        </MainLayout>
      </Spin>
    </AppInsightsContext.Provider>
  );
}

export default withAdalLoginApi(App, Fallback, AuthError);
