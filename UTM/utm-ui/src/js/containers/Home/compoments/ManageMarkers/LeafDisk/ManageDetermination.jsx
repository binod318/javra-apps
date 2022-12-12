import React, { Component } from "react";
import { connect } from "react-redux";
import { Table, Column } from "fixed-data-table-2";
import PropTypes from "prop-types";
import autoBind from "auto-bind";

import Page from "../../../../../components/Page/Page";
import LDHeaderCell from "./components/LDHeaderCell";
import LDTextCell from "./components/LDTextCell";
import {
  toggleMaterialMarker,
  saveMarkerMaterial
} from "../components/actions";
import Marker from "../../Marker/Marker";
import { markerToggle } from "../../Marker/markerAction";
import { clearLeafDiskFilters } from "../../../actions";
import "./style.scss";
import LDActionCell from "./components/LDActionCell";
// component
class ManageDeterminationComponent extends Component {
  constructor(props) {
    super(props);
    console.log("constructor ");
    this.state = {
      currentIndex: 0,
      columnWidths: { action: 100 },
      fixColumn: props.fixColumn || 1,
      headerHeight: 40,
      rowHeight: 36,
      pageNumber: props.pageNumber || 1,
      pageSize: props.pageSize || 150,
      tblWidth: props.tblWidth || 1000,
      tblHeight: props.tblHeight || 300,
      sample: props.sample,
      sampleNumber: props.sampleNumber,
      sampleRefresh: props.sampleRefresh,
      selectedRows: [],
      shiftStartRowIndex: null,
      refs: []
    };
    autoBind(this);
  }

  componentDidMount() {
    const payload = {
      testID: this.props.testID,
      pageNumber: 1,
      pageSize: 200,
      filter: []
    };
    this.props.fetchMaterialDeterminations(payload);
    this.props.fetchLeafDiskDeterminations(this.props.cropSelected);
    this.props.clearFilters();

    if (
      this.state.refs.length === 0 &&
      this.props.determinations.tableData.length > 0
    ) {
      this.createReferenceCodeRefs();
    }
  }

