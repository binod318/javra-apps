import React from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";

function HeaderCell(props) {
  const { keyValue } = props;
  if (keyValue === "Remarks" || keyValue === "PeriodName") {
    return <Cell className="headerCell">{props.view}</Cell>;
  }

  return (
    <Cell>
      <div className="headerCell">
        <span>{props.view}</span>
      </div>
    </Cell>
  );
}

HeaderCell.defaultProps = {
  view: "",
  keyValue: ""
};
HeaderCell.propTypes = {
  view: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  keyValue: PropTypes.oneOfType([PropTypes.string, PropTypes.number])
};
export default HeaderCell;
