import React from "react";
import { NavLink } from "react-router-dom";
import PropTypes from "prop-types";
import { v4 as uuidv4 } from "uuid";
import { Table, Column, Cell } from "fixed-data-table-2";
import "fixed-data-table-2/dist/fixed-data-table.css";

import "./TableGrid.scss";

import TextCell from "./TextCell";
import InputCell from "./InputCell";
import InputCellCapacityPlanning from "./InputCellCapacityPlanning";
import HeaderCell from "./HeaderCell";
import LabelCell from "./LabelCell";
import CheckCell from "./CheckCell";
import CollapseCell from "./CollapseCell";
const AC = { textAlign: "center" };

import colors from "../../colors";

class TableGrid extends React.Component {
  constructor(props) {
    super(props);

    this.state = {
      columns: props.columns,
      data: props.data,
      tblWidth: props.tblWidth,
      tblHeight: props.tblHeight,
      footer: props.footer || false,
      collapsedRows: props.collapsedRows,
      scrollToRow: null
    };
    this._isMounted = false;

    this._handleCollapseClick = this._handleCollapseClick.bind(this);
    this._subRowHeightGetter = this._subRowHeightGetter.bind(this);
    this._rowExpandedGetter = this._rowExpandedGetter.bind(this);
  }

  componentDidMount() {
    this._isMounted = true;
  }

