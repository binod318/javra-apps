import React, { Component } from "react";
import { connect } from "react-redux";
import { Table, Column } from "fixed-data-table-2";
import PropTypes from "prop-types";
import autoBind from "auto-bind";

import Page from "../../../../../components/Page/Page";
import SHHeaderCell from "./components/SHHeaderCell";
import SHTextCell from "./components/SHTextCell";
import SHActionCell from "./components/SHActionCell";
import { clearSeedHealthFilters } from "../../../actions";
// component
class ManageSeedHealth extends Component {
  constructor(props) {
    super(props);

    this.state = {
      currentIndex: 0,
      columnWidths: { action: 70 },
      fixColumn: props.fixColumn || 1,
      headerHeight: 40,
      rowHeight: 36,
      pageNumber: props.pageNumber || 1,
      pageSize: props.pageSize || 150,
      tblWidth: props.tblWidth || 1000,
      tblHeight: props.tblHeight || 300,
      sortedColumns: [],
      sample: props.sample
    };
    autoBind(this);
  }

  componentDidMount() {
    const payload = {
      filter: [],
      testID: this.props.testID,
      pageSize: 200,
      pageNumber: 1
    };
    this.props.fetchSeedHealthSampleData(payload);
    this.props.resetSaveSampleSucceededFlag();
    this.props.clearFilters();
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.materials.columns.length) {
      // filter columns to show
      const sortedColumns = nextProps.materials.columns.filter(
        col => col.isVisible
      );
      this.setState({ sortedColumns });
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
    // sampleSaved flag is set when data is saved,
    // so reload the grid data
    if (
      this.props.sampleSaved &&
      this.props.sampleSaved !== prevProps.sampleSaved
    ) {
      const payload = {
        filter: Object.values(this.props.filter),
        testID: this.props.testID,
        pageSize: this.props.samples.pageInfo.pageSize,
        pageNumber: this.props.samples.pageInfo.pageNumber
      };
      this.props.fetchSeedHealthSampleData(payload);
      this.props.resetSaveSampleSucceededFlag();
    }

    if (
      (this.props.samples.columns.length > 0 &&
        Object.keys(this.state.columnWidths).length === 1) ||
      JSON.stringify(this.props.samples.columns) !==
        JSON.stringify(prevProps.samples.columns)
    ) {
      // prepopulate columnWidths from columns data
      const { columnWidths } = this.state;
      this.props.samples.columns
        .filter(item => item.visible)
        .forEach(item => {
          columnWidths[item.columnID] = item.width || 100;
        });

      // eslint-disable-next-line react/no-did-update-set-state
      this.setState({ columnWidths });
    }
  }

  onPageClick = pg => {
    this.setState({ pageNumber: pg });
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
  };

  clearFilter = () => {
  };

  checkPage = payload => {
    this.props.fetchSeedHealthSampleData(payload);
  };

  changeScrollIndex = currentIndex => {
    this.setState({ currentIndex });
  };

  deleteSample = rowIndex => {
    const { testID } = this.props;
    const { sampleID, materialID } = this.props.samples.tableData[rowIndex];
    const payload = {
      testID,
      sampleID,
      materials: [materialID],
      action: "remove"
    };
    this.props.deleteSample(payload);
  };

