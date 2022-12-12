import React, { Fragment } from "react";
import PropTypes from "prop-types";

import moment from "moment";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import ConfirmBox from "../../../components/Confirmbox/confirmBox";

import PHTable from "../../../components/PHTable";
import { getDim, isWeekday } from "../../../helpers/helper";
import { localStorageService } from "../../../services/local-storage.service"

class LeafDiskCapacityPlanning extends React.Component {
  constructor(props) {
    super(props);
    let testTypes = props.testType;
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      list: props.slotList,
      pagenumber: props.pagenumber,
      pagesize: props.pagesize,
      total: props.total,

      breedingStation: props.breedingStation,
      crop: props.crop,
      testType: testTypes,
      materialType: props.materialType,
      testProtocol: props.testProtocol,
      siteLocation: props.siteLocation,
      columns: props.columns,

      sStation: "",
      sCrop: "",
      sTType: testTypes.length > 0 ? testTypes[0].testTypeID : 9, //9 for Leafdisk
      sdeterminationRequired: false,
      sMType: "",
      sTProtocol: "",
      sLLocation: "",
      tests: "",
      remark: "",

      currentPeriod: props.currentPeriod,
      availTests: props.availTests,

      errorMsg: props.errorMsg, // 'Error: allocation capacity',

      forced: props.forced,
      forceUpdate: props.forceUpdate,

      modeAdd: true,
      editRow: null,
      localFilter: props.filter,

      today: moment(),
      planned: null, // moment(),

      rolesRequest: false,
      rolesManagemasterdatautm: false
    };
    props.pageTitle();
  }

  componentDidMount() {
    this.props.fetchForm();
    this.props.resetStoreBreeder();
    this.toReset();
    window.addEventListener("resize", this.updateDimensions);
    this.updateDimensions();

    //initialy load location from localstorage
    let location = localStorageService.get("siteLocation");
    if(location !== undefined)
      this.setState({sLLocation : location });
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.roles.length > 0) {
      this.setState({
        rolesRequest: nextProps.roles.includes("requesttest"),
        rolesManagemasterdatautm: nextProps.roles.includes(
          "managemasterdatautm"
        )
      });
    }
    if (nextProps.currentPeriod !== this.props.currentPeriod) {
      this.setState({ currentPeriod: nextProps.currentPeriod });
    }

    if (nextProps.availTests !== this.props.availTests) {
      this.setState({ availTests: nextProps.availTests });
    }
    if (nextProps.availPlates !== this.props.availPlates) {
      this.setState({ availPlates: nextProps.availPlates });
    }

    if (nextProps.errorMsg !== this.props.errorMsg) {
      this.setState({ errorMsg: nextProps.errorMsg });
    }

    if (nextProps.submit === true) {
      this.toReset();
      this.props.submitToFalse();
    }
    if (nextProps.forced !== this.props.forced) {
      this.setState({ forced: nextProps.forced });
    }
    if (nextProps.forceUpdate !== this.props.forceUpdate) {
      this.setState({ forceUpdate: nextProps.forceUpdate });
    }

    if (nextProps.breedingStation !== this.props.breedingStation) {
      this.setState({
        breedingStation: nextProps.breedingStation,
        crop: nextProps.crop,
        testType: nextProps.testType,
        materialType: nextProps.materialType,
        testProtocol: nextProps.testProtocol,
        siteLocation: nextProps.siteLocation,
        columns: nextProps.columns
      });
    }

    if (nextProps.slotList !== this.props.slotList) {
      this.setState({ list: nextProps.slotList });
    }
    if (nextProps.pagenumber !== this.props.pagenumber) {
      this.setState({ pagenumber: nextProps.pagenumber });
    }
    if (nextProps.pagesize !== this.props.pagesize) {
      this.setState({ pagesize: nextProps.pagesize });
    }
    if (nextProps.total !== this.props.total) {
      this.setState({ total: nextProps.total });
    }

    //get normal mode after edit slot
    if (nextProps.update !== this.props.update && nextProps.update === false) {
        this.setState({ modeAdd: true });
        this.editCancel();
    }

  }

  componentWillUnmount() {
    window.removeEventListener("resize", this.updateDimensions);
    this.props.clearPageData();
  }

  updateDimensions = () => {
    const dim = getDim();
    this.setState({
      tblWidth: dim.width,
      tblHeight: dim.height
    });
  };

  toReset = () => {
    this.setState({
      sTType: this.state.testType.length > 0 ? this.state.testType[0].testTypeID : 9,
      sdeterminationRequired: false,
      sMType: "",
      sTProtocol: "",
      //sLLocation: "",
      tests: "",

      currentPeriod: "",
      availTests: null,
      remark: "",

      planned: null
    });
  };
  fetchTableDataOnChange = (name, value) => {
    // name :: station / crop
    const { sCrop, sStation, pagesize } = this.state;

    if (name === "crop") {
      if (sStation !== "") {
        this.props.fetchSlot(value, sStation, 1, pagesize, []);
      }
    }
    if (sCrop !== "") {
      this.props.fetchSlot(sCrop, value, 1, pagesize, []);
    }
  };

  changeSelect = e => {
    const { name, value } = e.target;
    const { planned, sLLocation, sTProtocol } = this.state; // sMType

    switch (name) {
      case "station":
        this.setState({ sStation: value });
        this.fetchTableDataOnChange(name, value);
        break;
      case "crop":
        this.props.fetchMaterialType(value);
        this.props.expectedBlank();
        this.setState({
          sCrop: value,
          sMType: "",
          sTProtocol: ""
        });
        this.fetchTableDataOnChange(name, value);
        break;
      case "testType": {
        const determination = this.state.testType.find(
          test => test.testTypeID === parseInt(value) // eslint-disable-line
        );
        this.setState({
          sTType: value,
          sdeterminationRequired: !determination.determinationRequired, // !determination[0]['determinationRequired'], // eslint-disable-line
          tests: !determination.determinationRequired // !determination[0]['determinationRequired'] // eslint-disable-line
            ? ""
            : this.state.tests
        });
        break;
      }
      case "materialType":
          this.setState({ sMType: value });
          break;
      case "testProtocol":
          this.availSampleFetch(value, planned, sLLocation);
          this.setState({ sTProtocol: value });
          break;
      case "labLocation": {
          //store location on local storage
          localStorageService.set("siteLocation", value);
          this.setState({ sLLocation: value });

          this.availSampleFetch(sTProtocol, planned, value);
          break;

      }
      case "tests":
        if (value > -1) {
          this.setState({ tests: value });
        }
        break;
      case "remark":
        this.setState({ remark: value });
        break;
      default:
    }
  };

  handlePlannedDateChange = date => {
    const { modeAdd, sTProtocol, sLLocation } = this.state;
    // only fetch plant tests if it's in add mode.
    if (modeAdd) {
      this.availSampleFetch(sTProtocol, date, sLLocation);
      this.setState({ planned: date });
    } else {
      this.setState({ planned: date });
    }
  };

  availSampleFetch = (protocol, planned, siteID) => {
    let plannedDate = "";
    if (planned !== null) {
      plannedDate = planned.format(window.userContext.dateFormat); // eslint-disable-line
    }

    if (plannedDate !== "" && protocol !== "" && siteID != "" ) {
      this.props.fetchAvailSamples(protocol, plannedDate, siteID);
    }
  };

  submit = () => {
    const {
      sStation,
      sCrop,
      sTType,
      sMType,
      sTProtocol,
      sLLocation,
      planned,
      tests,
      rolesRequest,
      remark
    } = this.state;

    if (!rolesRequest) return null;

    let testValidation = false;
    if (this.state.sdeterminationRequired) {
      testValidation = true;
    } else {
      testValidation = tests !== "";
    }
    if (
      sStation !== "" &&
      sCrop !== "" &&
      sMType !== "" &&
      sTProtocol !== "" &&
      sLLocation !== "" &&
      planned !== "" &&
      testValidation
    ) {
      const obj = {
        breedingStationCode: sStation,
        cropCode: sCrop,
        testTypeID: sTType,
        materialTypeID: sMType,
        testProtocolID: sTProtocol,
        siteID: sLLocation,
        plannedDate: planned.format(userContext.dateFormat) || "", // eslint-disable-line
        nrOfSample: tests,
        remark,
        forced: false
      };
      this.props.reserve(obj);
    } else {
      this.showError();
    }
    return null;
  };

  showError = () => {
    this.props.show_error({
      status: true,
      message: ["Please fill all required fields."],
      messageType: 2,
      notificationType: 0,
      code: ""
    });
  };

  forcedSubmit = condition => {
    const {
      sStation,
      sCrop,
      sTType,
      sMType,
      sTProtocol,
      sLLocation,
      planned,
      tests,
      remark
    } = this.state;

    if (condition) {
      const obj = {
        breedingStationCode: sStation,
        cropCode: sCrop,
        testTypeID: sTType,
        materialTypeID: sMType,
        testProtocolID: sTProtocol,
        siteID: sLLocation,
        plannedDate: planned.format(userContext.dateFormat) || "", // eslint-disable-line
        nrOfSample: tests,
        remark,
        forced: true
      };

      this.setState({ forcedSubmit: !this.state.forcedSubmit });
      this.props.reserve(obj);
      this.props.clearError();
      this.toReset();
    } else {
      this.setState({ forcedSubmit: !this.state.forcedSubmit });
      this.props.clearError();
    }
  };

  filterFetch = () => {
    const { sCrop, sStation } = this.state;
    const { pagesize } = this.props;
    const { localFilter } = this.state;

    this.props.fetchSlot(sCrop, sStation, 1, pagesize, localFilter);
  };
  filterClear = () => {
    const { sCrop, sStation } = this.state;
    const { pagesize } = this.props;
    this.setState({ localFilter: [] });
    this.props.filterClear();
    this.props.fetchSlot(sCrop, sStation, 1, pagesize, []);
  };
  pageClick = pg => {
    const { sCrop, sStation } = this.state;
    const { pagesize, filter } = this.props;
    this.props.fetchSlot(sCrop, sStation, pg, pagesize, filter);
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

  slotEdit = id => {
    const { materialType, list, testProtocol, siteLocation } = this.state;
    const {
      isolated,
      plannedDate,
      nrOfTests,
      materialTypeCode,
      testProtocolID,
      remark,
      testTypeID,
      siteID
    } = list[id];

    const sMType =
      materialType.filter(m => m.materialTypeCode === materialTypeCode)[0]
        .materialTypeID || 1;

    const sTProtocol =
      testProtocol.filter(m => m.testProtocolID === testProtocolID)[0]
        .testProtocolID || 1;

    const sLLocation =
      siteLocation.filter(m => m.siteID === siteID)[0]
        .siteID || 1;

    const determination = this.state.testType.find(
      test => test.testTypeID === testTypeID
    );

    this.setState({
      editRow: id,
      modeAdd: false,
      isolated, // slotID,
      sTType: testTypeID,
      sdeterminationRequired: determination
        ? !determination.determinationRequired
        : false,
      sMType,
      sTProtocol,
      sLLocation,
      planned: moment(plannedDate, userContext.dateFormat), // eslint-disable-line
      tests: nrOfTests,
      remark
    });

    this.props.changeUpdateMode(true);
    return null;
  };

  editCancel = () => {
    this.setState({
      editRow: null,
      modeAdd: true,

      sMType: "",
      sTProtocol: "",
      //sLLocation: "",
      planned: null,

      tests: "",
      remark: ""
    });
  };
  slotUpdate = (forced = false) => {
    const {
      tests,
      editRow,
      list,
      sStation,
      sCrop,
      planned
    } = this.state;
    const { slotID } = list[editRow];
    this.props.slotEdit({
      slotID,
      nrOfTests: tests,
      forced,
      brStationCode: sStation,
      cropCode: sCrop,
      plannedDate: planned.format(userContext.dateFormat)
    });
  };
  forceUpdateFunc = condition => {
    if (condition) {
      // alert('yes');
      this.slotUpdate(true);
      this.editCancel();
      this.props.clearError();
      this.props.updateToFalse();
    } else {
      this.props.clearError();
      this.props.updateToFalse();
    }
  };

  slotDelete = id => {
    const { list, sCrop, sStation } = this.state;
    // modeAdd
    const { slotID, slotName } = list[id];

    if (window.confirm(`Are you sure to delete Slot: ${slotName}?`)) {
      // eslint-disable-line
      this.props.slotDelete(slotID, sCrop, sStation, slotName);
    }
    return null;
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

  exportCapacityPlanning = () => {
    const { sCrop, sStation } = this.state;
    const { pagesize } = this.props;
    const { localFilter } = this.state;
    const payload = {
      cropCode: sCrop,
      brStationCode: sStation,
      pageNumber: 1,
      pageSize: pagesize,
      filter: localFilter
    };
    this.props.leafDiskExportCapacityPlanning(payload);
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
        name: col.label,
        filter: true,
        fixed: true
      };
    });
    columns.forEach(col => {

      //Cusom column-width mapping
      if( col.columnID === "CropCode")
        columnsWidth[col.columnID] = 50;
      else if( col.columnID === "PeriodName")
        columnsWidth[col.columnID] = 180;
      else if( col.columnID === "BreedingStationCode")
        columnsWidth[col.columnID] = 80;
      else
        columnsWidth[col.columnID] = col.width || 160;
    });
    return { columnsMapping, columnsWidth };
  };

  render() {
    const { tblWidth, tblHeight, list, modeAdd } = this.state;
    const { pagenumber, pagesize, total } = this.state;
    const columns = this.getColumns();
    const { columnsMapping, columnsWidth } = this.getColumnsMappingAndWidth();

    const { today, planned, currentPeriod } = this.state;
    const { tests, forced, availTests } = this.state;
    let { sLLocation } = this.state;
    const { breedingStation, crop, materialType, testProtocol, siteLocation } = this.state;
    const { testType, sStation, sCrop, sTType, sMType, sTProtocol } = this.state;
    const { forceUpdate, remark } = this.state;

    const periodName = this.props.periodName.length
      ? this.props.periodName[0].periodName
      : "";

    const subHeight = 355 - 20;
    const calcHeight = tblHeight - subHeight;
    const nHeight = calcHeight;

    return (
      <div className="breeder">
        {forced && (
          <ConfirmBox message={this.state.errorMsg} click={this.forcedSubmit} />
        )}
        {forceUpdate && (
          <ConfirmBox
            message={this.state.errorMsg}
            click={this.forceUpdateFunc}
          />
        )}
        <section className="page-action">
          <div className="left">
            {this.filterClearUI()}
            <div className="form-e">
              <label className="full">Current period : {periodName}</label>
            </div>
          </div>
        </section>

        <div className="container">
          <div className="row">
            <div className="form-e">
              <label htmlFor="crop">Crop *</label> {/* eslint-disable-line */}
              <select
                id="capacity_crop"
                name="crop"
                onChange={this.changeSelect}
                value={sCrop}
                disabled={!modeAdd}
              >
                <option value="">Select Crop</option>
                {crop.map(cropList => (
                  <option key={cropList.cropCode} value={cropList.cropCode}>
                    {cropList.cropCode} - {cropList.cropName}
                  </option>
                ))}
              </select>
            </div>
            <div className="form-e">
              <label htmlFor="station">Breeding Station *</label>{" "}
              {/* eslint-disable-line */}
              <select
                id="capacity_station"
                name="station"
                onChange={this.changeSelect}
                value={sStation}
                disabled={!modeAdd}
              >
                <option value="">Select Station</option>
                {breedingStation.map(d => (
                  <option
                    key={d.breedingStationCode}
                    value={d.breedingStationCode}
                  >
                    {d.breedingStationCode}
                  </option>
                ))}
              </select>
            </div>
            <div className="form-e">
              <label htmlFor="labLocation">Lab Location *</label>{" "}
              {/* eslint-disable-line */}
              <select
                id="capacity_labLocation"
                name="labLocation"
                onChange={this.changeSelect}
                value={sLLocation}
                disabled={!modeAdd}
              >
                <option value="">Select Location</option>
                {siteLocation.map(locations => {
                  const {
                    siteID,
                    siteName
                  } = locations;
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
            <div className="form-e">
              <label htmlFor="testType">Test Type</label>{" "}
              {/* eslint-disable-line */}
              <select
                id="capacity_testType"
                name="testType"
                onChange={this.changeSelect}
                value={sTType}
                disabled={!modeAdd}
              >
                {testType.map(testList => (
                  <option
                    key={`${testList.testTypeID}-${testList.testTypeName}`}
                    value={testList.testTypeID}
                  >
                    {testList.testTypeName}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="row">
            <div className="form-e">
              <label htmlFor="materialType">Material Type *</label>{" "}
              {/* eslint-disable-line */}
              <select
                id="capacity_materialType"
                name="materialType"
                onChange={this.changeSelect}
                value={sMType}
                disabled={!modeAdd}
              >
                <option value="">Select Material Type</option>
                {materialType.map(materialTypeList => {
                  const {
                    materialTypeID,
                    materialTypeCode,
                    materialTypeDescription
                  } = materialTypeList;
                  return (
                    <option
                      key={`${materialTypeID}-${materialTypeCode}`}
                      value={materialTypeID}
                    >
                      {materialTypeCode} - {materialTypeDescription}
                    </option>
                  );
                })}
              </select>
            </div>
            <div className="form-e">
              <label htmlFor="testProtocol">Method *</label>{" "}
              {/* eslint-disable-line */}
              <select
                id="capacity_testProtocol"
                name="testProtocol"
                onChange={this.changeSelect}
                value={sTProtocol}
                disabled={!modeAdd}
              >
                <option value="">Select Method</option>
                {testProtocol.map(testProtocolList => {
                  const {
                    testProtocolID,
                    testProtocolName
                  } = testProtocolList;
                  return (
                    <option
                      key={`${testProtocolID}`}
                      value={testProtocolID}
                    >
                      {testProtocolName}
                    </option>
                  );
                })}
              </select>
            </div>
            <div className="form-e">
              <label htmlFor="plannedDate">
                {" "}
                {/* eslint-disable-line */}
                Planned Date * {currentPeriod ? ` (${currentPeriod})` : ""}
              </label>
              <DatePicker
                id="capacit1y_planned"
                selected={planned || null}
                minDate={today}
                onChange={this.handlePlannedDateChange}
                dateFormat={userContext.dateFormat} // eslint-disable-line
                showWeekNumbers
                // disabled={!modeAdd}
                locale="en-gb"
                filterDate={isWeekday}
                autoComplete="off"
              />
            </div>
            <div/>
          </div>

          <div className="row">
            <div className="form-e">
              <label htmlFor="materialState">
                {" "}
                {/* eslint-disable-line */}
                Number of Samples *{" "}
                {availTests == null ? "" : `(${availTests})`}
              </label>
              <input
                id="capacity_test"
                type="number"
                name="tests"
                value={tests}
                disabled={this.state.sdeterminationRequired}
                onChange={this.changeSelect}
              />
              {/* disabled={this.state.sdeterminationRequired || !modeAdd} */}
            </div>
            <div className="form-e">
              <label htmlFor="materialState">{""}Remark</label>
              <input
                id="remark"
                type="text"
                name="remark"
                value={remark}
                disabled={!modeAdd}
                onChange={this.changeSelect}
              />
            </div>
            <div className="form-e">
              <label>&nbsp;</label>
              {modeAdd === true && (
                <button
                  id="capacity_reserve_btn"
                  onClick={this.submit}
                  disabled={!this.state.rolesRequest}
                >
                  Reserve Capacity
                </button>
              )}
              {modeAdd === false && (
                <Fragment>
                  <button onClick={() => this.slotUpdate()}>Update</button>
                  &nbsp;&nbsp;
                  <button onClick={this.editCancel}>Cancel</button>
                </Fragment>
              )}

              <button
                id="export-capacity-planning"
                onClick={this.exportCapacityPlanning}
                disabled={!modeAdd || list.length === 0}
              >
                Export Excel
              </button>
            </div>
            <div />
          </div>
        </div>

        {!false && (
          <div className="container">
            <PHTable
              fileSource
              sideMenu={this.props.sideMenu}
              filter={this.props.filter}
              tblWidth={tblWidth}
              tblHeight={nHeight}
              columns={columns}
              data={list}
              pagenumber={pagenumber}
              pagesize={pagesize}
              total={total}
              pageChange={this.pageClick}
              columnsMapping={columnsMapping}
              columnsWidth={columnsWidth}
              filterAdd={this.props.filterAdd}
              filterFetch={this.filterFetch}
              filterClear={this.filterClear}
              localFilterAdd={this.localFilterAdd}
              localFilter={this.state.localFilter}
              actions={{
                name: "breeder",
                edit: slotID => this.slotEdit(slotID),
                delete: slotID => this.slotDelete(slotID),
                rolesRequest: this.state.rolesRequest,
                rolesManagemasterdatautm: this.state.rolesManagemasterdatautm
              }}
            />
          </div>
        )}
      </div>
    );
  }
}

LeafDiskCapacityPlanning.defaultProps = {
  roles: [],
  slotList: [],
  filter: [],

  breedingStation: [],
  crop: [],
  testType: [],
  materialState: [],
  materialType: [],
  testProtocol: [],
  siteLocation: [],
  periodName: [],
  columns: [],

  currentPeriod: "",
  expectedPeriod: "",
  availTests: null,
  availPlates: null,

  errorMsg: "",
  submit: false,
  forced: false,
  forceUpdate: false,
  expectedDate: null
};
LeafDiskCapacityPlanning.propTypes = {
  roles: PropTypes.array, // eslint-disable-line
  slotEdit: PropTypes.func.isRequired,
  slotDelete: PropTypes.func.isRequired,

  clearPageData: PropTypes.func.isRequired,
  filterClear: PropTypes.func.isRequired,
  fetchSlot: PropTypes.func.isRequired,
  filter: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  filterAdd: PropTypes.func.isRequired,
  pagenumber: PropTypes.number.isRequired,
  pagesize: PropTypes.number.isRequired,
  total: PropTypes.number.isRequired,
  slotList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  sideMenu: PropTypes.bool.isRequired,

  updateToFalse: PropTypes.func.isRequired,
  pageTitle: PropTypes.func.isRequired,
  // sidemenu: PropTypes.func.isRequired,
  reserve: PropTypes.func.isRequired,
  fetchForm: PropTypes.func.isRequired,
  fetchAvailSamples: PropTypes.func.isRequired,
  show_error: PropTypes.func.isRequired,
  submitToFalse: PropTypes.func.isRequired,

  resetStoreBreeder: PropTypes.func.isRequired,
  expectedBlank: PropTypes.func.isRequired,
  fetchMaterialType: PropTypes.func.isRequired,
  clearError: PropTypes.func.isRequired,

  period: PropTypes.func.isRequired,

  breedingStation: PropTypes.array, // eslint-disable-line
  crop: PropTypes.array, // eslint-disable-line
  testType: PropTypes.array, // eslint-disable-line
  materialType: PropTypes.array, // eslint-disable-line
  testProtocol: PropTypes.array,
  siteLocation: PropTypes.array,
  periodName: PropTypes.array, // eslint-disable-line
  columns: PropTypes.array, // eslint-disable-line

  currentPeriod: PropTypes.string,
  availTests: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),

  errorMsg: PropTypes.string,
  submit: PropTypes.bool,
  forced: PropTypes.bool,
  forceUpdate: PropTypes.bool
};
export default LeafDiskCapacityPlanning;
