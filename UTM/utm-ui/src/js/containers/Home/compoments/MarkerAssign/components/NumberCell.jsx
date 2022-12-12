import React from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";
import autoBind from "auto-bind";
import { connect } from "react-redux";

class NumberComponent extends React.Component {
  constructor(props) {
    super(props);

    this.state = { name: "", value: "", focus: false }; // startDate: null
    autoBind(this);
  }

  getValue = () => {
    const { rowIndex, data, leafDiskMaterialMap, columnKey } = this.props;
    const { materialID } = data[rowIndex];

    if (leafDiskMaterialMap[`${materialID}-#plants`] === undefined) return "";
    return leafDiskMaterialMap[`${materialID}-#plants`].newState || "";

  };

  change = e => {
    const { rowIndex, data } = this.props;
    const { materialID } = data[rowIndex];
    const {
      target: { name, value }
    } = e;

    this.props.change(materialID, name, value);
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
    const { columnKey, selectedArray, rowIndex } = this.props;
    const { name, value } = this.state;
    this.props.applyToAll(name, value, columnKey, selectedArray, rowIndex);
    return null;
  };

  render() {
    const { rowIndex, data, columnKey, disabled } = this.props;
    const { materialID } = data[rowIndex];
    const { focus } = this.state;
    const value = this.getValue();
    return (
      <Cell className="tableInputSampleNr" onBlur={this.blur}>
        <div style={{ display: "flex" }}>
          <input
            tabIndex={rowIndex + 1}
            name={`${materialID}-${columnKey}`}
            key={`${rowIndex}${columnKey}`}
            type="number"
            value={value}
            onChange={this.change}
            onFocus={this.focus}
            disabled={disabled}
          />
          {focus && (
            <button tabIndex={-1} onClick={this.applyToAll} title="Apply below">
              To All
            </button>
          )}
        </div>
      </Cell>
    );
  }
}

const mapDipatch = dispatch => ({
  change: (materialID, name, value) =>
    dispatch({ type: "LEAF_DISK_NROFPLANT_CHANGE", materialID, name, value }),
  applyToAll: (name, value, colkey, selectedArray, rowIndex) => {
    dispatch({
      type: "UPDATE_NROFPLANT_ALL",
      name,
      value,
      colkey,
      selectedArray,
      rowIndex
    });
  }
});

NumberComponent.defaultProps = {
  selectedArray: [],
  leafDiskMaterialMap: {},
  data: [],
  columnKey: ""
};
NumberComponent.propTypes = {
  selectedArray: PropTypes.array, // eslint-disable-line
  leafDiskMaterialMap: PropTypes.object, // eslint-disable-line
  change: PropTypes.func.isRequired,
  applyToAll: PropTypes.func.isRequired,
  rowIndex: PropTypes.number, // eslint-disable-line
  data: PropTypes.array, // eslint-disable-line
  columnKey: PropTypes.string,
  disabled: PropTypes.bool.isRequired
};

export default connect(
  null,
  mapDipatch
)(NumberComponent);
