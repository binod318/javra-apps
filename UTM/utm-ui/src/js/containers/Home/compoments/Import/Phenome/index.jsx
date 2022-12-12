import React, { Fragment } from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import Autosuggest from "react-autosuggest";
import moment from "moment";
import TwoGB from "./components/TwoGB";
import SeedTwoSeed from "./components/SeedTwoSeed";
import ThreeGB from "./components/ThreeGB";
import Exist from "./components/Exist";
import CNT from "./components/CNT";
import RDT from "./components/RDT";
import SeedHealth from "./components/SeedHealth";
import LeafDisk from "./components/LeafDisk";
import Login from "./components/Login";
import Treeview from "./components/Treeview";
import ConfirmBox from "../../../../../components/Confirmbox/confirmBox";

import { phenomeLogin, importPhenomeAction } from "../../../actions/phenome";
import { fetchConfigurationList } from "../../../actions";
import { hiddenTesttypes } from "../../../../../helpers/helper";

const initPhenome = {
  importLevel: "PLT",
  importSource: "Phenome",
  sourceID: 0,
  todayDate: moment(),
  startDate: moment(),
  expectedDate: moment().add(14, "days"),

  materialTypeID: "",
  testProtocolID: "",
  materialStateID: "",
  containerTypeID: "",

  //leafdisk
  //testProtocolList: [],

  fileName: "",

  objectID: "",
  objectType: "",
  researchGroupID: "",
  cropID: "",
  folderObjectType: "",
  researchGroupObjectType: "",

  isolationStatus: false,
  cumulateStatus: false,

  // 3GB
  threeGBTaskID: "",
  cropSelected: "",
  breedingStationSelected: "",

  // Confirm
  warningFlag: false,
  warningMessage: "",

  // S2S
  year: "", // new Date().getFullYear(),
  capacitySlotList: [],
  capacityList: [],
  capacitySlot: "",
  capacitySlotName: "",
  location: "",
  maxPlants: "",
  cordysStatus: "",
  availPlants: "",
  excludeControlPosition: false,
  slotValue: "",
  suggestions: [],
  slotList: [],
  userSlotsOnly: true,
  sites: [],
  siteID: "",
  btrControl: false,
  researcherName: "",

  //Seed health
  sampleType: ""
};

