import React from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";
import { Tooltip } from "react-tippy";
import "react-tippy/dist/tippy.css";

const Datacell = props => {
  const { value, rowIndex, selectArray, columnKey } = props;
  const newStyle = {};
  const isCellHighlighted = true;
  if (selectArray) {
    if (selectArray.includes(rowIndex)) {
      newStyle.background = isCellHighlighted ? "#8bce3f" : "";
      newStyle.color = isCellHighlighted ? "#000" : "";
    }
  }

  return (
    <Cell
      title={columnKey !== "requestedMarkers" ? value : ""}
      style={newStyle}
    >
      {columnKey === "requestedMarkers" ? (
        <Tooltip
          position="top"
          className="requested-markers"
          interactive
          animation="fade"
          html={<div>{value}</div>}
          arrow
        >
          {value}
        </Tooltip>
      ) : (
        <span>{value}</span>
      )}
    </Cell>
  );
};
Datacell.defaultProps = {
  value: "",
  selectArray: []
};
Datacell.propTypes = {
  value: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  selectArray: PropTypes.array, // eslint-disable-line
  rowIndex: PropTypes.number.isRequired,
  columnKey: PropTypes.string.isRequired
};
export default Datacell;
