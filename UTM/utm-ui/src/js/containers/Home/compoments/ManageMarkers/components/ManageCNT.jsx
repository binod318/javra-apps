import React, { Component } from "react";
import { connect } from "react-redux";
import { Table, Column } from "fixed-data-table-2";
import PropTypes from "prop-types";
import autoBind from "auto-bind";

import Page from "../../../../../components/Page/Page";
import MaterialHeaderCell from "./components/HeaderCell";
import MaterialCell from "./components/TextCell";
import ScoreCell from "./components/ScoreCell";
import CheckCell from "./components/CheckCell";
import DonorCell from "./components/DonorCell";
// import S2SMarkerCell from './components/S2SMarkerCell';
import { toggleMaterialMarker } from "./actions"; // saveS2SMarkerMaterial
// component
class CNTTableComponent extends Component {
  constructor(props) {
    super(props);
    this.state = {
      columnWidths: {},
      fixColumn: props.fixColumn || 1,
      headerHeight: 40,
      rowHeight: 36,
      pageNumber: props.pageNumber || 1,
      pageSize: props.pageSize || 200,
      tblCellWidth: props.tblCellWidth || 120,
      tblWidth: props.tblWidth || 1000,
      tblHeight: props.tblHeight || 300,
      sortedColumns: ["", "", ""], // THREE VALUES ARE RESERVED FOR THREE FIRST COLUMNS Crop, GID, Plantnr
      scoreRefresh: props.scoreRefresh,
      scoreMaps: props.scoreMaps,
      donerMaps: props.donerMaps,
      focusTarget: ""
    };
    autoBind(this);
  }

  componentDidMount() {
    this.props.fetchProcess();
    this.props.fetchLabLocation();
    this.props.fetchStartMaterial();
    this.props.fetchTypeCt();
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.scoreRefresh !== this.props.scoreRefresh) {
      this.setState({
        donerMaps: nextProps.donerMaps,
        scoreRefresh: nextProps.scoreRefresh
      });
    }

