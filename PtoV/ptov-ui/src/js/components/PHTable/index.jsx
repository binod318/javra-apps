/*!
 *
 * PHTABLE COMPONENT
 * ------------------------------
 * deleteColumn : new function add to CONVERSION SCREEN removes column.
 * opAsParentFunc : new function add to MAIN SCREEN marks data OP as Parent before request.
 *
 * changePage : function help to change page
 * handleRowMouseDown :
 * filterClear : clears all filter applied to current fetch
 * filterRemove : clear the filter clicked for remover
 * filterAdd : adds filter to current fetch
 * filtersort : sorts record asc or desc
 * selectBlur :
 * onNewCropChange :
 * handleDoubleClickItem :
 *
 */
import React from 'react';
import { Table, Column } from 'fixed-data-table-2';
import PropTypes from 'prop-types';

import Header from './components/Header';
import Data from './components/Data';
import Option from './components/Option';

import Filter from './components/Filter';
import Page from './components/Page';

class PHTable extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      filterKey: '',
      columnWidths: {},
      name: props.name,
      without: props.withoutHierarchy
    };
  }
  componentDidMount() {
    window.addEventListener('resize', this.updateDimensions);
    this.updateDimensions();
    if (this.props.columnList) {
      this.createColumn(this.props.columnList);
    }
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.withoutHierarchy !== this.props.withoutHierarchy) {
      this.setState({
        without: nextProps.withoutHierarchy
      });
    }
    if (nextProps.columnList.length !== this.props.columnList.length) {
      this.setState({
        columnList: nextProps.columnList
      });
    }
    if (nextProps.plantList) {
      if (nextProps.plantList.length > 0) {
        this.createColumn(nextProps.columnList);
      }
    }

    if (nextProps.plantList) {
      this.updateDimensions();
    }
    if (nextProps.filterList) {
      this.updateDimensions();
    }
  }
  componentWillUnmount() {
    window.removeEventListener('resize', this.updateDimensions);
  }

  withoutChange = bool => {
    const { without } = this.state;

    if (this.props.withoutHierarchyChange) {
      this.props.withoutHierarchyChange(bool);
    }
  }

  createColumn = columns => {

    const columnWidths = {};
    if (this.props.name === "pedigree") {
      columns.forEach(column => {
        const lbl = column.columnLabel;
        let calWidth = lbl ? lbl.length * 12 : 100;
        calWidth = calWidth > 100 ? calWidth : 90;
        Object.assign(columnWidths, { [lbl]: calWidth + 50 });
      });
      this.setState({
        columnWidths
      });
      return null;
    }

    columns.forEach(column => {
      const lbl = column.traitID ? column.traitID : column.columnLabel;
      let calWidth = lbl.length * 12;
      calWidth = calWidth > 100 ? calWidth : 90;
      Object.assign(columnWidths, { [lbl]: calWidth + 50 });
    });
    this.setState({
      columnWidths
    });
  };
  updateDimensions = () => {
    const _this = this;
    const width = window.document.body.offsetWidth;
    const height = window.document.body.offsetHeight;

    let dec = 110 + this.props.sub;

    _this.setState({
      tblWidth: width - 30,
      tblHeight: height - dec
    });
  };

  getClosest = (elem, selector) => {
    if (!Element.prototype.matches) {
      Element.prototype.matches =
        Element.prototype.matchesSelector ||
        Element.prototype.mozMatchesSelector ||
        Element.prototype.msMatchesSelector ||
        Element.prototype.oMatchesSelector ||
        Element.prototype.webkitMatchesSelector ||
        function (s) {
          var matches = (this.document || this.ownerDocument).querySelectorAll(s),
            i = matches.length;
          while (--i >= 0 && matches.item(i) !== this) { }
          return i > -1;
        };
    }

    // Get the closest matching element
    for (; elem && elem !== document; elem = elem.parentNode) {
      if (elem.matches(selector)) return elem;
    }
    return null;
  };

  _onColumnResizeEndCallback = (newColumnWidth, columnKey) => {
    const { columnList } = this.props;
    const result = columnList.filter( c => c.columnLabel2 == columnKey);
    const matchingKeyName = result[0]["traitID"] || result[0]["columnLabel"] || '';

    this.setState(({ columnWidths }) => {
      return {
        columnWidths: {
          ...columnWidths,
          [matchingKeyName]: newColumnWidth
        }
      };
    });
    /*
    */
  };

  filterKeySet = key => {
    this.setState({
      filterKey: key === this.state.filterKey ? '' : key
    });
  };

  render() {
    const { without, name, tblWidth, tblHeight, filterKey, columnWidths } = this.state;
    const {
      columnList,
      plantList,
      sorting,
      filterList,
      fileStatus,
      opAsParentFunc,
      opasparent,
      popup
    } = this.props;
    const { total, page, size, selectRow } = this.props;
    const { selected, checkList, tableType } = this.props;
    const { handleDoubleClickItem, onNewCropChange, selectBlur } = this.props;

    const dataList = plantList || [];

    /**
     * width fixing for popup and normal window
     */
    let computetWidth = tblWidth;
    if (typeof(popup) !== undefined && popup > 1) {
      computetWidth = popup || 840;
    }

    let SRI = this.props.scrollToRow > 0 ? this.props.scrollToRow : 0;
    let newtblHeight = tblHeight;
    if (name === 'pedigree') {
      if (!this.props.filterList.length) {
        newtblHeight += 35;
      }
      newtblHeight -= 40;
    }

    return (
      <div className="pvttable">
        <Filter
          name={this.props.name}
          without={without}
          withoutChange={this.withoutChange}
          filterList={filterList}
          filterRemove={this.props.filterRemove}
          filterClear={this.props.filterClear}
        />
        <Table
          rowHeight={36}
          headerHeight={40}
          width={computetWidth}
          height={newtblHeight}
          rowsCount={dataList.length}
          onColumnResizeEndCallback={this._onColumnResizeEndCallback}
          isColumnResizing={false}
          scrollToRow={selectRow}
          onRowClick={(event, rowIndex) => {
            const columnKey = this.getClosest(event.target, '.GID');
            const shiftK = event.shiftKey; // ? true : false;
            const ctrlK = event.ctrlKey; // ? true : false;
            const check =
              this.props.checkList && !this.props.checkList.includes(rowIndex);

            if (ctrlK || shiftK || check) {
              this.props.handleRowMouseDown(rowIndex, shiftK, ctrlK, columnKey);
            }
          }}
        >
          {columnList.map((col, i) => {
            const {
              phenomeColID,
              columnLabel,
              columnLabel2,
              traitID,
              refColumn,
              colorCode
            } = col;

            const lbl = traitID || columnLabel;
            let width = columnWidths[lbl] || 130;

            if (columnLabel === 'userSelect') {
              width = 40;
            }

            if (columnLabel === 'GID') {
              width *= 2;
            }


            let matchValue = '';
            filterList.map(f => {
              if (traitID !== null && name !== 'pedigree') {
                if (f.name === traitID) {
                  matchValue = f.value;
                } else {
                  /**
                   * This condition is placed for Pedigree display
                   * Because records in Pedigree got traitID but don'not matches
                   * with column name
                   */
                  matchValue = f.value;
                }
              } else {
                if ((f.name).toString().toLocaleLowerCase() == columnLabel2.toString().toLocaleLowerCase()) {
                  matchValue = f.value;
                }
              }
              return null;
            });

            let key = columnLabel2;
            if (key === 'userSelect') {
              key = `${columnLabel}-${i}`;
            }



            let labelCheck = false;
            if (columnLabel !== undefined) {
              labelCheck =
              columnLabel.toLocaleLowerCase() === 'newcrop' ||
              columnLabel.toLocaleLowerCase() === 'cntryoforigin' ||
              columnLabel.toLocaleLowerCase() === 'prod.segment';
            }

            let fixed = false;
            if (columnLabel !== undefined) {
              fixed =
                columnLabel.toLocaleLowerCase() === 'gid' ||
                columnLabel.toLocaleLowerCase() === 'opasparent' ||
                columnLabel.toLocaleLowerCase() === 'userSelect';
            }


            return (
              <Column
                key={columnLabel}
                fixGrow={1}
                columnKey={key}
                fixed={fixed}
                header={
                  <Header
                    name={name}
                    sorting={sorting}
                    filterSort={this.props.filterSort}
                    column={this.props.columnList}
                    deleteColumn={this.props.deleteColumn}
                    traitID={traitID}
                    colorCode={colorCode}
                    filterList={filterList}
                    filterValue={matchValue}
                    filterKey={filterKey}
                    filterKeySet={this.filterKeySet}
                    filterAdd={this.props.filterAdd}
                    data={dataList}
                    selected={this.props.selected}
                    deleteList={this.props.deleteList}
                  >
                    {columnLabel}
                  </Header>
                }
                cell={
                  tableType === 'active' && labelCheck ? (
                    <Option
                      data={dataList}
                      column={this.state.columnList}
                      traitID={traitID}
                      dClick={handleDoubleClickItem} // changed from doubleclick to single click
                      selected={selected}
                      onNewCropChange={onNewCropChange}
                      selectBlur={selectBlur}
                      checkList={checkList}
                    />
                  ) : (
                    <Data
                      data={dataList}
                      column={this.state.columnList}
                      traitID={traitID}
                      refColumn={refColumn}
                      checkList={checkList}
                      tableType={tableType}
                      fileStatus={fileStatus}
                      opAsParent={opAsParentFunc}
                      opasparentStore={opasparent}
                      without={without}
                      isFilter={filterList.length > 0}
                    />
                  )
                }
                width={width}
                isResizable={true}  // eslint-disable-line
              />
            );
          })}
        </Table>

        <Page
          filterList={[]}
          filterClear={() => {}}
          filterKey=""
          total={total}
          page={page}
          size={size}
          changePage={this.props.changePage}
        />
      </div>
    );
  }
}

