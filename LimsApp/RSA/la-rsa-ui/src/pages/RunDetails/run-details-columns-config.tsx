import { ColumnsType } from 'antd/lib/table';
import { Inventory, RunColumn, Score, StringMap } from '../../models';

export interface InventoryRow {
  inventoryDetails: {
    plateId: string;
    runId: string;
    stepCode: string;
    id: string;
    replicateId: string;
    plateRowCol: string;
  };
  dynamicColumns: StringMap;
  error: boolean;
}

const RUNS_DEFAULT_DETAILS_COLUMNS = [
  {
    title: 'Inventory#-RepID',
    dataIndex: 'id',
    key: 'id',
    render: function InventoryColumn(_: string, row: InventoryRow) {
      return `${row.inventoryDetails.id}-${row.inventoryDetails.replicateId}`;
    },
    width: 140,
    fixed: 'left',
  },
  {
    title: 'Position',
    dataIndex: 'plateRowCol',
    key: 'plateRowCol',
    render: function InventoryColumn(_: string, row: InventoryRow) {
      return row.inventoryDetails.plateRowCol;
    },
    width: 115,
  },
];

export const prepareRunDetailsListColumns = (
  columns: RunColumn[],
  runClass: string,
): ColumnsType<InventoryRow> => {
  const preparedColumns = columns.map((col) => {
    return {
      title: `${col.caption ? col.caption.replace(/\\n/g, '\n') : col.caption}`,
      dataIndex: col.columnName,
      key: col.columnName,
      render: function dynanmicColumn(_: string, row: InventoryRow) {
        return row.dynamicColumns[col.columnName];
      },
      width: 90,
    };
  });

  return [
    ...(runClass !== '1'
      ? RUNS_DEFAULT_DETAILS_COLUMNS.filter((runCol) => runCol.key !== 'plateRowCol')
      : RUNS_DEFAULT_DETAILS_COLUMNS),
    ...preparedColumns,
  ];
};

export const prepareRunDetailsListData = (
  inventories: Inventory[],
  plateId: string,
  runId: string,
  stepCode: string,
): InventoryRow[] => {
  return inventories.map((inventory) => {
    const falttenedScoreData = flattenScoreData(inventory.score);
    return {
      inventoryDetails: {
        plateId,
        runId,
        stepCode,
        id: inventory.id,
        replicateId: inventory.replicateID.toString(),
        plateRowCol: inventory.plateRowCol as string,
      },
      dynamicColumns: {
        ...falttenedScoreData,
      },
      error: inventory.error as boolean,
    };
  });
};

export const getInventoryLine = (
  inventoryId: string,
  inventories: Inventory[],
  plateId: string,
  runId: string,
  stepCode: string,
  replicationId: number,
  plateRowCol: string,
): InventoryRow | undefined => {
  const foundInventory = inventories.find(
    (inventory) =>
      inventory.id === inventoryId &&
      inventory.replicateID == replicationId &&
      inventory.plateRowCol === plateRowCol,
  );
  if (!foundInventory) {
    return;
  }
  const flattendScoreData = flattenScoreData(foundInventory.score);
  return {
    inventoryDetails: {
      plateId,
      runId,
      stepCode,
      id: foundInventory.id,
      replicateId: foundInventory.replicateID.toString(),
      plateRowCol: foundInventory.plateRowCol as string,
    },
    dynamicColumns: {
      ...flattendScoreData,
    },
    error: foundInventory.error as boolean,
  };
};

const flattenScoreData = (scoreList: Score[]): StringMap => {
  const scoreMap: StringMap = {};
  scoreList.forEach((score) => {
    scoreMap[score.columnName] = score.val || '';
  });
  return scoreMap;
};
