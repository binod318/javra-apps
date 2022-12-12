import React from 'react';
import { Table, Column, Cell } from 'fixed-data-table-2';
import PropTypes from 'prop-types';
import Header from './components/Header';
import Action from './components/Action';
import MailAction from './components/MailAction';
import Filter from './components/Filter';
import Page from './components/Page';
import './pvtable.scss';

class PVTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      filterKey: '',
      columnWidths: props.columnWidths
    };
  }

  componentDidMount() {
    window.addEventListener('resize', this.updateDimensions);
    this.updateDimensions();
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.data) {
      this.updateDimensions();
    }
  }

  componentWillUnmount() {
    window.removeEventListener('resize', this.updateDimensions);
  }

  getCell = (rowIndex, columnKey) => {
    const { data } = this.props;
    const value = data[rowIndex][columnKey];
    if (columnKey === 'sameValue') {
      const status = value ? 'Yes' : 'No';
      return <Cell title={status}>{status}</Cell>;
    }
    return <Cell title={value}>{value}</Cell>;
  };

  updateDimensions = () => {
    const _this = this;
    const width = window.document.body.offsetWidth;
    const height = window.document.body.offsetHeight;

    let dec = 110 + this.props.sub;
    if (this.props.filterList.length > 0) {
      dec += 25;
    }

    _this.setState({
      tblWidth: width - 30,
      tblHeight: height - dec
    });
  };

  _onColumnResizeEndCallback = (newColumnWidth, columnKey) => {
    this.setState(({ columnWidths }) => ({
      columnWidths: {
        ...columnWidths,
        [columnKey]: newColumnWidth
      }
    }));
  };

  filterKeySet = key => {
    this.setState({
      filterKey: key === this.state.filterKey ? '' : key
    });
  };

  actionCell = (columnKey) => {
    const { data, total, page, size, filterList, structure } = this.props;
    return columnKey === 'Action' ? (
      <Action
        data={data}
        projesh={100}
        check={structure[columnKey].check || false}
        checkList={this.props.checkList}
        aCheck={this.props.aCheck}
        dataEdit={this.props.dataEdit}
        dataDelete={this.props.dataDelete}
      />
    ) : (
      <MailAction
        data={data}
        projesh={100}
        check={structure[columnKey].check || false}
        checkList={this.props.checkList}
        aCheck={this.props.aCheck}
        dataAdd={this.props.dataAdd}
        dataEdit={this.props.dataEdit}
        dataDelete={this.props.dataDelete}
      />
    )
  };

  render() {
    const { data, total, page, size, filterList, structure } = this.props;
    const { tblWidth, tblHeight, filterKey, columnWidths } = this.state;

    return (
      <div className="pvttable">
        <Filter
          filterList={filterList}
          filterRemove={this.props.filterRemove}
          filterClear={this.props.filterClear}
        />

        <Table
          rowHeight={36}
          headerHeight={40}
          width={tblWidth}
          height={tblHeight}
          rowsCount={data.length}
          onColumnResizeEndCallback={this._onColumnResizeEndCallback}
          isColumnResizing={false}
        >
          {Object.keys(structure).map(columnKey => {
            let filterValue = '';
            if (this.props.filterList.length > 0) {
              filterValue = this.props.filterList.find(
                d => d.name === columnKey
              );
            }
            const width = columnWidths[columnKey] || 200;
            return (
              <Column
                key={columnKey}
                fixed={false}
                flexGrow={structure[columnKey].grow}
                columnKey={columnKey}
                header={
                  <Header
                    sortable={structure[columnKey].sort}
                    filterble={structure[columnKey].filter}
                    check={structure[columnKey].check}
                    filterList={filterList}
                    filterValue={filterValue ? filterValue.value : ''}
                    filterKeySet={this.filterKeySet}
                    filterData={this.props.filterData}
                    filterKey={filterKey}
                    filterAdd={this.props.filterAdd}
                    filterSort={this.props.filterSort}
                    sorting={this.props.sorting}
                    checkAll={this.props.checkAll}
                    checkLength={this.props.checkList.length}
                    size={this.props.size}
                  >
                    {structure[columnKey].name}
                  </Header>
                }
                cell={
                  columnKey === 'Action' || columnKey === 'MailAction' ?
                    this.actionCell(columnKey) :
                    cell => this.getCell(cell.rowIndex, cell.columnKey)
                }

                width={width}
                isResizable
              />
            );
          })}
        </Table>

        <Page
          total={total}
          page={page}
          size={size}
          changePage={this.props.changePage}
          filterList={[]}
          filterClear={this.props.filterClear}
        />
      </div>
    );
  }
}

PVTable.defaultProps = {
  columnWidths: {},
  structure: {},
  sorting: {},
  sub: 0,
  data: [],
  filterList: [],
  checkList: [],
  checkAll: () => {},
  aCheck: () => {}
};
PVTable.propTypes = {
  columnWidths: PropTypes.object, // eslint-disable-line
  structure: PropTypes.object, // eslint-disable-line
  sorting: PropTypes.object, // eslint-disable-line
  data: PropTypes.array, // eslint-disable-line
  filterList: PropTypes.array, // eslint-disable-line
  checkList: PropTypes.array, // eslint-disable-line
  sub: PropTypes.number,
  total: PropTypes.number.isRequired,
  page: PropTypes.number.isRequired,
  size: PropTypes.number.isRequired,
  filterRemove: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  filterData: PropTypes.func.isRequired,
  filterAdd: PropTypes.func.isRequired,
  filterSort: PropTypes.func.isRequired,
  changePage: PropTypes.func.isRequired,
  dataEdit: PropTypes.func.isRequired,
  dataDelete: PropTypes.func.isRequired,
  checkAll: PropTypes.func,
  aCheck: PropTypes.func
};
export default PVTable;