    if (nextProps.materials.columns.length) {
      this.sortColumns(nextProps.materials.columns);
    }
    if (nextProps.tblWidth !== this.props.tblWidth) {
      this.setState({
        tblWidth: nextProps.tblWidth
      });
    }
    if (nextProps.tblHeight !== this.props.tblHeight) {
      this.setState({
        tblHeight: nextProps.tblHeight
      });
    }
  }

  componentWillUnmount() {
    // TODO :: IMPORTANT check this what this was done
    this.props.resetMarker();
  }

  onPageClick = pg => {
    this.setState({ pageNumber: pg });
  };

  setFocusTarget = focusTarget => {
    this.setState({ focusTarget });
    return null;
  };

  exportExcel = () => {
    this.props.export(this.props.testID);
  };

  saveCNTMarkerMaterial() {
    // alert('here');
    // testTypeID, scoreMaps, pageNumber, filter,
    const { materials, testID, donerMaps } = this.props;
    const { markerMaterialMap } = materials;
    const materialWithMarkerSelected = [];
    const materialWithMarker = [];

    Object.keys(markerMaterialMap).forEach(key => {
      if (markerMaterialMap[key].changed) {
        const map = key.split("-");
        if (map[1] === "d_selected") {
          materialWithMarkerSelected.push({
            materialID: map[0],
            materialKey: markerMaterialMap[key].mk,
            selected: !!markerMaterialMap[key].newState
          });
        } else {
          const maps = map[1].split("_");
          // code: `${map[0]}-${maps[1]}`,
          materialWithMarker.push({
            materialID: map[0],
            determinationID: maps[1],
            selected: !!markerMaterialMap[key].newState
          });
        }
      }
    });

    const donerResult = [];
    Object.keys(donerMaps).forEach(key => {
      if (donerMaps[key].changed) {
        const map = key.split("-");
        donerResult.push({
          materialID: map[0],
          ...donerMaps[key]
        });
      }
    });

    const objMarker = {
      testID,
      markers: materialWithMarker,
      materials: materialWithMarkerSelected,
      details: donerResult
    };
    this.props.saveChange(objMarker);
  }

  combineValues = (a, b) => {
    const collection = [];

    a.forEach(k => {
      const m = b.filter(x => x.materialID === k.materialID);
      if (m.length) {
        collection.push({ ...m[0], selected: k.selected });
      } else {
        collection.push({ ...k, alliceScore: null });
      }
    });
    b.forEach(k => {
      const m = collection.some(x => x.code === k.code);
      if (!m) {
        collection.push({ ...k, selected: null });
      }
    });
    return collection;
  };

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
    const sortedColumns = ["", "", "", "", "", "", "", "", ""]; // THREE VALUES ARE RESERVED FOR THREE FIRST COLUMNS Crop, GID, Plantnr
    columns.forEach(col => {
      switch (col.columnLabel) {
        // case 'Crop': {
        //   sortedColumns[0] = col;
        //   break;
        // }
        case "GID": {
          sortedColumns[0] = col;

          break;
        }
        case "Plant name":
          sortedColumns[1] = col;
          break;
        case "Selected": {
          sortedColumns[2] = col;
          break;
        }
        // case 'Requested': {
        //   sortedColumns[3] = col;
        //   break;
        // }
        // case 'Transplant': {
        //   sortedColumns[4] = col;
        //   break;
        // }
        // case 'ProcessID': {
        //   sortedColumns[5] = col;
        //   break;
        // }
        // case 'LabLocationID': {
        //   sortedColumns[6] = col;
        //   break;
        // }
        // case 'StartMaterialID': {
        //   sortedColumns[7] = col;
        //   break;
        // }
        // case 'TypeID': {
        //   sortedColumns[8] = col;
        //   break;
        // }
        default: {
          sortedColumns.push(col);
          break;
        }
      }
    });
    this.setState({ sortedColumns: sortedColumns.filter(x => x !== "") });
  }

  _onColumnResizeEndCallback = (newColumnWidth, columnKey) => {
    this.setState(({ columnWidths }) => ({
      columnWidths: {
        ...columnWidths,
        [columnKey]: newColumnWidth
      }
    }));
  };

  _fixColumn = () => {};

  clearFilter = () => {};

  tabelCellSelection = (traitID, colKey) => {
    const data = this.props.materials.tableData;
    // return <div>test</div>;

    if (traitID) {
      if (traitID.substring(0, 2).toLowerCase() === "d_") {
        return (
          <CheckCell
            data={data}
            traitID={traitID}
            markerMaterialMap={this.props.materials.markerMaterialMap}
            toggleMaterialMarker={this.toggleMaterialMarker}
          />
        );
      }
      if (traitID.substring(0, 6).toLowerCase() === "score_") {
        return (
          <ScoreCell
            data={data}
            traitID={traitID}
            scoreMaps={this.state.scoreMaps}
            refresh={this.state.scoreRefresh}
          />
        );
      }
    }
    // DH0Net, Requested, Transplant, ToBeSown
    const List = [
      "Requested",
      "Transplant",
      "ProcessID",
      "LabLocationID",
      "StartMaterialID",
      "TypeID",
      "Net",
      "Remarks",
      "DH1ReturnDate",
      "RequestedDate",
      "DonorNumber"
    ];
    //
    if (List.includes(colKey)) {
      let name = "";
      if (colKey === "Requested") name = "requested";
      if (colKey === "Transplant") name = "transplant";
      if (colKey === "DonorNumber") name = "donorNumber";
      if (colKey === "ProcessID") name = "processID";
      if (colKey === "LabLocationID") name = "labLocationID";
      if (colKey === "StartMaterialID") name = "startMaterialID";
      if (colKey === "TypeID") name = "typeID";
      if (colKey === "Net") name = "net";
      if (colKey === "Remarks") name = "remarks";
      if (colKey === "DH1ReturnDate") name = "dH1ReturnDate";
      if (colKey === "RequestedDate") name = "requestedDate";

      // transplant
      // toBeSown
      return (
        <DonorCell
          name={name}
          data={data}
          donerMaps={this.state.donerMaps}
          refresh={this.state.scoreRefresh}
          process={this.props.process}
          location={this.props.location}
          startMaterial={this.props.startMaterial}
          typeCT={this.props.typeCT}
        />
        // setFocusTarget={this.setFocusTarget}
        // focusTarget={this.state.focusTarget}
      );
    }

    return (
      <MaterialCell
        data={data}
        traitID={traitID}
        markerMaterialMap={this.props.materials.markerMaterialMap}
        toggleMaterialMarker={this.toggleMaterialMarker}
      />
    );
  };

  render() {
    // fixColumn,
    const {
      tblCellWidth,
      columnWidths,
      headerHeight,
      rowHeight,
      sortedColumns
    } = this.state;
    const { materials, dirty } = this.props;

    // flag for disabling save button in case of marker status is unchanged.
    const markerStatusChanged =
      Object.keys(materials.markerMaterialMap).some(
        key => materials.markerMaterialMap[key].changed
      ) || dirty;

    let { tblWidth, tblHeight } = this.state;

    tblWidth -= 30; // substracting offsets for aesthetic purpose
    tblHeight -= 300; // 270; // substracting offsets for aesthetic purpose

    if (this.props.sideMenu) {
      tblWidth -= 210;
    } else {
      tblWidth -= 60;
    }
    if (this.props.visibility) {
      tblHeight -= 221;
    }

    if (tblHeight < 200) {
      tblHeight = 200;
    }

    const data = this.props.materials.tableData;
    // return (
    //   <div>test</div>
    // )

    return (
      <div className="manage-marker-table">
        <div className="action-buttons">
          <button
            className="save-material-marker"
            disabled={!markerStatusChanged}
            onClick={this.saveCNTMarkerMaterial}
          >
            <i className="icon icon-floppy" />
            Save Changes
          </button>

          <button className="save-material-marker" onClick={this.exportExcel}>
            <i className="icon icon-file-excel" />
            Export
          </button>
        </div>

        <Table
          rowHeight={rowHeight}
          rowsCount={data.length}
          onColumnResizeEndCallback={this._onColumnResizeEndCallback}
          isColumnResizing={false}
          width={tblWidth}
          height={tblHeight}
          headerHeight={headerHeight}
          {...this.state}
        >
          {sortedColumns.map(d => {
            let width = columnWidths[d.columnLabel] || tblCellWidth;
            if (d.traitID && d.traitID.substring(0, 2).toLowerCase() === "d_") {
              width =
                d.columnLabel.length * 15 ||
                columnWidths[d.traitID] ||
                tblCellWidth;
            }
            const fix = d.fixed === 1; // i < fixColumn;
            const colKey = d.traitID || d.columnLabel;

            if (colKey) {
              const newwid = colKey.length * 11;
              width = width < newwid ? newwid : width;
            }
            if (colKey === "Plant name") width = 150;
            if (colKey === "ProcessID") width = 150;
            if (colKey === "LabLocationID") width = 150;
            if (colKey === "StartMaterialID") width = 150;
            if (colKey === "TypeID") width = 150;

            return (
              <Column
                key={
                  (!!d.columnLabel && d.columnLabel.toString().toLowerCase()) ||
                  (!!d.traitID && d.traitID.toString().toLowerCase())
                }
                header={
                  <MaterialHeaderCell
                    {...this.state}
                    data={d || {}}
                    traitID={d.traitID}
                    label={d.columnHeader}
                    showFilter={this._filter}
                  />
                }
                columnKey={colKey && colKey.toString()}
                width={width}
                isResizable
                fixed={fix}
                minWidth={tblCellWidth}
                cell={this.tabelCellSelection(d.traitID, colKey)}
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
          onPageClick={this.props.pageClick}
          isBlocking={this.props.dirty}
          isBlockingChange={this.props.resetDirtyMarked}
          pageClicked={this.onPageClick}
          _fixColumn={this._fixColumn}
          clearFilter={this.clearFilter}
          dirtyMessage={this.props.dirtyMessage}
        />
      </div>
    );
  }
}

// Container
const mapStateToProps = state => ({
  sideMenu: state.sidemenuReducer,
  materials: state.assignMarker.materials,
  testValue: state.assignMarker.materials.markerMaterialMap,
  // scoreMaps: state.assignMarker.scoreMap.score,
  scoreMaps: state.assignMarker.materials.score,
  donerMaps: state.assignMarker.materials.donerInfoMap,
  scoreRefresh: state.assignMarker.materials.refresh,
  // scoreDirty: state.assignMarker.scoreMap.dirty,
  testID: state.rootTestID.testID,
  testTypeID: state.assignMarker.testType.selected,
  records: state.assignMarker.materials.totalRecords,
  filter: state.assignMarker.materials.filters,
  dirty: state.assignMarker.materials.dirty,
  pageSize: state.assignMarker.total.pageSize,

  process: state.ctMaintain.process,
  location: state.ctMaintain.location,
  startMaterial: state.ctMaintain.startMaterial,
  typeCT: state.ctMaintain.type
});
const mapDispatchToProps = dispatch => ({
  toggleMaterialMarker: markerMaterialList =>
    dispatch(toggleMaterialMarker(markerMaterialList)),
  saveChange: obj => {
    dispatch({ type: "POST_CNT_MANAGE_MARKERS", ...obj });
  },
  pageClick: obj => {
    dispatch({ ...obj, type: "FETCH_CNT_DATA_WITH_MARKERS" });
  },
  resetDirtyMarked: () => dispatch({ type: "RESET_MARKER_DIRTY" }),
  resetMarker: () => dispatch({ type: "RESET_SCORE" }),

  fetchProcess: () => {
    dispatch({ type: "CT_PROCESS_FETCH" });
  },
  fetchLabLocation: () => {
    dispatch({ type: "CT_LABLOCATIONS_FETCH" });
  },
  fetchStartMaterial: () => {
    dispatch({ type: "CT_STARTMATERIAL_FETCH" });
  },
  fetchTypeCt: () => {
    dispatch({ type: "CT_TYPE_FETCH" });
  },
  export: testID => {
    dispatch({ type: "GET_CNT_EXPORT_EXCEL", testID });
  }
});
const S2STable = connect(
  mapStateToProps,
  mapDispatchToProps
)(CNTTableComponent);

CNTTableComponent.defaultProps = {
  donerMaps: {},
  scoreMaps: {},
  fixColumn: 0,
  pageNumber: 1,
  tblCellWidth: 100,
  tblHeight: 300,
  tblWidth: 1000,
  dirtyMessage: "",
  filter: []
};

CNTTableComponent.propTypes = {
  typeCT: PropTypes.any, // eslint-disable-line
  startMaterial: PropTypes.any, // eslint-disable-line
  location: PropTypes.any, // eslint-disable-line
  process: PropTypes.any, // eslint-disable-line
  export: PropTypes.func.isRequired,
  resetMarker: PropTypes.func.isRequired,
  fetchTypeCt: PropTypes.func.isRequired,
  fetchStartMaterial: PropTypes.func.isRequired,
  fetchLabLocation: PropTypes.func.isRequired,
  fetchProcess: PropTypes.func.isRequired,
  donerMaps: PropTypes.object, // eslint-disable-line
  scoreMaps: PropTypes.object, // eslint-disable-line
  scoreRefresh: PropTypes.any, // eslint-disable-line

  sideMenu: PropTypes.bool.isRequired,
  visibility: PropTypes.bool.isRequired,

  testTypeID: PropTypes.number.isRequired,
  testID: PropTypes.number.isRequired,
  fixColumn: PropTypes.number,
  pageSize: PropTypes.number.isRequired,
  pageNumber: PropTypes.number,
  tblCellWidth: PropTypes.number,
  tblWidth: PropTypes.number,
  tblHeight: PropTypes.number,
  materials: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  toggleMaterialMarker: PropTypes.func.isRequired,
  saveChange: PropTypes.func.isRequired,

  dirty: PropTypes.bool.isRequired,
  dirtyMessage: PropTypes.string,
  resetDirtyMarked: PropTypes.func.isRequired,
  pageClick: PropTypes.func.isRequired,
  records: PropTypes.number.isRequired,
  filter: PropTypes.array // eslint-disable-line react/forbid-prop-types
};

export default S2STable;
