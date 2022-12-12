import { Select } from 'antd';
import { Plate } from '../../models';

export interface PlateSelectProps {
  plates: Plate[];
  selectedValue: Plate | undefined;
  onSelectionChange: (plateId: string) => void;
}

export const PlateSelect: React.FC<PlateSelectProps> = ({
  plates,
  selectedValue,
  onSelectionChange,
}: React.PropsWithChildren<PlateSelectProps>) => {
  return (
    <Select
      showSearch
      placeholder='Select a plate'
      optionFilterProp='children'
      value={selectedValue ? selectedValue.plateID : undefined}
      onChange={(value: string) => onSelectionChange(value)}
      className='selectDropdown'
    >
      {plates.map((plate, index) => (
        <Select.Option key={index} value={plate.plateID}>
          {plate.plateID}
        </Select.Option>
      ))}
    </Select>
  );
};
