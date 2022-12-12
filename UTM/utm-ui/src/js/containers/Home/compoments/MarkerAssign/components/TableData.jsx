import React from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import { Table, Column } from "fixed-data-table-2";
import "fixed-data-table-2/dist/fixed-data-table.css";
import HeaderCell from "./HeaderCell";
import MyCell from "./MyCell";
import NumberComponent from "./NumberCell";

class TableDataComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      columnWidths: {},
      fixColumn: props.fixColumn,
      headerHeight: 40,
      rowHeight: 36,
      pageNumber: props.pageNumber,
      pageSize: props.pageSize,
      tblCellWidth: props.tblCellWidth,
      tblWidth: props.tblWidth,
      tblHeight: props.tblHeight,
      markerLength: props.markerLength,

      filter: props.filter,
      localFilter: props.filter,

      selectArray: props.selectArray || []
    };
    this._onColumnResizeEndCallback = this._onColumnResizeEndCallback.bind(
      this
    );
    this._filter = this._filter.bind(this);
    this._columnSize = this._columnSize.bind(this);
  }

  componentWillMount() {
    const { columnList } = this.props;
    const obj = this._columnSize(columnList);

    this.setState({ columnWidths: { ...obj } });
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.filter) {
      this.setState({
        filter: nextProps.filter,
        localFilter: nextProps.filter
      });
    }
    if (nextProps.filter.length !== this.props.filter.length) {
      this.props.setIndexArray(null);
    }
    if (nextProps.fixColumn !== this.props.fixColumn) {
      this.setState({ fixColumn: nextProps.fixColumn });
    }

    if (nextProps.columnList.length !== this.props.columnList.length) {
      const { columnList } = this.props;
      const obj = this._columnSize(columnList);
      this.setState({ columnWidths: { ...obj } });
    }
    if (nextProps.pageNumber !== this.props.pageNumber) {
      this.setState({ pageNumber: nextProps.pageNumber });
    }
    if (nextProps.pageSize !== this.props.pageSize) {
      this.setState({ pageSize: nextProps.pageSize });
    }
    if (nextProps.tblWidth) {
      this.setState({ tblWidth: nextProps.tblWidth });
    }
    if (nextProps.tblHeight) {
      this.setState({ tblHeight: nextProps.tblHeight });
    }
    if (nextProps.markerLength !== this.props.markerLength) {
      this.setState({ markerLength: nextProps.markerLength });
    }

    if (nextProps.selectArray.length) {
      this.setState({ selectArray: nextProps.selectArray });
    }

    if (nextProps.scoreRefresh !== this.props.scoreRefresh) {
      this.setState({
        leafDiskMaterialMap: nextProps.leafDiskMaterialMap,
        scoreRefresh: nextProps.scoreRefresh
      });
    }
  }

  _columnSize(fields) {
    // eslint-disable-line
    const obj = {};
    fields.map(d => {
      const { columnLabel } = d;
      const nW = columnLabel.length * 8 + 20;
      obj[d.columnLabel] = nW < 120 ? 140 : nW;
      return null;
    });
    return obj;
  }

  _onColumnResizeEndCallback(newColumnWidth, columnKey) {
    this.setState(({ columnWidths }) => ({
      columnWidths: {
        ...columnWidths,
        [columnKey]: newColumnWidth
      }
    }));
  }

  // JUST SHOW AND HIDE FILTER SECTION
  _filter() {
    const hh = this.state.headerHeight;
    this.setState({
      headerHeight: hh === 40 ? 90 : 40
    });
  }

  localFilterAdd = (name, value) => {
    const { localFilter } = this.state;

    const obj = {
      name,
      value,
      expression: "contains",
      operator: "and",
      dataType: "NVARCHAR(255)"
    };

    const check = localFilter.find(d => d.name === obj.name);
    let newFilter = "";
    if (check) {
      newFilter = localFilter.map(item => {
        if (item.name === obj.name) {
          return { ...item, value: obj.value };
        }
        return item;
      });
      this.setState({ localFilter: newFilter });
    } else {
      this.setState({ localFilter: localFilter.concat(obj) });
    }
  };

  _rowClassNameGetter = rowIndex => {
    const { selectArray } = this.props;
    if (selectArray.includes(rowIndex)) {
      return "highlight-row";
    }
    return null;
  };

  selectRow = (rowIndex, shift, ctrl) => {
    const { selectArray } = this.state;
    const match = selectArray.includes(rowIndex);
    const index = rowIndex;

    // CHECKING IF THE ROW IS FIXED OR NOT
    this.props.selectedChange(index, shift, match, ctrl);
  };

  tabelCellSelection = (data, col) => {
    const disabled = this.props.statusCode > 150;
    //if leafdisk and column name is #plants then make cell updatable for numeric values
    if (
      this.props.testTypeID === 9 &&
      this.props.importLevel === "CROSSES/SELECTION" &&
      col.columnLabel === "#plants"
    ) {
      return (
        <NumberComponent
          selectedArray={this.state.selectArray}
          data={data}
          leafDiskMaterialMap={this.props.leafDiskMaterialMap}
          refresh={this.state.scoreRefresh}
          disabled={disabled}
        />
      );
    }

    return (
      <MyCell data={data} traitID={col.traitID} click={this._onRowClick} />
    );
  };

  render() {
    const {
      tblCellWidth,
      // fixColumn,
      columnWidths,
      headerHeight,
      rowHeight
    } = this.state;
    let { tblWidth, tblHeight } = this.state;
    const { markerLength } = this.state;

    const {
      sideMenu,
      columnList: columns,
      dataList: data,
      markerShow,
      visibility,
      testTypeID,
      sampleType,
      markerstatus
    } = this.props;

    if (sideMenu) {
      tblWidth -= 210;
    } else {
      tblWidth -= 60;
    }
    tblWidth -= 30;

    if (markerLength === 0) {
      tblHeight -= 160;
    } else {
      tblHeight -= 320;
    }

    if (!markerShow) {
      tblHeight += 65;
    } else {
      tblHeight -= 40; // 40
    }
    // if SelectFileAttribute in visible
    if (visibility) {
      if (testTypeID == 10)
        tblHeight -= 146;
      else
        tblHeight -= 220;
    }
    if (testTypeID === 2 || testTypeID === 4 || testTypeID === 5) {
      tblHeight -= 60;
    }
    if (testTypeID === 6 && !markerstatus) tblHeight -= 60;
    tblHeight -= 40;
    if (tblHeight < 200) tblHeight = 200;

    if (testTypeID === 9 || testTypeID === 10) tblHeight -= 50;

    if(testTypeID === 10 && sampleType != 'seedcluster')
    tblHeight += 60;

    return (
      <div style={{ zIndex: 0, position: "relative" }}>
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
            let shiftK = false;
            let ctrlK = false;
            if (event.ctrlKey) ctrlK = true;
            if (event.shiftKey) shiftK = true;
            this.selectRow(rowIndex, shiftK, ctrlK);
          }}
        >
          {columns.map(d => {
            const minWidth = 120;
            const compWidth =
              columnWidths[d.columnLabel] ||
              d.columnLabel.length * 10 ||
              minWidth;
            const width = compWidth < minWidth ? minWidth : compWidth;
            const { traitID } = d;
            const fix = d.fixed === 1; //
            const colKey = d.traitID || d.columnLabel;
            return (
              <Column
                key={d.columnLabel}
                header={
                  <HeaderCell
                    {...this.state}
                    data={
                      d // eslint-disable-line
                    }
                    traitID={traitID}
                    label={d.columnLabel}
                    showFilter={this._filter}
                    localFilterAdd={this.localFilterAdd}
                    localFilter={this.state.localFilter}
                    setIndexArray={this.props.setIndexArray}
                  />
                }
                columnKey={colKey}
                width={width}
                isResizable
                fixed={fix}
                minWidth={tblCellWidth}
                cell={this.tabelCellSelection(data, d)}
              />
            );
          })}
        </Table>
      </div>
    );
  }
}

