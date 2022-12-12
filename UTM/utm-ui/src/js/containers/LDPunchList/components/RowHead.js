import React from "react";
import PropTypes from "prop-types";

const RowHead = ({ cols, cellsPerRow }) => {
  const chuncked = [];
  for (let i = 0, j = cols.length; i < j; i += cellsPerRow) {
    const partialCols = cols.slice(i, i + cellsPerRow);
    const rowTemplate = partialCols.map((col, partialColsIndex) => (
      <div className="indent" key={partialColsIndex}> {/*eslint-disable-line*/}
        <div>{col.columnHeader || ""}</div>
      </div>
    ));
    chuncked.push(<div className="plateRowLD">{rowTemplate}</div>);
  }
  return (
    <div className="rowWrapper">
      <div />
      <div>{chuncked}</div>
    </div>
  );
};

RowHead.propTypes = {
  cols: PropTypes.array.isRequired,  // eslint-disable-line
  cellsPerRow: PropTypes.number.isRequired
};
export default RowHead;
