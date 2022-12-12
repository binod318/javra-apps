import React, { Component } from "react";
import { connect } from "react-redux";
import { Table, Column } from "fixed-data-table-2";
import PropTypes from "prop-types";
import autoBind from "auto-bind";

import Page from "../../../../../components/Page/Page";
import MaterialHeaderCell from "./components/HeaderCell";
import MaterialCell from "./components/TextCell";
// import MaterialCellNoOfSample from './components/SampleNumberCell';
import SampleComponent from "./components/SampleCell";
import { toggleMaterialMarker, saveMarkerMaterial } from "./actions";
// component
class Manage2GB extends Component {
  constructor(props) {
    super(props);
    this.state = {
      currentIndex: 0,
      columnWidths: {},
      fixColumn: props.fixColumn || 1,
      headerHeight: 40,
      rowHeight: 36,
      pageNumber: props.pageNumber || 1,
      pageSize: props.pageSize || 150,
      tblCellWidth: props.tblCellWidth || 150,
      tblWidth: props.tblWidth || 1000,
      tblHeight: props.tblHeight || 300,
      sortedColumns: ["", "", ""], // THREE VALUES ARE RESERVED FOR THREE FIRST COLUMNS Crop, GID, Plantnr
      sample: props.sample,
      sampleNumber: props.sampleNumber,
      sampleRefresh: props.sampleRefresh
    };
    autoBind(this);
  }

  componentWillReceiveProps(nextProps) {
    if (
      nextProps.sampleRefresh !== this.props.sampleRefresh ||
      nextProps.sampleNumber.length !== this.props.sampleNumber.length
    ) {
      this.setState({ sampleNumber: nextProps.sampleNumber });
    }
    if (nextProps.materials.columns.length) {
      this.sortColumns(nextProps.materials.columns);
    }
    if (nextProps.sample !== this.props.sample) {
      this.setState({ sample: nextProps.sample });
    }
    if (nextProps.tblWidth !== this.props.tblWidth) {
      this.setState({ tblWidth: nextProps.tblWidth });
    }
    if (nextProps.tblHeight !== this.props.tblHeight) {
      this.setState({ tblHeight: nextProps.tblHeight });
    }
  }

  componentWillUnmount() {
    this.props.resetManageMarker();
  }

  onPageClick = pg => {
    this.setState({ pageNumber: pg });
  };

  saveMarkerMaterial() {
    const {
      materials: { markerMaterialMap },
      testTypeID,
      testID
    } = this.props;
    const { sample } = this.state;

    const materialWithMarker = [];
    Object.keys(markerMaterialMap).forEach(key => {
      if (markerMaterialMap[key].changed) {
        const map = key.split("-");
        materialWithMarker.push({
          materialID: map[0],
          determinationID: map[1].split("_")[1],
          selected: !!markerMaterialMap[key].newState
        });
      }
    });

    const materialsMarkers = {
      testTypeID,
      testID,
      materialWithMarker
    };
    this.props.saveMarkerMaterial(materialsMarkers);

    if (sample) {
      this.sampleChangeSave();
    }
  }

  toggleMaterialMarker(markerMaterialList) {
    this.props.toggleMaterialMarker(markerMaterialList);
  }

  _filter() {
    const hh = this.state.headerHeight;
    this.setState({
      headerHeight: hh === 40 ? 90 : 40
    });
  }

  // sould sort column in order of  Crop, GID, Platnr and rest of columns
  sortColumns(columns) {
    // 2017 Aug 01
    // TODO :: @krishna is providing fixed = 1
    // need to manage fix column from backedn
    // const sortedColumns = ['', '', ''];
    const sortedColumns = []; // THREE VALUES ARE RESERVED FOR THREE FIRST COLUMNS Crop, GID, Plantnr
    columns.forEach(col => {
      switch (col.columnLabel) {
        // case 'Crop': {
        //   sortedColumns[0] = col;
        //   break;
        // }
        // case 'GID': {
        // sortedColumns[0] = col;

        // break;
        // }
        // case 'Plantnr': {
        //   sortedColumns[2] = col;
        //
        //   break;
        // }
        default: {
          sortedColumns.push(col);
          break;
        }
      }
    });
    this.setState({ sortedColumns });
  }