const mapStateToProps = state => ({
  sideMenu: state.sidemenuReducer,
  markerLength: state.assignMarker.marker.length,
  columnList: state.assignMarker.column,
  dataList: state.assignMarker.data
});

TableDataComponent.defaultProps = {
  localFilter: [],
  filter: [],
  // markerLength: 0,
  selected: null,
  plantList: [],
  plantSuggestions: [],
  selectArray: [],
  suggestions: [],
  well: [],
  wellTypeID: [],
  deleteCall: null,
  isBlockingChange: null,
  pageClick: null,
  selectArrayChange: null,
  selectedChange: null,
  show_error: null,
  move: null,
  confirmDial: null,
  goToAssignMarker: null,
  isBlocking: null,
  plantID: null,
  plantValue: null,
  remarkRequired: null,
  testTypeName: null,
  wellValue: null
};
TableDataComponent.propTypes = {
  visibility: PropTypes.any, // eslint-disable-line
  markerShow: PropTypes.any, // eslint-disable-line
  sideMenu: PropTypes.bool.isRequired,
  setIndexArray: PropTypes.func.isRequired,
  localFilter: PropTypes.array, // eslint-disable-line
  filter: PropTypes.array, // eslint-disable-line
  fixColumn: PropTypes.any, // eslint-disable-line
  markerLength: PropTypes.number.isRequired,
  // fixColumn: PropTypes.number.isRequired,
  pageNumber: PropTypes.number.isRequired,
  columnLength: PropTypes.number.isRequired,
  pageSize: PropTypes.number.isRequired,
  selected: PropTypes.number,
  statusCode: PropTypes.number.isRequired,
  tblHeight: PropTypes.number.isRequired,
  tblWidth: PropTypes.number.isRequired,
  tblCellWidth: PropTypes.number.isRequired,
  testID: PropTypes.number.isRequired,
  testTypeID: PropTypes.number.isRequired,
  columnList: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  dataList: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  plantList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  plantSuggestions: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  selectArray: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  statusList: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  suggestions: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  well: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  wellTypeID: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  deleteCall: PropTypes.func,
  isBlockingChange: PropTypes.func,
  pageClick: PropTypes.func,
  selectArrayChange: PropTypes.func,
  selectedChange: PropTypes.func,
  show_error: PropTypes.func,
  move: PropTypes.func,
  confirmDial: PropTypes.bool,
  goToAssignMarker: PropTypes.bool,
  isBlocking: PropTypes.bool,
  markerstatus: PropTypes.bool.isRequired,
  plantID: PropTypes.string,
  plantValue: PropTypes.string,
  remarkRequired: PropTypes.string,
  testTypeName: PropTypes.string,
  wellValue: PropTypes.string
};

const TableData = connect(mapStateToProps)(TableDataComponent);
export default TableData;
