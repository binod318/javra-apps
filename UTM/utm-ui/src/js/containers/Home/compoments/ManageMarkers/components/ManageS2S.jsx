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
import { toggleMaterialMarker, saveS2SMarkerMaterial } from "./actions";
// component
class S2STableComponent extends Component {
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
      donerMaps: props.donerMaps
    };
    autoBind(this);
  }

  componentDidMount() {
    const { cropSelected } = this.props;
    this.props.fetchS2SProjectList(cropSelected);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.scoreRefresh !== this.props.scoreRefresh) {
      this.setState({
        scoreMaps: nextProps.scoreMaps,
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

  saveS2SMarkerMaterial() {
    const {
      testTypeID,
      materials,
      testID,
      scoreMaps,
      donerMaps,
      pageNumber,
      filter
    } = this.props;
    const { markerMaterialMap } = materials;
    const materialWithMarkerSelected = [];
    const materialWithMarker = [];
    Object.keys(markerMaterialMap).forEach(key => {
      if (markerMaterialMap[key].changed) {
        const map = key.split("-");
        if (map[1] === "d_selected") {
          materialWithMarkerSelected.push({
            materialKey: markerMaterialMap[key].mk,
            selected: !!markerMaterialMap[key].newState
          });
        } else {
          const maps = map[1].split("_");
          materialWithMarker.push({
            code: `${map[0]}-${maps[1]}`,
            materialID: map[0],
            determinationID: maps[1],
            selected: !!markerMaterialMap[key].newState
          });
        }
      }
    });

    const materialWithScore = [];
    Object.keys(scoreMaps).forEach(key => {
      if (scoreMaps[key].changed) {
        const map = key.split("-");
        const maps = map[1].split("_");
        materialWithScore.push({
          code: `${map[0]}-${maps[1]}`,
          materialID: map[0],
          determinationID: maps[1],
          alliceScore: scoreMaps[key].newState
        });
      }
    });

    const donerResult = [];
    Object.keys(donerMaps).forEach(key => {
      if (donerMaps[key].changed) {
        const map = key.split("-");
        donerResult.push({
          code: `${map[0]}`,
          materialID: map[0],
          ...donerMaps[key]
        });
      }
    });

    const materialsMarkers = {
      testID,
      testTypeID,
      materialWithMarkerAndScore: this.combineValues(
        materialWithMarker,
        materialWithScore
      ),
      donerInfo: donerResult,
      pageNumber,
      filter
    };

    const materialsMarkers1 = {
      testID,
      materialWithMarker: materialWithMarkerSelected
    };

    this.props.saveMarkerMaterial(materialsMarkers);
    if (materialWithMarkerSelected.length > 0)
      this.props.saveMarkerSelected(materialsMarkers1);
  }

  combineValues = (a, b) => {
    const collection = [];

    a.forEach(k => {
      const m = b.filter(x => x.code === k.code);
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
    this.setState({ sortedColumns: columns });
  }

  _onColumnResizeEndCallback = (newColumnWidth, columnKey) => {
    this.setState(({ columnWidths }) => ({
      columnWidths: {
        ...columnWidths,
        [columnKey]: newColumnWidth
      }
    }));
  };

  tabelCellSelection = (traitID, colKey) => {
    const data = this.props.materials.tableData;

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
    if (
      colKey === "DH0Net" ||
      colKey === "Requested" ||
      colKey === "Transplant" ||
      colKey === "ToBeSown" ||
      colKey === "ProjectCode"
    ) {
      let name = "dH0Net";
      if (colKey === "Requested") name = "requested";
      if (colKey === "Transplant") name = "transplant";
      if (colKey === "ToBeSown") name = "toBeSown";
      if (colKey === "ProjectCode") name = "projectCode";
      // transplant
      // toBeSown
      return (
        <DonorCell
          name={name}
          data={data}
          donerMaps={this.state.donerMaps}
          refresh={this.state.scoreRefresh}
          projects={this.props.projectList}
        />
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
    const {
      tblCellWidth,
      columnWidths,
      headerHeight,
      rowHeight,
      sortedColumns
    } = this.state; // fixColumn,
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

    return (
      <div className="manage-marker-table">
        <div className="action-buttons">
          <button
            className="save-material-marker"
            disabled={!markerStatusChanged}
            onClick={this.saveS2SMarkerMaterial}
          >
            <i className="icon icon-floppy" />
            Save Changes
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
                d.columnLabel.length * 13 ||
                columnWidths[d.traitID] ||
                tblCellWidth;
            }
            const fix = d.fixed === 1;
            const colKey = d.traitID || d.columnLabel;

            if (colKey) {
              const newwid = colKey.length * 11;
              width = width < newwid ? newwid : width;
            }
            if (
              colKey === "DH0Net" ||
              colKey === "Requested" ||
              colKey === "Transplant" ||
              colKey === "ToBeSown"
            ) {
              width = 100;
            }

            return (
              <Column
                key={
                  (!!d.traitID && d.traitID.toString().toLowerCase()) ||
                  (!!d.columnLabel && d.columnLabel.toString().toLowerCase())
                }
                header={
                  <MaterialHeaderCell
                    {...this.state}
                    data={d || {}}
                    traitID={d.traitID}
                    label={d.columnLabel}
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
  projectList: state.assignMarker.project
});
const mapDispatchToProps = dispatch => ({
  toggleMaterialMarker: markerMaterialList =>
    dispatch(toggleMaterialMarker(markerMaterialList)),
  saveMarkerMaterial: materialsMarkers => {
    dispatch(saveS2SMarkerMaterial(materialsMarkers));
  },
  saveMarkerSelected: materialsMarkers => {
    dispatch({ type: "SAVE_3GB_MATERIAL_MARKER", materialsMarkers });
  },
  pageClick: obj => {
    dispatch({ ...obj, type: "FETCH_S2S" });
  },
  resetDirtyMarked: () => dispatch({ type: "RESET_MARKER_DIRTY" }),
  resetMarker: () => dispatch({ type: "RESET_SCORE" }),
  fetchS2SProjectList: crop =>
    dispatch({ type: "FETCH_S2S_PROJECT_LIST", crop })
});
const S2STable = connect(
  mapStateToProps,
  mapDispatchToProps
)(S2STableComponent);

S2STableComponent.defaultProps = {
  projectList: [],
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

S2STableComponent.propTypes = {
  projectList: PropTypes.array, // eslint-disable-line
  saveMarkerSelected: PropTypes.func.isRequired,
  resetMarker: PropTypes.func.isRequired,
  cropSelected: PropTypes.any, // eslint-disable-line
  fetchS2SProjectList: PropTypes.func.isRequired,
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
  saveMarkerMaterial: PropTypes.func.isRequired,

  dirty: PropTypes.bool.isRequired,
  dirtyMessage: PropTypes.string,
  resetDirtyMarked: PropTypes.func.isRequired,
  pageClick: PropTypes.func.isRequired,
  records: PropTypes.number.isRequired,
  filter: PropTypes.array // eslint-disable-line react/forbid-prop-types
};
export default S2STable;
