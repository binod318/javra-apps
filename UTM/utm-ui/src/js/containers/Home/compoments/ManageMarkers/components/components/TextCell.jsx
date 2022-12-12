import React, { Component } from "react";
import autoBind from "auto-bind";
import { Cell } from "fixed-data-table-2";
import PropTypes from "prop-types";
import { connect } from "react-redux";

class TextComponent extends Component {
  constructor(props) {
    super(props);
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
    const key = `${data[rowIndex].materialID}-d_selected`;
    // const key = `${data[rowIndex].materialKey}-d_Selected`;
    // const key = `${data[rowIndex].materialKey}-d_To3GB`;
    const value = e.target.checked ? 1 : 0;
    this.props.toggleMaterialMarker([{ key, value }]);
  }

  localRdtPrint = () => {
    const { rowIndex, data } = this.props;
    const row = data[rowIndex] || {};
    this.props.setRdtPrintData(row);
    // this.props.rdtPrint(row);
  };

  render() {
    const {
      traitID,
      rowIndex,
      data,
      columnKey,
      markerMaterialMap
    } = this.props;
    let cellData = "";
    const statusDisabled = this.props.statusCode >= 400;
    const printDisable = this.props.statusCode >= 500;

    // Issue occured because of same traid value
    const cc = columnKey ? columnKey.split("_")[0] : null;

    if (columnKey) {
      if (columnKey.toLocaleLowerCase() === "d_selected") {
        // if (columnKey.toLocaleLowerCase() === 'to3gb') {

        // //////////////////////////
        // ## HOT 3GB CHANGE
        // ///////////////////////////
        // const check3gb = `${data[rowIndex].materialKey}-d_To3GB`;
        // const check3gb = `${data[rowIndex].materialKey}-d_Selected`;
        // const cs = markerMaterialMap[check3gb].newState;
        const check3gb = `${data[rowIndex].materialID}-d_selected`;

        const checkedStatus = markerMaterialMap[check3gb].newState || 0;
        return (
          <div className="tableCheck">
            <input
              id={`${check3gb}`}
              type="checkbox"
              disabled={statusDisabled}
              checked={checkedStatus}
              onChange={this.toggleMaterialMarker3GB}
            />
            <label htmlFor={`${check3gb}`} /> {/* eslint-disable-line  */}
          </div>
        );
      }

      if (columnKey === "Print") {
        return (
          <Cell align="center">
            <button
              className="tblPrintBtn"
              disabled={!printDisable}
              onClick={this.localRdtPrint}
            >
              Print
            </button>
          </Cell>
        );
      }
    }
    // SAMPLE NUMBER SECTION
    if (traitID) {
      // check if determination trait
      // if true paint checkbox
      const { materialID } = data[rowIndex];
      if (traitID.toString().substring(0, 2) === "D_") {
        // TODO
        // need to fixe form S2S and other Manage section is different
        // test value code
        // const checkedStatus = markerMaterialMap[`${materialKey}-d_Selected`].newState || 0;
        const checkedStatus =
          markerMaterialMap[`${materialID}-${traitID.toLowerCase()}`]
            .newState || 0;

        cellData = (
          <div className="tableCheck">
            <input
              id={`${materialID}-${traitID.toLowerCase()}`}
              type="checkbox"
              disabled={statusDisabled}
              checked={checkedStatus}
              onChange={this.toggleMaterialMarker}
            />
            <label htmlFor={`${materialID}-${traitID.toLowerCase()}`} />{" "}
            {/* eslint-disable-line */}
          </div>
        );
      } else cellData = data[rowIndex][traitID];
    } else {
      const row = data[rowIndex];
      const key =
        !!cc &&
        Object.keys(row).find(
          column => column.toLowerCase() === cc.toLowerCase()
        );
      if (key) {
        cellData = row[key];
      }
    }
    return <Cell>{cellData}</Cell>;
  }
}

TextComponent.defaultProps = {
  traitID: null,
  columnKey: null
};

TextComponent.propTypes = {
  // rdtPrint: PropTypes.func.isRequired,
  setRdtPrintData: PropTypes.func.isRequired,
  statusCode: PropTypes.number.isRequired,
  rowIndex: PropTypes.number.isRequired,
  columnKey: PropTypes.string,
  traitID: PropTypes.string,
  toggleMaterialMarker: PropTypes.func.isRequired,
  data: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  markerMaterialMap: PropTypes.object.isRequired // eslint-disable-line react/forbid-prop-types
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
  }
});

const MaterialCell = connect(
  mapStateToProps,
  mapDispatchProps
)(TextComponent);
export default MaterialCell;