  _onColumnResizeEndCallback = (newColumnWidth, columnKey) => {
    this.setState(({ columnWidths }) => ({
      columnWidths: {
        ...columnWidths,
        [columnKey]: newColumnWidth
      }
    }));
  };

  _fixColumn = () => {
    console.log("-fixCol");
  };

  clearFilter = () => {
    console.log("clearFilter");
  };

  sampleChangeSave = () => {
    this.props.postSampleChanges();
  };

  checkPage = obj => {
    // if (this.props.selected && this.props.selected.source) { }
    this.props.pageClick(obj, this.props.selected.source);
  };

  changeScrollIndex = currentIndex => {
    this.setState({ currentIndex });
  };

  render() {
    const {
      // sample, // input number of samele variables
      tblCellWidth,
      columnWidths,
      headerHeight,
      rowHeight,
      sortedColumns
    } = this.state;
    const { materials } = this.props;

    // flag for disabling save button in case of marker status is unchanged.
    const markerStatusChanged = Object.keys(materials.markerMaterialMap).some(
      key => materials.markerMaterialMap[key].changed
    );

    let { tblWidth, tblHeight } = this.state; // currentIndex
    const { currentIndex } = this.state; // currentIndex

    tblWidth -= 40; // 30; // substracting offsets for aesthetic purpose
    tblHeight -= 270; // 300; // substracting offsets for aesthetic purpose

    if (this.props.sideMenu) {
      tblWidth -= 210;
    } else {
      tblWidth -= 60;
    }

    if (this.props.visibility) tblHeight -= 221;

    if (tblHeight < 200) tblHeight = 200;
    const btnName = "Save Selected"; // Material Markers and Sample";

    const sampleChange = this.props.sampleNumber.some(i => i.changed);
    const data = this.props.materials.tableData;

    return (
      <div className="manage-marker-table">
        <div className="action-buttons">
          <button
            className="save-material-marker"
            disabled={!markerStatusChanged && !sampleChange}
            onClick={this.saveMarkerMaterial}
          >
            <i className="icon icon-floppy" />
            {btnName}
          </button>
        </div>
        <Table
          rowHeight={rowHeight}
          rowsCount={data.length}
          onColumnResizeEndCallback={this._onColumnResizeEndCallback}
          isColumnResizing={false}
          scrollToRow={currentIndex}
          width={tblWidth}
          height={tblHeight}
          headerHeight={headerHeight}
          {...this.state}
        >
          {sortedColumns.map(d => {
            let width = columnWidths[d.columnLabel] || tblCellWidth;
            if (d.traitID && d.traitID.substring(0, 2).toLowerCase() === "d_") {
              width = columnWidths[d.traitID] || tblCellWidth;
            }
            const fix = d.fixed === 1;
            const colKey = d.traitID || d.columnLabel;
            if (colKey) {
              const newwid = d.columnLabel.length * 15;
              width = width < newwid ? newwid : width;
            }

            return (
              <Column
                key={
                  (!!d.traitID && d.traitID.toString().toLowerCase()) ||
                  (!!d.columnLabel && d.columnLabel.toString().toLowerCase())
                }
                header={
                  // /// ////
                  // Issue occured because of same traid value
                  // change in columnKey adding index value
                  // /// ////
                  <MaterialHeaderCell
                    {...this.state}
                    data={d || {}}
                    traitID={d.traitID}
                    label={d.columnLabel}
                    showFilter={this._filter}
                  />
                  //  + `_${i}`
                }
                columnKey={colKey && colKey.toString()}
                width={width}
                isResizable
                fixed={fix}
                minWidth={tblCellWidth}
                cell={
                  colKey !== "NrOfSamples" ? (
                    <MaterialCell
                      data={data}
                      traitID={d.traitID}
                      markerMaterialMap={this.props.materials.markerMaterialMap}
                      toggleMaterialMarker={this.toggleMaterialMarker}
                    />
                  ) : (
                    <SampleComponent indexChange={this.changeScrollIndex} />
                  )
                }
              />
            );
          })}
        </Table>
        <Page
          testID={this.props.testID}
          pageNumber={this.state.pageNumber}
          pageSize={this.props.pageSize}
          records={this.props.records}
          filter={this.props.filter}
          filterLength={Object.keys(this.props.filter).length}
          onPageClick={this.checkPage}
          isBlocking={this.props.dirty}
          isBlockingChange={this.props.resetDirtyMarked}
          pageClicked={this.onPageClick}
          _fixColumn={this._fixColumn}
          clearFilter={this.clearFilter}
          dirtyMessage={this.props.dirtyMessage}
          total={this.props.total}
        />
      </div>
    );
  }
}

