import React, { Component } from "react";
import autoBind from "auto-bind";
import { Cell } from "fixed-data-table-2";
import PropTypes from "prop-types";
import { connect } from "react-redux";

class RDTDateCell extends Component {
  constructor(props) {
    super(props);
    this.state = { name: "", value: "", focus: false }; // startDate: null
    autoBind(this);
  }

  getValue = () => {
    const { rowIndex, data, donerMaps, columnKey } = this.props;
    const { materialID } = data[rowIndex];
    const lowKey = columnKey.toLowerCase() || "";
    if (donerMaps[`${materialID}-${lowKey}`] === undefined) return "";

    return donerMaps[`${materialID}-${lowKey}`].newState || "";
  };
  handleChange(e) {
    const { rowIndex, data } = this.props;
    const { materialID } = data[rowIndex];

    const {
      target: { name, value }
    } = e;

    this.props.RDTDateChange(materialID, name, value);
    return null;
  }

  blur = () => {
    setTimeout(() => {
      this.setState({ focus: false });
    }, 500);
  };
  focus = e => {
    const { target } = e;
    const { name } = target;
    if (name === "remarks") return null;

    this.setState({
      name,
      focus: true,
      value: this.getValue()
    });
    return null;
  };

  applyToAll = () => {
    const { columnKey, selectedArray, rowIndex } = this.props;
    const { name, value } = this.state;
    this.props.RDTDateApplyAll(name, value, columnKey, selectedArray, rowIndex);
    return null;
  };

  render() {
    const { rowIndex, data, columnKey } = this.props;
    const { materialID } = data[rowIndex];
    const lowKey = columnKey.toLowerCase() || "";

    const { focus } = this.state;
    const value = this.getValue();

    const disabledStatus = this.props.statusCode !== 100;

    return (
      <Cell className="tableInputSampleNr" onBlur={this.blur}>
        <div style={{ display: "flex" }}>
          <input
            tabIndex={rowIndex + 1}
            name={`${materialID}-${lowKey}`}
            key={`${rowIndex}${columnKey}`}
            type="text"
            value={value}
            onChange={this.handleChange}
            onFocus={this.focus}
            placeholder="dd/mm/yyyy"
            disabled={disabledStatus}
          />
          {!disabledStatus && focus && (
            <button tabIndex={-1} onClick={this.applyToAll} title="Apply below">
              To sel/below
            </button>
          )}
        </div>
      </Cell>
    );
  }
}

const mapState = state => ({
  statusCode: state.rootTestID.statusCode
});

const mapDipatch = dispatch => ({
  RDTDateChange: (materialID, name, value) =>
    dispatch({ type: "RDT_DATE_CHANGE", materialID, name, value }),
  RDTDateApplyAll: (name, value, colkey, selectedArray, rowIndex) => {
    dispatch({
      type: "UPDATE_RDTDATE_ALL",
      name,
      value,
      colkey,
      selectedArray,
      rowIndex
    });
  }
});

RDTDateCell.defaultProps = {
  selectedArray: [],
  donerMaps: {},
  data: [],
  columnKey: ""
};
RDTDateCell.propTypes = {
  selectedArray: PropTypes.array, // eslint-disable-line
  donerMaps: PropTypes.object, // eslint-disable-line
  RDTDateChange: PropTypes.func.isRequired,
  RDTDateApplyAll: PropTypes.func.isRequired,
  rowIndex: PropTypes.number, // eslint-disable-line
  data: PropTypes.array, // eslint-disable-line
  columnKey: PropTypes.string,
  statusCode: PropTypes.number.isRequired
};
export default connect(
  mapState,
  mapDipatch
)(RDTDateCell);
