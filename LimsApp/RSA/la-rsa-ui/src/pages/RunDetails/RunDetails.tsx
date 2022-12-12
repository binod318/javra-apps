import { useEffect, useRef, useState } from 'react';
import { useHistory } from 'react-router-dom';
import {
  Inventory,
  Plate,
  RunColumn,
  LocalRunModel,
  RunProgress,
  LocalRunStore,
} from '../../models';
import { Button, Form, Progress, Switch } from 'antd';
import { PlateSelect } from './PlateSelect';
import { InventorySelect } from './InventorySelect';
import { RunDetailsList } from './RunDetailsList';
import { getInventoryLine, prepareRunDetailsListData } from './run-details-columns-config';
import style from './RunDetails.module.less';
import notSyncedButtonUrl from '../../images/not-synced.svg';
import syncErrorButtonUrl from '../../images/sync-error.svg';
import syncedButtonUrl from '../../images/sync.svg';
import { useGlobalState } from '../../contexts';
import { runsService } from '../../services';
import { CheckOutlined } from '@ant-design/icons';
import { Modal } from 'antd';
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights.service';

// FIXME Segregate this function to meet the linting !
// eslint-disable-next-line max-lines-per-function
export const RunDetails: React.FC = () => {
  const [inventories, setInventories] = useState<Inventory[]>([]);
  const [plates, setPlates] = useState<Plate[]>([]);
  const [title, setTitle] = useState<string>();
  const [stepCode, setStepCode] = useState<string>();
  const [runId, setRunId] = useState<string>();
  const [runClass, setRunClass] = useState<string>();
  const [runColumns, setRunColumns] = useState<RunColumn[]>([]);
  const [selectedPlate, setSelectedPlate] = useState<Plate>();
  const [runProgress, setRunProgress] = useState<RunProgress>();
  const [runProgressPercentage, setRunProgressPercentage] = useState<number>();
  const [lovIsTypable, setLovIsTypable] = useState<boolean>(false);
  type InventorySelectHandle = React.ElementRef<typeof InventorySelect>;
  const inventorySelectRef = useRef<InventorySelectHandle>(null);
  const history = useHistory();
  const { state, dispatch } = useGlobalState();
  const [isRunSynced, setisRunSynced] = useState<boolean>();
  const [hasError, setHasError] = useState<boolean>();

  //componentDidMount equivalent
  useEffect(() => {
    appInsights.trackPageView({ name: 'RunDetail' });
  }, []);

  useEffect(() => {
    const currentRun: LocalRunModel | undefined = state.selectedRun;
    const selectedPlateId = state.selectedPlateId || undefined;
    if (!currentRun || !currentRun.details) {
      history.push({ pathname: '/' });
      return;
    }
    setHasError(currentRun.error);
    setisRunSynced(currentRun.isSynced);
    setRunId(currentRun.id);
    setStepCode(currentRun.stepCode);
    setLovIsTypable(currentRun.lovTypable as boolean);
    setRunClass(currentRun.details.class);
    setTitle(`${currentRun.id} ${currentRun.workflowName} ${currentRun.stepName.substring(0, 4)}`);
    const details = currentRun.details;
    const plateInState = selectedPlateId
      ? details.plates.find((plate) => plate.plateID === selectedPlateId)
      : undefined;
    const invsInState = plateInState ? plateInState.invs : undefined;
    setPlates(details.plates);
    setSelectedPlate(plateInState ? plateInState : details.plates[0]);
    setInventories(invsInState ? invsInState : details.plates[0].invs);
    setRunColumns(details.columns);
    setRunProgress(currentRun.details.progress);
    const percent =
      currentRun.details.progress &&
      Math.round((100 * currentRun.details.progress.scored) / currentRun.details.progress.total);
    setRunProgressPercentage(percent);
  }, [state.selectedRun]);

  const onPlateSelectionChange = (selectedPlateId: string): void => {
    const selectedPlate: Plate | undefined = plates.find(
      (plate) => plate.plateID === selectedPlateId,
    );
    setSelectedPlate(selectedPlate);
    dispatch({ selectedPlateId: selectedPlateId });
    setInventories(selectedPlate?.invs || []);
    inventorySelectRef.current?.clear();
  };

  const onInventorySelectionChange = (selectedInventory: string): void => {
    const inventoryIdDashedRepCode = selectedInventory.split('__');
    history.push({
      pathname: `/${inventoryIdDashedRepCode[0]}/score`,
      state: {
        columns: runColumns,
        selectedInventory: getInventoryLine(
          inventoryIdDashedRepCode[0],
          inventories,
          selectedPlate?.plateID as string,
          runId as string,
          stepCode as string,
          parseInt(inventoryIdDashedRepCode[1]),
          inventoryIdDashedRepCode[2],
        ),
        inventoryLines: prepareRunDetailsListData(
          inventories,
          selectedPlate?.plateID as string,
          runId as string,
          stepCode as string,
        ),
        runClass,
      },
    });
  };

  const onLovSwitcherChange = (checked: boolean): void => {
    const currentRun: LocalRunModel | undefined = state.selectedRun;
    if (!currentRun) {
      history.push({ pathname: '/' });
      return;
    }
    currentRun.lovTypable = checked;
    setLovIsTypable(currentRun.lovTypable as boolean);
    if (!state.runs) {
      return;
    }
    state.runs[runsService.getLocalStoreKey(currentRun.id, currentRun.stepCode)] = currentRun;
    dispatch({ runs: state.runs });
    runsService.setStore(state.runs as LocalRunStore);
  };

  const onRemoveCompletedRun = (): void => {
    const currentRun: LocalRunModel | undefined = state.selectedRun;
    if (!currentRun) {
      history.push({ pathname: '/' });
      return;
    }
    Modal.confirm({
      icon: null,
      content: 'Are you sure you want to mark this step as complete and remove it from the list?',
      okText: 'Confirm',
      className: 'modal',
      width: '90%',
      style: { maxWidth: 500 },
      onOk() {
        const runs = runsService.removeRun(currentRun.id, currentRun.stepCode);
        dispatch({ runs });
        history.push({ pathname: '/' });
      },
    });
  };

  return (
    <div>
      <Form layout={'vertical'}>
        <div className={style.runDetailsHeader}>
          <h2 className={style.runFolder}>
            Run Folder : <strong>{title}</strong>
          </h2>
          {runProgress?.scored === runProgress?.total && isRunSynced ? (
            <Button
              style={{ borderColor: '#A2AF4F' }}
              shape='circle'
              icon={<CheckOutlined style={{ fontSize: 17, color: '#A2AF4F' }} />}
              onClick={onRemoveCompletedRun}
            />
          ) : (
            <img
              className={style.syncAsync}
              src={
                hasError ? syncErrorButtonUrl : isRunSynced ? syncedButtonUrl : notSyncedButtonUrl
              }
              alt='Sync status'
              width='30'
            />
          )}
        </div>
        {plates.length === 1 ? (
          <h3 className={style.plateName}>
            Plate: <strong>{selectedPlate?.plateID}</strong>
          </h3>
        ) : (
          <Form.Item label='Select Plate'>
            <PlateSelect
              plates={plates}
              selectedValue={selectedPlate}
              onSelectionChange={onPlateSelectionChange}
            />
          </Form.Item>
        )}
        <Form.Item label='Select Sample / Inventory'>
          <InventorySelect
            inventories={inventories}
            onSelectionChange={onInventorySelectionChange}
            ref={inventorySelectRef}
          />
        </Form.Item>
        {plates.length ? (
          <Switch
            className={
              plates.length === 1 ? style.lovSwithcerSingleLineText : style.lovSwithcerWithSelect
            }
            checkedChildren='Typeable'
            unCheckedChildren='Select'
            onClick={onLovSwitcherChange}
            checked={lovIsTypable}
          />
        ) : null}
      </Form>
      <div className={style.scoreProgress}>
        <Progress
          percent={runProgressPercentage}
          size='small'
          status='active'
          strokeColor='#a2af4f'
          format={() => {
            return `${runProgress?.scored}/${runProgress?.total}`;
          }}
        />
      </div>
      <RunDetailsList
        inventories={inventories}
        columns={runColumns}
        runId={runId as string}
        plateId={selectedPlate?.plateID as string}
        stepCode={stepCode as string}
        platesLength={plates.length}
        runClass={runClass as string}
      />
    </div>
  );
};

export default withAITracking(reactPlugin, RunDetails);