PHTable.defaultProps = {
  name: '', // just for ref. which table
  deleteColumn: () => {},
  opAsParentFunc: () => {},
  opasparent: [],
  fileStatus: 100,
  filterList: [],
  columnList: [],
  plantList: [],
  sub: 0,
  tableType: '',
  selected: null,
  selectRow: null,
  total: 0
};
PHTable.propTypes = {
  name: PropTypes.string,  // eslint-disable-line
  deleteColumn: PropTypes.func,
  opAsParentFunc: PropTypes.func,
  opasparent: PropTypes.array, // eslint-disable-line
  fileStatus: PropTypes.number,
  filterList: PropTypes.array, // eslint-disable-line
  columnList: PropTypes.array, // eslint-disable-line
  plantList: PropTypes.array, // eslint-disable-line
  sub: PropTypes.number,
  sorting: PropTypes.object, // eslint-disable-line
  handleDoubleClickItem: PropTypes.func.isRequired,
  onNewCropChange: PropTypes.func.isRequired,
  selectBlur: PropTypes.func.isRequired,
  filterSort: PropTypes.func.isRequired,
  filterAdd: PropTypes.func.isRequired,
  filterRemove: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  handleRowMouseDown: PropTypes.func.isRequired,
  changePage: PropTypes.func.isRequired,
  tableType: PropTypes.string,
  checkList: PropTypes.array, // eslint-disable-line
  selected: PropTypes.object, // eslint-disable-line
  selectRow: PropTypes.number,
  size: PropTypes.number.isRequired,
  page: PropTypes.number.isRequired,
  total: PropTypes.number
};
export default PHTable;
