import React, { Component } from "react";
import autoBind from "auto-bind";
import { Cell } from "fixed-data-table-2";
import PropTypes from "prop-types";
import { connect } from "react-redux";

class SHTextCellComponent extends Component {
  constructor(props) {
    super(props);
    this.state = { name: "", value: "", focus: false }; // startDate: null
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

  getValue = () => {
    const { rowIndex, data, columnKey } = this.props;
    if (data[rowIndex][columnKey] === undefined) return "";

    return data[rowIndex][columnKey] || "";
  };

  blur = () => {
    setTimeout(() => {
      this.setState({ focus: false });
    }, 500);
  };

  focus = e => {
    const { target } = e;
    const { name } = target;
    this.setState({
      name,
      focus: true,
      value: this.getValue()
    });
  };

  applyToAll = () => {
    const { rowIndex, columnKey } = this.props;
    var value = parseInt(this.getValue(), 10);
    this.props.applyToAll(name, value, columnKey, rowIndex);
    return null;
  };

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
                disabled={statusDisabled}
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
        case "integer": {
          const value = data[rowIndex][columnKey] || "";
          return (
            <div className="dynamic-input">
              <input
                type="number"
                value={value}
                disabled={statusDisabled}
                onChange={this.handleDynamicInputChange}
                onKeyPress={this.handleDynamicInputKeyPress}
                onFocus={this.focus}
              />
              {focus && (
                <button tabIndex={-1} onClick={this.applyToAll} title="Apply below">
                  To all/below
                </button>
              )}
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

SHTextCellComponent.defaultProps = {
  columnKey: null,
  onRowCellClick: () => {},
  handleDynamicInputChange: () => {},
  onEnter: () => {},
  refs: []
};

SHTextCellComponent.propTypes = {
  statusCode: PropTypes.number.isRequired,
  rowIndex: PropTypes.number.isRequired,
  columnKey: PropTypes.string,
  data: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  column: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  toggleDeterminationOfSample: PropTypes.func.isRequired,
  onRowCellClick: PropTypes.func,
  handleDynamicInputChange: PropTypes.func,
  onEnter: PropTypes.func,
  refs: PropTypes.array //arrayOf(PropTypes.refs)
};

const mapStateToProps = state => ({
  statusCode: state.rootTestID.statusCode
});
const mapDispatchProps = dispatch => ({
  // scoreChange: (name, value) => {
  //   dispatch({
  //     type: "UPDATE_SOCREMAP",
  //     name,
  //     value
  //   });
  // },
  // setRdtPrintData: obj => {
  //   dispatch({ type: "RDT_PRINT_DATA", data: obj });
  // },
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
    }),
  applyToAll: (name, value, columnKey, rowIndex) =>
    dispatch({
      type: "APPLY_TO_ALL_BELOW",
      name,
      value,
      columnKey,
      rowIndex
    })
});

const SHTextCell = connect(
  mapStateToProps,
  mapDispatchProps
)(SHTextCellComponent);
export default SHTextCell;