  componentWillMount() {
    this._isMounted = false;
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.columns) {
      this.setState({ columns: nextProps.columns });
    }
    if (nextProps.data) {
      this.setState({
        data: nextProps.data,
      });
    }
    if (nextProps.tblWidth !== this.props.tblWidth) {
      this.setState({ tblWidth: nextProps.tblWidth });
    }
    if (nextProps.tblHeight !== this.props.tblHeight) {
      this.setState({ tblHeight: nextProps.tblHeight });
    }
    if (nextProps.collapsedRows !== this.props.collapsedRows) {
      this.setState({ collapsedRows: nextProps.collapsedRows });
    }
  }

  _rowClassNameGetter = (rowIndex) => {
    const { data } = this.props;
    const { UsedFor, group } = data[rowIndex];

    if (data[rowIndex]["IsLabPriority"]) {
      return "prio-row";
    }
    if (UsedFor && UsedFor.toLowerCase() === "par") return "par-row";

    if (group) return "group-row";

    return "";
  };

  drawCell = (Editable, ColumnID, rowIndex) => {
    const { data } = this.state;
    const { changeValue, isChange, focusRef, actionfunc, platePosition} = this.props;
    const grid = this.props.grid || "none";

    const toAllFlag = this.props.tblConfig
      ? this.props.tblConfig.toAllBtn
      : true;

    // DECLUSTER
    if (
      this.props.action !== undefined &&
      this.props.action.name === "labResult"
    ) {
      const ccc = colors && colors[data[rowIndex][ColumnID]];

      const spanStyles = {
        background: ccc,
        height: "10px",
        width: "10px",
        marginRight: "5px",
        borderRadius: "3px",
        float: "left",
        position: "relative",
        top: "5px",
      };

      if(ColumnID === '') {

        const { PatternID } = this.state.data[rowIndex];
        var obj = platePosition.find(o => o.patternID === PatternID);

        if (data[rowIndex]['Sample'] < 30)
          return <CollapseCell
                  callback={this._handleCollapseClick}
                  collapsedRows={this.state.collapsedRows}
                  rowIndex={rowIndex}
                  data={obj}
                />

        return null;
      }

      //Show remarks icon when remarks is present
      if(ColumnID === 'Pat#') {
        return <Cell style= {{ color: ccc }} title={data[rowIndex][ColumnID] || ""}>
          {ccc !== undefined && <span style={spanStyles}></span>}
          {data[rowIndex][ColumnID]}

          {data[rowIndex]['Remarks'] ? <i title="Remark saved" className='icon ib-right icon-commenting' /> : ""}

        </Cell>

      }

      return Editable ? (
        <InputCell
         // toAllFlag={toAllFlag}
          arrayKey={ColumnID}
          data={data}
          change={changeValue}
          isChanged={isChange}
          //applyToAll={this.props.applyToAll}
          blur={this.props.blur}
          focusName={this.props.focusName}
          setFocusName={this.props.setFocusName}
          focusRef={focusRef}
          focusStatus={this.props.focusStatus}
          refFunc={this.props.refFunc}
          rowIndex={rowIndex}
          grid={grid}
        />
      ) : (
        <Cell style={(ColumnID === "Matching Varieties") ? { color: ccc, cursor: "grab" } : { color: ccc }} title={data[rowIndex][ColumnID] || ""}>
          {ccc !== undefined && <span style={spanStyles}></span>}
          {data[rowIndex][ColumnID]}
        </Cell>
      );
    }
    if (
      this.props.action !== undefined &&
      this.props.action.name === "decluster"
    ) {
      const colorCode = colors && colors[data[rowIndex][ColumnID]];

      const cellStyle = {
        display: "flex",
        alignItems: "center",
        background: colorCode,
        color: colorCode ? "white" : "black",
      };
      const spanStyle = {
        background: colorCode,
        height: "10px",
        width: "10px",
        marginRight: "5px",
        borderRadius: "3px",
        float: "left",
        position: "relative",
        top: "3px",
      };

      return (
        <Cell style={{ color: colorCode }}>
          {colorCode !== undefined && <span style={spanStyle}></span>}
          {data[rowIndex][ColumnID]}
        </Cell>
      );
    }

    if (ColumnID === "Action") {
      const { action } = this.props;

      // LAB RESULT PAGE ACTION
      if (action !== undefined && action.name === "labResult_view") {
        if (data[rowIndex] && data[rowIndex].DetAssignmentID) {
          return (
            <Cell style={AC}>
              <NavLink
                exact
                to={`/lab_result/${data[rowIndex].DetAssignmentID}`}
              >
                <i className='icon ib hov icon-eye' />
              </NavLink>
            </Cell>
          );
        }
      }
      // FOLDER PAGE
      if (action !== undefined && action.name === "folder") {
        if (data[rowIndex] && data[rowIndex].DetAssignmentID) {
          return (
            <Cell style={AC}>
              {
                <i
                  className='icon ib hov icon-eye'
                  role='button'
                  onClick={() => action.view(data[rowIndex].DetAssignmentID)}
                />
              }
            </Cell>
          );
        }
        const { open, TestStatusCode } = data[rowIndex];

        let dt = data.find(o => o.TestStatusCode >= 300);
        return (
          <Cell style={AC}>

            <div className= { dt ? "lab-prep-action" : "lab-prep-action-center"}>

              {TestStatusCode >= 300 && (
                <i
                  className="icon ib ig icon-print"
                  role='button'
                  onClick={() => action.print(data[rowIndex].TestID)}
                />
              )}

              <i className={
                  "icon ib ig icon-fix-right " +
                  (!open ? "icon-plus-squared" : "icon-minus-squared")
                }
                role='button'
                onClick={() => action.open(data[rowIndex].id)}
              />

            </div>


          </Cell>
        );
      }

      const { StatusName, MarkerPerVarID } = data[rowIndex];
      if (StatusName === "Active") {
      }
      const act = StatusName === "Active" ? "d" : "a";
      return (
        <Cell style={AC}>
          <div style={{ display: "flex" }}>
            <i
              className={
                "icon ib " +
                (act === "a" ? "ig icon-ok-squared" : "ir icon-cancel")
              }
              role='button'
              onClick={() => actionfunc.delete(MarkerPerVarID, act)}
              title={StatusName}
            />
            &nbsp;
            <i
              className='icon ib icon-pencil'
              role='button'
              onClick={() => actionfunc.edit(MarkerPerVarID, act)}
            />
          </div>
        </Cell>
      );
    }

    const check =
      ColumnID === "RepeatIndicator" ||
      ColumnID === "IsPlanned" ||
      ColumnID === "TraitMarkers";
    const disableStatus =
      ColumnID === "RepeatIndicator" || ColumnID === "TraitMarkers";
    if (ColumnID === "TraitMarkers") {
      const n = `${ColumnID}-${rowIndex}`;

      return (
        <Cell style={{ textAlign: "center" }} className='tableCheck'>
          <div className='tableCheck'>
            <input
              id={n}
              type='checkbox'
              checked={data[rowIndex]["TraitMarkers"] || false}
              onChange={() => {}}
              disabled={true}
            />
            <label htmlFor={n} />
          </div>
        </Cell>
      );
    }
    if (Editable && check) {
      return (
        <CheckCell
          arrayKey={ColumnID}
          data={data}
          disableStatus={disableStatus}
        />
      );
    }
    if (
      false &&
      this.props.action !== undefined &&
      this.props.action.name === "capacityPlanning"
    ) {
      return Editable ? (
        <InputCellCapacityPlanning
          arrayKey={ColumnID}
          data={data}
          rowIndex={rowIndex}
        />
      ) : (
        <LabelCell arrayKey={ColumnID} data={data} rowIndex={rowIndex} />
      );
    }

    return Editable ? (
      <InputCell
        toAllFlag={toAllFlag}
        arrayKey={ColumnID}
        data={data}
        change={changeValue}
        isChanged={isChange}
        applyToAll={this.props.applyToAll}
        blur={this.props.blur}
        focusName={this.props.focusName}
        setFocusName={this.props.setFocusName}
        focusRef={focusRef}
        focusStatus={this.props.focusStatus}
        refFunc={this.props.refFunc}
        rowIndex={rowIndex}
        grid={grid}
      />
    ) : (
      <LabelCell arrayKey={ColumnID} data={data} rowIndex={rowIndex} />
    );
  };

  rowDoubleClicked = (event, rowData) => {
    var data = this.state.data[rowData];
    let copyText = data['Matching Varieties'];

    //Copy value in the clipboard
    if(copyText && copyText != '')
      navigator.clipboard.writeText(copyText);
  }

  _handleCollapseClick(rowIndex) {
    const { collapsedRows } = this.state;
    const shallowCopyOfCollapsedRows = new Set([...collapsedRows]);
    let scrollToRow = rowIndex;
    if (shallowCopyOfCollapsedRows.has(rowIndex)) {
      shallowCopyOfCollapsedRows.delete(rowIndex);
      scrollToRow = null;
    } else {
      //expand
      shallowCopyOfCollapsedRows.add(rowIndex);

      // pass value to parent
      const { data } = this.props;
      const { PatternID} = data[rowIndex];
      this.props._handleExpandClick(PatternID);
    }

    this.setState({
      scrollToRow: scrollToRow,
      collapsedRows: shallowCopyOfCollapsedRows,
    });
  }

  _subRowHeightGetter(index) {
    if(this.state.collapsedRows.has(index)) {
      const { platePosition, data } = this.props;

      if(platePosition.length > 0){
        let plateData = platePosition.find(o => o.patternID === data[index].PatternID)

        if(plateData) {
            let height = 60;
            height += 31 * (plateData.data.length < 1 ? 1 : plateData.data.length)

            return height;

        } else {
          return 80;
        }
      }
      else {
        return 80;
      }
    } else return 0;
  }

  _rowExpandedGetter({ rowIndex, width, height }) {
    if (!this.state.collapsedRows.has(rowIndex)) {
      return null;
    }

    const style = {
      height: height,
      width: width - 2,
    };

    const expandStyle = {
      background: 'white',
      border: '1px solid #d3d3d3',
      boxSizing: 'border-box',
      padding: '5px 28px',
      overflow: 'hidden',
      width: '100%',
      height: '100%',
    };

    //generate column and data format
    const { data, platePosition } = this.props;
    const { PatternID} = data[rowIndex];

    var obj = platePosition.find(o => o.patternID === PatternID);

    if(obj){
      const { columns, data} = obj;
      let { tblWidth } = this.state;

      let tblExpHeight = 45;
      tblExpHeight += 31 * (data.length < 1 ? 1 : data.length);

      return (
        <div style={style}>
          <div style={expandStyle}>

            <Table
              rowHeight={30}
              rowsCount={data.length}
              width={tblWidth}
              height={tblExpHeight}
              headerHeight={30}>
              {columns
              .map((col) => {
                const { ColumnID, Label, Width } = col;
                let cellWidth = 80;
                cellWidth = Width || cellWidth;

                return (
                  <Column
                    key={ColumnID}
                    header={() => {
                      return (
                        <HeaderCell
                          keyValue={ColumnID}
                          view={Label}
                          sort={false}
                          filter={false}
                        />
                      );
                    }}
                    columnKey={ColumnID}
                    width={cellWidth}
                    cell={({rowIndex, ...props}) => (
                      <Cell {...props}>
                        {data[rowIndex][ColumnID]}
                      </Cell>
                    )}

                  />
                );
              })}
            </Table>
          </div>
        </div>
      );
    }

    return null;
  }

  render() {
    const {
      isChange,
      changeValue,
      showApply,
      customWidth,
      sortFunc,
      filterFunc,
    } = this.props;
    const { columns, data } = this.state;
    let { tblWidth, tblHeight, collapsedRows, scrollToRow } = this.state;

    tblWidth -= 30; // 80
    if (this.props.sideMenu) {
      tblWidth -= 210;
    } else {
      tblWidth -= 60;
    }

    tblHeight -= 120;

    //dynamic height for inside table
    if(collapsedRows.size > 0)
    {
      var arr = Array.from(collapsedRows);

      arr.map((index) => {
        tblHeight += 60;
        let plateData = this.props.platePosition.find(o => o.patternID === data[index].PatternID)
        if (plateData){
          tblHeight += 31 * (plateData.data.length < 1 ? 1 : plateData.data.length)
        }
      });
    }

    return (
      <Table
        className='detail-grid'
        scrollToRow={scrollToRow}
        rowHeight={40}
        headerHeight={this.props.headerHeight || 40}
        rowsCount={data.length}
        width={tblWidth}
        height={tblHeight}
        footerHeight={this.state.footer ? 140 : 0}
        {...this.props}
        rowClassNameGetter={this._rowClassNameGetter}
        onRowDoubleClick={this.rowDoubleClicked}
        subRowHeightGetter={this._subRowHeightGetter}
        rowExpanded={this._rowExpandedGetter}
      >
        {columns
          .filter((is) => is.IsVisible)
          .map((col) => {
            const { ColumnID, Label, Editable, sort, filter, id } = col;
            let cellWidth = 80;
            cellWidth = customWidth[ColumnID] || cellWidth;

            const fixed = false;

            // Planning Batches SO
            let grow =
              ColumnID === "BatchOutputDesc" || ColumnID === "PlateNames"
                ? 1
                : 0;

            if (ColumnID === "Remarks") grow = 1;

            return (
              <Column
                key={ColumnID}
                fixed={fixed}
                flexGrow={grow}
                header={() => {
                  if (
                    this.props.action !== undefined &&
                    (this.props.action.name === "decluster" ||
                      this.props.action.name === "labResult")
                  ) {
                    return (
                      <HeaderCell
                        click={showApply}
                        keyValue={ColumnID}
                        view={Label}
                        sort={sort || false}
                        filter={filter || false}
                        filterFunc={filterFunc}
                        sortFunc={sortFunc}
                        isExtraTraitMarker={col.isExtraTraitMarker}
                        activeSorting={this.props.activeSorting}
                      />
                    );
                  }
                  return (
                    <HeaderCell
                      click={showApply}
                      keyValue={ColumnID}
                      view={Label}
                      sort={sort || false}
                      filter={filter || false}
                      filterFunc={filterFunc}
                      sortFunc={sortFunc}
                    />
                  );
                }}
                columnKey={ColumnID}
                width={cellWidth}
                cell={({ rowIndex }) =>
                  this.drawCell(Editable, ColumnID, rowIndex)
                }
                footer={(ColumnID) => {
                  if (!this.state.footer) return null;
                  const { columnKey } = ColumnID;
                  const df = [];
                  this.props.footerData.map((f) => {
                    df.push(
                      <div key={uuidv4()} className='footerCell'>
                        {f[columnKey]}
                      </div>
                    );
                  });
                  return <Cell>{df}</Cell>;
                }}
              />
            );
          })}
      </Table>
    );
  }
}
TableGrid.defaultProps = {
  refFunc: () => {},
  collapsedRows: new Set()
};
TableGrid.propTypes = {
  sideMenu: PropTypes.bool.isRequired,
  data: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  columns: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  isChange: PropTypes.bool.isRequired,
  changeValue: PropTypes.func.isRequired,
  tblHeight: PropTypes.number.isRequired,
  tblWidth: PropTypes.number.isRequired,
};
export default TableGrid;