  componentWillReceiveProps(nextProps) {
    if (
      nextProps.sampleRefresh !== this.props.sampleRefresh ||
      nextProps.sampleNumber.length !== this.props.sampleNumber.length
    ) {
      this.setState({ sampleNumber: nextProps.sampleNumber });
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

  componentDidUpdate(prevProps) {
    if (
      this.props.assignLDDetermationSucceeded &&
      prevProps.assignLDDetermationSucceeded !==
        this.props.assignLDDetermationSucceeded
    ) {
      // eslint-disable-next-line react/no-did-update-set-state
      this.setState({
        selectedRows: []
      });
      this.props.resetAssignLDDeterminationSucceededFlag();
    }
    if (
      this.props.filterCleared &&
      prevProps.filterCleared !== this.props.filterCleared
    ) {
      const payload = {
        testID: this.props.testID,
        pageNumber: 1,
        pageSize: 200,
        filter: []
      };
      this.props.fetchMaterialDeterminations(payload);
      this.props.resetFilterClearedFlag();
    }

    if (
      (this.props.determinations.columns.length > 0 &&
        Object.keys(this.state.columnWidths).length === 1) ||
      this.props.determinations.columns.length !==
        prevProps.determinations.columns.length
    ) {
      // prepopulate columnWidths from columns data
      const { columnWidths } = this.state;
      this.props.determinations.columns
        .filter(item => item.visible)
        .forEach(item => {
          columnWidths[item.columnID] = item.width || 100;
        });

      // eslint-disable-next-line react/no-did-update-set-state
      this.setState({ columnWidths });
    }

    const oldTableSet = JSON.stringify(this.props.determinations.tableData);

    const newTableSet = JSON.stringify(prevProps.determinations.tableData);

    if (oldTableSet !== newTableSet) {
      this.createReferenceCodeRefs();
    }

    // sampledSaved flag is set when data is saved,
    // so reload the grid data
    if (
      this.props.sampleSaved &&
      this.props.sampleSaved !== prevProps.sampleSaved
    ) {
      const payload = {
        testID: this.props.testID,
        pageNumber: 1,
        pageSize: 200,
        filter: []
      };
      this.props.fetchMaterialDeterminations(payload);
      this.props.resetSaveSampleSucceededFlag();
    }
  }

  componentWillUnmount() {
    this.props.resetManageMarker();
  }

  onRowClick = (rowIndex, shiftK, ctrlK) => {
    const { selectedRows } = this.state;
    if (shiftK) {
      // handle shift key press
      // this action will select records between starting row to ending row selection
      const { shiftStartRowIndex } = this.state;
      // if there is no start row index then set it
      if (this.state.shiftStartRowIndex === null) {
        this.setState({
          shiftStartRowIndex: rowIndex,
          selectedRows: [rowIndex]
        });
      } else {
        const rowIndexes = [shiftStartRowIndex, rowIndex];
        rowIndexes.sort();
        const finalSelectedRows = [];
        for (let i = rowIndexes[0]; i <= rowIndexes[1]; i += 1) {
          finalSelectedRows.push(i);
        }
        this.setState({ selectedRows: finalSelectedRows });
      }
    } else if (ctrlK) {
      // handle control key press
      if (selectedRows.indexOf(rowIndex) === -1) {
        this.setState({
          selectedRows: selectedRows.concat(rowIndex),
          shiftStartRowIndex: rowIndex
        });
      } else {
        this.setState({
          selectedRows: selectedRows.filter(item => item !== rowIndex),
          shiftStartRowIndex: rowIndex
        });
      }
    } else {
      this.setState({
        selectedRows: selectedRows.indexOf(rowIndex) === -1 ? [rowIndex] : [],
        shiftStartRowIndex:
          selectedRows.indexOf(rowIndex) === -1 ? rowIndex : null
      });
    }
  };
  onPageClick = pg => {
    this.setState({ pageNumber: pg });
  };

  createReferenceCodeRefs = () => {
    const refs = [];
    this.props.determinations.tableData.forEach(() => {
      const ref = React.createRef();
      refs.push(ref);
    });

    // eslint-disable-next-line react/no-did-update-set-state
    this.setState({ refs });
  };

  toggleFilter() {
    const hh = this.state.headerHeight;
    this.setState({
      headerHeight: hh === 40 ? 90 : 40
    });
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

  checkPage = payload => {
    this.props.fetchLeafDiskMaterialDeterminations(payload);
  };

  changeScrollIndex = currentIndex => {
    this.setState({ currentIndex });
  };

  assignMarker = () => {
    const { selectedRows } = this.state;
    const filter = Object.values(this.props.filters);

    const {
      tableData,
      determinations: determinationList
    } = this.props.determinations;
    const sampleIDs = selectedRows.map(
      rowIndex => tableData[rowIndex].sampleTestID
    );
    const determinations = determinationList
      .filter(item => item.selected)
      .map(item => item.determinationID);
    const payload = {
      testID: this.props.testID,
      sampleInfo: [],
      action: "add",
      determinations,
      sampleIDs,
      pageNumber: this.props.pageNumber,
      pageSize: this.props.pageSize,
      filter
    };
    this.props.assignLDDeterminations(payload);
  };

  saveLDDeterminationsChanged = rowIndex => {
    const filter = Object.values(this.props.filters);
    const { tableData } = this.props.determinations;
    const sampleInfo = [];
    tableData.forEach(item => {
      item.determinationsChanged.forEach(column => {
        sampleInfo.push({
          sampleTestID: item.sampleTestID,
          key: column,
          value: item[column]
        });
      });
    });

    const payload = {
      testID: this.props.testID,
      sampleInfo,
      action: "update",
      determinations: [],
      sampleIDs: [],
      pageNumber: this.props.pageNumber,
      pageSize: this.props.pageSize,
      filter
    };
    this.props.saveLDDeterminationsChanged(payload);
    if (rowIndex !== undefined) {
      this.setState({ currentIndex: rowIndex + 1 });
      if (rowIndex < this.props.determinations.tableData.length - 1) {
        const nextWidgetIndex = rowIndex + 1;
        if (this.state.refs[nextWidgetIndex].current) {
          this.state.refs[nextWidgetIndex].current.select();
        }
      }
    }
  };

  toggleDetermination = determinationID => {
    this.props.toggleDetermination(determinationID);
  };

  toggleMaterialMarker(markerMaterialList) {
    this.props.toggleMaterialMarker(markerMaterialList);
  }

  rowClassName = rowIndex => {
    const { selectedRows } = this.state;
    if (selectedRows.includes(rowIndex)) {
      return "highlight-row";
    }
    return null;
  };

  deleteSample = rowIndex => {
    console.log("delete rowindex", rowIndex);

    const filter = Object.values(this.props.filters);
    const { sampleTestID } = this.props.determinations.tableData[rowIndex];
    const payload = {
      testID: this.props.testID,
      sampleInfo: [],
      action: "remove",
      determinations: [],
      sampleIDs: [sampleTestID],
      pageNumber: this.props.pageNumber,
      pageSize: this.props.pageSize,
      filter
    };
    this.setState({ currentIndex: rowIndex });
    this.props.saveLDDeterminationsChanged(payload);
  };

  render() {
    const { columnWidths, headerHeight, rowHeight } = this.state;
    const { statusCode } = this.props;
    const disableMarker = statusCode > 150;

    let { tblWidth, tblHeight } = this.state; // currentIndex
    const { currentIndex } = this.state; // currentIndex

    tblWidth -= 40; // 30; // substracting offsets for aesthetic purpose
    tblHeight -= 400; // 300; // substracting offsets for aesthetic purpose

    if (this.props.sideMenu) {
      tblWidth -= 210;
    } else {
      tblWidth -= 60;
    }

    if (this.props.visibility) tblHeight -= 221;
    if (tblHeight < 200) tblHeight = 200;

    const { tableData, columns, determinations } = this.props.determinations;

    const isSampledeterminationChanged = tableData.some(
      item => item.determinationsChanged.length > 0
    );

    // conditions: if none of the grid column sample's determinations are altered and
    // any of the listed determinations are checked and
    const isAssignMarkerEnabled =
      !isSampledeterminationChanged &&
      determinations.some(item => item.selected);

    const actionColumn = {
      allowFilter: false,
      allowSort: null,
      columnID: "action",
      columnLabel: "Action",
      dataType: "integer",
      editable: false,
      order: 0,
      traitID: null,
      visible: true,
      width: 100
    };

    const finalColumns =
      this.props.importLevel.toLowerCase() === "plot"
        ? [...columns, actionColumn]
        : [...columns];

    return (
      <div className="manage-marker-table">
        <div className="trow marker">
          <div className="tcell">
            <div className="markTitle">
              <button
                onClick={this.assignMarker}
                disabled={!isAssignMarkerEnabled}
                id="assign_marker_btn"
                title="Assign marker"
                className="icon"
              >
                <i className="icon icon-ok-squared" />
                Assign Marker
              </button>
              <button
                onClick={() => this.saveLDDeterminationsChanged()}
                disabled={!isSampledeterminationChanged}
                id="save"
                title="Save"
                className="icon"
              >
                <i className="icon icon-ok-squared" />
                Save
              </button>
            </div>
            <div className="markContainer">
              {determinations.map(mark => (
                <Marker
                  key={`${mark.determinationID}_${
                    mark.columnLabel
                  }_${Math.random * 100}`} /* eslint-disable-line */
                  {...mark}
                  onChange={() =>
                    this.toggleDetermination(mark.determinationID)
                  }
                  disabled={disableMarker}
                />
              ))}
            </div>
          </div>
        </div>
        <Table
          rowHeight={rowHeight}
          rowsCount={(tableData || []).length}
          onColumnResizeEndCallback={this._onColumnResizeEndCallback}
          isColumnResizing={false}
          scrollToRow={currentIndex || 0}
          width={tblWidth}
          height={tblHeight}
          headerHeight={headerHeight}
          // rowClassNameGetter={this.rowClassName}
          {...this.state}
        >
          {finalColumns
            .filter(column => column.visible)
            .map(column => {
              // setting default width or adjusted width
              const fix = column.fixed === 1;
              return (
                <Column
                  key={column.columnID}
                  header={
                    <LDHeaderCell
                      {...this.state}
                      data={column}
                      traitID={column.traitID}
                      label={column.columnLabel}
                      showFilter={this.toggleFilter}
                      fetchData={this.props.fetchLeafDiskMaterialDeterminations}
                    />
                  }
                  columnKey={column.columnID}
                  width={columnWidths[column.columnID] || 0}
                  isResizable
                  fixed={fix}
                  minWidth={column.width}
                  cell={
                    column.columnID === "action" ? (
                      <LDActionCell
                        data={tableData}
                        column={column}
                        deleteSample={this.deleteSample}
                      />
                    ) : (
                      <LDTextCell
                        data={tableData}
                        traitID={column.traitID}
                        markerMaterialMap={{}}
                        toggleMaterialMarker={this.toggleMaterialMarker}
                        onRowClick={this.onRowClick}
                        selectedRows={this.state.selectedRows}
                        column={column}
                        onRowCellClick={this.onRowClick}
                        onEnter={this.saveLDDeterminationsChanged}
                        refs={this.state.refs}
                      />
                    )
                  }
                />
              );
            })}
        </Table>
        <Page
          testID={this.props.testID}
          pageNumber={this.props.determinations.pageInfo.pageNumber}
          pageSize={this.props.determinations.pageInfo.pageSize}
          records={this.props.determinations.pageInfo.grandTotal}
          isBlocking={this.props.dirty}
          pageClicked={this.onPageClick}
          onPageClick={this.checkPage}
          filter={Object.values(this.props.filters)}
          filterLength={Object.keys(this.props.filters).length}
          isBlockingChange={this.props.resetDirtyMarked}
          _fixColumn={this._fixColumn}
          clearFilter={this.clearFilter}
          dirtyMessage={this.props.dirtyMessage}
          total={this.props.determinations.pageInfo}
        />
      </div>
    );
  }
}

// Container
const mapStateToProps = state => ({
  sideMenu: state.sidemenuReducer,
  pageSize: state.assignMarker.determinations.pageInfo.pageSize,
  pageNumber: state.assignMarker.determinations.pageInfo.pageNumber,
  materials: state.assignMarker.materials,
  testID: state.rootTestID.testID,
  testTypeID: state.assignMarker.testType.selected,
  records: state.assignMarker.materials.totalRecords,
  filters: state.assignMarker.leafDiskFilters,
  dirty: state.assignMarker.materials.dirty,
  sampleNumber: state.assignMarker.numberOfSamples.samples,
  sampleRefresh: state.assignMarker.numberOfSamples.refresh,
  selected: state.assignMarker.file.selected,
  total: state.assignMarker.determinations.pageInfo,
  determinations: state.assignMarker.determinations,
  assignLDDetermationSucceeded:
    state.assignMarker.determinations.assignLDDetermationSucceeded,
  filterCleared: state.assignMarker.determinations.filterCleared,
  sampleSaved: state.assignMarker.samples.sampleSaved
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
  resetManageMarker: () => dispatch({ type: "RESET_SCORE" }),
  fetchMaterialDeterminations: payload =>
    dispatch({ type: "FETCH_MATERIAL_DETERMINATIONS", payload }),
  fetchLeafDiskDeterminations: cropcode =>
    dispatch({ type: "FETCH_LEAF_DISK_DETERMINATIONS", cropcode }),
  fetchLeafDiskMaterialDeterminations: payload =>
    dispatch({ type: "FETCH_MATERIAL_DETERMINATIONS", payload }),
  toggleClick: id => dispatch(markerToggle(id)),
  toggleDetermination: determinationID =>
    dispatch({ type: "TOGGLE_DETERMINATION", determinationID }),
  assignLDDeterminations: payload =>
    dispatch({ type: "ASSIGN_LD_DETERMINATIONS", payload }),
  saveLDDeterminationsChanged: payload =>
    dispatch({ type: "SAVE_LD_DETERMINATIONS_CHANGED", payload }),
  resetAssignLDDeterminationSucceededFlag: () =>
    dispatch({ type: "RESET_ASSIGN_LD_DETERMINATION_SUCCEEDED_FLAG" }),
  clearFilters: () => dispatch(clearLeafDiskFilters()),
  resetFilterClearedFlag: () => dispatch({ type: "RESET_FILTER_CLEARED_FLAG" })
});
const ManageDetermination = connect(
  mapStateToProps,
  mapDispatchToProps
)(ManageDeterminationComponent);

ManageDeterminationComponent.defaultProps = {
  selected: {},
  sample: false,
  fixColumn: 0,
  pageNumber: 1,
  pageSize: 150,
  tblHeight: 300,
  tblWidth: 1000,
  dirtyMessage: "",
  filter: {},
  sampleNumber: []
};

ManageDeterminationComponent.propTypes = {
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
  total: PropTypes.any, // eslint-disable-line
  fetchMaterialDeterminations: PropTypes.func.isRequired,
  determinations: PropTypes.any, // eslint-disable-line
  fetchLeafDiskDeterminations: PropTypes.func.isRequired,
  cropSelected: PropTypes.string.isRequired,
  toggleClick: PropTypes.func.isRequired,
  toggleDetermination: PropTypes.func.isRequired,
  assignLDDeterminations: PropTypes.func.isRequired,
  fetchLeafDiskMaterialDeterminations: PropTypes.func.isRequired,
  saveLDDeterminationsChanged: PropTypes.func.isRequired,
  filters: PropTypes.shape({
    [PropTypes.string]: PropTypes.shape({
      name: PropTypes.string,
      value: PropTypes.string,
      expression: PropTypes.string,
      operator: PropTypes.string,
      dataType: PropTypes.string
    })
  }).isRequired, // eslint-disable-line
  assignLDDetermationSucceeded: PropTypes.bool.isRequired,
  resetAssignLDDeterminationSucceededFlag: PropTypes.func.isRequired,
  clearFilters: PropTypes.func.isRequired,
  filterCleared: PropTypes.bool.isRequired,
  resetFilterClearedFlag: PropTypes.func.isRequired,
  resetSaveSampleSucceededFlag: PropTypes.func.isRequired,
  sampleSaved: PropTypes.bool.isRequired,
  importLevel: PropTypes.string.isRequired
};

export default ManageDetermination;