class Phenome extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      testType: props.testType ? props.testType : 'MT',

      ...initPhenome,
      sourceSelected: props.sourceSelected,
      existFile: props.existFile,

      // Confirm
      warningFlag: props.warningFlag,
      warningMessage: props.warningMessage
    };
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.sites.length) {
      this.setState({
        sites: nextProps.sites
      });
    }
    if (nextProps.warningFlag !== this.props.warningFlag) {
      this.setState({
        warningFlag: nextProps.warningFlag,
        warningMessage: nextProps.warningMessage
      });
    }
    if (nextProps.capacitySlotList) {
      this.setState({
        capacitySlotList: nextProps.capacitySlotList,
        capacityList: nextProps.capacitySlotList
      });
    }
    if (nextProps.slotList) {
      this.setState({ suggestions: nextProps.slotList });
    }
  }

  componentDidMount() {
    if(this.props.testType === "RDT" || this.props.testType === "LDISK" || this.props.testType === "SeedHealth")
      this.props.fetchGetSites();

    if(this.props.testType === "LDISK")
      this.props.fetchConfigurationList();
  }

  onSlotChange = (event, { newValue }) => {
    this.setState({ slotValue: newValue });
  };

  getToken = () => sessionStorage.getItem("adal.idtoken");

  handleChange = e => {
    const { testType } = this.state;
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

    if (name === "importSource") {
      this.setState({ importSource: val });
    }

    if (name === "sampleList") {
      this.setState({ sourceID: val });
    }

    // reset researcher name if btr checkbox is unchecked
    if (name === "btrControl" && !val) {
      this.setState({ researcherName: "" });
    }

    if (name === "testType") this.resetState();

    if (name === "testType" && (value === "RDT" || value === "LDISK" || value === "SeedHealth")) {
      this.props.fetchGetSites();
    }

    if (name === "testType" && value === "LDISK") {
      this.props.fetchConfigurationList();
    }

    // IN 3GB type getting filename
    if (name === "threeGBTaskID") {
      const { threegbList } = this.props;
      const projectName = threegbList.find(x => x.threeGBTaskID === value * 1);
      // const { threeGBProjectcode: fileName } = projectName;
      this.setState({
        fileName: projectName.threeGBProjectcode || ""
      }); // threeGBProjectcode
    }
    /**
     * Product List fetch not required in TestType S2S
     */
    if (type !== "checkbox" && testType !== "S2S")
      this.changeFetch(name, value);

    if (testType === "S2S") {
      const {
        cropSelected,
        // breedingStationSelected,
        year,
        importLevel
      } = this.state;
      const s2sCond1 =
        name === "cropSelected" &&
        // breedingStationSelected !== '' &&
        value !== "";
      const s2sCond2 =
        name === "breedingStationSelected" &&
        cropSelected !== "" &&
        value !== "";
      const s2sCond3 = name === "importLevel" && cropSelected !== "";
      // &&
      // breedingStationSelected;
      if (s2sCond1) {
        this.props.fetchS2SCapacity({
          breEzysAdministration: "PH", // breedingStationSelected.slice(0, 2),
          crop: value,
          year,
          importLevel
        });
      }

      if (s2sCond2) {
        this.props.fetchS2SCapacity({
          breEzysAdministration: value.slice(0, 2),
          crop: cropSelected,
          year,
          importLevel
        });
      }

      if (s2sCond3) {
        this.props.fetchS2SCapacity({
          breEzysAdministration: "PH", // breedingStationSelected.slice(0, 2),
          crop: cropSelected,
          year,
          importLevel: value
        });
      }
    }

    const { capacitySlotList } = this.state;
    if (name === "capacitySlot") {
      if (value === "") {
        this.setState({
          maxPlants: "",
          cordysStatus: "",
          availPlants: "",
          location: "",
          capacityList: capacitySlotList
        });
        return null;
      }
      const selected = capacitySlotList.find(
        c => c.capacitySlotID === value * 1
      );
      const {
        // capacitySlotID,
        maxPlants,
        status: cordysStatus,
        dH0Location: location,
        availableNrPlants: availPlants,
        sowingDate,
        expectedDeliveryDate,
        sowingCode
      } = selected;

      this.setState({
        location,
        maxPlants,
        cordysStatus,
        availPlants,
        startDate: sowingDate,
        expectedDate: moment(expectedDeliveryDate),
        capacitySlotName: sowingCode
      });
    }
    /*
        capacitySlotList: [],
        capacitySlot: '',
        location: ''
        */
    if (name === "location") {
      const newCapacitySlotList = capacitySlotList
        .map(x => {
          if (x.dH0Location == value) return x; // eslint-disable-line
          return null;
        })
        .filter(Boolean);
      this.setState({
        capacitySlot: "",
        capacityList: value !== "" ? newCapacitySlotList : capacitySlotList
      });
    }
    return null;
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

  filterTestType = testType => {

    var selectedMenu = window.localStorage.getItem("selectedMenuGroup");

    //do not filter if menu selected is not present
    if(!selectedMenu || selectedMenu == '')
      return true;

    selectedMenu = selectedMenu.toLowerCase();

    //rdt, seedhealth (same menu name and testtypecode)
    if(selectedMenu === testType.testTypeCode.toLowerCase())
      return true;

    //other than rdt, leafdisk, seedhealth
    if(selectedMenu === "utmgeneral" && testType.testTypeID < 8)
      return true;

    //leafdisk whose testtypecode is ldisk
    if(selectedMenu === "leafdisk" && testType.testTypeCode.toLowerCase() === "ldisk")
      return true;

    return false;
  };

  testTypeUI = () => (
    <div>
      <label>
        Test Type
        <select
          id="import_testType"
          name="testType"
          value={this.state.testType}
          onChange={this.handleChange}
        >
          {this.props.testTypeList
            .filter(testType => {
              if(hiddenTesttypes().split('|').find(o => o == testType.testTypeCode.toLowerCase())) // Hide testtype
                return false;
              return true;
            })
            .filter(testType => {
              //filter testtype with menu group
              return this.filterTestType(testType);
            })
            .map(x => (
              <option key={x.testTypeCode} value={x.testTypeCode}>
                {x.testTypeName}
              </option>
            ))}
        </select>
      </label>
    </div>
  );

  testComponentUI = testType => {
    const { existFile } = this.props;
    if (existFile) return <Exist {...this.state} />;

    if (testType === "DI" || testType === "MT" || testType === "BTR")
      return (
        <Fragment>
          {this.testTypeUI()}
          <TwoGB
            {...this.props}
            handleChange={this.handleChange}
            handlePlannedDateChange={this.handlePlannedDateChange}
            handleExpectedDateChange={this.handleExpectedDateChange}
            {...this.state}
          />
        </Fragment>
      );

    if (testType === "S2S")
      return (
        <Fragment>
          {this.testTypeUI()}
          <SeedTwoSeed
            {...this.props}
            handleChange={this.handleChange}
            handlePlannedDateChange={this.handlePlannedDateChange}
            handleExpectedDateChange={this.handleExpectedDateChange}
            {...this.state}
          />
        </Fragment>
      );

    if (testType === "C&T") {
      return (
        <Fragment>
          {this.testTypeUI()}
          <CNT
            {...this.props}
            handleChange={this.handleChange}
            handlePlannedDateChange={this.handlePlannedDateChange}
            handleExpectedDateChange={this.handleExpectedDateChange}
            {...this.state}
          />
        </Fragment>
      );
    }

    if (testType === "RDT") {
      return (
        <Fragment>
          {this.testTypeUI()}
          <RDT
            {...this.props}
            handleChange={this.handleChange}
            handlePlannedDateChange={this.handlePlannedDateChange}
            handleExpectedDateChange={this.handleExpectedDateChange}
            {...this.state}
          />
        </Fragment>
      );
    }

    //LeafDisk
    if (testType === "LDISK") {
      return (
        <Fragment>
          {this.testTypeUI()}
          <LeafDisk
            {...this.props}
            handleChange={this.handleChange}
            handlePlannedDateChange={this.handlePlannedDateChange}
            {...this.state}
          />
        </Fragment>
      );
    }

    //Seed health
    if (testType === "SeedHealth") {
      return (
        <Fragment>
          {this.testTypeUI()}
          <SeedHealth
            {...this.props}
            handleChange={this.handleChange}
            handlePlannedDateChange={this.handlePlannedDateChange}
            handleExpectedDateChange={this.handleExpectedDateChange}
            {...this.state}
          />
        </Fragment>
      );
    }

    return (
      <Fragment>
        {this.testTypeUI()}
        <ThreeGB
          {...this.props}
          handleChange={this.handleChange}
          {...this.state}
        />
      </Fragment>
    );
  };

  fetchPhenomToken = () => {
    this.props.fetchPhenomToken(token => {
      this.props.testLogin(token);
    });
  };

  resetState = () => {
    this.setState({ ...initPhenome });
  };

  changeFetch = (name, value) => {
    if (name === "threeGBTaskID") {
      const { testTypeID } = this.state;
      const { threegbList } = this.props;
      const projectDisplay = testTypeID === 4 || testTypeID === 5;
      if (projectDisplay) {
        let threegbFilename = "";
        threegbList.map(d => {
          if (d.threeGBTaskID === value * 1) {
            threegbFilename = d.threeGBProjectcode;
          }
          return null;
        });
        this.setState({
          fileName: threegbFilename
        });
      }
    }

    const { cropSelected, breedingStationSelected, testType } = this.state;
    const { fetchProjectList } = this.props;
    if (name === "cropSelected") {
      if (breedingStationSelected !== "") {
        fetchProjectList(value, breedingStationSelected, testType);
      }
      this.setState({ threeGBTaskID: "", fileName: "" });
    }
    if (name === "breedingStationSelected") {
      if (cropSelected !== "" && value !== "") {
        fetchProjectList(cropSelected, value, testType);
      }
      this.setState({ threeGBTaskID: "", fileName: "" });
    }
  };

  saveTreeObjectData = (
    objectType,
    objectID,
    cropID,
    researchGroupID,
    folderObjectType,
    researchGroupObjectType
  ) => {
    const obj = {
      objectID,
      objectType,
      researchGroupID: folderObjectType == 4 ? researchGroupID : null, // eslint-disable-line
      cropID,
      folderObjectType,
      researchGroupObjectType
    };

    this.setState(obj);
  };

  showErrorFunc = message => {
    this.props.showError({
      type: "NOTIFICATION_SHOW",
      status: true,
      message,
      messageType: 2,
      notificationType: 0,
      code: ""
    });
  };

  importPhenomeData = forcedImport => {
    const {
      testType,
      materialTypeID,
      testProtocolID,
      materialStateID,
      containerTypeID,
      objectID,
      objectType,
      fileName,
      startDate,
      expectedDate,
      cropID,
      folderObjectType,
      researchGroupObjectType,
      researchGroupID,
      isolationStatus,
      cumulateStatus,
      threeGBTaskID,
      cropSelected: cropCode,
      breedingStationSelected: brStationCode,
      sourceSelected: source,
      importLevel,
      existFile,
      capacitySlotName,
      excludeControlPosition,
      siteID,
      btrControl,
      researcherName,
      importSource,
      sourceID,
      sampleType
    } = this.state;

    let inValid = false;
    const messageArray = [];

    //get selected menu
    let selectedMenu = window.localStorage.getItem("selectedMenuGroup");

    const determination = this.props.testTypeList.find(
      test => test.testTypeCode === testType
    );
    const { testTypeID, determinationRequired } = determination;

    const ThreeGBType = testType === "GMAS" || testType === "3GBProject";
    const SeedToSeed = testType === "S2S";
    const CandT = testType === "C&T";
    const RDTCondition = testType === "RDT";
    const SeedHealthCondition = testType === "SeedHealth";
    const LDiskCondition = testType === "LDISK";
    const mmcCondition =
      materialTypeID === "" || materialStateID === "" || containerTypeID === "";

    //if Leafdisk and import from Sample list
    if(LDiskCondition && importSource === "SampleList") {

      if (materialTypeID === "" || materialTypeID === 0 || testProtocolID === "" || testProtocolID === 0 || siteID === "" || siteID === 0) {
        inValid = true;
        messageArray.push("Please select Lab Location, Material Type and Method.");
      }

      if (fileName === "") {
        inValid = true;
        messageArray.push("Please provide file name.");
      }

      if (sourceID === "" || sourceID === 0) {
        inValid = true;
        messageArray.push("Please select configuration from list.");
      }

      const importObj = {
        sourceID,
        forcedImport,
        //cropCode,
        //brStationCode,
        testTypeID,
        materialTypeID,
        testProtocolID,
        //materialStateID,
        //containerTypeID,
        plannedDate: startDate.format(window.userContext.dateFormat),
        // expectedDate:
        //   testType !== "S2S"
        //     ? expectedDate.format(window.userContext.dateFormat)
        //     : expectedDate,
        //isolated: isolationStatus,
        //folderID: researchGroupID,
        //objectID: objectID.split("~")[0], // TOD check
        //objectType,
        //cropID,
        //folderObjectType,
        //researchGroupObjectType,
        testName: fileName,
        //source,
        //determinationRequired,
        //threeGBTaskID,
        //cumulate: cumulateStatus,
        //importLevel,
        //capacitySlotName,
        //excludeControlPosition,
        siteID,
        //btr: btrControl,
        //researcherName,
        testTypeMenu: selectedMenu
      };

      this.props.importPhenome(importObj);

      return null;
    }

    //Seed Health
    if(SeedHealthCondition && (researchGroupID == null || researchGroupID == 0)) {
      inValid = true;
      messageArray.push(
        "Unable to import Lot from this level. Please import from country level !"
      );
    }

    const diffDate = expectedDate.diff(startDate, "days");
    if (diffDate < 14) {
      if (
        /* eslint-disable */
        !confirm(
          "Normal test time is 14 days, please confirm with the lab before proceeding or update expected date. Continue ?"
        )
        /* eslint-enable */
      ) {
        return null;
      }
    }

    if (existFile) {
      const { selectedFile: file } = this.props;

      const determination = this.props.testTypeList.find(
        test => test.testTypeCode === testType
      );

      if (inValid) {
        this.showErrorFunc(messageArray);
        return null;
      }

      // testTypeID
      const { determinationRequired } = determination;
      const newObj = {
        cropCode: file.cropCode,
        brStationCode: file.breedingStationCode,
        testTypeID: file.testTypeID,
        materialTypeID: file.materialTypeID,
        testProtocolID: file.testProtocolID,
        materialStateID: file.materialstateID,
        containerTypeID: file.containerTypeID,
        plannedDate: file.plannedDate,
        expectedDate: file.expectedDate,
        isolated: file.isolated,

        forcedImport,

        folderID: researchGroupID,
        objectID: objectID.split("~")[0], // TOD check
        objectType,
        cropID,
        folderObjectType,
        researchGroupObjectType,

        testName: file.fileTitle,
        source: file.source,

        determinationRequired,
        cumulate: file.cumulate,
        importLevel: file.importLevel,
        fileID: file.fileID,
        capacitySlotName,
        excludeControlPosition,
        siteID,
        sampleType,
        testTypeMenu: selectedMenu
      };
      this.props.importPhenome(newObj);
      return null;
    }

    if (
      !ThreeGBType &&
      !SeedToSeed &&
      !CandT &&
      !RDTCondition &&
      !LDiskCondition &&
      !SeedHealthCondition &&
      mmcCondition
    ) {
      inValid = true;
      messageArray.push(
        "Please select Material Type, Material State and Container Type."
      );
    }

    if ((RDTCondition || SeedHealthCondition || LDiskCondition) && !siteID) {
      inValid = true;
      messageArray.push("Please select site location.");
    }

    if (SeedHealthCondition && sampleType === "") {
      inValid = true;
      messageArray.push("Please select sample type.");
    }

    if (objectID === "" || objectType === "") {
      inValid = true;
      messageArray.push("Please select object from the tree.");
    }

    if (fileName === "") {
      const fNameMsg = ThreeGBType
        ? "Please select Project."
        : "Please provide file name.";
      inValid = true;
      messageArray.push(fNameMsg);
    }

    if (btrControl && researcherName.trim() === "") {
      inValid = true;
      messageArray.push("Please provide Researcher name when BTR is selected.");
    }

    if (LDiskCondition &&
      (materialTypeID === "" || materialTypeID === 0 || testProtocolID === "" || testProtocolID === 0 || siteID === "" || siteID === 0)) {
      inValid = true;
      messageArray.push("Please select Lab Location, Material Type and Method.");
    }

    if (inValid) {
      this.showErrorFunc(messageArray);
      return null;
    }

    const importObj = {
      forcedImport,
      cropCode,
      brStationCode,
      testTypeID,
      materialTypeID,
      testProtocolID,
      materialStateID,
      containerTypeID,
      plannedDate:
        testType !== "S2S"
          ? startDate.format(window.userContext.dateFormat)
          : startDate,
      expectedDate:
        testType !== "S2S"
          ? expectedDate.format(window.userContext.dateFormat)
          : expectedDate,
      isolated: isolationStatus,
      folderID: researchGroupID,
      objectID: objectID.split("~")[0], // TOD check
      objectType,
      cropID,
      folderObjectType,
      researchGroupObjectType,
      testName: fileName,
      source,
      determinationRequired,
      threeGBTaskID,
      cumulate: cumulateStatus,
      importLevel,
      capacitySlotName,
      excludeControlPosition,
      siteID,
      btr: btrControl,
      researcherName,
      sampleType,
      testTypeMenu: selectedMenu
    };

    if (SeedToSeed) {
      const {
        maxPlants,
        cordysStatus,
        location: dH0Location,
        capacitySlot: capacitySlotID,
        availPlants,
        startDate: plannedDate,
        expectedDate: ed,
        capacitySlotName: csn
      } = this.state;
      this.props.importPhenome({
        ...importObj,
        ...{
          capacitySlotID,
          maxPlants,
          cordysStatus,
          dH0Location,
          availPlants,
          plannedDate,
          expectedDate: ed,
          capacitySlotName: csn,
          siteID
        }
      });
      return null;
    }
    this.props.importPhenome(importObj);
    return null;
  };

  forceConfirm = choice => {
    // importPhemoneExisting, close
    const { confirmationNo } = this.props;
    if (choice) {
      confirmationNo();
      this.importPhenomeData(true);
    } else {
      confirmationNo();
    }
  };

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
    const testTypeCode = ttype ? ttype.testTypeCode : "MT";

    const {
      slotName,
      plannedDate,
      expectedDate,
      materialTypeID,
      testProtocolID,
      siteID,
      materialStateID,
      cropCode,
      breedingStationCode,
      isolated
    } = value;

    //fetch sites and sample list when slot selects for leaf disk
    if(siteID > 0) {
      this.props.fetchGetSites();
      this.props.fetchConfigurationList();
    }

    this.setState({
      testType: testTypeCode,
      materialTypeID,
      testProtocolID,
      siteID,
      materialStateID,
      cropSelected: cropCode,
      breedingStationSelected: breedingStationCode,
      isolationStatus: isolated,
      startDate: moment(plannedDate, userContext.dateFormat), // eslint-disable-line
      expectedDate: moment(expectedDate, userContext.dateFormat) // eslint-disable-line
    });

    if(testTypeCode !== "LDISK")
      this.setState({ importSource : "Phenome" });

    /**
     slotID: 5181
      slotName: "NLEN-LT-05181"
      cropCode: "LT"
      plannedDate: "07/05/2020"
      expectedDate: "21/05/2020"
      materialTypeID: 2
      materialStateID: 1
      isolated: false
     */
    return slotName;
  };

  handleUserSlotsOnly = () => {
    this.setState({
      userSlotsOnly: !this.state.userSlotsOnly,
      cropSelected: "",
      slotValue: "",
      materialTypeID: "",
      testProtocolID: "",
      containerTypeID: "",
      siteID: "",
      materialStateID: "",
      isolationStatus: false,
      importSource: "Phenome",
      startDate: moment(),
      expectedDate: moment().add(14, "days")
    });
  };

  render() {
    const {
      testType,
      warningFlag,
      warningMessage,
      slotValue,
      suggestions,
      cropSelected,
      breedingStationSelected
    } = this.state;

    let configurationList = this.props.configurationList.filter(o => o.cropCode === cropSelected && o.breedingStationCode === breedingStationSelected);

    const inputProps = {
      placeholder: "Select Slot",
      value: slotValue,
      onChange: this.onSlotChange
    };

    const checCond = testType === "DI" || testType === "MT" || testType === "LDISK"; // || testType === 'C&T';
    let validObjectTypeList = '';

    if (testType === 'LDISK')
      validObjectTypeList = ['26','27','28'];
    else if (testType === 'SeedHealth')
      validObjectTypeList = ['27','28','37'];
    else
      validObjectTypeList = ['24'];

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
              <span>Import Data from Phenome</span>
            </div>

            <div className="data-section phenome-container">
              <div className="data-section">
                <div className="body">
                  {checCond && (
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
                  {this.testComponentUI(testType)}
                </div>
                <div className="body2" />
                <div className="footer">
                  <button
                    id="import_data_btn"
                    onClick={() => this.importPhenomeData(false)}
                  >
                    Import data
                  </button>
                </div>
              </div>
              <div className="phenome-section">
                {this.state.importSource === "SampleList" ? (
                  <label htmlFor="sampleList">
                  Sample List
                  <select
                    id="sampleList"
                    name="sampleList"
                    value={this.state.sourceID}
                    onChange={this.handleChange}
                    key
                  >
                    <option value="">Select</option>
                    {configurationList.map(x => (
                      <option key={x.id} value={x.id}>
                        {x.name}
                      </option>
                    ))}
                  </select>
                </label>
                ) : (
                  this.props.isLoggedIn ? (
                    <Treeview validObjectTypeList={validObjectTypeList} saveTreeObjectData={this.saveTreeObjectData} />
                  ) : (
                    <Fragment>
                      {window.adalConfig.enabled ? (
                        <div className="flexCenterCenter">
                          <button
                            onClick={this.fetchPhenomToken}
                            id="import_phenome_loging_btn"
                          >
                            Phenome Login
                          </button>
                        </div>
                      ) : (
                        <Login />
                      )}
                    </Fragment>
                  ))}
              </div>
            </div>
          </div>
        </div>
        {warningFlag && (
          <ConfirmBox click={this.forceConfirm} message={warningMessage} />
        )}
      </Fragment>
    );
  }
}

