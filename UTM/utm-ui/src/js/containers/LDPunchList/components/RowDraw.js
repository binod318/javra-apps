import React from "react";
import PropTypes from "prop-types";

const RowDraw = ({ row, cellsPerRow }) => {
  const style = {
    position: "relative"
  };
  const chunckedCellsTemplate = [];
  for (let i = 0, j = row.cells.length; i < j; i += cellsPerRow) {
    const partialCells = row.cells.slice(i, i + cellsPerRow);
    const chunckedTemplates = partialCells.map((cell, partialCellIndex) => (
      <div style={style} index={partialCellIndex}>
        <div className="plant-name font9px">{cell.value}</div>
      </div>
    ));
    chunckedCellsTemplate.push(chunckedTemplates);
  }
  return chunckedCellsTemplate.map((template, chunckCellIndex) => (
  <div className="plateRowLD" key={chunckCellIndex}> {/*eslint-disable-line*/}{template}</div>
  ));
};

RowDraw.propTypes = {
  row: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  cellsPerRow: PropTypes.number.isRequired
};

export default RowDraw;
