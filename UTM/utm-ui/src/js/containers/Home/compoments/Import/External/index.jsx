import React, { Fragment } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import Autosuggest from "react-autosuggest";
import moment from "moment";
import ImportFile from "./ImportFile";
import DateInput from "../../../../../components/DateInput";

class External extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      testType: "MT",
      todayDate: moment(),
      startDate: moment(),
      expectedDate: moment().add(14, "days"),

      materialTypeID: 0,
      materialStateID: 0,
      containerTypeID: 0,
      testProtocolID: 0,

      cropSelected: "",
      breedingStationSelected: "",

      isolationStatus: false,
      excludeControlPosition: false,
      btrControl: false,
      researcherName: "",

      slotValue: "",
      slotList: [],
      suggestions: [],
      userSlotsOnly: true
    };
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.slotList) {
      this.setState({ suggestions: nextProps.slotList });
    }
  }

  handleChange = e => {
    const { target } = e;
    const { name, value, type } = target;
    let val = "";
    if (type === "text") {
      val = value;
    } else if (type === "checkbox") {
      val = target.checked;
    } else if (value * 1) {
      val = value * 1;
    } else {
      val = value;
    }
    this.setState({ [name]: val });
    if (name === "testType" && (val !== "MT" || val !== "DI")) {
      this.setState({
        btrControl: false,
        researcherName: ""
      });
    }
    // reset researcher name if btr checkbox is unchecked
    if (name === "btrControl" && !val) {
      this.setState({ researcherName: "" });
    }
  };

  handlePlannedDateChange = date => {
    this.setState({
      startDate: date,
      expectedDate: moment(date).add(14, "days")
    });
  };
  handleExpectedDateChange = date => {
    this.setState({ expectedDate: date });
  };

  //reserved slots
  wellFetchRequested = ({ value }) => {
    const _this = this;
    const { testType } = this.state;
    const inputValue = value.trim().toLowerCase();
    clearTimeout(this.timer);
    this.timer = setTimeout(() => {
      _this.props.fetchApprovedSlots(inputValue, testType, _this.state.userSlotsOnly);
    }, 500);
  };
  wellClearRequested = () => {
    this.setState({ suggestions: [] });
  };
  wellSuggestionValue = value => {

    const ttype = this.props.testTypeList.find(
      test => test.testTypeID === value.testTypeID
    );

    const {
      slotName,
      plannedDate,
      expectedDate,
      materialTypeID,
      testProtocolID,
      materialStateID,
      cropCode,
      isolated,
      breedingStationCode
    } = value;
    this.setState({
      testType: ttype ? ttype.testTypeCode : "MT",
      materialTypeID,
      testProtocolID,
      materialStateID,
      cropSelected: cropCode,
      isolationStatus: isolated,
      breedingStationSelected: breedingStationCode,
      startDate: moment(plannedDate, userContext.dateFormat), // eslint-disable-line
      expectedDate: moment(expectedDate, userContext.dateFormat) // eslint-disable-line
    });

    return slotName;
  };

  handleUserSlotsOnly = () => {
    this.setState({
      userSlotsOnly: !this.state.userSlotsOnly,
      cropSelected: "",
      breedingStationSelected: "",
      slotValue: "",
      testType: "MT",
      materialTypeID: "",
      testProtocolID: "",
      materialStateID: "",
      isolationStatus: false,
      startDate: moment(),
      expectedDate: moment().add(14, "days")
    });
  };

  onSlotChange = (event, { newValue }) => {
    this.setState({ slotValue: newValue });
  };

  render() {
    const {
      testType,
      todayDate,
      startDate,
      expectedDate,
      materialTypeID,
      testProtocolID,
      materialStateID,
      containerTypeID,
      isolationStatus,
      cropSelected,
      breedingStationSelected,
      excludeControlPosition,
      btrControl,
      researcherName,
      slotValue,
      suggestions
    } = this.state;

    const inputProps = {
      placeholder: "Select Slot",
      value: slotValue,
      onChange: this.onSlotChange
    };

    //Filter test protocol
    let testProtocolList = [];
    let ttype = this.props.testTypeList.filter(o => o.testTypeCode == this.state.testType);
    if(ttype)
      testProtocolList = this.props.testProtocolList.filter(o => o.testTypeID === ttype[0].testTypeID);

    const checCond = testType === "DI" || testType === "MT"; // || testType === 'C&T';
    const enableBTR = testType === "MT" || testType === "DI";
    const enableLDisk = testType === "LDISK";
    return (
      <Fragment>
        <div className="import-modal">
          <div className="content">
            <div className="title">
              <span
                className="close"
                onClick={this.props.close}
                tabIndex="0"
                onKeyDown={() => {}}
                role="button"
              >
                &times;
              </span>
              <span>Import Data from External</span>
            </div>
            <div className="data-section">
              <div className="body">
                {(checCond || enableLDisk) && (
                    <Fragment>
                      <div>
                        <label>
                          Slot
                          <Autosuggest
                            suggestions={suggestions}
                            onSuggestionsFetchRequested={
                              this.wellFetchRequested
                            }
                            onSuggestionsClearRequested={
                              this.wellClearRequested
                            }
                            getSuggestionValue={this.wellSuggestionValue}
                            renderSuggestion={suggestion => (
                              <div>{suggestion.slotName}</div>
                            )}
                            inputProps={inputProps}
                            alwaysRenderSuggestions

                          />
                        </label>
                      </div>
                      <div className="markContainer class24">
                        <div
                          className="marker"
                          style={{ marginTop: "30px", maxWidth: "120px" }}
                        >
                          <input
                            type="checkbox"
                            id="userSlotsOnly"
                            name="userSlotsOnly"
                            checked={this.state.userSlotsOnly}
                            onChange={() => this.handleUserSlotsOnly()}
                          />
                          <label htmlFor="userSlotsOnly">My Slot(s) Only</label>{" "}
                          {/*eslint-disable-line*/}
                        </div>
                      </div>
                    </Fragment>
                  )}
                <div>
                  <label htmlFor="cropSelected">
                    Crops
                    <select
                      name="cropSelected"
                      value={this.state.cropSelected}
                      onChange={this.handleChange}
                      placeholder="Select crop"
                    >
                      <option value="">Select</option>
                      {this.props.crops.map(c => (
                        <option value={c} key={c}>
                          {c}
                        </option>
                      ))}
                    </select>
                  </label>
                </div>

                <div>
                  <label htmlFor="breedingStationSelected">
                    Br.Station
                    <select
                      name="breedingStationSelected"
                      value={this.state.breedingStationSelected}
                      onChange={this.handleChange}
                    >
                      <option value="">Select</option>
                      {this.props.breedingStation.map(b => (
                        <option
                          value={b.breedingStationCode}
                          key={b.breedingStationCode}
                        >
                          {b.breedingStationCode}
                        </option>
                      ))}
                    </select>
                  </label>
                </div>

                <div />

                <div>
                  <label>
                    Test Type
                    <select
                      name="testType"
                      value={this.state.testType}
                      onChange={this.handleChange}
                    >
                      {this.props.testTypeList.map(x => (
                        <option key={x.testTypeCode} value={x.testTypeCode}>
                          {x.testTypeName}
                        </option>
                      ))}
                    </select>
                  </label>
                </div>

                <DateInput
                  label="Planned Week"
                  todayDate={todayDate}
                  selected={startDate}
                  change={this.handlePlannedDateChange}
                />
                {!enableLDisk && (
                  <DateInput
                    label="Expected Week"
                    todayDate={startDate}
                    selected={expectedDate}
                    change={this.handleExpectedDateChange}
                  />
                )}

                <div>
                  <label htmlFor="cropSelected">
                    Material Type
                    <select
                      name="materialTypeID"
                      value={this.state.materialTypeID}
                      onChange={this.handleChange}
                    >
                      <option value="">Select</option>
                      {this.props.materialTypeList.map(x => (
                        <option
                          key={x.materialTypeCode}
                          value={x.materialTypeID}
                        >
                          {x.materialTypeDescription}
                        </option>
                      ))}
                    </select>
                  </label>
                </div>

                {enableLDisk && (
                   <div>
                   <label htmlFor="cropSelected">
                     Method
                     <select
                       name="testProtocolID"
                       value={this.state.testProtocolID}
                       onChange={this.handleChange}
                     >
                       <option value="">Select</option>
                       {testProtocolList.map(x => (
                         <option
                           key={x.testProtocolID}
                           value={x.testProtocolID}
                         >
                           {x.testProtocolName}
                         </option>
                       ))}
                     </select>
                   </label>
                 </div>
                )}

                {!enableLDisk && (
                  <div>
                  <label htmlFor="cropSelected">
                    Material State
                    <select
                      name="materialStateID"
                      value={this.state.materialStateID}
                      onChange={this.handleChange}
                    >
                      <option value="">Select</option>
                      {this.props.materialStateList.map(x => (
                        <option
                          key={x.materialStateCode}
                          value={x.materialStateID}
                        >
                          {x.materialStateDescription}
                        </option>
                      ))}
                    </select>
                  </label>
                </div>
                )}

                {!enableLDisk && (
                  <div>
                    <label htmlFor="cropSelected">
                      Container Type
                      <select
                        name="containerTypeID"
                        value={this.state.containerTypeID}
                        onChange={this.handleChange}
                      >
                        <option value="">Select</option>
                        {this.props.containerTypeList.map(x => (
                          <option
                            key={x.containerTypeCode}
                            value={x.containerTypeID}
                          >
                            {x.containerTypeName}
                          </option>
                        ))}
                      </select>
                    </label>
                  </div>
                )}

                {!enableLDisk && (
                  <div className="markContainer">
                    <div className="marker">
                      {/*
                        <label>&nbsp;</label>
                      */}
                      <input
                        type="checkbox"
                        name="isolationStatus"
                        id="isolationModal"
                        checked={this.state.isolationStatus}
                        onChange={this.handleChange}
                      />
                      <label htmlFor="isolationModal">Already Isolated</label>{" "}
                      {/*eslint-disable-line*/}
                    </div>
                  </div>
                )}

                {!enableLDisk && (
                  <div className="markContainer">
                    <div className="marker">
                      <input
                        type="checkbox"
                        id="excludeControlPosition"
                        name="excludeControlPosition"
                        checked={this.state.excludeControlPosition}
                        onChange={this.handleChange}
                      />
                      <label htmlFor="excludeControlPosition">
                        Exclude Position
                      </label>{" "}
                      {/*eslint-disable-line*/}
                    </div>
                  </div>
                )}
                
                {enableBTR && (
                  <div className="markContainer">
                    <div className="marker">
                      <input
                        type="checkbox"
                        id="btrControl"
                        name="btrControl"
                        // checked={props.excludeControlPosition}
                        checked={this.state.btrControl}
                        onChange={this.handleChange}
                      />
                      <label htmlFor="btrControl">BTR</label>{" "}
                      {/*eslint-disable-line*/}
                      {this.state.btrControl && (
                        <input
                          id="researcherName"
                          name="researcherName"
                          type="text"
                          value={this.state.researcherName}
                          onChange={this.handleChange}
                          placeholder="Researcher name"
                        />
                      )}
                    </div>
                  </div>
                )}
              </div>
              <div className="footer">
                <ImportFile
                  {...{
                    testType,
                    startDate,
                    expectedDate,
                    materialTypeID,
                    testProtocolID,
                    materialStateID,
                    containerTypeID,
                    isolationStatus,
                    cropSelected,
                    breedingStationSelected,
                    excludeControlPosition,
                    btrControl,
                    researcherName
                  }}
                  closeModal={this.props.close}
                  changeTabIndex={this.props.handleChangeTabIndex}
                  source={this.props.sourceSelected}
                />
              </div>
            </div>
          </div>
        </div>
      </Fragment>
    );
  }
}

