import React from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";

const LabelCell = ({ data, rowIndex, arrayKey }) => {
  if (arrayKey === "PlateNames") {
  }
  return (
    <Cell title={data[rowIndex][arrayKey]}>
      <div>{data[rowIndex][arrayKey]}</div>
    </Cell>
  );
};
LabelCell.defaultProps = {
  data: [],
  arrayKey: "",
  rowIndex: 0,
};
LabelCell.propTypes = {
  rowIndex: PropTypes.number,
  data: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  arrayKey: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};
export default LabelCell;
