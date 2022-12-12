import { useLocation } from 'react-router-dom';
import { Form, Col, Row, Button } from 'antd';
import { RunColumn, Score as ScoreModel, StringMap } from '../../models';
import style from './Score.module.less';
import closeButtonUrl from '../../images/close.svg';
import { useHistory } from 'react-router-dom';
import { runsService } from '../../services';
import { useGlobalState } from '../../contexts';
import { useEffect, useRef, useState } from 'react';
import { ScoringWidgets } from './ScoringWidgets';
import { InventoryRow } from '../RunDetails';
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights.service';

// FIXME we need to have proper way to load pipeline variables for development mode
if (process.env.NODE_ENV !== 'production') {
  window.STEP_NAMES = '["Leaf punch", "Checking viable plants"]';
}
export interface ScoreState {
  columns: RunColumn[];
  selectedInventory: InventoryRow;
  inventoryLines: InventoryRow[];
  runClass: string;
}

// FIXME Segregate this function to meet the linting !
// eslint-disable-next-line max-lines-per-function
export const Score: React.FC = () => {
  const [blinker, setBlinker] = useState(true);
  const [isNext, setIsNext] = useState(false);
  const location = useLocation<ScoreState>();
  const history = useHistory();
  const { columns, selectedInventory, inventoryLines, runClass } = location.state;
  const [selectedInventoryLine, setSelectedInventoryLine] = useState<InventoryRow>(
    selectedInventory || {},
  );
  const [disableNextPrev, setDisableNextPrev] = useState<boolean | undefined>(false);
  const { state, dispatch } = useGlobalState();
  const [form] = Form.useForm();
  type ScoringWidgetsHandle = React.ElementRef<typeof ScoringWidgets>;
  const scoringWidgetsRef = useRef<ScoringWidgetsHandle>(null);

  //componentDidMount equivalent
  useEffect(() => {
    appInsights.trackPageView({ name: 'Score' });
  }, []);

  useEffect(() => {
    const stepNamesFromPipeline: string[] | null = window.STEP_NAMES
      ? window.STEP_NAMES.split(',')
      : null;

    if (stepNamesFromPipeline && stepNamesFromPipeline.length && state.selectedRun?.stepName) {
      const foundStepName = stepNamesFromPipeline.find(
        (stepName) => stepName.toLowerCase() === state.selectedRun?.stepName.toLowerCase(),
      );
      setDisableNextPrev(!!foundStepName);
    }
  }, [state.selectedRun]);

  useEffect(() => {
    if (blinker) {
      setTimeout(() => {
        setBlinker(false);
        setIsNext(false);
      }, 1100);
    }
  }, [blinker]);

  const onScoreSubmit = async (submittedScore: StringMap) => {
    await form.validateFields();
    const validationErrors = Object.values(form.getFieldsError());
    const formIsValid = !validationErrors.find((validationError) => validationError.errors.length);
    if (!formIsValid) {
      return;
    }
    const currentSelectedIndex = getCurrentSelectedInventoryIndex();
    const scoreModels: ScoreModel[] = Object.keys(submittedScore).map((score) => {
      inventoryLines[currentSelectedIndex].dynamicColumns[score] = submittedScore[score] || '';
      return {
        columnName: score,
        val: submittedScore[score] || '',
      };
    });
    await runsService.saveScore({
      runId: selectedInventoryLine.inventoryDetails.runId,
      plateId: selectedInventoryLine.inventoryDetails.plateId,
      stepCode: selectedInventoryLine.inventoryDetails.stepCode,
      inventoryId: selectedInventoryLine.inventoryDetails.id,
      score: scoreModels,
      replicateId: parseInt(selectedInventoryLine.inventoryDetails.replicateId),
      plateRowCol: selectedInventoryLine.inventoryDetails.plateRowCol,
    });
    dispatch({ runs: runsService.getRunsLocalStore(), selectedRun: runsService.getSelectedRun() });

    const shouldGoToNextRecord =
      currentSelectedIndex >= 0 &&
      currentSelectedIndex < inventoryLines.length - 1 &&
      !disableNextPrev;

    if (shouldGoToNextRecord) {
      setIsNext(true);
      // This time out is for the delay requested by Esther
      setTimeout(() => {
        setSelectedInventoryLine(inventoryLines[currentSelectedIndex + 1]);
        form.setFieldsValue(inventoryLines[currentSelectedIndex + 1].dynamicColumns);
        setBlinker(true);
        scoringWidgetsRef.current?.selectFirstWidget();
      }, 1000);
      return;
    }
    history.goBack();
  };

  const previousInventory = () => {
    const currentSelectedIndex = getCurrentSelectedInventoryIndex();
    if (currentSelectedIndex > 0) {
      // This time out is for the delay requested by Esther
      setTimeout(() => {
        setSelectedInventoryLine(inventoryLines[currentSelectedIndex - 1]);
        form.setFieldsValue(inventoryLines[currentSelectedIndex - 1].dynamicColumns);
        setBlinker(true);
        scoringWidgetsRef.current?.selectFirstWidget();
      }, 1000);
      return;
    }
    history.goBack();
  };

  const getCurrentSelectedInventoryIndex = (): number => {
    return inventoryLines.findIndex(
      (inv) =>
        selectedInventoryLine.inventoryDetails.id === inv.inventoryDetails.id &&
        selectedInventoryLine.inventoryDetails.replicateId == inv.inventoryDetails.replicateId &&
        selectedInventoryLine.inventoryDetails.plateRowCol == inv.inventoryDetails.plateRowCol,
    );
  };

  const onScoreSelectionChange = async (index: number): Promise<void> => {
    const currentScoreValues = form.getFieldsValue();
    if (index === Object.values(currentScoreValues).length - 1) {
      onScoreSubmit(currentScoreValues);
    }
  };

  return (
    <div>
      <Form form={form} onFinish={onScoreSubmit}>
        <div className={`${style.scoreFormHeaderWrapper} ${blinker ? 'blinker' : 'noblinker'}`}>
          <h2 className={style.plateName + ' path'}>
            Inventory-RepID:{' '}
            <strong>{`${selectedInventoryLine.inventoryDetails.id}-${selectedInventoryLine.inventoryDetails.replicateId}`}</strong>
          </h2>
          <button onClick={history.goBack} className={style.closeButton} type='button'>
            <img src={closeButtonUrl} />
          </button>
        </div>
        <div className={style.scoreWidgetsWrapper}>
          <span className={style.header}>Scoring</span>
          {runClass === '1' ? (
            <h4 className={style.plateRowCol}>
              Position: <strong>{selectedInventoryLine.inventoryDetails.plateRowCol}</strong>
            </h4>
          ) : null}
          <Row gutter={24}>
            <ScoringWidgets
              columns={columns}
              selectedLine={selectedInventoryLine.dynamicColumns}
              onSelectionChange={onScoreSelectionChange}
              ref={scoringWidgetsRef}
            ></ScoringWidgets>
          </Row>
        </div>
        <Row>
          <Col span={24}>
            <div
              className={
                disableNextPrev ? style.scoreActionWrapperSubmitable : style.scoreActionWrapper
              }
            >
              {!disableNextPrev ? (
                <Button
                  onClick={previousInventory}
                  type='primary'
                  htmlType='button'
                  className={style.scoreAction}
                >
                  Previous
                </Button>
              ) : null}
              <Button
                type='primary'
                htmlType='submit'
                className={style.scoreAction}
                loading={isNext}
              >
                {disableNextPrev ? 'Submit' : 'Next'}
              </Button>
            </div>
          </Col>
        </Row>
      </Form>
    </div>
  );
};

export default withAITracking(reactPlugin, Score);
