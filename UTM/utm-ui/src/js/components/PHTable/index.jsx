import React, { Component } from "react";
import PropTypes from "prop-types";
import { Table, Column } from "fixed-data-table-2";

import HeaderCell from "./components/HeaderCell";
import Datacell from "./components/DataCell";
import PlatePlanOverviewAction from "./components/PlatPlanOverviewAction";
import RelationAction from "./components/RelationAction";
import ResultAction from "./components/ResultAction";
import BreederAction from "./components/BreederAction";
import LaboverviewAction from "./components/LaboverviewAction";
import MailAction from "./components/MailAction";
import CTAction from "./components/CTAction";
import ProtocolAction from "./components/ProtocolAction";
import RDToverviewAction from "./components/RDToverviewAction";
import LDOverviewAction from "./components/LDOverviewAction";
import SHOverviewAction from "./components/SHOverviewAction";
import RDTResultAction from "./components/RDTResultAction";
import "./phtable.scss";
import Page from "../Page/Page";

class PHTable extends Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      data: props.data,
      rowHeight: 36,
      visibility: false,
      columnsMapping: props.columnsMapping,
      columnsWidth: props.columnsWidth,
      selectArray: props.selectArray || []
    };

    this._onColumnResizeEndCallback = this._onColumnResizeEndCallback.bind(
      this
    );
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.selectArray) {
      this.setState({ selectArray: nextProps.selectArray });
    }
    if (nextProps.tblWidth !== this.props.tblWidth) {
      this.setState({ tblWidth: nextProps.tblWidth });
    }
    if (nextProps.tblHeight !== this.props.tblHeight) {
      this.setState({ tblHeight: nextProps.tblHeight });
    }
    if (nextProps.data) {
      this.setState({
        data: nextProps.data
      });
    }
  }
  componentDidUpdate(prevProps) {
    if (
      Object.keys(this.props.columnsWidth).length !==
      Object.keys(prevProps.columnsWidth).length
    ) {
      // eslint-disable-next-line react/no-did-update-set-state
      this.setState({ columnsWidth: { ...this.props.columnsWidth } });
    }
  }

  _onColumnResizeEndCallback(newColumnWidth, columnKey) {
    this.setState(({ columnsWidth }) => ({
      columnsWidth: {
        ...columnsWidth,
        [columnKey]: newColumnWidth
      }
    }));
  }

  handle = () => {
    this.setState({
      visibility: !this.state.visibility
    });
  };

  pageClick = pg => this.props.pageChange(pg);

  render() {
    const {
      rowHeight,
      columnsMapping,
      columnsWidth,
      data,
      visibility,

      selectArray
    } = this.state;
    const { columns } = this.props;
    let { tblWidth, tblHeight } = this.state;

    let tblHeaderHeight = 90;
    if (!visibility) tblHeaderHeight = 40;

    tblWidth -= 30;
    if (this.props.sideMenu) {
      tblWidth -= 210;
    } else {
      tblWidth -= 60;
    }
    const { pagesize, total } = this.props;
    const mod = total / pagesize;
    if (mod > 1) {
      tblHeight -= 45;
    }

    tblHeight = tblHeight < 200 ? 200 : tblHeight;

    return (
      <div className="phtable">
        <br />
        <Table
          rowHeight={rowHeight}
          headerHeight={tblHeaderHeight}
          rowsCount={data.length}
          onColumnResizeEndCallback={this._onColumnResizeEndCallback}
          onRowMouseDown={(event, rowIndex) => {
            let shiftK = false;
            let ctrlK = false;
            if (event.ctrlKey) {
              ctrlK = true;
            }
            if (event.shiftKey) {
              shiftK = true;
            }
            if (this.props.selectRow) {
              this.props.selectRow(rowIndex, shiftK, ctrlK);
            }
          }}
          isColumnResizing={false}
          width={tblWidth}
          height={tblHeight}
          {...this.props}
          data={data}
        >
          {columns.map(col => {
            let fixed = 0;
            if (columnsMapping && columnsMapping[col]) {
              fixed = columnsMapping[col].fixed ? 1 : 0;
            }

            let matchValue = "";

            this.props.filter.map(f => {
              if (
                f.name.toString().toLocaleLowerCase() ===
                col.toString().toLocaleLowerCase()
              ) {
                matchValue = f.value;
              }
              return null;
            });

            let mapping = columnsMapping[col];
            if (mapping == null) mapping = this.props.columnsMapping[col];
            return (
              <Column
                key={col}
                columnKey={col}
                header={
                  <HeaderCell
                    {...this.props}
                    value={mapping}
                    activeFilter={visibility}
                    onClick={() => {}}
                    handle={this.handle}
                    filterFetch={this.props.filterFetch}
                    filterValue={matchValue}
                    localFilterAdd={this.props.localFilterAdd}
                    localFilter={this.props.localFilter}
                  />
                }
                flexGrow={fixed}
                cell={({ ...props }) => {
                  const { rowIndex, columnKey } = props;
                  if (columnKey === "Action") {
                    if (this.props.actions.name === "planPlate") {
                      return (
                        <PlatePlanOverviewAction
                          data={data[rowIndex]}
                          ids={rowIndex}
                          onexport={this.props.actions.export}
                          ondelete={this.props.actions.deleteRow}
                          accessRole={this.props.actions.accessRole}
                          isBTR={this.props.actions.isBTR}
                          sampleList={this.props.actions.gotoSampleList}
                        />
                      );
                    }
                    if (this.props.actions.name === "rdtoverview") {
                      return (
                        <div>
                          <RDToverviewAction
                            data={data[rowIndex]}
                            ids={rowIndex}
                            onexport={this.props.actions.export}
                            ondelete={this.props.actions.deleteRow}
                            accessRole={this.props.actions.accessRole}
                          />
                        </div>
                      );
                    }
                    if (this.props.actions.name === "ldoverview") {
                      return (
                        <div>
                          <LDOverviewAction
                            data={data[rowIndex]}
                            ids={rowIndex}
                            onexport={this.props.actions.export}
                            ondelete={this.props.actions.deleteRow}
                            accessRole={this.props.actions.accessRole}
                          />
                        </div>
                      );
                    }
                    if (this.props.actions.name === "shoverview") {
                      return (
                        <div>
                          <SHOverviewAction
                            data={data[rowIndex]}
                            ids={rowIndex}
                            onexport={this.props.actions.export}
                            ondelete={this.props.actions.deleteRow}
                            accessRole={this.props.actions.accessRole}
                          />
                        </div>
                      );
                    }
                    if (this.props.actions.name === "relation") {
                      return (
                        <RelationAction
                          data={data[rowIndex]}
                          role={this.props.role}
                          onUpdate={this.props.actions.edit}
                          onRemove={this.props.actions.delete}
                        />
                      );
                    }
                    if (this.props.actions.name === "result") {
                      return (
                        <ResultAction
                          data={data[rowIndex]}
                          role={this.props.role}
                          ids={rowIndex}
                          onUpdate={this.props.actions.edit}
                          onRemove={this.props.actions.delete}
                        />
                      );
                    }
                    if (this.props.actions.name === "rdt_result") {
                      return (
                        <RDTResultAction
                          data={data[rowIndex]}
                          role={this.props.role}
                          ids={rowIndex}
                          onUpdate={this.props.actions.edit}
                          onRemove={this.props.actions.delete}
                        />
                      );
                    }
                    if (this.props.actions.name === "laboverview") {
                      return (
                        <LaboverviewAction
                          data={data[rowIndex]}
                          ids={rowIndex}
                          onUpdate={this.props.actions.edit}
                          onRemove={() => {}}
                        />
                      );
                    }
                    if (this.props.actions.name === "breeder") {
                      return (
                        <BreederAction
                          data={data[rowIndex]}
                          ids={rowIndex}
                          onUpdate={this.props.actions.edit}
                          onRemove={this.props.actions.delete}
                          rolesRequest={this.props.actions.rolesRequest}
                          rolesManagemasterdatautm={
                            this.props.actions.rolesManagemasterdatautm
                          }
                        />
                      );
                    }
                    if (this.props.actions.name === "mail") {
                      return (
                        <MailAction
                          data={data[rowIndex]}
                          ids={rowIndex}
                          onAdd={this.props.actions.add}
                          onUpdate={this.props.actions.edit}
                          onRemove={this.props.actions.delete}
                        />
                      );
                    }
                    if (this.props.actions.name === "ctmaintain") {
                      return (
                        <CTAction
                          data={data[rowIndex]}
                          ids={rowIndex}
                          onUpdate={this.props.actions.edit}
                          onRemove={this.props.actions.delete}
                        />
                      );
                    }
                    if (this.props.actions.name === "protocol") {
                      return (
                        <ProtocolAction
                          data={data[rowIndex]}
                          ids={rowIndex}
                          onUpdate={this.props.actions.edit}
                        />
                      );
                    }
                  }
                  return (
                    <Datacell
                      value={data[rowIndex][columnKey]}
                      {...props}
                      selectArray={selectArray}
                    />
                  );
                }}
                width={columnsWidth[col] || 200}
                isResizable
                minWidth={100}
              />
            );
          })}
        </Table>

        <Page
          testID={10}
          pageNumber={this.props.pagenumber}
          pageSize={this.props.pagesize}
          records={this.props.total}
          filter={[]}
          onPageClick={() => {}}
          isBlocking={false}
          isBlockingChange={() => {}}
          pageClicked={this.pageClick}
          resetSelect={() => {}}
          clearFilter={this.props.filterClear}
          filterLength={this.props.filter.length}
        />
      </div>
    );
  }
}

PHTable.defaultProps = {
  actions: {},
  fileSource: false,
  selectArray: []
};

PHTable.propTypes = {
  localFilter: PropTypes.any, // eslint-disable-line
  localFilterAdd: PropTypes.any, // eslint-disable-line
  selectArray: PropTypes.array, // eslint-disable-line
  selectRow: PropTypes.func, // eslint-disable-line
  fileSource: PropTypes.bool,
  filterFetch: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  pageChange: PropTypes.func.isRequired,
  data: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  filter: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  columns: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  actions: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  columnsMapping: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  columnsWidth: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  tblWidth: PropTypes.number.isRequired,
  tblHeight: PropTypes.number.isRequired,
  pagenumber: PropTypes.number.isRequired,
  pagesize: PropTypes.number.isRequired,
  total: PropTypes.number.isRequired,
  sideMenu: PropTypes.bool.isRequired
};

export default PHTable;
