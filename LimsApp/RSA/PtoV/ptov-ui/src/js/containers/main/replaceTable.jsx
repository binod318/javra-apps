import React, { Component } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";

import PHTable from "../../components/PHTable";

import { replaceSave } from "./action";

class ReplaceTable extends Component {
  constructor(props) {
    super(props);
    this.state = {
      baseGid: props.baseGid,
      pedigreeList: props.pedigree,
      columnList: props.column,
      size: props.pageSize,
      filterList: props.filterList,
      sorting: props.sort,
      checkList: [],
      selectedRow: null,
      selected: {},
      selectedNodes: props.selectedNodes || [].concat([props.gid])
    };
  }

  componentDidMount() {
    const { backwardGen, forwardGen } = window.pedigree;
    const includeChildFrom = null;
    const parentNode = 0;
    const parentLevel = null;
    if (this.props.pedigree.length === 0) {
      this.props.getPedigree(
        this.props.gid,
        this.props.baseGid,
        backwardGen,
        forwardGen,
        includeChildFrom,
        parentNode,
        parentLevel
      );
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.selectedNodes.length !== this.props.selectedNodes) {
      this.setState({
        selectedNodes: nextProps.selectedNodes
      });
    }
    if (nextProps.column.length !== this.props.column.length) {
      nextProps.column.forEach(c => {
        if (c.columnLabel === "Stem" && nextProps.stem !== "") {
          const obj = {
            display: c.columnLabel,
            name: c.columnLabel2,
            value: nextProps.stem,
            expression: "contains",
            operator: "and"
          };
          this.props.stemKeySet(c.columnLabel2);
          this.filterAdd(obj);
        }
      });
    }
    if (nextProps.refresh !== this.props.refresh) {
      let { selectedRow } = this.state;
      if (selectedRow === null) {
        nextProps.pedigree.map((x, i) => {
          if (x.lvl === "0") {
            selectedRow = i;
          }
          return null;
        });
      }

      this.setState({
        columnList: nextProps.column,
        pedigreeList: nextProps.pedigree
      });
      if (
        !nextProps.column.filter(c => c.columnLabel.toLowerCase() === "stem")
          .length
      ) {
        nextProps.filterClear();
      }
    }

    if (nextProps.filterChange !== this.props.filterChange) {
      this.setState({
        filterList: nextProps.filterList,
        selectedRow: null,
        checkList: []
      });
    }
  }

  handleRowMouseDown = (rowIndex, shiftK, ctrlK, columnKey) => {
    const { checkList, baseGid, filterList } = this.state;
    const NewList = [];
    if (!checkList.includes(rowIndex)) {
      NewList.concat(checkList);
      NewList.push(rowIndex);
    }
    this.setState({
      checkList: NewList,
      selectedRow: rowIndex
    });

    if (columnKey !== null) {
      const filter = {};
      filterList.map(i => {
        const { name, value } = i;
        Object.assign(filter, { [name]: value });
        return null;
      });

      let filterData = [];
      filterData = this.state.pedigreeList.filter(item => {
        for (var key in filter) {
          const itemLower = item[key] ? item[key].toString().toLowerCase() : "";
          const filterLower = filter[key]
            ? filter[key].toString().toLowerCase()
            : "";
          const wildFilter = !itemLower.includes(filterLower);
          if (item[key] === undefined || wildFilter) return false;
        }
        return true;
      });

      const selectedRow = filterData[rowIndex];
      const { selectedNodes } = this.state;
      const includeChildFrom = rowIndex;
      if (!this.state.selectedNodes.includes(selectedRow.GID * 1)) {
        if (selectedRow.parentNode !== null) {
          const backwardGen = 0;
          const forwardGen =
            selectedRow.parentNode === 0
              ? 1
              : window.pedigree.forwardGen + selectedRow.parentLevel;
          const parentNode = selectedRow.parentNode + 1;
          const parentLevel =
            selectedRow.parentNode === 0
              ? Math.abs(selectedRow.lvl)
              : selectedRow.parentLevel;
          this.props.selectedNodesFunc([...selectedNodes, selectedRow.GID * 1]);

          // TODO remove fetch function
          this.props.getPedigree(
            selectedRow.GID,
            baseGid,
            backwardGen,
            forwardGen,
            includeChildFrom,
            parentNode,
            parentLevel
          );
        }
      }
    }
  };

