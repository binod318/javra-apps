import { Inventory, RunColumn } from '../../models';
import { Table } from '../../components/Table';
import {
  InventoryRow,
  prepareRunDetailsListColumns,
  prepareRunDetailsListData,
} from './run-details-columns-config';
import { useHistory } from 'react-router-dom';
import { useGlobalState } from '../../contexts';

// FIXME refactor this props its growing which doesnot seems good\
// FIXME We now have selected run in global so grab all run details
// FIXME form there and make the props lean !!
export interface RunDetailsListProps {
  inventories: Inventory[];
  columns: RunColumn[];
  runId: string;
  plateId: string;
  platesLength: number;
  stepCode: string;
  runClass: string;
}

export const RunDetailsList: React.FC<RunDetailsListProps> = ({
  inventories,
  columns,
  runId,
  plateId,
  platesLength,
  stepCode,
  runClass,
}: React.PropsWithChildren<RunDetailsListProps>) => {
  const history = useHistory();
  const { state } = useGlobalState();

  const inventoryLines = prepareRunDetailsListData(inventories, plateId, runId, stepCode);
  // based on layout design the offset is substracted for finding table height.
  const tableOffset = platesLength === 1 ? 306 : 348;
  const tableHeight = state.viewport ? state.viewport.height - tableOffset : 200;

  return (
    <div>
      <Table
        columns={prepareRunDetailsListColumns(columns, runClass)}
        dataSource={inventoryLines}
        rowKey={(row: InventoryRow) =>
          `${row.inventoryDetails.id}-${row.inventoryDetails.replicateId}-${row.inventoryDetails.plateRowCol}`
        }
        size='small'
        pagination={false}
        scroll={{ x: 'max-content', y: Math.max(tableHeight, 200) }}
        rowClassName={(record) => (record.error ? 'hasError' : '')}
        onRow={(selectedInventory: InventoryRow) => {
          return {
            onClick: () => {
              history.push({
                pathname: `/${selectedInventory.inventoryDetails.id}/score`,
                state: { columns, selectedInventory, inventoryLines, runClass },
              });
            },
          };
        }}
      ></Table>
    </div>
  );
};