// Container
const mapStateToProps = state => ({
  sideMenu: state.sidemenuReducer,
  pageSize: state.assignMarker.total.pageSize,
  materials: state.assignMarker.materials,
  testID: state.rootTestID.testID,
  testTypeID: state.assignMarker.testType.selected,
  records: state.assignMarker.materials.totalRecords,
  filter: state.assignMarker.materials.filters,
  dirty: state.assignMarker.materials.dirty,
  sampleNumber: state.assignMarker.numberOfSamples.samples,
  sampleRefresh: state.assignMarker.numberOfSamples.refresh,
  selected: state.assignMarker.file.selected,
  total: state.assignMarker.materials.total
});
const mapDispatchToProps = dispatch => ({
  toggleMaterialMarker: markerMaterialList =>
    dispatch(toggleMaterialMarker(markerMaterialList)),
  saveMarkerMaterial: materialsMarkers =>
    dispatch(saveMarkerMaterial(materialsMarkers)),
  pageClick: (obj, source) => {
    if (source === "External") {
      dispatch({ ...obj, type: "FETCH_MATERIAL_EXTERNAL" });
    } else {
      dispatch({ ...obj, type: "FETCH_MATERIALS" });
    }
  },
  resetDirtyMarked: () => {
    dispatch({ type: "RESET_MARKER_DIRTY" });
  },
  postSampleChanges: () => {
    dispatch({
      type: "POST_NO_OF_SAMPLES",
      sample: 1
    });
  },
  resetManageMarker: () => dispatch({ type: "RESET_SCORE" })
});
const ManageMarkerTable = connect(
  mapStateToProps,
  mapDispatchToProps
)(Manage2GB);

Manage2GB.defaultProps = {
  selected: {},
  sample: false,
  fixColumn: 0,
  pageNumber: 1,
  pageSize: 150,
  tblCellWidth: 100,
  tblHeight: 300,
  tblWidth: 1000,
  dirtyMessage: "",
  filter: {},
  sampleNumber: []
};

Manage2GB.propTypes = {
  selected: PropTypes.object, // eslint-disable-line
  postSampleChanges: PropTypes.func.isRequired,
  resetManageMarker: PropTypes.func.isRequired,
  sampleRefresh: PropTypes.any, // eslint-disable-line
  sample: PropTypes.bool,
  testTypeID: PropTypes.number.isRequired,
  testID: PropTypes.number.isRequired,
  fixColumn: PropTypes.number,
  pageSize: PropTypes.number,
  pageNumber: PropTypes.number,
  tblCellWidth: PropTypes.number,
  tblWidth: PropTypes.number,
  tblHeight: PropTypes.number,
  materials: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  toggleMaterialMarker: PropTypes.func.isRequired,
  saveMarkerMaterial: PropTypes.func.isRequired,

  sideMenu: PropTypes.bool.isRequired,
  visibility: PropTypes.bool.isRequired,

  dirty: PropTypes.bool.isRequired,
  dirtyMessage: PropTypes.string,
  resetDirtyMarked: PropTypes.func.isRequired,
  pageClick: PropTypes.func.isRequired,
  records: PropTypes.number.isRequired,
  filter: PropTypes.any, // eslint-disable-line react/forbid-prop-types
  sampleNumber: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  total: PropTypes.any // eslint-disable-line
};

export default ManageMarkerTable;