const mapStateToProps = state => ({
  phenomeLogin,
  isLoggedIn: state.phenome.isLoggedIn,
  crops: state.user.crops,
  breedingStation: state.breedingStation.station,
  threegbList: state.assignMarker.threegb,
  selectedFile: state.assignMarker.file.selected,
  capacitySlotList: state.assignMarker.s2sCapacitySlot,
  slotList: state.assignMarker.slotList,
  sites: state.assignMarker.getSites,
  configurationList: state.assignMarker.configurationList
});
const mapDispatchToProps = dispatch => ({
  importPhenome: data => dispatch(importPhenomeAction(data)),
  fetchProjectList: (crop, breeding, testTypeCode) =>
    dispatch({
      type: "THREEGB_PROJECTLIST_FETCH",
      crop,
      breeding,
      testTypeCode
    }),
  testLogin: tok => dispatch(phenomeLogin(tok)),
  confirmationNo: () => dispatch({ type: "PHENOME_WARNING_FALSE" }),
  fetchS2SCapacity: obj => dispatch({ type: "FETCH_S2S_CAPACITY", ...obj }),
  fetchApprovedSlots: (slotName, testType, userSlotsOnly) =>
    dispatch({
      type: "GET_APPROVED_SLOTS",
      slotName,
      testType,
      userSlotsOnly
    }),
  fetchGetSites: () => dispatch({ type: "FETCH_GETSITES" }),
  fetchConfigurationList: () => dispatch(fetchConfigurationList()),

  fetchPhenomToken: callback =>
    dispatch({ type: "FETCH_PHENOM_TOKEN", callback })
});