  filterAdd = obj => {
    this.props.filterAdd(obj);
  };
  filterRemove = name => {
    if (name === this.props.stemKey) {
      this.props.stemSet("");
    }
    this.props.filterRemove(name);
  };
  filterClear = () => {
    this.props.stemSet("");
    this.props.filterClear();
  };
  changePage = pageNumber => {
    const { size } = this.state;
    this.fetchData(pageNumber, size);
  };

  fetchData = (page, size) => {
    this.props.getPedigree(page, size);
  };

  saveReplaceLot = () => {
    const { replaceNode } = this.props;
    const { pedigreeList, selectedRow, filterList } = this.state;

    const filter = {};
    filterList.map(i => {
      const { name, value } = i;
      Object.assign(filter, { [name]: value });
      return null;
    });

    let filterData = [];
    filterData = pedigreeList.filter(item => {
      for (var key in filter) {
        const itemLower = item[key] ? item[key].toString().toLowerCase() : "";
        const filterLower = filter[key]
          ? filter[key].toString().toLowerCase()
          : "";
        const wildFilter = !itemLower.includes(filterLower);
        if (item[key] === undefined || wildFilter) return false;
      }
      return true;
    });

    const { GID: LotGID, lvl: Level, lotID: PhenomeLotID } = filterData[
      selectedRow
    ];

    const GID = replaceNode;
    const Data = {};

    Object.keys(filterData[selectedRow]).map(item => {
      if (
        item.substring(0, 3) === "GER" &&
        filterData[selectedRow][item].length > 0 &&
        this.state.columnList.some(
          ({ ID, exclude }) => ID === item && exclude === false
        )
      ) {
        // desc
        const { desc } = this.state.columnList.find(({ ID }) => ID === item);
        Data[desc] = filterData[selectedRow][item];
      }
      return null;
    });

    if (
      confirm(`Are you sure to assign new Lot ${LotGID} to GID ${replaceNode}?`)
    ) {
      this.props.saveChange(GID, LotGID, PhenomeLotID, Level, Data);
    }
  };

  closeReplaceLot = () => {
    this.props.close();
    this.props.resetPage();
    this.props.filterClear();
  };

  select = () => console.log("select row");

  render() {
    const { mWidth, replaceNode } = this.props;
    const { pedigreeList, columnList, filterList, checkList } = this.state;
    const { sorting, selected, selectedRow } = this.state;

    const checkListLength = checkList.length;
    let SRI = 0;
    SRI = pedigreeList.findIndex(x => x.lvl === 0);
    const modWidth = mWidth - 100 < 900 ? 900 : mWidth;
    const tableWidth = modWidth - 30;
    if (columnList.length === 0) return null;

    const filter = {};
    filterList.map(i => {
      const { name, value } = i;
      Object.assign(filter, { [name]: value });
      return null;
    });

    let filterData = [];
    filterData = pedigreeList.filter(item => {
      for (var key in filter) {
        const itemLower = item[key] ? item[key].toString().toLowerCase() : "";
        const filterLower = filter[key]
          ? filter[key].toString().toLowerCase()
          : "";
        const wildFilter = !itemLower.includes(filterLower);
        if (item[key] === undefined || wildFilter) return false;
      }
      return true;
    });

    return (
      <div className="formWrap" style={{ width: `${modWidth}px` }}>
        <div className="formTitle">
          Replace Lot, GID {replaceNode}
          <button onClick={this.closeReplaceLot}>
            <i className="icon icon-cancel" />
          </button>
        </div>
        <div className="fo rmBody" style={{ padding: 0 }}>
          <div>
            <PHTable
              name="pedigree"
              sub={40}
              filterList={filterList}
              plantList={filterData}
              columnList={columnList}
              sorting={sorting}
              total={this.props.total}
              page={this.props.pageNumber}
              size={this.props.pageSize}
              filterSort={() => {}}
              filterAdd={this.filterAdd}
              filterRemove={this.filterRemove}
              filterClear={this.filterClear}
              changePage={this.changePage}
              handleRowMouseDown={this.handleRowMouseDown}
              selectRow={selectedRow}
              selected={selected}
              checkList={checkList}
              handleDoubleClickItem={() => {}}
              onNewCropChange={() => {}}
              selectBlur={() => {}}
              tableType="active"
              opAsParentFunc={() => {}}
              opasparent={[]}
              popup={tableWidth}
              scrollToRow={SRI}
            />
          </div>
        </div>
        <div className="formAction">
          <button onClick={this.closeReplaceLot}>Close</button>
          <button
            disabled={checkListLength === 0}
            onClick={this.saveReplaceLot}
          >
            Save Lot Change
          </button>
        </div>
      </div>
    );
  }
}

