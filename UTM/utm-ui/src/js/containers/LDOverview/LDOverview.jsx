import React from "react";
import { confirmAlert } from "react-confirm-alert"; // Import
import PropTypes from "prop-types";
import PHTable from "../../components/PHTable";
import { getDim } from "../../helpers/helper";

class LDOverviewComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      // relationList: props.relation,
      filter: props.filter,
      localFilter: props.filter,
      selectArray: [],
      active: props.active,
      columns: props.columns
    };
  }

  componentDidMount() {
    const { pagenumber, pagesize, filter, active } = this.props;
    this.props.fetchData(pagenumber, pagesize, filter, active);
    window.addEventListener("resize", this.updateDimensions);
    this.updateDimensions();
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.active !== this.props.active) {
      this.setState({ active: nextProps.active });
      const { pagesize, filter, active } = nextProps;
      this.props.fetchData(1, pagesize, filter, active);
    }
    if (nextProps.data) {
      this.updateDimensions();
    }
    if (nextProps.filter.length !== this.props.filter) {
      this.setState({
        filter: nextProps.filter
      });
    }
    if (nextProps.columns !== this.props.columns) {
      this.setState({
        columns: nextProps.columns
      });
    }
  }

  componentWillUnmount() {
    window.removeEventListener("resize", this.updateDimensions);
  }

  updateDimensions = () => {
    const dim = getDim();
    this.setState({
      tblWidth: dim.width,
      tblHeight: dim.height
    });
  };

  filterFetch = () => {
    const { pagesize, active } = this.props;
    const { localFilter } = this.state;
    this.props.fetchData(1, pagesize, localFilter, active);
  };

  filterClear = () => {
    const { pagesize, active } = this.props;
    this.setState({ localFilter: [] });
    this.props.filterClear();
    this.props.fetchData(1, pagesize, [], active);
  };

  pageClick = pg => {
    const { pagesize, filter, active } = this.props;
    this.props.fetchData(pg, pagesize, filter, active);
  };

  filterClearUI = () => {
    const { filter: filterLength } = this.props;
    if (filterLength < 1) return null;
    return (
      <button className="with-i" onClick={this.filterClear}>
        <i className="icon icon-cancel" />
        Filters
      </button>
    );
  };

  selectRow = () => null;

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

  activeChange = active => {
    this.props.activeChange(active);
  };

  buttonUI = () => {
    const btnList = [
      { n: "Active", v: true },
      { n: "Completed", v: false },
      { n: "All", v: null }
    ];
    return (
      <div className="btn-group">
        {btnList.map(b => (
          <button
            key={b.n}
            className={this.state.active === b.v ? "pbt active" : "pbt"}
            onClick={() => this.activeChange(b.v)}
          >
            {b.n}
          </button>
        ))}
      </div>
    );
  };

  getColumns = () => {
    const { columns } = this.state;
    columns.sort((a, b) => a.order - b.order);
    return [
      ...["Action"],
      ...columns
        .filter(col => col.visible)
        .map(
          col => col.columnID.charAt(0).toLowerCase() + col.columnID.slice(1)
        )
    ];
  };

  getColumnsMappingAndWidth = () => {
    const columnsMapping = {
      Action: { name: "Action", filter: false, fixed: false }
    };
    const columnsWidth = {
      Action: 70
    };
    let { columns } = this.state;
    columns = columns.filter(col => col.visible);
    columns.sort((a, b) => a.order - b.order);
    columns.forEach(col => {
      const testKey =
        col.columnID.charAt(0).toLowerCase() + col.columnID.slice(1);
      columnsMapping[testKey] = {
        name: col.columnLabel,
        filter: col.allowFilter,
        fixed: true
      };
    });
    columns.forEach(col => {
      columnsWidth[col.columnID] = col.width || 160;
    });
    return { columnsMapping, columnsWidth };
  };

  render() {
    const {
      tblWidth,
      tblHeight,
      filter: filterLength,
      selectArray
    } = this.state;

    const hasSelection = selectArray.length > 0;
    const hasFilter = filterLength.length > 0 || hasSelection;
    const calcHeight = tblHeight - 120;

    const columns = this.getColumns();
    const { columnsMapping, columnsWidth } = this.getColumnsMappingAndWidth();

    return (
      <div className="traitContainer">
        <section className="page-action">
          {hasFilter && <div className="left"> {this.filterClearUI()} </div>}
          <div className="right">{this.buttonUI()}</div>
        </section>
        <div className="container">
          <PHTable
            selection
            selectArray={selectArray}
            selectRow={this.selectRow}
            sideMenu={this.props.sideMenu}
            filter={this.props.filter}
            tblWidth={tblWidth}
            tblHeight={calcHeight}
            columns={columns}
            data={this.props.data}
            pagenumber={this.props.pagenumber}
            pagesize={this.props.pagesize}
            total={this.props.total}
            pageChange={this.pageClick}
            columnsMapping={columnsMapping}
            columnsWidth={columnsWidth}
            filterAdd={this.props.filterAdd}
            filterFetch={this.filterFetch}
            filterClear={this.filterClear}
            localFilterAdd={this.localFilterAdd}
            localFilter={this.state.localFilter}
            actions={{
              name: "ldoverview",
              deleteRow: (id, row) => {
                if (confirm("Are you sure to delete test?")) {
                  // eslint-disable-line
                  this.props.deleteTest(id, row);
                }
              },
              export: (id, row) => {
                this.props.export(id, row);
              },
              accessRole: this.props.roles.includes("handlelabcapacity")
            }}
          />
        </div>
      </div>
    );
  }
}
LDOverviewComponent.defaultProps = {
  active: false,
  data: [],
  columns: [],
  total: 0,
  filter: []
};
LDOverviewComponent.propTypes = {
  roles: PropTypes.any, // eslint-disable-line
  active: PropTypes.bool,
  activeChange: PropTypes.func.isRequired,
  deleteTest: PropTypes.func.isRequired,
  sideMenu: PropTypes.bool.isRequired,
  total: PropTypes.number,
  filterAdd: PropTypes.func.isRequired,
  fetchData: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,

  pagenumber: PropTypes.number.isRequired,
  pagesize: PropTypes.number.isRequired,

  filter: PropTypes.array, // eslint-disable-line
  data: PropTypes.array, // eslint-disable-line
  columns: PropTypes.array, // eslint-disable-line

  export: PropTypes.func.isRequired
};
export default LDOverviewComponent;
