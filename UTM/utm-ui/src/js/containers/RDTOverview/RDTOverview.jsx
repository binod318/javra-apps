import React from "react";
import { confirmAlert } from "react-confirm-alert"; // Import
import PropTypes from "prop-types";
import PHTable from "../../components/PHTable";
import { getDim } from "../../helpers/helper";

class RDTOverview extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      // relationList: props.relation,
      filter: props.filter,
      localFilter: props.filter,
      selectArray: [],
      active: props.active
    };
  }

  componentDidMount() {
    const { pagenumber, pagesize, filter, active } = this.props;
    this.props.fetchDate(pagenumber, pagesize, filter, active);
    window.addEventListener("resize", this.updateDimensions);
    this.updateDimensions();
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.active !== this.props.active) {
      this.setState({ active: nextProps.active });
      const { pagesize, filter, active } = nextProps;
      this.props.fetchDate(1, pagesize, filter, active);
    }
    if (nextProps.rdt) {
      // this.setState({ relationList: nextProps.relation });
      this.updateDimensions();
    }
    if (nextProps.filter.length !== this.props.filter) {
      this.setState({
        filter: nextProps.filter
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
    this.props.fetchDate(1, pagesize, localFilter, active);
  };

  filterClear = () => {
    const { pagesize, active } = this.props;
    this.setState({ localFilter: [] });
    this.props.filterClear();
    this.props.fetchDate(1, pagesize, [], active);
  };

  pageClick = pg => {
    const { pagesize, filter, active } = this.props;
    this.props.fetchDate(pg, pagesize, filter, active);
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

    const columns = [
      "Action",
      "crop",
      "breedingStation",
      "test",
      "folder",
      "siteName",
      // 'platePlan',
      "expectedDate",
      "usedTests",
      "status"
    ];

    // if (active) {
    //   columns.splice(4, 0, 'platePlan');
    // }
    // 'Action',
    const columnsMapping = {
      crop: { name: "Crop", filter: true, fixed: false },
      breedingStation: { name: "Br.Station", filter: true, fixed: true },
      test: { name: "Test Name", filter: true, fixed: true },
      folder: { name: "Folder", filter: true, fixed: true },
      siteName: { name: "Site Location", filter: true, fixed: true },
      platePlan: { name: "Folder", filter: true, fixed: true },
      expectedDate: { name: "Expected Date", filter: true, fixed: true },
      usedTests: { name: "Used Tests", filter: true, fixed: true },
      status: { name: "Status", filter: true, fixed: true },
      Action: { name: "Action", filter: false, fixed: true }
    };
    const columnsWidth = {
      crop: 80,
      breedingStation: 100,
      test: 180,
      folder: 100,
      siteName: 160,
      platePlan: 160,
      expectedDate: 130,
      usedMarkers: 120,
      status: 200,
      Action: 60
    };

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
            data={this.props.rdt}
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
              name: "rdtoverview",
              deleteRow: (id, row) => {
                if (confirm("Are you sure to delete test?")) {
                  // eslint-disable-line
                  this.props.deleteTest(id, row);
                }
              },
              export: (id, row) => {
                confirmAlert({
                  title: "Export",
                  //message: "How do you want to export?",
                  closeOnClickOutside: true,
                  closeOnEscape: true,
                  buttons: [
                    {
                      label: <span>Test score</span>,
                      className: "react-confirm-yes",
                      onClick: () => this.props.export(id, row, true)
                    },
                    {
                      label: <span>Trait score</span>,
                      className: "react-confirm-no",
                      onClick: () => this.props.export(id, row, false)
                    }
                  ]
                });
              },
              accessRole: this.props.roles.includes("handlelabcapacity")
            }}
          />
        </div>
      </div>
    );
  }
}
RDTOverview.defaultProps = {
  active: false,
  rdt: [],
  total: 0,
  filter: []
};
RDTOverview.propTypes = {
  roles: PropTypes.any, // eslint-disable-line
  active: PropTypes.bool,
  activeChange: PropTypes.func.isRequired,
  deleteTest: PropTypes.func.isRequired,
  sideMenu: PropTypes.bool.isRequired,
  total: PropTypes.number,
  filterAdd: PropTypes.func.isRequired,
  fetchDate: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,

  pagenumber: PropTypes.number.isRequired,
  pagesize: PropTypes.number.isRequired,

  filter: PropTypes.array, // eslint-disable-line
  rdt: PropTypes.array, // eslint-disable-line

  export: PropTypes.func.isRequired
};
export default RDTOverview;