ReplaceTable.defaultProps = {
  pedigree: [],
  column: [],
  filterList: [],
  sort: {},
  stem: "",
  stemKey: "",
  replaceNode: "",
  mWidth: 0
};
ReplaceTable.propTypes = {
  gid: PropTypes.number.isRequired,
  baseGid: PropTypes.number.isRequired,
  pedigree: PropTypes.array, // eslint-disable-line
  filterChange: PropTypes.bool.isRequired,
  total: PropTypes.number.isRequired,
  pageSize: PropTypes.number.isRequired,
  pageNumber: PropTypes.number.isRequired,
  sort: PropTypes.object, // eslint-disable-line
  column: PropTypes.array, // eslint-disable-line
  filterList: PropTypes.array, // eslint-disable-line
  refresh: PropTypes.bool.isRequired,

  getPedigree: PropTypes.func.isRequired,
  stem: PropTypes.string,
  stemKeySet: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  resetPage: PropTypes.func.isRequired,

  stemKey: PropTypes.string,
  stemSet: PropTypes.func.isRequired,
  filterRemove: PropTypes.func.isRequired,
  replaceNode: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  filterAdd: PropTypes.func.isRequired,
  close: PropTypes.func.isRequired,
  saveChange: PropTypes.func.isRequired,
  mWidth: PropTypes.number
};

const mapState = state => ({
  pedigree: state.pedigree.pedigree,
  column: state.pedigree.column,
  filterChange: state.pedigree.total.filterChange,
  total: state.pedigree.total.total,
  pageNumber: state.pedigree.total.pageNumber,
  pageSize: state.pedigree.total.pageSize,
  filterList: state.pedigree.filter,
  sort: state.main.sort,
  refresh: state.pedigree.refresh,
  selectedNodes: state.pedigree.pedigreeNode.selectedNodes
});
const mapDispatch = dispatch => ({
  replace: () => {
    console.log("place replace");
  },
  getPedigree: (
    gid,
    baseGid,
    backwardGen,
    forwardGen,
    includeChildFrom,
    parentNode,
    parentLevel
  ) => {
    dispatch({
      type: "GET_PEDIGREE",
      gid,
      baseGid,
      backwardGen,
      forwardGen,
      includeChildFrom,
      parentNode,
      parentLevel
    });
  },
  resetPage: () => dispatch({ type: "PEDIGREE_RESET" }),
  filterAdd: obj => dispatch({ type: "FILTER_PEDIGREE_ADD", ...obj }),
  filterRemove: name => dispatch({ type: "FILTER_PEDIGREE_REMOVE", name }),
  filterClear: () => dispatch({ type: "FILTER_PEDIGREE_CLEAR" }),
  saveChange: (GID, LotGID, PhenomeLotID, Level, Data) =>
    dispatch(replaceSave(GID, LotGID, PhenomeLotID, Level, Data)),
  selectedNodesFunc: selectedNodes => {
    dispatch({
      type: "PEDIGREE_VIEW_SELECTEDNODES",
      selectedNodes
    });
  }
});
export default connect(
  mapState,
  mapDispatch
)(ReplaceTable);
