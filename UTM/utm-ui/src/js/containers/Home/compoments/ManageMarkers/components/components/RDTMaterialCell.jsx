import React, { Component } from "react";
import autoBind from "auto-bind";
import { Cell } from "fixed-data-table-2";
import PropTypes from "prop-types";
import { connect } from "react-redux";

class RDTMaterialCell extends Component {
  constructor(props) {
    super(props);
    this.state = {
      name: "",
      // value: this.getValue() || '',
      focus: false
    };
    autoBind(this);
  }

  getValue = () => {
    const { rowIndex, data, rdtMaterialMaps } = this.props;
    const { materialID } = data[rowIndex];

    if (rdtMaterialMaps && rdtMaterialMaps[`${materialID}-materialstatus`]) {
      return rdtMaterialMaps[`${materialID}-materialstatus`].newState;
    }
    return "";
  };

  handleChange(e) {
    const { rowIndex, data } = this.props;
    const { materialID } = data[rowIndex];
    const {
      target: { name, value }
    } = e;

    this.props.materialStatusChange(materialID, name, value);
    // this.setState({ value });
    return null;
  }
  handleDateChange = () => {};

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
      focus: true
      // value: this.getValue()
    });
    return null;
  };

  applyToAll = () => {
    const { rowIndex, data, selectedArray } = this.props;
    const { materialID } = data[rowIndex];
    const { name } = this.state;

    this.props.materialStatusAllChange(
      materialID,
      name,
      this.getValue(),
      selectedArray,
      rowIndex
    );

    return null;
  };

  render() {
    const { rowIndex, data, rdtMaterialMaps } = this.props;
    const { materialID } = data[rowIndex];
    const { focus } = this.state;

    const disabledStatus = this.props.statusCode !== 100;

    let value = "";
    if (rdtMaterialMaps && rdtMaterialMaps[`${materialID}-materialstatus`]) {
      value = rdtMaterialMaps[`${materialID}-materialstatus`].newState;
    } else {
      return null;
    }
    return (
      <Cell className="tableInputSampleNr" onBlur={this.blur}>
        <div style={{ display: "flex" }}>
          <select
            tabIndex={rowIndex + 1}
            name={`${materialID}-materialstatus`}
            value={value}
            onChange={this.handleChange}
            onFocus={this.focus}
            disabled={disabledStatus}
          >
            <option value="" />
            {this.props.msterialStateRDT.map(p => (
              <option key={p.code} value={p.name}>
                {p.name}
              </option>
            ))}
          </select>
          {!disabledStatus && focus && (
            <button tabIndex={-1} onClick={this.applyToAll}>
              To sel/below
            </button>
          )}
        </div>
      </Cell>
    );
  }
}

RDTMaterialCell.defaultProps = {
  selectedArray: [],
  msterialStateRDT: [],
  data: [],
  rdtMaterialMaps: [],
  columnKey: ""
};
RDTMaterialCell.propTypes = {
  selectedArray: PropTypes.array, // eslint-disable-line
  materialStatusAllChange: PropTypes.func.isRequired,
  materialStatusChange: PropTypes.func.isRequired,
  rowIndex: PropTypes.number.isRequired,
  msterialStateRDT: PropTypes.array, // eslint-disable-line
  data: PropTypes.array, // eslint-disable-line
  rdtMaterialMaps: PropTypes.oneOfType([PropTypes.object, PropTypes.array]), // eslint-disable-line
  columnKey: PropTypes.any, // eslint-disable-line,
  statusCode: PropTypes.number.isRequired
};

const mapState = state => ({
  refresh: state.assignMarker.materials.refresh,
  statusCode: state.rootTestID.statusCode
});
const mapDispatch = dispatch => ({
  materialStatusChange: (materialID, name, value) => {
    // materialStatusChange(materialID, name, value);
    dispatch({ type: "MATERIAL_CHANGE", materialID, name, value });
  },
  materialStatusAllChange: (materialID, name, value, selectedArray, rowIndex) =>
    dispatch({
      type: "MATERIAL_ALL_CHANGE",
      materialID,
      name,
      value,
      selectedArray,
      rowIndex
    })
});
export default connect(
  mapState,
  mapDispatch
)(RDTMaterialCell);
