import React, { Component } from "react";
import autoBind from "auto-bind";
import { Cell } from "fixed-data-table-2";
import PropTypes from "prop-types";
import { connect } from "react-redux";

class LDTextCellComponent extends Component {
  constructor(props) {
    super(props);
    autoBind(this);
  }

  onRowCellClick = rowIndex => e => {
    this.props.onRowCellClick(rowIndex, !!e.shiftKey, !!e.ctrlKey);
  };

  toggleDeterminationOfSample(e) {
    e.stopPropagation();
    const { rowIndex, columnKey } = this.props;
    this.props.toggleDeterminationOfSample(
      rowIndex,
      columnKey,
      e.target.checked
    );
  }

  handleDynamicInputChange(e) {
    const { rowIndex, columnKey } = this.props;
    this.props.handleDynamicInputChange(rowIndex, columnKey, e.target.value);
  }

  handleDynamicInputKeyPress(e) {
    if (e.key === "Enter") {
      const { columnKey } = this.props;
      if (columnKey === "referenceCode")
        this.props.onEnter(this.props.rowIndex);
      else this.props.onEnter();
    }
  }

  render() {
    const { rowIndex, data, columnKey, column } = this.props;
    let cellData = "";
    const statusDisabled = this.props.statusCode >= 400;

    // Issue occured because of same traid value
    if (column.editable) {
      switch (column.dataType) {
        case "boolean": {
          const cellIndex = `${rowIndex}-${columnKey}`;

          return (
            // eslint-disable-next-line jsx-a11y/no-static-element-interactions
            <div
              onClick={this.onRowCellClick(rowIndex)}
              onKeyPress={() => {}}
              className="tableCheck"
            >
              <input
                id={`${cellIndex}`}
                type="checkbox"
                disabled={statusDisabled}
                checked={!!data[rowIndex][columnKey]}
                onChange={this.toggleDeterminationOfSample}
              />
              <label htmlFor={`${cellIndex}`} />
            </div>
          );
        }
        case "string": {
          const value = data[rowIndex][columnKey] || "";
          return (
            <div className="dynamic-input">
              <input
                type="text"
                value={value}
                onChange={this.handleDynamicInputChange}
                onKeyPress={this.handleDynamicInputKeyPress}
                ref={
                  columnKey === "referenceCode"
                    ? this.props.refs[rowIndex]
                    : null
                }
              />
            </div>
          );
        }
        default: {
          break;
        }
      }
    }
    if (column.dataType === "boolean") {
      const cellIndex = `${rowIndex}-${columnKey}`;

      return (
        // eslint-disable-next-line jsx-a11y/no-static-element-interactions
        <div
          onClick={this.onRowCellClick(rowIndex)}
          onKeyPress={() => {}}
          className="tableCheck"
        >
          <input
            id={`${cellIndex}`}
            type="checkbox"
            disabled={statusDisabled}
            checked={!!data[rowIndex][columnKey]}
            onChange={this.toggleDeterminationOfSample}
          />
          <label htmlFor={`${cellIndex}`} />
        </div>
      );
    }

    const row = data[rowIndex];

    const key =
      !!columnKey &&
      Object.keys(row).find(
        col => col.toLowerCase() === columnKey.toLowerCase()
      );
    if (key) {
      cellData = row[key];
    }

    return <Cell onClick={this.onRowCellClick(rowIndex)}>{cellData}</Cell>;
  }
}

LDTextCellComponent.defaultProps = {
  columnKey: null,
  onRowCellClick: () => {},
  handleDynamicInputChange: () => {},
  onEnter: () => {},
  refs: []
};

LDTextCellComponent.propTypes = {
  statusCode: PropTypes.number.isRequired,
  rowIndex: PropTypes.number.isRequired,
  columnKey: PropTypes.string,
  data: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  column: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  toggleDeterminationOfSample: PropTypes.func.isRequired,
  onRowCellClick: PropTypes.func,
  handleDynamicInputChange: PropTypes.func,
  onEnter: PropTypes.func,
  refs: PropTypes.arrayOf(PropTypes.refs)
};

const mapStateToProps = state => ({
  statusCode: state.rootTestID.statusCode
});
const mapDispatchProps = dispatch => ({
  scoreChange: (name, value) => {
    dispatch({
      type: "UPDATE_SOCREMAP",
      name,
      value
    });
  },
  setRdtPrintData: obj => {
    dispatch({ type: "RDT_PRINT_DATA", data: obj });
  },
  toggleDeterminationOfSample: (rowIndex, columnKey, checkedStatus) =>
    dispatch({
      type: "TOGGLE_DETERMINATION_OF_SAMPLE",
      rowIndex,
      columnKey,
      checkedStatus
    }),
  handleDynamicInputChange: (rowIndex, columnKey, value) =>
    dispatch({
      type: "HANDLE_DYNAMIC_INPUT_CHANGE",
      rowIndex,
      columnKey,
      value
    })
});

const LDTextCell = connect(
  mapStateToProps,
  mapDispatchProps
)(LDTextCellComponent);
export default LDTextCell;
