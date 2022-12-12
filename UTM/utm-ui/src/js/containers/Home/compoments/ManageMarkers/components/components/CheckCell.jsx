import React, { Component } from "react";
import autoBind from "auto-bind";
// import { Cell } from 'fixed-data-table-2';
import PropTypes from "prop-types";
import { connect } from "react-redux";

class CheckComponent extends Component {
  constructor(props) {
    super(props);
    this.state = {
      // statusCode: props.statusCode,
      name: "",
      valueNumber: 0 // this.computevalue() // props.columnKey === 'NrOfSamples' ? 200 : 0
    };
    this.min = 0;
    this.max = 92 * 5;

    autoBind(this);
  }

  toggleMaterialMarker(e) {
    const { traitID, rowIndex, data } = this.props;
    const key = `${data[rowIndex].materialID}-${traitID.toLowerCase()}`;
    const value = e.target.checked ? 1 : 0;
    this.props.toggleMaterialMarker([{ key, value }]);
  }
  toggleMaterialMarker3GB(e) {
    const { rowIndex, data } = this.props;
    // //////////////////////////
    //  ## HOT 3GB CHANGE
    // ///////////////////////////
    const key = `${data[rowIndex].materialKey}-d_selected`;
    // const key = `${data[rowIndex].materialKey}-d_To3GB`;
    const value = e.target.checked ? 1 : 0;
    this.props.toggleMaterialMarker([{ key, value }]);
  }

  handleChange = e => {
    const { target } = e;
    const { name, value } = target;
    this.setState({ valueNumber: value });

    this.props.scoreChange(name, value);
  };

  applyToAll = () => {
    const { name, valueNumber } = this.state;
    alert(`${name} : ${valueNumber} - here`);
  };

  render() {
    const { traitID, rowIndex, data, markerMaterialMap } = this.props;

    const { materialID } = data[rowIndex];
    // TODO
    // const checkedStatus = markerMaterialMap[`${materialKey}-d_Selected`].newState || 0;
    const checkedStatus =
      markerMaterialMap[`${materialID}-${traitID.toLowerCase()}`].newState || 0;

    return (
      <div className="tableCheck">
        <input
          id={`${materialID}-${traitID.toLowerCase()}`}
          type="checkbox"
          checked={checkedStatus}
          onChange={this.toggleMaterialMarker}
        />
        <label htmlFor={`${materialID}-${traitID.toLowerCase()}`} />{" "}
        {/* eslint-disable-line */}
      </div>
    );
    // return null;
  }
}

CheckComponent.defaultProps = {
  traitID: null
  // columnKey: null
};

CheckComponent.propTypes = {
  statusCode: PropTypes.number.isRequired,
  rowIndex: PropTypes.number.isRequired,
  // columnKey: PropTypes.string,
  traitID: PropTypes.string,
  toggleMaterialMarker: PropTypes.func.isRequired,
  data: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  markerMaterialMap: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  scoreChange: PropTypes.func.isRequired
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
  }
});

const MaterialCell = connect(
  mapStateToProps,
  mapDispatchProps
)(CheckComponent);
export default MaterialCell;