  render() {
    const { columnWidths, headerHeight, rowHeight } = this.state;

    let { tblWidth, tblHeight } = this.state; // currentIndex
    const { currentIndex } = this.state; // currentIndex

    tblWidth -= 40; // 30; // substracting offsets for aesthetic purpose
    tblHeight -= 230; // 300; // substracting offsets for aesthetic purpose

    if (this.props.sideMenu) {
      tblWidth -= 210;
    } else {
      tblWidth -= 60;
    }

    if (this.props.visibility) tblHeight -= 146;
    if (tblHeight < 200) tblHeight = 200;

    const { tableData, columns } = this.props.samples;

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
      this.props.sampleType === "seedcluster"
        ? [...columns, actionColumn]
        : [...columns];

    const data = tableData || [];

    return (
      <div className="manage-marker-table">
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
          {finalColumns
            .filter(column => column.visible)
            .map(column => (
              <Column
                key={column.columnID}
                header={
                  <SHHeaderCell
                    {...this.state}
                    data={column}
                    traitID={column.traitID}
                    label={column.columnLabel}
                    showFilter={this.toggleFilter}
                    fetchData={this.props.fetchSeedHealthSampleData}
                  />
                }
                columnKey={column.columnID}
                width={columnWidths[column.columnID] || 0}
                isResizable
                fixed={false}
                minWidth={column.width}
                cell={
                  column.columnID === "action" ? (
                    <SHActionCell
                      data={data}
                      column={column}
                      deleteSample={this.deleteSample}
                    />
                  ) : (
                    <SHTextCell
                      data={data}
                      traitID={column.traitID}
                      markerMaterialMap={this.props.materials.markerMaterialMap}
                      column={column}
                    />
                  )
                }
              />
            ))}
        </Table>
        <Page
          testID={this.props.testID}
          pageNumber={this.state.pageNumber}
          pageSize={this.props.pageSize}
          records={this.props.records}
          filter={Object.values(this.props.filter)}
          filterLength={Object.keys(this.props.filter).length}
          onPageClick={this.checkPage}
          isBlocking={this.props.dirty}
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
  pageSize: state.assignMarker.samples.pageInfo.pageSize,
  materials: state.assignMarker.materials,
  testID: state.rootTestID.testID,
  testTypeID: state.assignMarker.testType.selected,
  records: state.assignMarker.samples.pageInfo.grandTotal,
  filter: state.assignMarker.seedHealthFilters,
  dirty: state.assignMarker.materials.dirty,
  selected: state.assignMarker.file.selected,
  total: state.assignMarker.samples.pageInfo,
  samples: state.assignMarker.samples,
  sampleSaved: state.assignMarker.samples.sampleSaved
});
const mapDispatchToProps = dispatch => ({
  fetchSeedHealthSampleData: payload => {
    dispatch({ type: "FETCH_SEED_HEALTH_SAMPLE_DATA", payload });
  },
  clearFilters: () => dispatch(clearSeedHealthFilters()),
  deleteSample: payload => {
    dispatch({ type: "DELETE_SEED_HEALTH_SAMPLE", payload });
  }
});
const ManageMarkerTable = connect(
  mapStateToProps,
  mapDispatchToProps
)(ManageSeedHealth);

ManageSeedHealth.defaultProps = {
  selected: {},
  sample: false,
  fixColumn: 0,
  pageNumber: 1,
  pageSize: 150,
  tblHeight: 300,
  tblWidth: 1000,
  dirtyMessage: "",
  filter: {}
};

ManageSeedHealth.propTypes = {
  selected: PropTypes.object, // eslint-disable-line
  sample: PropTypes.bool,
  testTypeID: PropTypes.number.isRequired,
  testID: PropTypes.number.isRequired,
  fixColumn: PropTypes.number,
  pageSize: PropTypes.number,
  pageNumber: PropTypes.number,
  tblWidth: PropTypes.number,
  tblHeight: PropTypes.number,
  materials: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types

  sideMenu: PropTypes.bool.isRequired,
  visibility: PropTypes.bool.isRequired,

  dirty: PropTypes.bool.isRequired,
  dirtyMessage: PropTypes.string,
  // resetDirtyMarked: PropTypes.func.isRequired,
  records: PropTypes.number.isRequired,
  filter: PropTypes.any, // eslint-disable-line react/forbid-prop-types
  total: PropTypes.any, // eslint-disable-line
  fetchSeedHealthSampleData: PropTypes.func.isRequired,
  samples: PropTypes.any.isRequired, // eslint-disable-line
  clearFilters: PropTypes.func.isRequired,
  deleteSample: PropTypes.func.isRequired,
  sampleSaved: PropTypes.bool.isRequired,
  resetSaveSampleSucceededFlag: PropTypes.func.isRequired,
  sampleType: PropTypes.string.isRequired
};

export default ManageMarkerTable;
