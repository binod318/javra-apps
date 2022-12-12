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
import RDTDateCell from "./components/RDTDateCell";
import RDTMaterialCell from "./components/RDTMaterialCell";
import { toggleMaterialMarker, saveRDTMarkerMaterial } from "./actions";
import NumberComponent from "./components/NumberCell";

// component
class RDTTableComponent extends Component {
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
      donerMaps: props.donerMaps,
      selectArray: [],
      delay: 250
    };
    autoBind(this);
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
      this.setState({ tblWidth: nextProps.tblWidth });
    }
    if (nextProps.tblHeight !== this.props.tblHeight) {
      this.setState({ tblHeight: nextProps.tblHeight });
    }
    if (nextProps.pageNumber !== this.props.pageNumber) {
      this.setState({ selectArray: [] });
      // this.setState({ pageNumber: nextProps.pageNumber });
    }
  }

  componentWillUnmount() {
    // TODO :: IMPORTANT check this what this was done
    this.props.resetMarker();
    this.props.resetPageSize();
  }

  onPageClick = pg => {
    this.setState({ pageNumber: pg });
  };

  setIndexArray = index => {
    if (index === null) this.setState({ selectArray: [] });
    else this.setState({ selectArray: index });
  };

  saveRDTAssignTests() {
    const {
      testTypeID,
      materials,
      testID,
      donerMaps,
      filter,
      maxSelectMaps,
      breedingStationSelected,
      cropSelected
    } = this.props;
    const { markerMaterialMap, rdtMaterialStatus } = materials;
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
          const expectedDate =
            donerMaps[`${map[0]}-date_${maps[1]}`].newState || "";
          const maxSelect = maxSelectMaps[`${map[0]}-maxSelect${maps[1]}`]
            ? maxSelectMaps[`${map[0]}-maxSelect${maps[1]}`].newState || ""
            : "";
          materialWithMarker.push({
            code: `${map[0]}-${maps[1]}`,
            materialID: map[0],
            determinationID: maps[1],
            selected: !!markerMaterialMap[key].newState,
            expectedDate,
            maxSelect
          });
        }
      }
    });

    const donerResult = [];
    Object.keys(donerMaps).forEach(key => {
      if (donerMaps[key].changed) {
        const map = key.split("-");
        const maps = map[1].split("_");
        const selected =
          markerMaterialMap[`${map[0]}-d_${maps[1]}`].newState === 1;
        donerResult.push({
          code: `${map[0]}-${maps[1]}`,
          materialID: map[0],
          determinationID: maps[1],
          expectedDate: donerMaps[key].newState,
          selected
        });
      }
    });

    const maxSelectResult = [];
    Object.keys(maxSelectMaps).forEach(key => {
      if (maxSelectMaps[key].changed) {
        const map = key.split("-");
        const maps = map[1].split("t");
        const selected =
          markerMaterialMap[`${map[0]}-d_${maps[1]}`].newState === 1;
        maxSelectResult.push({
          code: `${map[0]}-${maps[1]}`,
          materialID: map[0],
          determinationID: maps[1],
          maxselect: maxSelectMaps[key].newState,
          selected
        });
      }
    });

    const propertyValue = [];
    Object.keys(rdtMaterialStatus).forEach(key => {
      if (rdtMaterialStatus[key].changed) {
        const map = key.split("-");

        propertyValue.push({
          materialID: map[0],
          key: "materialstatus",
          value: rdtMaterialStatus[key].newState
        });
      }
    });

    const materialsMarkers = {
      testID,
      testTypeID,
      materialWithMarkerAndExpectedDate: this.combineValues(
        this.combineValues(materialWithMarker, donerResult),
        maxSelectResult
      ),
      propertyValue,
      pageNumber: this.state.pageNumber || 1,
      filter
    };

    //get selected menu
    let selectedMenu = window.localStorage.getItem("selectedMenuGroup");
    this.props.saveMarkerMaterial(
      materialsMarkers,
      breedingStationSelected,
      cropSelected,
      testID,
      selectedMenu
    );
  }

  combineValues = (a, b) => {
    const collection = [];
    a.forEach(k => {
      const m = b.filter(x => x.code === k.code);
      if (m.length) {
        collection.push({ ...m[0], selected: k.selected });
      } else {
        collection.push({ ...k });
      }
    });
    b.forEach(k => {
      const m = collection.some(x => x.code === k.code);
      if (!m) {
        collection.push({ ...k });
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

    if (traitID === null && colKey === "MaterialStatus") {
      return (
        <RDTMaterialCell
          selectedArray={this.state.selectArray}
          data={data}
          msterialStateRDT={this.props.msterialStateRDT}
          rdtMaterialMaps={this.props.rdtMaterialMaps}
        />
      );
    }

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
      if (traitID.substring(0, 5).toLowerCase() === "date_") {
        return (
          <RDTDateCell
            selectedArray={this.state.selectArray}
            data={data}
            donerMaps={this.props.donerMaps}
            refresh={this.state.scoreRefresh}
          />
        );
      }

      if (traitID.indexOf("maxSelect") > -1) {
        return (
          <NumberComponent
            selectedArray={this.state.selectArray}
            data={data}
            maxSelectMaps={this.props.maxSelectMaps}
            refresh={this.state.scoreRefresh}
          />
        );
      }
    }

    return (
      <MaterialCell
        data={data}
        traitID={traitID}
        markerMaterialMap={this.props.materials.markerMaterialMap}
        toggleMaterialMarker={this.toggleMaterialMarker}
        rdtPrint={this.props.rdtPrint}
      />
    );
  };

  localPrintAction = () => {
    const { importLevel, testID } = this.props;
    if (importLevel === "PLT") {
      if (confirm("Are you sure?")) {
        // eslint-disable-line
        this.props.print({
          testID,
          materialStatus: [],
          materialDeterminations: []
        });
      }
    } else {
      this.props.rdtPrint();
    }
  };

  longClickTimer = null;
  prevent = false;

  cancelLongClick() {
    if (this.longClickTimer) {
      clearTimeout(this.longClickTimer);
      this.longClickTimer = null;
    }
  }
  selectRow = (rowIndex, shift, ctrl) => {
    if (rowIndex === null) {
      return null;
    }
    const { selectArray } = this.state;
    // const match = selectArray.includes(rowIndex);
    // const index = rowIndex;

    if (ctrl) {
      if (!selectArray.includes(rowIndex)) {
        this.setIndexArray([...selectArray, rowIndex]);
      } else {
        const ind = selectArray.indexOf(rowIndex);
        const newSelect = [
          ...selectArray.slice(0, ind),
          ...selectArray.slice(ind + 1)
        ];
        this.setIndexArray(newSelect);
      }
    } else if (shift) {
      const newShiftArray = this.state.selectArray;
      newShiftArray.push(rowIndex);
      newShiftArray.sort((a, b) => a - b);
      const preArray = [];
      for (
        let i = newShiftArray[0];
        i <= newShiftArray[newShiftArray.length - 1];
        i += 1
      ) {
        preArray.push(i);
      }
      this.setIndexArray(preArray);
    } else {
      const checkSelect = selectArray.includes(rowIndex);
      if (checkSelect) {
        this.setIndexArray([]);
      } else {
        this.setIndexArray([rowIndex]);
      }
    }
    // CHECKING IF THE ROW IS FIXED OR NOT
    return null;
  };

  _rowClassNameGetter = rowIndex => {
    const { selectArray } = this.state;
    if (selectArray.includes(rowIndex)) {
      return "highlight-row";
    }
    return null;
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
      dirty ||
      Object.keys(materials.markerMaterialMap).some(
        key => materials.markerMaterialMap[key].changed
      );

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
    const statuscodeGreaterEqul500 = this.props.statusCode >= 500;

    return (
      <div className="manage-marker-table">
        <div className="action-buttons">
          <button
            className="save-material-marker"
            disabled={!markerStatusChanged}
            onClick={this.saveRDTAssignTests}
          >
            <i className="icon icon-floppy" />
            Save Changes
          </button>
          {statuscodeGreaterEqul500 && (
            <button
              disabled={this.props.rdtFrmDisplay || markerStatusChanged}
              className="save-material-marker"
              onClick={this.localPrintAction}
            >
              <i className="icon icon-print" />
              Print
            </button>
          )}
        </div>

        <Table
          rowHeight={rowHeight}
          rowsCount={data.length}
          onColumnResizeEndCallback={this._onColumnResizeEndCallback}
          isColumnResizing={false}
          width={tblWidth}
          height={tblHeight}
          rowClassNameGetter={this._rowClassNameGetter}
          headerHeight={headerHeight}
          {...this.state}
          onRowMouseDown={(event, rowIndex) => {
            // text, submit, select-one
            if (
              event.target.type === "select-one" ||
              event.target.type === "text" ||
              event.target.type === "submit"
            ) {
              return null;
            }
            let shiftK = false;
            let ctrlK = false;
            if (event.ctrlKey) ctrlK = true;
            if (event.shiftKey) shiftK = true;
            this.selectRow(rowIndex, shiftK, ctrlK);
            return null;
          }}
        >
          {sortedColumns.map(d => {
            let width = columnWidths[d.columnLabel] || tblCellWidth;
            if (d.traitID && d.traitID.substring(0, 2).toLowerCase() === "d_") {
              width =
                d.columnLabel.length * 13 ||
                columnWidths[d.traitID] ||
                tblCellWidth;
            }

            if (
              d.traitID &&
              d.traitID.substring(0, 5).toLowerCase() === "date_"
            ) {
              width =
                d.columnLabel.length * 10 ||
                columnWidths[d.traitID] ||
                tblCellWidth;
            }
            const fix = d.fixed === 1;
            const colKey = d.traitID || d.columnLabel;

            if (colKey) {
              const newwid = colKey.length * 11;
              width = width < newwid ? newwid : width;
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
                    addFilter={this._addFilter}
                  />
                }
                columnKey={colKey && colKey.toString()}
                width={width}
                isResizable
                fixed={fix}
                fixedRight={colKey === "Print"}
                minWidth={tblCellWidth}
                cell={this.tabelCellSelection(d.traitID, colKey)}
              />
            );
          })}
        </Table>
        <Page
          testID={this.props.testID}
          pageNumber={this.props.pageNumber}
          pageSize={this.props.pageSize}
          records={this.props.records}
          filter={this.props.filter}
          filterLength={Object.keys(this.props.filter).length}
          onPageClick={this.props.pageClick}
          isBlocking={this.props.dirty}
          isBlockingChange={this.props.resetDirtyMarked}
          pageClicked={this.onPageClick}
          _fixColumn={() => {}}
          clearFilter={() => {}}
          dirtyMessage={this.props.dirtyMessage}
          testTypeID={this.props.testTypeID}
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
  scoreMaps: state.assignMarker.materials.score,
  donerMaps: state.assignMarker.materials.donerInfoMap,
  maxSelectMaps: state.assignMarker.materials.maxSelectInfoMap,
  scoreRefresh: state.assignMarker.materials.refresh,
  rdtMaterialMaps: state.assignMarker.materials.rdtMaterialStatus,
  testID: state.rootTestID.testID,
  testTypeID: state.assignMarker.testType.selected,
  records: state.assignMarker.materials.totalRecords,
  dirty: state.assignMarker.materials.dirty,
  pageSize: state.assignMarker.total.pageSize,
  pageNumber: state.assignMarker.total.pageNumber,
  projectList: state.assignMarker.project,
  msterialStateRDT: state.assignMarker.materialStateRDT,
  filter: state.assignMarker.RDTFilter,
  rdtFrmDisplay: state.assignMarker.rdtPrint,
  breedingStationSelected: state.breedingStation.selected,
  cropSelected: state.user.selectedCrop
});
const mapDispatchToProps = dispatch => ({
  toggleMaterialMarker: markerMaterialList =>
    dispatch(toggleMaterialMarker(markerMaterialList)),
  saveMarkerMaterial: (materialsMarkers, breeding, crop, testID, testTypeMenu) => {
    dispatch({ type: "FILELIST_FETCH", breeding, crop, testTypeMenu });
    dispatch(saveRDTMarkerMaterial(materialsMarkers));
    dispatch({
      type: "FETCH_TESTLOOKUP",
      breedingStationCode: breeding,
      cropCode: crop,
      testTypeMenu
    });
    dispatch({ type: "FETCH_STATULSLIST" });
    dispatch({ type: "FETCH_SLOT", testID });
  },
  saveMarkerSelected: () => {
    // dispatch({ type: 'SAVE_3GB_MATERIAL_MARKER', materialsMarkers });
  },
  pageClick: obj => dispatch({ ...obj, type: "FETCH_RDT_MATERIAL_WITH_TESTS" }),
  resetDirtyMarked: () => dispatch({ type: "RESET_MARKER_DIRTY" }),
  resetMarker: () => dispatch({ type: "RESET_SCORE" }),
  rdtPrint: () => dispatch({ type: "RDT_PRINT_SHOW" }),
  print: obj => dispatch({ type: "POST_RDT_PRINT", ...obj }),
  resetPageSize: () => dispatch({ type: "SIZE_RECORD", pageSize: 200 })
});
const RDTTable = connect(
  mapStateToProps,
  mapDispatchToProps
)(RDTTableComponent);

RDTTableComponent.defaultProps = {
  selectArray: [],
  msterialStateRDT: [],
  rdtMaterialMaps: {},
  donerMaps: {},

  fixColumn: 0,
  pageNumber: 1,
  tblCellWidth: 100,
  tblHeight: 300,
  tblWidth: 1000,
  dirtyMessage: "",
  importLevel: "",
  filter: []
};

RDTTableComponent.propTypes = {
  resetPageSize: PropTypes.func.isRequired,
  selectArray: PropTypes.array, // eslint-disable-line
  rdtFrmDisplay: PropTypes.bool.isRequired,
  rdtPrint: PropTypes.func.isRequired,
  print: PropTypes.func.isRequired,
  importLevel: PropTypes.string,
  statusCode: PropTypes.number.isRequired,

  msterialStateRDT: PropTypes.array, // eslint-disable-line
  rdtMaterialMaps: PropTypes.object, // eslint-disable-line
  donerMaps: PropTypes.object, // eslint-disable-line
  maxSelectMaps: PropTypes.object, // eslint-disable-line
  scoreRefresh: PropTypes.bool.isRequired,

  resetMarker: PropTypes.func.isRequired,

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

  cropSelected: PropTypes.string.isRequired,
  breedingStationSelected: PropTypes.string.isRequired,

  dirty: PropTypes.bool.isRequired,
  dirtyMessage: PropTypes.string,
  resetDirtyMarked: PropTypes.func.isRequired,
  pageClick: PropTypes.func.isRequired,
  records: PropTypes.number.isRequired,
  filter: PropTypes.array // eslint-disable-line react/forbid-prop-types
};
export default RDTTable;
