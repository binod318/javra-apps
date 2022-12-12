import { Select } from 'antd';
import { forwardRef, Ref, useImperativeHandle, useState } from 'react';
import { Inventory } from '../../models';
export interface InventorySelectProps {
  inventories: Inventory[];
  onSelectionChange: (selectedInventory: string) => void;
}

type InventorySelectHandle = {
  clear: () => void;
};

const InventorySelectBox: React.ForwardRefRenderFunction<
  InventorySelectHandle,
  InventorySelectProps
> = (
  { inventories, onSelectionChange }: React.PropsWithChildren<InventorySelectProps>,
  ref: Ref<InventorySelectHandle>,
) => {
  const [selected, setSelected] = useState<string>();
  useImperativeHandle(ref, () => ({
    clear(): void {
      setSelected('');
    },
  }));
  return (
    <Select
      showSearch
      placeholder='Select an Inventory'
      optionFilterProp='children'
      value={selected}
      onChange={(value: string) => {
        setSelected(value);
        onSelectionChange(value);
      }}
      className='selectDropdown'
    >
      {inventories.map((inventory, index) => (
        <Select.Option
          key={index}
          value={`${inventory.id}__${inventory.replicateID}__${inventory.plateRowCol}`}
        >
          {`${inventory.id}-${inventory.replicateID}`}
        </Select.Option>
      ))}
    </Select>
  );
};

export const InventorySelect = forwardRef(InventorySelectBox);
