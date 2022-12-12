import { getRunColumnConfig } from './runs-columns-config';
import { Table } from '../../components/Table';
import { LocalRunModel } from '../../models';
import { useHistory } from 'react-router-dom';
import { runsService } from '../../services';
import { useEffect, useState } from 'react';
import { useGlobalState } from '../../contexts';
import { ResyncModal } from './ResyncModal';
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights.service';

export const Runs: React.FC = () => {
  const [resyncRun, setResyncRun] = useState<LocalRunModel>();
  const [showRysyncModal, setShowResyncModel] = useState<boolean>(false);
  const [currentRunList, setCurrentRunList] = useState<LocalRunModel[]>([]);
  const { state, dispatch } = useGlobalState();
  const history = useHistory();

  //componentDidMount equivalent
  useEffect(() => {
    appInsights.trackPageView({ name: 'Run' });
  }, []);

  useEffect(() => {
    runsService.resetTheSelectedStates();
    dispatch({
      runs: runsService.getRunsLocalStore(),
      selectedPlateId: undefined,
      showHomeButton: false,
      selectedRun: undefined,
    });
    return function cleanup() {
      dispatch({ showHomeButton: true });
    };
  }, []);

  useEffect(() => {
    setCurrentRunList(Object.values(state.runs || []));
  }, [state.runs]);

  async function downloadRunDetails(run: LocalRunModel): Promise<void> {
    if (!state.runs) {
      return;
    }
    const downloadedRun = state.runs[runsService.getLocalStoreKey(run.id, run.stepCode)];
    downloadedRun.downloading = true;
    dispatch({ runs: state.runs });
    await runsService.getRunDetails(run.id, run.stepCode, run.workflowCode);
    dispatch({ runs: runsService.getRunsLocalStore() });
  }

  async function openResyncModel(run: LocalRunModel): Promise<void> {
    setResyncRun(run);
    setShowResyncModel(!showRysyncModal);
  }

  function onResyncModalClose(): void {
    setShowResyncModel(!showRysyncModal);
  }

  // based on layout design the offset is substracted for finding table height.
  const tableOffset = 130;
  const tableHeight = state.viewport ? state.viewport.height - tableOffset : 200;
  return (
    <div>
      <Table
        onRow={(run: LocalRunModel) => {
          return {
            onClick: () => {
              if (!run.details || !state.runs) {
                return;
              }
              const selectedRun = state.runs[runsService.getLocalStoreKey(run.id, run.stepCode)];
              selectedRun.selected = true;
              runsService.setStore(state.runs);
              dispatch({ runs: state.runs, selectedRun: run });
              history.push({
                pathname: `/${run.id}/detail`,
              });
            },
          };
        }}
        scroll={{ x: 'max-content', y: tableHeight }}
        columns={getRunColumnConfig(downloadRunDetails, openResyncModel)}
        dataSource={currentRunList}
        rowKey='id'
        size='small'
        pagination={false}
      ></Table>
      <ResyncModal
        run={resyncRun as LocalRunModel}
        toggle={showRysyncModal}
        onModalClose={onResyncModalClose}
      />
    </div>
  );
};

export default withAITracking(reactPlugin, Runs);