Phenome.defaultProps = {
  testTypeList: [],
  threegbList: [],
  slotList: [],
  capacitySlotList: [],
  warningMessage: [],
  sourceSelected: ""
};
Phenome.propTypes = {
  sites: PropTypes.array, // eslint-disable-line
  fetchGetSites: PropTypes.func.isRequired,
  fetchConfigurationList:  PropTypes.func.isRequired,
  isLoggedIn: PropTypes.bool.isRequired,
  close: PropTypes.func.isRequired,
  confirmationNo: PropTypes.func.isRequired,
  importPhenome: PropTypes.func.isRequired,
  selectedFile: PropTypes.object, // eslint-disable-line
  showError: PropTypes.func.isRequired,
  fetchProjectList: PropTypes.func.isRequired,
  testLogin: PropTypes.func.isRequired,
  testTypeList: PropTypes.array, // eslint-disable-line
  fetchS2SCapacity: PropTypes.func.isRequired,
  threegbList: PropTypes.array, // eslint-disable-line
  slotList: PropTypes.array, // eslint-disable-line
  capacitySlotList: PropTypes.array, // eslint-disable-line
  warningMessage: PropTypes.array, // eslint-disable-line
  warningFlag: PropTypes.bool.isRequired,
  existFile: PropTypes.bool.isRequired,
  sourceSelected: PropTypes.string,
  fetchPhenomToken: PropTypes.func.isRequired
};

export default connect(
  mapStateToProps,
  mapDispatchToProps
)(Phenome);
