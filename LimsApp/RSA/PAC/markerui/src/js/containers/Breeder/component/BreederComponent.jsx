import React, { Fragment } from "react";
import PropTypes from "prop-types";

import moment from "moment";
import DatePicker from "react-datepicker";
import "react-datepicker/dist/react-datepicker.css";
import ConfirmBox from "../../../components/Confirmbox/confirmBox";

import PHTable from "../../../components/PHTable/";
import { getDim } from "../../../helpers/helper";
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights-service';

class Breeder extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      list: props.slotList,
      pagenumber: props.pagenumber,
      pagesize: props.pagesize,
      total: props.total,

      breedingStation: props.breedingStation,
      crop: props.crop,
      testType: props.testType,
      materialState: props.materialState,
      materialType: props.materialType,

      sStation: "",
      sCrop: "",
      sTType: 1,
      sdeterminationRequired: false,
      sMState: "",
      sMType: "",
      isolated: false,
      plates: "",
      tests: "",

      currentPeriod: props.currentPeriod,
      expectedPeriod: props.expectedPeriod,
      availTests: props.availTests,
      availPlates: props.availPlates,

      errorMsg: props.errorMsg, // 'Error: allocation capacity',

      forced: props.forced,

      modeAdd: true,
      localFilter: props.filter,

      today: moment(),
      planned: null, // moment(),
      expected: moment(props.expectedDate, userContext.dateFormat) || null, // eslint-disable-line
    };
    props.pageTitle();
  }

  componentDidMount() {
    appInsights.trackPageView({ name: 'Breeder' });
    this.props.fetchForm();
    this.props.resetStoreBreeder();
    this.toReset();
    window.addEventListener("resize", this.updateDimensions);
    this.updateDimensions();
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.currentPeriod !== this.props.currentPeriod) {
      this.setState({ currentPeriod: nextProps.currentPeriod });
    }
    if (nextProps.expectedPeriod !== this.props.expectedPeriod) {
      this.setState({ expectedPeriod: nextProps.expectedPeriod });
    }
    if (nextProps.expectedDate !== this.props.expectedDate) {
      const check =
        moment(nextProps.expectedDate, userContext.dateFormat) || null; // eslint-disable-line

      if (check) {
        this.setState({ expected: check });
      }
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

    if (nextProps.breedingStation.length !== this.props.breedingStation) {
      this.setState({
        breedingStation: nextProps.breedingStation,
        crop: nextProps.crop,
        testType: nextProps.testType,
        materialState: nextProps.materialState,
        materialType: nextProps.materialType,
      });
    }

    if (nextProps.slotList !== this.props.slotList) {
      this.setState({
        list: nextProps.slotList,
      });
    }
    if (nextProps.pagenumber !== this.props.pagenumber) {
      this.setState({
        pagenumber: nextProps.pagenumber,
      });
    }
    if (nextProps.pagesize !== this.props.pagesize) {
      this.setState({
        pagesize: nextProps.pagesize,
      });
    }
    if (nextProps.total !== this.props.total) {
      this.setState({
        total: nextProps.total,
      });
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
      tblHeight: dim.height,
    });
  };

  toReset = () => {
    this.setState({
      sTType: 1,
      sdeterminationRequired: false,
      sMState: "",
      sMType: "",
      isolated: false,
      plates: "",
      tests: "",

      currentPeriod: "",
      expectedPeriod: "",
      availTests: 0,
      availPlates: 0,

      planned: null,
      expected: null,
    });
  };
  fetchTableDataOnChange = (name, value) => {
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

  changeSelect = (e) => {
    const { name, value } = e.target;
    const { sCrop, isolated, planned } = this.state; // sMType

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
          expected: null,
        });
        this.fetchTableDataOnChange(name, value);
        break;
      case "testType": {
        const determination = this.state.testType.find(
          (test) => test.testTypeID === parseInt(value) // eslint-disable-line
        );
        this.setState({
          sTType: value,
          sdeterminationRequired: !determination.determinationRequired, // !determination[0]['determinationRequired'], // eslint-disable-line
          tests: !determination.determinationRequired // !determination[0]['determinationRequired'] // eslint-disable-line
            ? ""
            : this.state.tests,
        });
        break;
      }
      case "materialType":
        this.plantTestFetch(sCrop, value, isolated, planned);
        this.setState({ sMType: value });
        break;
      case "materialState":
        this.setState({ sMState: value });
        break;
      case "plates":
        if (value > -1) {
          this.setState({ plates: value });
        }
        break;
      case "tests":
        if (value > -1) {
          this.setState({ tests: value });
        }
        break;
      default:
    }
  };

  handleIsolationChange = () => {
    const { sMType, sCrop, planned } = this.state;
    this.plantTestFetch(sCrop, sMType, !this.state.isolated, planned);
    this.setState({ isolated: !this.state.isolated });
  };

  handlePlannedDateChange = (date) => {
    const { sMType, sCrop, isolated } = this.state;
    this.plantTestFetch(sCrop, sMType, isolated, date);
    this.setState({ planned: date });
  };

  plantTestFetch = (crop, mType, isolated, planned) => {
    let planDate = "";
    if (planned !== null) {
      planDate = planned.format(userContext.dateFormat); // eslint-disable-line
    }

    if (planDate !== "" && crop !== "" && mType !== "") {
      this.props.plateTest(planDate, crop, mType, isolated);
    }
  };

  handleExpectedDateChange = (date) => {
    this.props.period(date.format(userContext.dateFormat).toString(), 2); // eslint-disable-line
    this.setState({ expected: date });
  };

  submit = () => {
    const {
      sStation,
      sCrop,
      sTType,
      sMState,
      sMType,
      isolated,
      planned,
      expected,
      plates,
      tests,
    } = this.state;

    let testValidation = false;
    if (this.state.sdeterminationRequired) {
      testValidation = true;
    } else {
      testValidation = tests !== "";
    }
    if (
      sStation !== "" &&
      sCrop !== "" &&
      sMState !== "" &&
      sMType !== "" &&
      planned !== "" &&
      expected !== "" &&
      plates !== "" &&
      testValidation
    ) {
      const obj = {
        breedingStationCode: sStation,
        cropCode: sCrop,
        testTypeID: sTType,
        materialTypeID: sMType,
        materialStateID: sMState,
        isolated,
        plannedDate: planned.format(userContext.dateFormat) || "", // eslint-disable-line
        expectedDate: expected.format(userContext.dateFormat) || "", // eslint-disable-line
        nrOfPlates: plates,
        nrOfTests: tests,
        forced: false,
      };
      this.props.reserve(obj);
    } else {
      this.showError();
    }
  };

  showError = () => {
    this.props.show_error({
      status: true,
      message: ["Please fill all required fields."],
      messageType: 2,
      notificationType: 0,
      code: "",
    });
  };

  forcedSubmit = (condition) => {
    const {
      sStation,
      sCrop,
      sTType,
      sMState,
      sMType,
      isolated,
      planned,
      expected,
      plates,
      tests,
    } = this.state;

    if (condition) {
      const obj = {
        breedingStationCode: sStation,
        cropCode: sCrop,
        testTypeID: sTType,
        materialTypeID: sMType,
        materialStateID: sMState,
        isolated,
        plannedDate: planned.format(userContext.dateFormat) || "", // eslint-disable-line
        expectedDate: expected.format(userContext.dateFormat) || "", // eslint-disable-line
        nrOfPlates: plates,
        nrOfTests: tests,
        forced: true,
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
  pageClick = (pg) => {
    const { sCrop, sStation } = this.state;
    const { pagesize, filter } = this.props;
    this.props.fetchSlot(sCrop, sStation, pg, pagesize, filter);
  };

  filterClearUI = () => {
    const { filter: filterLength } = this.props;
    if (filterLength < 1) return null;
    return (
      <button className='with-i' onClick={this.filterClear}>
        <i className='icon icon-cancel' />
        Filters
      </button>
    );
  };

  slotEdit = (id) => {
    const { modeAdd, list } = this.state;
    if (!modeAdd) return null;
    const {
      isolated,
      plannedDate,
      expectedDate,
      totalPlates,
      totalTests,
    } = list[id];

    this.setState({
      modeAdd: false,
      isolated, // slotID,
      sMType: 13,
      sMState: 2,
      planned: moment(plannedDate, userContext.dateFormat), // eslint-disable-line
      expected: moment(expectedDate, userContext.dateFormat), // eslint-disable-line
      plates: totalPlates,
      tests: totalTests,
    });

    return null;
  };

  editCancel = () => {
    this.setState({
      modeAdd: true,
      isolated: false,

      sMType: "",
      sMState: "",
      planned: "",
      expected: null,

      plates: "",
      tests: "",
    });
  };
  slotUpdate = () => {
    console.log("slot update acton");
  };

  slotDelete = (id) => {
    const { list, modeAdd, sCrop, sStation } = this.state;
    const { slotID, slotName } = list[id];
    if (!modeAdd) return null;

    if (confirm(`Are you sure to delete Slot: ${slotName}?`)) {
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
      dataType: "NVARCHAR(255)",
    };

    const check = localFilter.find((d) => d.name === obj.name);
    let newFilter = "";
    if (check) {
      newFilter = localFilter.map((item) => {
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

  render() {
    const { tblWidth, tblHeight, list, modeAdd } = this.state;
    const { pagenumber, pagesize, total } = this.state;
    const columns = [
      "Action",
      "cropCode",
      "breedingStationCode",
      "slotName",
      "periodName",
      "materialStateCode",
      "materialTypeCode",
      "totalPlates",
      "totalTests",
      "availablePlates",
      "availableTests",
      "statusName",
    ];
    const columnsMapping = {
      cropCode: { name: "Crop", filter: true, fixed: true },
      breedingStationCode: { name: "Br.Station", filter: true, fixed: true },
      slotName: { name: "Slot Name", filter: true, fixed: true },
      periodName: { name: "Period Name", filter: true, fixed: true },
      materialStateCode: { name: "Material State", filter: true, fixed: true },
      materialTypeCode: { name: "Material Type", filter: true, fixed: true },
      totalPlates: { name: "Total Plates", filter: true, fixed: true },
      totalTests: { name: "Total Tests", filter: true, fixed: true },
      availablePlates: { name: "Available Plates", filter: true, fixed: true },
      availableTests: { name: "Available Tests", filter: true, fixed: true },
      statusName: { name: "Status", filter: true, fixed: true },
      Action: { name: "Action", filter: false, fixed: false },
    };
    const columnsWidth = {
      cropCode: 80,
      breedingStationCode: 100,
      slotName: 160,
      periodName: 240,
      materialStateCode: 120,
      materialTypeCode: 120,
      availablePlates: 140,
      availableTests: 130,
      totalPlates: 120,
      totalTests: 120,
      statusName: 120,
      Action: 70,
    };

    const { today, planned, currentPeriod, expectedPeriod } = this.state;
    const { plates, tests, forced, availPlates, availTests } = this.state;
    let { expected } = this.state;
    const { breedingStation, crop, materialState, materialType } = this.state;
    const { testType, sStation, sCrop, sTType, sMState, sMType } = this.state;
    const { isolated } = this.state;

    let notallow = true;
    if (sMType !== "" && sCrop !== "" && planned !== null) {
      notallow = false;
    }

    const periodName = this.props.periodName.length
      ? this.props.periodName[0].periodName
      : "";

    if (expected) {
      if (expected.format("L") === "Invalid date") {
        expected = null;
      }
    }

    const subHeight = 355 - 20;
    const calcHeight = tblHeight - subHeight;
    const nHeight = calcHeight;

    return (
      <div className='breeder'>
        {forced && (
          <ConfirmBox message={this.state.errorMsg} click={this.forcedSubmit} />
        )}
        <section className='page-action'>
          <div className='left'>
            {this.filterClearUI()}
            <div className='form-e'>
              <label className='full12'>Current period : {periodName}</label>
            </div>
          </div>
        </section>

        <div className='container'>
          <div className='row'>
            <div className='form-e'>
              <label htmlFor='crop'>Crop *</label> {/* eslint-disable-line */}
              <select
                id='capacity_crop'
                name='crop'
                onChange={this.changeSelect}
                value={sCrop}
                disabled={!modeAdd}
              >
                <option value=''>Select Crop</option>
                {crop.map((cropList) => (
                  <option key={cropList.cropCode} value={cropList.cropCode}>
                    {cropList.cropCode} - {cropList.cropName}
                  </option>
                ))}
              </select>
            </div>
            <div className='form-e'>
              <label htmlFor='station'>Breeding Station *</label>{" "}
              {/* eslint-disable-line */}
              <select
                id='capacity_station'
                name='station'
                onChange={this.changeSelect}
                value={sStation}
                disabled={!modeAdd}
              >
                <option value=''>Select Station</option>
                {breedingStation.map((d) => (
                  <option
                    key={d.breedingStationCode}
                    value={d.breedingStationCode}
                  >
                    {d.breedingStationCode}
                  </option>
                ))}
              </select>
            </div>
            <div className='form-e'>
              <label htmlFor='testType'>Test Type</label>{" "}
              {/* eslint-disable-line */}
              <select
                id='capacity_testType'
                name='testType'
                onChange={this.changeSelect}
                value={sTType}
                disabled={!modeAdd}
              >
                {testType.map((testList) => (
                  <option
                    key={`${testList.testTypeID}-${testList.testTypeName}`}
                    value={testList.testTypeID}
                  >
                    {testList.testTypeName}
                  </option>
                ))}
              </select>
            </div>
            <div className='form-e'>
              <label>&nbsp;</label> {/* eslint-disable-line */}
              <div className='checkBox'>
                <input
                  checked={isolated || false}
                  type='checkbox'
                  id='isolationBreeder'
                  onChange={this.handleIsolationChange}
                  disabled={!modeAdd}
                />
                <label htmlFor='isolationBreeder'>Isolated</label>{" "}
                {/* eslint-disable-line */}
              </div>
            </div>
          </div>
          <div className='row'>
            <div className='form-e'>
              <label htmlFor='materialType'>Material Type *</label>{" "}
              {/* eslint-disable-line */}
              <select
                id='capacity_materialType'
                name='materialType'
                onChange={this.changeSelect}
                value={sMType}
                disabled={!modeAdd}
              >
                <option value=''>Select Material Type</option>
                {materialType.map((materialTypeList) => {
                  const {
                    materialTypeID,
                    materialTypeCode,
                    materialTypeDescription,
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
            <div className='form-e'>
              <label htmlFor='materialState'>Material State *</label>{" "}
              {/* eslint-disable-line */}
              <select
                id='capacity_materialState'
                name='materialState'
                onChange={this.changeSelect}
                value={sMState}
                disabled={!modeAdd}
              >
                <option value=''>Select Material State</option>
                {materialState.map((materialStateList) => {
                  const {
                    materialStateID,
                    materialStateCode,
                    materialStateDescription,
                  } = materialStateList;
                  return (
                    <option key={materialStateID} value={materialStateID}>
                      ({materialStateCode}) {materialStateDescription}
                    </option>
                  );
                })}
              </select>
            </div>
            <div className='form-e'>
              <label htmlFor='materialState'>
                {" "}
                {/* eslint-disable-line */}
                Planned Date * {currentPeriod ? ` (${currentPeriod})` : ""}
              </label>
              <DatePicker
                id='capacity_planned'
                selected={planned || null}
                minDate={today}
                onChange={this.handlePlannedDateChange}
                dateFormat={userContext.dateFormat} // eslint-disable-line
                showWeekNumbers
                locale='en-gb'
              />
            </div>
            <div className='form-e'>
              <label htmlFor='materialState'>
                {" "}
                {/* eslint-disable-line */}
                Expected Date * {expectedPeriod ? ` (${expectedPeriod})` : ""}
              </label>
              <DatePicker
                id='capacity_expected'
                selected={expected || null}
                minDate={planned || today}
                disabled={notallow}
                onChange={this.handleExpectedDateChange}
                dateFormat={userContext.dateFormat} // eslint-disable-line
                showWeekNumbers
                locale='en-gb'
              />
            </div>
          </div>

          <div className='row'>
            <div className='form-e'>
              <label htmlFor='materialState'>
                {" "}
                {/* eslint-disable-line */}
                Number of plates * {availPlates ? `(${availPlates})` : ""}
              </label>
              <input
                id='capacity_plates'
                type='number'
                name='plates'
                value={plates}
                onChange={this.changeSelect}
                disabled={!modeAdd}
              />
            </div>
            <div className='form-e'>
              <label htmlFor='materialState'>
                {" "}
                {/* eslint-disable-line */}
                Number of tests * {availTests ? `(${availTests})` : ""}
              </label>
              <input
                id='capacity_test'
                type='number'
                name='tests'
                value={tests}
                disabled={this.state.sdeterminationRequired || !modeAdd}
                onChange={this.changeSelect}
              />
            </div>
            <div className='form-e'>
              <label>&nbsp;</label>
              {modeAdd === true && (
                <button id='capacity_reserve_btn' onClick={this.submit}>
                  Reserve Capacity
                </button>
              )}
              {modeAdd === false && (
                <Fragment>
                  <button onClick={this.slotUpdate}>Update</button>
                  &nbsp;&nbsp;
                  <button onClick={this.editCancel}>Cancel</button>
                </Fragment>
              )}
            </div>
            <div />
          </div>
        </div>

        <div className='container'>
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
              edit: (slotID) => this.slotEdit(slotID),
              delete: (slotID) => this.slotDelete(slotID),
            }}
          />
        </div>
      </div>
    );
  }
}

Breeder.defaultProps = {
  slotList: [],
  filter: [],

  breedingStation: [],
  crop: [],
  testType: [],
  materialState: [],
  materialType: [],
  periodName: [],

  currentPeriod: "",
  expectedPeriod: "",
  availTests: 0,
  availPlates: 0,

  errorMsg: "",
  submit: false,
  forced: false,
  expectedDate: null,
};
Breeder.propTypes = {
  // slotEdit: PropTypes.func.isRequired,
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

  pageTitle: PropTypes.func.isRequired,
  reserve: PropTypes.func.isRequired,
  fetchForm: PropTypes.func.isRequired,
  plateTest: PropTypes.func.isRequired,
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
  materialState: PropTypes.array, // eslint-disable-line
  materialType: PropTypes.array, // eslint-disable-line
  periodName: PropTypes.array, // eslint-disable-line

  currentPeriod: PropTypes.string,
  expectedPeriod: PropTypes.string,
  availTests: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),
  availPlates: PropTypes.oneOfType([PropTypes.number, PropTypes.string]),

  errorMsg: PropTypes.string,
  submit: PropTypes.bool,
  forced: PropTypes.bool,
  expectedDate: PropTypes.oneOfType([PropTypes.object, PropTypes.string]),
};

export default withAITracking(reactPlugin, Breeder);
