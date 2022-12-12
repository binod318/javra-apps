import React from "react";
import PropTypes from "prop-types";

import PHTable from "../../../components/PHTable";
import { getDim } from "../../../helpers/helper";
import LabOverviewSlotUpdateModal from "../containers/LDLabOverviewSlotUpdateModal";
import ConfirmBox from "../../../components/Confirmbox/confirmBox";
import { localStorageService } from "../../../services/local-storage.service"

class LDLabOverview extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 900,
      tblHeight: 600,
      periods: {},
      peroidSelected: "",
      startYear: 2015, // why hard coded ???
      endYear: 2030, // why hard coded ???
      currentYear: new Date().getFullYear(),
      filteredData: props.data,
      columns: props.columns,

      updatePlan: false,
      plannedDate: "",
      slotName: "",
      slotID: "",
      samples: 0,
      updatePeriod: false,
      siteLocation: 0,

      errorMsg: props.errorMsg,
      // submit: props.submit,
      forced: props.forced,
      editObj: {},
      localFilter: props.filter
      // refresh: props.refresh
    };
    const dd = new Date();
    this.currentYear = dd.getFullYear();
    this.props.pageTitle();
  }

  componentDidMount() {
    window.addEventListener("beforeunload", this.handleWindowClose);
    window.addEventListener("resize", this.updateDimensions);
    this.updateDimensions();
    
    this.props.locationFetch();

    // fetch lab overview data
    //this.props.labFetch(this.state.currentYear, 0, []);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.errorMsg !== this.props.errorMsg) {
      this.setState({ errorMsg: nextProps.errorMsg });
    }

    if(nextProps.columns !== this.props.columns) {
      this.setState({
        columns: nextProps.columns
      });
    }

    if (nextProps.submit === true) {
      this.setState({
        updatePlan: false,
        editObj: {}
      });
      this.props.errorReset();
    }
    if (nextProps.forced !== this.props.forced) {
      this.setState({ forced: nextProps.forced });
    }
    if (nextProps.refresh !== this.props.refresh) {
      // }
      // TODO: should have been checked for data update flag
      // if (nextProps.data.length !== this.props.data.length) {
      this.updateDimensions();
      const periods = {};
      nextProps.data.forEach(data => {
        if (periods[data.periodID] === undefined) {
          periods[data.periodID] = data.periodName;
        }
      });
      this.setState({
        periods,
        filteredData: nextProps.data
      });
    } else {
      // TODO: remove if else condtion
      const periods = {};
      this.props.data.forEach(data => {
        if (periods[data.periodID] === undefined) {
          periods[data.periodID] = data.periodName;
        }
      });
      this.setState({
        periods,
        filteredData: this.props.data
      });
    }

    if (nextProps.location != this.props.location && nextProps.location.length > 0) {
      //trigger data fetch
      this.initiateFetch(nextProps.location);
    }
  }

  componentWillUnmount() {
    window.removeEventListener("beforeunload", this.handleWindowClose);
    window.removeEventListener("resize", this.updateDimensions);
  }

  initiateFetch(locationList) {
    let location = localStorageService.get("siteLocation");
    if(location == undefined)
      location = locationList[0].siteID;

    this.setState({siteLocation: location});
    this.props.labFetch(this.currentYear, 0, location, []);
  }

  updateDimensions = () => {
    const dim = getDim();
    this.setState({
      tblWidth: dim.width,
      tblHeight: dim.height
    });
  };

  changeYear = e => {
    this.updateDimensions();
    this.currentYear = e.target.value;
    
    const { siteLocation } = this.state;
    this.props.labFetch(e.target.value, 0, siteLocation, []); // PeriodID is not used for backend call: so always 0
  };

  changePeriod = e => {
    const val = e.target.value * 1 || "";
    this.setState({ peroidSelected: val });

    // All periods is selected
    if (e.target.value === "") {
      this.setState({ filteredData: this.props.data });
      return null;
    }
    const dataList = this.props.data.filter(record => record.periodID === val);
    this.setState({ filteredData: dataList });
    return null;
  };

  changeLocation = e => {
    const siteLocation = e.target.value;

    if(siteLocation > 0) {
      //store location on local storage
      localStorageService.set("siteLocation", siteLocation);
    }
    this.setState({ siteLocation });
    this.props.labFetch(this.currentYear, 0, siteLocation, []);
  };

  computeData = () => {
    const { filteredData, peroidSelected } = this.state;
    const { filter: filterLength } = this.props;
    let filterData2 = [];
    if (filterLength.length > 0) {
      const filter = {};
      filterLength.map(i => {
        const { name, value } = i;
        Object.assign(filter, { [name]: value });
        return null;
      });

      filterData2 = filteredData.filter(item => {
        /* eslint-disable */
        for (const key in filter) {
          const itemLower = item[key]
            ? item[key].toString().toLowerCase()
            : '';
          const filterLower = filter[key]
            ? filter[key].toString().toLowerCase()
            : '';
          const wildFilter = !itemLower.includes(filterLower);
          if (item[key] === undefined || wildFilter) return false;
        }
        /* eslint-enable */

        if (peroidSelected) {
          return item.periodID === peroidSelected;
        }
        return true;
      });
    } else if (peroidSelected) {
      filterData2 = filteredData.filter(
        record => record.periodID === peroidSelected
      );
    } else {
      filterData2 = filteredData;
    }
    return filterData2;
  };

  // SELECTING SLOT
  editSlot = slotIndex => {
    const filteredData = this.computeData(); // this.state;
    const {
      planneDate,
      slotID,
      slotName,
      samples,
      updatePeriod
    } = filteredData[slotIndex];
    this.setState({
      updatePlan: true,
      plannedDate: planneDate,
      slotID,
      slotName,
      samples,
      updatePeriod
    });
  };

  slotEdit = obj => {
    this.setState({ editObj: obj });
    this.props.slotEdit(obj);
  };

  closeModal = () => {
    this.setState({
      updatePlan: false
    });
  };

  forcedSubmit = condition => {
    if (condition) {
      const { editObj } = this.state;
      this.props.slotEdit({ ...editObj, forced: true });
      this.props.errorReset();
    } else {
      this.props.errorReset();
    }
    return null;
  };

  filterFetch = () => {
    this.props.filterAdd(this.state.localFilter);
  };
  filterClear = () => {
    this.props.filterClear();
    this.setState({ localFilter: [] });
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

  exportLabOverview = (peroidSelected, currentYear, siteID) => {
    this.props.export(peroidSelected, currentYear, siteID, this.state.localFilter);
  };

  getColumns = () => {
    const { columns } = this.state;
    columns.sort((a, b) => a.order - b.order);
    return [
      ...["Action"],
      ...columns
        .filter(col => col.isVisible)
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
    columns = columns.filter(col => col.isVisible);
    columns.sort((a, b) => a.order - b.order);
    columns.forEach(col => {
      const testKey =
        col.columnID.charAt(0).toLowerCase() + col.columnID.slice(1);
      columnsMapping[testKey] = {
        name: col.columnLabel,
        filter: true,
        fixed: true
      };
    });
    columns.forEach(col => {
      columnsWidth[col.columnID] = col.width || 160;
    });
    return { columnsMapping, columnsWidth };
  };

  render() {
    const { updatePlan } = this.state;
    let { tblHeight } = this.state;
    const {
      tblWidth,
      startYear,
      endYear,
      periods,
      slotID,
      samples,
      slotName,
      updatePeriod,
      forced,
      errorMsg,
      // filteredData,
      peroidSelected,
      siteLocation
    } = this.state;
    // const { filter: filterLength } = this.props;

    const columns = this.getColumns();
    const { columnsMapping, columnsWidth } = this.getColumnsMappingAndWidth();

    const yearList = [];
    for (let i = startYear; i <= endYear; i += 1) {
      yearList.push(
        <option key={i} value={i}>
          {i}
        </option>
      );
    }

    tblHeight -= 120;

    // const columns = [
    //   "Action",
    //   "periodName",
    //   "slotName",
    //   "breedingStationCode",
    //   "cropName",
    //   "requestUser",
    //   "markers",
    //   "plates",
    //   "testProtocolName",
    //   "statusName"
    // ];
    // const columnsMapping = {
    //   Action: { name: "Action", filter: false, fixed: false },
    //   periodName: { name: "Week", filter: !true, fixed: true },
    //   slotName: { name: "Slot Name", filter: true, fixed: true },
    //   breedingStationCode: {
    //     name: "Breeding station",
    //     filter: true,
    //     fixed: true
    //   },
    //   cropName: { name: "Crop", filter: true, fixed: true },
    //   requestUser: { name: "Requester", filter: true, fixed: true },
    //   markers: { name: "#tests", filter: true, fixed: false },
    //   plates: { name: "#plates", filter: true, fixed: false },
    //   testProtocolName: { name: "Method", filter: true, fixed: false },
    //   statusName: { name: "Status", filter: true, fixed: false }
    // };
    // // hard coded for current data widths
    // const columnsWidth = {
    //   Action: 70,
    //   periodName: 240,
    //   slotName: 160,
    //   breedingStationCode: 160,
    //   cropName: 100,
    //   requestUser: 200,
    //   markers: 90,
    //   plates: 90,
    //   testProtocolName: 90,
    //   statusName: 90
    // };

    return (
      <div className="labove rview traitContainer">
        {forced && <ConfirmBox message={errorMsg} click={this.forcedSubmit} />}
        <section className="page-action">
          <div className="left">
            <div className="left"> {this.filterClearUI()} </div>
            <div className="form-e">
              <label htmlFor="year">Year</label>
              <select
                id="year"
                name="year"
                onChange={this.changeYear}
                defaultValue={this.state.currentYear}
              >
                {yearList}
              </select>
            </div>
            <div className="form-e">
              <label>Period</label>
              <select
                id="period"
                name="period"
                value={peroidSelected}
                onChange={this.changePeriod}
                className="w-250"
              >
                <option value="">All Periods</option>
                {Object.keys(periods).map(periodID => (
                  <option key={periodID} value={periodID}>
                    {periods[periodID]}
                  </option>
                ))}
              </select>
            </div>
            <div className="form-e">
              <label className="w-120">Lab Location</label>
              <select
                id="labLocation"
                name="labLocation"
                value={siteLocation}
                onChange={this.changeLocation}
                className="w-200"
              >
                <option value="0">All Locations</option>
                {this.props.location.map(location => {
                  const {
                    siteID,
                    siteName
                  } = location;
                  return (
                    <option
                      key={`${siteID}`}
                      value={siteID}
                    >
                      {siteName}
                    </option>
                  );
                })}
              </select>
            </div>
          </div>

          <div className="right">
            <button
              title="Export"
              className="with-i full-btn"
              onClick={e => {
                e.preventDefault();
                this.exportLabOverview(peroidSelected, this.currentYear, siteLocation);
              }}
            >
              <i className="icon icon-file-excel" />
              Export
            </button>
          </div>
        </section>

        <div className="container">
          <PHTable
            sideMenu={this.props.sideMenu}
            filter={[]}
            tblWidth={tblWidth}
            tblHeight={tblHeight}
            columns={columns}
            data={this.computeData()}
            pagenumber={1}
            pagesize={200}
            total={1}
            pageChange={() => {}}
            columnsMapping={columnsMapping}
            columnsWidth={columnsWidth}
            filterFetch={this.filterFetch}
            filterClear={this.filterClear}
            filterAdd={this.props.filterAdd}
            localFilterAdd={this.localFilterAdd}
            localFilter={this.state.localFilter}
            actions={
              {
                name: "laboverview",
                edit: id => this.editSlot(id),
                delete: () => {}
              } // eslint-disable-line
            }
          />

          {updatePlan && (
            <LabOverviewSlotUpdateModal
              closeModal={this.closeModal}
              plannedDate={this.state.plannedDate}
              slotID={slotID}
              slotName={slotName}
              updateSlot={this.slotEdit}
              currentYear={this.state.currentYear}
              samples={samples}
              updatePeriod={updatePeriod}
              forced={forced}
            />
          )}
        </div>
      </div>
    );
  }
}
LDLabOverview.defaultProps = {
  errorMsg: "",
  data: [],
  columns: [],
  filter: [],
  refresh: false,
  error: [],  
  location: []
};

LDLabOverview.propTypes = {
  errorMsg: PropTypes.string,
  sideMenu: PropTypes.bool.isRequired,
  refresh: PropTypes.bool.isRequired,
  data: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  location: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  filter: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  pageTitle: PropTypes.func.isRequired,
  slotEdit: PropTypes.func.isRequired,
  labFetch: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  filterAdd: PropTypes.func.isRequired,
  errorReset: PropTypes.func.isRequired,
  forced: PropTypes.bool.isRequired,
  submit: PropTypes.bool.isRequired,
  export: PropTypes.func.isRequired
};
export default LDLabOverview;
