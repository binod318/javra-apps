import { ColumnsType } from 'antd/lib/table';
import downloadButtonUrl from '../../images/download.svg';
import syncButtonUrl from '../../images/sync.svg';
import syncErrorButtonUrl from '../../images/sync-error.svg';
import unSyncedButtonUrl from '../../images/not-synced.svg';
import { LocalRunModel } from '../../models';
import style from '../../styles/Button.module.less';
import runStyle from './Runs.module.less';
import { useGlobalState } from '../../contexts';
import { LoadingOutlined } from '@ant-design/icons';

function actionColumn(
  row: LocalRunModel,
  onDownloadButtonClick: (run: LocalRunModel) => Promise<void>,
  onResyncButtonClick: (runId: LocalRunModel) => Promise<void>,
): JSX.Element {
  const { state } = useGlobalState();
  if (!row.details) {
    return (
      <div className={style.actionColumn}>
        {row.downloading ? (
          <LoadingOutlined style={{ fontSize: 24 }} spin />
        ) : (
          <button
            className={style.download}
            disabled={!state.isOnline}
            onClick={() => onDownloadButtonClick(row)}
          >
            <img src={downloadButtonUrl} width='18' alt='Download Run' />
          </button>
        )}
      </div>
    );
  }
  const progress = row.details && row.details.progress;

  return (
    <div className={style.actionColumn}>
      <span className={runStyle.scoreProgress}>{`${progress?.scored}/${progress?.total}`}</span>
      <button
        className={style.sync}
        onClick={(event) => {
          if (row.error) {
            event.stopPropagation();
            onResyncButtonClick(row);
            return;
          }
        }}
      >
        <img
          src={row.error ? syncErrorButtonUrl : row.isSynced ? syncButtonUrl : unSyncedButtonUrl}
          width='18'
          alt='Sync status'
        />
      </button>
    </div>
  );
}

function scoreDate(scoreDate: string): string {
  const date = new Date(scoreDate);
  const month = (date.getMonth() + 1).toString();
  const day = date.getDate().toString();
  return day.padStart(2, '0') + '-' + month.padStart(2, '0');
}

function runColumn(id: string, row: LocalRunModel): JSX.Element {
  return (
    <span className={runStyle.runFolder}>
      <span>{id} </span>
      {`${row.workflowName} ${row.stepName.substring(0, 4)}`}
    </span>
  );
}

export function getRunColumnConfig(
  onDownloadButtonClick: (run: LocalRunModel) => Promise<void>,
  onResyncButtonClick: (runId: LocalRunModel) => Promise<void>,
): ColumnsType<LocalRunModel> {
  return [
    {
      title: 'Run Folder',
      dataIndex: 'id',
      key: 'id',
      fixed: 'left',
      render: runColumn,
    },
    {
      title: 'Date',
      dataIndex: 'scoreDate',
      key: 'scoreDate',
      width: 75,
      render: scoreDate,
    },
    {
      title: '',
      key: 'action',
      dataIndex: 'action',
      render: function ActionColumn(_: string, row: LocalRunModel): JSX.Element {
        return actionColumn(row, onDownloadButtonClick, onResyncButtonClick);
      },
    },
  ];
}
