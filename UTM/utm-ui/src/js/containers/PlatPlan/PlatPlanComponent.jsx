import React from "react";
import PropTypes from "prop-types";
import { confirmAlert } from "react-confirm-alert"; // Import
import PHTable from "../../components/PHTable";
import { getDim } from "../../helpers/helper";

class PlatPlanComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      filter: props.filter,
      localFilter: props.filter,
      selectArray: [],
      active: props.active,
      btr: false
    };
  }

  componentDidMount() {
    const { pagenumber, pagesize, filter, active } = this.props;
    this.props.fetchDate(pagenumber, pagesize, filter, active, this.state.btr);
    window.addEventListener("resize", this.updateDimensions);
    this.updateDimensions();
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.active !== this.props.active) {
      this.setState({ active: nextProps.active });
      const { pagesize, filter, active } = nextProps;
      this.props.fetchDate(1, pagesize, filter, active, this.state.btr);
    }
    if (nextProps.relation) {
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
    this.props.fetchDate(1, pagesize, localFilter, active, this.state.btr);
  };

  filterClear = () => {
    const { pagesize, active } = this.props;
    this.setState({ localFilter: [] });
    this.props.filterClear();
    this.props.fetchDate(1, pagesize, [], active, this.state.btr);
  };

  pageClick = pg => {
    const { pagesize, filter, active } = this.props;
    this.props.fetchDate(pg, pagesize, filter, active, this.state.btr);
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
  handleBTRChange = e => {
    const btr = e.target.value === "btr";
    this.setState({ btr });
    const { pagenumber, pagesize, filter, active } = this.props;
    this.props.fetchDate(pagenumber, pagesize, filter, active, btr);
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
    // const subHeight = hasFilter ? 120 : 80; // when action bar not required
    const calcHeight = tblHeight - 120;

    let columns = [
      "Action",
      "crop",
      "breedingStation",
      "test",
      "platePlan",
      "slotName",
      "plannedDate",
      "expectedDate",
      "usedMarkers",
      "usedPlates",
      "status",
      "researcher",
      "remark",
      "requestedMarkers"
    ];

    const { btr } = this.state;
    // 'Action',
    const columnsMapping = {
      crop: { name: "Crop", filter: true, fixed: false },
      breedingStation: { name: "Br.Station", filter: true, fixed: true },
      test: { name: "Test Name", filter: true, fixed: true },
      slotName: { name: "Slot Name", filter: true, fixed: true },
      platePlan: { name: "Folder", filter: true, fixed: true },
      plannedDate: { name: "Planned Date", filter: true, fixed: true },
      expectedDate: { name: "Expected Date", filter: true, fixed: true },
      usedMarkers: { name: "Used Markers", filter: true, fixed: true },
      usedPlates: { name: "Used Plates", filter: true, fixed: true },
      status: { name: "Status", filter: true, fixed: true },
      Action: { name: "Action", filter: false, fixed: true },
      requestedMarkers: {
        name: "Requested Markers",
        filter: false,
        fixed: true
      },
      researcher: { name: "Name", filter: true, fixed: true },
      remark: { name: "Remark", filter: true, fixed: true }
    };

    if (btr) {
      // filter out planned date in case of BTR records
      columns = columns.filter(columnName => !(columnName === "plannedDate"));
    } else {
      // filter out researcher and remark in case of non BTR records
      columns = columns.filter(columnName => {
        if (["researcher", "remark"].indexOf(columnName) > -1) return false;
        return true;
      });
    }

    const columnsWidth = {
      crop: 80,
      breedingStation: 100,
      test: 180,
      platePlan: 160,
      slotName: 140,
      plannedDate: 130,
      expectedDate: 130,
      usedMarkers: 120,
      usedPlates: 120,
      status: 200,
      Action: 80,
      requestedMarkers: 400,
      name: 80,
      remarks: 100
    };

    return (
      <div className="traitContainer">
        <section className="page-action">
          {hasFilter && <div className="left"> {this.filterClearUI()} </div>}
          <div className="right">
            <div className="btr-group">
              <label htmlFor="btr">
                <input
                  type="radio"
                  name="btr"
                  value="non-btr"
                  checked={!this.state.btr}
                  onChange={this.handleBTRChange}
                  title="Select non BTR records"
                />
                Non BTR
              </label>
              <label>
                <input
                  type="radio"
                  name="btr"
                  value="btr"
                  checked={this.state.btr}
                  onChange={this.handleBTRChange}
                  title="Select BTR records"
                />
                BTR
              </label>
            </div>

            {this.buttonUI()}
          </div>
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
            columns={[].concat(columns)}
            data={this.props.relation}
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
              name: "planPlate",
              deleteRow: (id, row) => {
                confirmAlert({
                  title: "Delete",
                  message: (
                    <span>
                      Are you sure to delete the test
                      <strong> {row.test}</strong>?
                    </span>
                  ),
                  buttons: [
                    {
                      label: <span>Delete</span>,
                      className: "react-confirm-delete",
                      onClick: () => this.props.deleteTest(id, row)
                    },
                    {
                      label: "Cancel",
                      className: "react-confirm-no"
                    }
                  ]
                });
              },
              export: (id, row) => {
                if (btr) {
                  confirmAlert({
                    title: "Confirm",
                    message: "Do you want to export with control position?",
                    closeOnClickOutside: false,
                    closeOnEscape: false,
                    buttons: [
                      {
                        label: <span>Yes</span>,
                        className: "react-confirm-yes",
                        onClick: () => this.props.export(id, row, true)
                      },
                      {
                        label: "No",
                        className: "react-confirm-no",
                        onClick: () => this.props.export(id, row, false)
                      }
                    ]
                  });
                } else {
                  this.props.export(id, row, null);
                }
              },
              gotoSampleList: (id) => {
                this.props.history.push("/samplelist", {testID: id});
              },
              accessRole: this.props.roles.includes("handlelabcapacity"),
              isBTR: this.state.btr
            }}
          />
        </div>
      </div>
    );
  }
}
PlatPlanComponent.defaultProps = {
  active: false,
  relation: [],
  total: 0,
  filter: []
};
PlatPlanComponent.propTypes = {
  roles: PropTypes.any, // eslint-disable-line
  active: PropTypes.bool,
  activeChange: PropTypes.func.isRequired,
  deleteTest: PropTypes.func.isRequired,
  export: PropTypes.func.isRequired,

  sideMenu: PropTypes.bool.isRequired,
  total: PropTypes.number,
  filterAdd: PropTypes.func.isRequired,
  fetchDate: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,

  pagenumber: PropTypes.number.isRequired,
  pagesize: PropTypes.number.isRequired,

  filter: PropTypes.array, // eslint-disable-line
  relation: PropTypes.array // eslint-disable-line
};
export default PlatPlanComponent;
