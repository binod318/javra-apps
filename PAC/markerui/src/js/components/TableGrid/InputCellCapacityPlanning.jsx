import React from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";
import { v4 as uuidv4 } from "uuid";
import { connect } from "react-redux";

const errorStyle = {
  borderColor: "red",
};
const changeStyle = {
  borderColor: "#03a9f4",
};

class InputCellCapacityPlanning extends React.Component {
  constructor(props) {
    super(props);
    const val =
      props.data[props.rowIndex][props.arrayKey] !== null
        ? props.data[props.rowIndex][props.arrayKey]
        : "";
    this.state = {
      data: props.data,
      rowIndex: props.rowIndex,
      arrayKey: props.arrayKey,
      value: val,
      oldValue: val,
    };
  }
  render() {
    const { data, rowIndex, arrayKey, value } = this.state;
    const namename = `nm-${rowIndex}-${arrayKey}-${data[rowIndex].id}`;

    return (
      <Cell className='tableInputSampleNr' key={namename}>
        <div style={{ display: "flex" }}>
          <input
            type='number'
            tabIndex={rowIndex}
            key={namename}
            name={namename}
            value={value}
            onChange={(e) => {}}
            onWheel={(e) => {
              e.preventDefault();
              e.currentTarget.blur();
            }}
          />
          <span>{value}</span>
        </div>
      </Cell>
    );
  }
}
export default InputCellCapacityPlanning;