const mapState = state => ({
  crops: state.user.crops,
  breedingStation: state.breedingStation.station,
  slotList: state.assignMarker.slotList
});

const mapDispatchToProps = dispatch => ({
  fetchApprovedSlots: (slotName, testType, userSlotsOnly) =>
    dispatch({
      type: "GET_APPROVED_SLOTS",
      slotName,
      testType,
      userSlotsOnly
    })
});

External.defaultProps = {
  breedingStation: [],
  crops: [],
  sourceSelected: "",
  containerTypeList: [],
  materialStateList: [],
  materialTypeList: [],
  testProtocolList: [],
  testTypeList: [],
  slotList: []
};
External.propTypes = {
  breedingStation: PropTypes.array, // eslint-disable-line
  crops: PropTypes.array, // eslint-disable-line
  sourceSelected: PropTypes.string,
  handleChangeTabIndex: PropTypes.func.isRequired,
  containerTypeList: PropTypes.array, // eslint-disable-line
  materialStateList: PropTypes.array, // eslint-disable-line
  materialTypeList: PropTypes.array, // eslint-disable-line
  testProtocolList: PropTypes.array,
  testTypeList: PropTypes.array, // eslint-disable-line
  close: PropTypes.func.isRequired,
  slotList: PropTypes.array, // eslint-disable-line
};
export default connect(
  mapState,
  mapDispatchToProps
)(External);
// export default {External};
// export default Test;
