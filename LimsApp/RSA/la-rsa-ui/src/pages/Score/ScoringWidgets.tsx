import { Form, Col, Select, Input } from 'antd';
import { useEffect, useImperativeHandle, useRef, Ref, forwardRef } from 'react';
import { useGlobalState } from '../../contexts';
import { RunColumn, RunColumnDataTypes, StringMap } from '../../models';

const REQUIRED_MESSAGE = 'This field is required';

interface ScoringWidgetsProps {
  columns: RunColumn[];
  selectedLine: StringMap;
  onSelectionChange: (index: number) => Promise<void>;
}

type SocringWidgetHandle = {
  selectFirstWidget: () => void;
};

export const drawScoringWidget = (
  column: RunColumn,
  firstField: React.RefObject<Input> | null,
  onSelectionChange: (index: number) => Promise<void>,
  scoreIndex: number,
  lovTypable: boolean | undefined,
): JSX.Element => {
  if (column.dataType.toLowerCase() === RunColumnDataTypes.LOV) {
    const LOVS = column.LOVs ? column.LOVs : [];
    return (
      <Select
        showSearch={lovTypable}
        optionFilterProp='children'
        className='selectDropdown'
        placeholder='Select a Score'
        ref={firstField || null}
        onChange={() => onSelectionChange(scoreIndex)}
      >
        {LOVS.map((lov: string, index: number) => (
          <Select.Option key={index} value={lov}>
            {lov}
          </Select.Option>
        ))}
      </Select>
    );
  }
  if (
    column.dataType.toLowerCase() === RunColumnDataTypes.INTEGER ||
    column.dataType.toLowerCase() === RunColumnDataTypes.DECIMAL
  ) {
    return <Input type='number' ref={firstField ? firstField : null} />;
  }
  return <Input ref={firstField ? firstField : null} />;
};

export const Widgets: React.ForwardRefRenderFunction<SocringWidgetHandle, ScoringWidgetsProps> = (
  { columns, selectedLine, onSelectionChange }: ScoringWidgetsProps,
  ref: Ref<SocringWidgetHandle>,
) => {
  const firstfield = useRef<Input>(null);
  const { state } = useGlobalState();
  useImperativeHandle(ref, () => ({
    selectFirstWidget(): void {
      focusAndSelectFirstField();
    },
  }));

  useEffect(() => {
    focusAndSelectFirstField();
  }, []);

  const focusAndSelectFirstField = (): void => {
    if (firstfield.current) {
      firstfield.current.focus();
      if (firstfield.current instanceof Input) {
        firstfield.current.select();
      }
    }
  };

  const lovTypable = state?.selectedRun?.lovTypable;
  const runClass = state?.selectedRun?.details?.class;

  const widgets = columns.map((col, index) => {
    return (
      <Col key={col.columnName} span={24}>
        <Form.Item
          label={col.caption ? col.caption.replace(/\\n/g, '\n') : col.caption}
          name={col.columnName}
          rules={[{ required: runClass !== '3a', message: REQUIRED_MESSAGE }]}
          initialValue={selectedLine[col.columnName] || undefined}
          labelCol={{ span: 8 }}
          wrapperCol={{ span: 16 }}
        >
          {drawScoringWidget(
            col,
            index === 0 ? firstfield : null,
            onSelectionChange,
            index,
            lovTypable,
          )}
        </Form.Item>
      </Col>
    );
  });
  return <>{widgets}</>;
};

export const ScoringWidgets = forwardRef(Widgets);
