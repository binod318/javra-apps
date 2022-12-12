import React, { Fragment } from "react";
import PropTypes from "prop-types";
import { Redirect, Prompt } from "react-router-dom";
import shortid from "shortid";
import moment from "moment";
import { Tab, Tabs, TabList, TabPanel } from "react-tabs";
import autoBind from "auto-bind";

import ImportData from "./Import";
import "./Import/modal.scss";

import MarkerAssign from "./MarkerAssign";
import ManageMarkers from "./ManageMarkers";
import SelectedFileAttributes from "./SelectedFileAttributes";
import Slot from "../../../components/Slot";
import SaveDialogue from "../../../components/SaveDialogue";
import Export from "./Export";

import { getDim, getStatusName } from "../../../helpers/helper";

import imgExport from "../../../../../public/images/export.gif";
import imgAdd from "../../../../../public/images/add.gif";
import imgAdd2 from "../../../../../public/images/add2.gif";

import SendButton from "./SendButton";
import ManageLeafDiskDetermination from "./ManageMarkers/LeafDisk/ManageDetermination";
import CreateLeafDiskSampleModal from "./ManageMarkers/components/components/CreateLeafDiskSampleModal";
import ManageLeafDisk from "./ManageMarkers/LeafDisk/ManageLeafDisk";
import ManageSeedHealth from "./ManageMarkers/SeedHealth/ManageSeedHealth";
import ManageSeedHealthDetermination from "./ManageMarkers/SeedHealth/ManageDetermination";

class HomeComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      todayDate: moment(),
      plannedDate: props.plannedDate,
      expectedDate: props.expectedDate,
      goToPlateFilling: false,

      testID: props.testID,
      testTypeID: props.testTypeID,
      testTypeSelected: props.testTypeSelected,
      testType: "",
      siteID: props.siteID,
      sampleConfigName: props.sampleConfigName,

      siteID: props.siteID,
      sampleType: props.sampleType,

      slotID: props.slotID,
      slotVisibility: false,
      saveConfigVisibility: false,

      sourceList: props.sources,
      phenomeDisplay: true,
      sourceSelected: props.sourceSelected,
      sourceLoginRequired: false,

      loginModalVisibility: false,

      materialTypeList: props.materialTypeList,
      materialStateList: props.materialStateList,
      containerTypeList: props.containerTypeList,

      // leafdisk
      testProtocolList: props.testProtocolList,

      cropCode: props.cropCode,
      fileDataLength: props.fileDataLength,
      fileID: props.fileID,
      markerstatus: props.markerstatus,

      pageNumber: props.pageNumber || 1,
      pageSize: props.pageSize,
      tblCellWidth: props.tblCellWidth,
      tblWidth: 0, // props.tblWidth,
      tblHeight: 0, // props.tblHeight,

      fixColumn: 0,
      columnLength: props.columnLength,
      markerShow: true,
      isolationSelected: props.isolated || false,
      cumulateSelected: props.cumulate,

      importedFilesAttributesVisibility: false,
      importFileModalVisibility: false,

      importForm: false,

      statusCode: props.statusCode,
      filterLength: props.filterLength,
      selectedTabIndex: 0,
      dirty: props.dirty,
      dirtyMessage: "There are unsaved changes in Manage Marker & Materials",
      statusList: props.statusList,

      cropSelected: props.cropSelected,
      breedingStation: props.breedingStation,
      breedingStationSelected: props.breedingStationSelected,

      exportVisibility: false,
      importLevel: props.importLevel,

      importPhemoneExisting: props.importPhemoneExisting,

      existingFlag: false,

      warningFlag: props.warningFlag,
      warningMessage: props.warningMessage,
      fillRate: props.fillRate,

      //Seed health
      siteID: 0,
      sampleType: '',

      autoFetchTimer: 10000,
      creatSampleModalVisible: false
    };
    props.pageTitle();
    this.watcher = null;
    autoBind(this);
  }

  componentDidMount() {
    window.addEventListener("beforeunload", this.handleWindowClose);
    window.addEventListener("resize", this.updateDimensions);
    this.updateDimensions();

    this.props.fetchTestType();
    if (this.props.sources.length === 0) {
      this.props.fetchImportSource();
    }

    if (this.props.statusList.length === 0) {
      this.props.getStatusList();
    }

    // fetch material type :: changes added
    if (this.props.materialTypeList.length === 0)
      this.props.fetchMaterialType();
    if (this.props.materialStateList.length === 0)
      this.props.fetchMaterialState();
    if (this.props.containerTypeList.length === 0)
      this.props.fetchContainerType();

    // leafdisk
    if (this.props.testProtocolList.length === 0)
      this.props.fetchTestProtocol();

    this.props.fetchBreeding();
    if (this.props.testID) {
      if (this.props.testTypeID !== 4 && this.props.testTypeID !== 5) {
        this.fileFetch(this.props.testID, false);

        if (this.props.testTypeID === 6)
          this.props.fetchS2SFillRate(this.props.testID);
      } else {
        const options = {
          testID: this.props.testID,
          pageNumber: 1,
          pageSize: 150,
          filter: this.props.filter
        };
        this.props.fetchThreeGBMark(options);
      }
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.fillRate.change !== this.props.fillRate.change) {
      this.setState({ fillRate: nextProps.fillRate });
    }
    // PHEONOME WARNING CONFIRMATION
    if (nextProps.warningFlag !== this.props.warningFlag) {
      this.setState({
        warningFlag: nextProps.warningFlag,
        warningMessage: nextProps.warningMessage
      });
    }
    if (nextProps.importPhemoneExisting !== this.props.importPhemoneExisting) {
      this.setState({
        importPhemoneExisting: nextProps.importPhemoneExisting
      });
    }

    //Refetch data when menu item changes
    if(nextProps.selectedMenu !== this.props.selectedMenu && nextProps.selectedMenu !== '') {
      this.clearPollingForTestStatusUpdate();
      this.props.resetMarkerDirty();
      this.props.resetIsColumnMarker();
      this.props.emptyRowColumns();

      const { cropSelected, breedingStationSelected } = nextProps;
      if (cropSelected && breedingStationSelected)
        this.fetchTestList(breedingStationSelected, cropSelected);
    }

    if (nextProps.importLevel !== this.props.importLevel) {
      this.setState({ importLevel: nextProps.importLevel });
    }
    if (nextProps.sources.length !== this.state.sourceList.length) {
      this.setState({ sourceList: nextProps.sources });
    }
    if (nextProps.sourceSelected !== this.props.sourceSelected) {
      this.setState({ sourceSelected: nextProps.sourceSelected });
    }
    if (nextProps.cumulate !== this.props.cumulate) {
      this.setState({ cumulateSelected: nextProps.cumulate });
    }
    if (nextProps.cropSelected !== this.props.cropSelected) {
      this.setState({ cropSelected: nextProps.cropSelected });
      if (nextProps.breedingStationSelected !== "") {
        const { cropSelected, breedingStationSelected } = nextProps;
        this.fetchTestList(breedingStationSelected, cropSelected);
      }
    }
    if (
      nextProps.breedingStation.length !== this.props.breedingStation.length
    ) {
      this.setState({ breedingStation: nextProps.breedingStation });
    }
    if (
      nextProps.breedingStationSelected !== this.props.breedingStationSelected
    ) {
      this.setState({
        breedingStationSelected: nextProps.breedingStationSelected
      });
      if (nextProps.cropSelected !== "") {
        const { cropSelected, breedingStationSelected } = nextProps;
        this.fetchTestList(breedingStationSelected, cropSelected);
      }
    }

    if (nextProps.filterLength !== this.props.filterLength) {
      this.setState({ filterLength: nextProps.filterLength });
    }

    if (nextProps.statusCode === 200) {
      this.pollForTestStatusUpdate();
    }

    if (nextProps.statusCode !== this.props.statusCode) {
      this.setState({ statusCode: nextProps.statusCode });
      if (this.watcher && nextProps.statusCode === 500) {
        const { testID, testTypeID } = this.state;
        this.clearPollingForTestStatusUpdate();
        const { cropSelected, breedingStationSelected } = nextProps;
        this.fetchTestList(breedingStationSelected, cropSelected);
        this.props.getStatusList();
        this.props.fetchSlotList(nextProps.testID);
        this.fileFetch(nextProps.testID, true);
        this.props.fetchRDTmaterialwithtest({
          testID,
          testTypeID,
          filter: [],
          pageNumber: 1,
          pageSize: this.props.pageSize
        });
        this.props.fetchRDTMaterialState();
      }
    }
    if (nextProps.statusList !== this.props.statusList) {
      this.setState({ statusList: nextProps.statusList });
    }
    if (nextProps.fileDataLength !== this.props.fileDataLength) {
      this.updateDimensions();
      this.setState({ fileDataLength: nextProps.fileDataLength });
    }
    if (nextProps.testID !== this.props.testID) {
      this.setState({ testID: nextProps.testID });

      if (nextProps.testTypeID != 9 && nextProps.testTypeID != 10)
        this.props.fetchSlotList(nextProps.testID);

      // comment here today
      if (nextProps.testTypeID === 6)
        if (nextProps.testID) this.props.fetchS2SFillRate(nextProps.testID);
    }
    if (nextProps.slotID !== this.props.slotID) {
      this.setState({ slotID: nextProps.slotID || 0 });
    }
    if (nextProps.fileList.length > this.props.fileList.length) {
      this.setState({
        selectedTabIndex: 0,
        importForm: false,
        importFileModalVisibility: false
      });
    }
    if (nextProps.fileList) {
      this.setState({ fileList: nextProps.fileList });
    }
    if (nextProps.testTypeID !== this.props.testTypeID) {
      let dirtyMsg = "There are unsaved changes in Manage Marker & Materials";
      if(nextProps.testTypeID == 10)
        dirtyMsg = "There are unsaved changes in Manage Determination";

      this.setState({ testTypeID: nextProps.testTypeID, dirtyMessage: dirtyMsg });
    }
    // locally change
    if (nextProps.testTypeSelected !== this.props.testTypeSelected) {
      this.setState({ testTypeID: nextProps.testTypeSelected });
    }
    if (nextProps.markerstatus !== this.props.markerstatus) {
      this.setState({ markerstatus: nextProps.markerstatus });
    }
    if (nextProps.columnLength !== this.props.columnLength) {
      this.setState({ columnLength: nextProps.columnLength });
    }
    if (nextProps.fileID !== this.props.fileID) {
      this.setState({ fileID: nextProps.fileID });
    }
    if (nextProps.fileName !== this.props.fileName) {
      this.setState({ fileName: nextProps.fileName });
    }
    if (nextProps.pageNumber !== this.props.pageNumber) {
      this.setState({ pageNumber: nextProps.pageNumber });
    }
    if (nextProps.pageSize !== this.props.pageSize) {
      this.setState({ pageSize: nextProps.pageSize });
    }

    if (nextProps.materialTypeList) {
      this.setState({ materialTypeList: nextProps.materialTypeList });
    }
    if (nextProps.testProtocolList) {
      this.setState({ testProtocolList: nextProps.testProtocolList });
    }
    if (nextProps.materialStateList) {
      this.setState({ materialStateList: nextProps.materialStateList });
    }
    if (nextProps.containerTypeList) {
      this.setState({ containerTypeList: nextProps.containerTypeList });
    }
    if (nextProps.isolated !== this.props.isolated) {
      this.setState({ isolationSelected: nextProps.isolated });
    }
    if (nextProps.plannedDate !== this.props.plannedDate) {
      this.setState({ plannedDate: nextProps.plannedDate });
    }
    if (nextProps.expectedDate !== this.props.expectedDate) {
      this.setState({ expectedDate: nextProps.expectedDate });
    }
    if (nextProps.cropCode !== this.props.cropCode) {
      this.setState({ cropCode: nextProps.cropCode });
    }
    if (nextProps.platePlanName !== this.props.platePlanName) {
      this.setState({ platePlanName: nextProps.platePlanName });
    }
    if (nextProps.siteID !== this.props.siteID) {
      this.setState({ siteID: nextProps.siteID });
    }
    if (nextProps.sampleType !== this.props.sampleType) {
      this.setState({ sampleType: nextProps.sampleType });
    }
    if (nextProps.sampleConfigName !== this.props.sampleConfigName) {
      this.setState({ sampleConfigName: nextProps.sampleConfigName });
    }
  }

  componentWillUnmount() {
    this.clearPollingForTestStatusUpdate();
    window.removeEventListener("beforeunload", this.handleWindowClose);
    window.removeEventListener("resize", this.updateDimensions);
    this.props.resetMarkerDirty();
    this.props.resetIsColumnMarker();
  }

  fetchTestList(breedingStationSelected, cropSelected) {
    //get selected menu
    let selectedMenu = window.localStorage.getItem("selectedMenuGroup");

    //if menu is not set then set default menu(Utm general) from here
    if(!selectedMenu || selectedMenu == '') {
      selectedMenu = 'utmGeneral';
      window.localStorage.setItem("selectedMenuGroup", selectedMenu);
    }

    this.props.fetchFileList(breedingStationSelected, cropSelected, selectedMenu);
    this.props.fetch_testLookup(breedingStationSelected, cropSelected, selectedMenu);
  }

  handleChangeSource = e => {
    const currentSelect = e.target.value;
    this.props.ImportSourceChange(currentSelect);
  };

  handleChangeTabIndex = index => {
    this.setState({ selectedTabIndex: index });
  };

  handleWindowClose(e) {
    if (this.props.dirty || this.props.dirtyNumOfSamp || this.props.isColumnMarkerDirty) {
      e.returnValue = true;
    }
  }

  updateDimensions() {
    const dim = getDim();
    this.setState({
      tblWidth: dim.width,
      tblHeight: dim.height
    });
  }

  _markerShowToggle() {
    this.setState({ markerShow: !this.state.markerShow });
  }

  _fixColumn(e) {
    this.setState({ fixColumn: e.target.value });
  }

  fileChange(e) {
    if (this.props.dirty || this.props.dirtyNumOfSamp) {
      if (confirm(this.state.dirtyMessage)) {
        // eslint-disable-line
        // eslint-disable-line
        if (e.target.value) this.fileFetch(e.target.value, true);
        this.updateDimensions();
        this.setState({ selectedTabIndex: 0 });
        this.props.resetMarkerDirty();
      }
    } else {
      if (e.target.value) this.fileFetch(e.target.value, true);
      this.updateDimensions();
      this.setState({ selectedTabIndex: 0 });
    }
    this.clearPollingForTestStatusUpdate();
  }
  fileFetch(value, filechange = false) {
    if (value !== "") {
      const selectedFile = this.props.fileList.find(
        file => file.testID === value * 1
      );
      if (selectedFile) {
        this.props.selectFile(selectedFile);

        selectedFile.pageNumber =
          this.state.pageNumber || this.props.pageNumber;

        selectedFile.pageSize = this.props.defaultPageSize;
        selectedFile.filter = this.props.filter;

        this.setState({
          sourceSelected: selectedFile.source || ""
        });

        this.props.assignData(selectedFile, filechange);
      }
    }
  }

  clearFilter() {
    // clear filter :: handled in fetch data call
    // fetch data
    const { testID, testTypeID, selectedTabIndex } = this.state;
    const obj = {
      testID,
      testTypeID,
      filter: [],
      pageNumber: 1,
      pageSize: this.props.defaultPageSize
    };
    // Leaf  Disk
    if (testTypeID === 9) {
      this.props.clearLDFilters();
      switch (selectedTabIndex) {
        case 0:
          this.props.clearFilterFetch(obj);
          break;
        case 1:
          this.props.reloadSampleData();
          break;
        case 2:
          this.props.reloadManageDeterminations();
          break;
        default:
          break;
      }
    }
    // Seed Health
    else if (testTypeID === 10) {
      this.props.clearSHFilters();
      switch (selectedTabIndex) {
        case 0:
          this.props.clearFilterFetch(obj);
          break;
        case 1:
          this.props.reloadSHSampleData();
          break;
        case 2:
          this.props.reloadSHManageDeterminations();
          break;
        default:
          break;
      }
    } else if (selectedTabIndex !== 1) {
      this.props.clearFilterFetch(obj);
    } else {
      this.props.fetchRDTmaterialwithtest(obj);
      this.props.clearRDTFilter();
    }
  }

  toggleImportedFilesAttributesVisibility() {
    this.setState({
      importedFilesAttributesVisibility: !this.state
        .importedFilesAttributesVisibility
    });
  }

  toggleImportFileModalVisibility() {
    if (this.props.dirty || this.props.dirtyNumOfSamp) {
      if (confirm(this.state.dirtyMessage)) {
        // eslint-disable-line
        this.props.resetMarkerDirty();
        this.setState({
          importFileModalVisibility: !this.state.importFileModalVisibility
        });
      }
    } else {
      this.setState({
        importFileModalVisibility: !this.state.importFileModalVisibility
      });
    }
  }

  /**
   * Show Phenome Import Form
   * And Flag Existing Test or New Test
   * @param  {boolen} existingFlag
   * @return {null}
   */
  phenomeImportExistingFormUI = existingFlag => {
    let testType = "";

    //when only one testtype then select from here
    let selectedMenu = window.localStorage.getItem("selectedMenuGroup");

    //if menu is not set then set default menu(Utm general) from here
    if(!selectedMenu || selectedMenu == '') {
      selectedMenu = 'utmGeneral';
      window.localStorage.setItem("selectedMenuGroup", selectedMenu);
    }

    selectedMenu = selectedMenu.toLowerCase();
    if(selectedMenu == "leafdisk")
      selectedMenu = 'ldisk';

    var ttype = this.props.testTypeList.filter(o => o.testTypeCode.toLowerCase() == selectedMenu);

    if(ttype && ttype.length == 1)
      testType = ttype[0].testTypeCode;

    // This code was used to select the testtype from already selected test. But now the left menu is leading so it is removed
    // if (this.state.fileID) {
    //   const data = this.state.fileList.filter(
    //     o => o.fileID === this.state.fileID
    //   );

    //   if (data.length) {
    //     var dt = this.props.testTypeList.filter(
    //       o => o.testTypeID === data[0].testTypeID
    //     );
    //     testType = dt[0].testTypeCode;
    //   } else {
    //     const protocol = this.state.testProtocolList.filter(
    //       o => o.selected == true
    //     );
    //     if (protocol.length) {
    //       var dt = this.props.testTypeList.filter(
    //         o => o.testTypeID === protocol[0].testTypeID
    //       );
    //       testType = dt[0].testTypeCode;
    //     } else testType = "MT";
    //   }
    // }

    this.setState({
      importForm: true,
      existingFlag,
      testType
    });
  };
  PhenomeImportFormUI = () => {
    const { existingFlag } = this.state;
    const pt = document.getElementsByClassName("phenome-treeview");
    if (pt.length === 1) {
      pt[0].scrollTop = 0;
      pt[0].scrollLeft = 0;
    }
    if (this.props.dirty || this.props.dirtyNumOfSamp) {
      if (confirm(this.state.dirtyMessage)) {
        // eslint-disable-line
        this.props.resetMarkerDirty();
        this.friendlyToggle(existingFlag);
      }
    } else {
      this.friendlyToggle(existingFlag);
    }
  };
  friendlyToggle = existingImport => {
    this.setState({
      importForm: !this.state.importForm,
      importPhemoneExisting: existingImport
    });
  };

  toggleSlotVisibility() {
    this.setState({ slotVisibility: !this.state.slotVisibility });
  }

  toggleSaveConfigVisibility() {
    this.setState({ saveConfigVisibility: !this.state.saveConfigVisibility });
  }

  toggleLoginVisibility() {
    this.setState({
      loginModalVisibility: !this.state.loginModalVisibility
    });
  }
  // fetch data in each switch of tab to get fresh data from server
  // tabIndex 0 = Selected & Assigned tab
  // tabIndex 1 = New tab or Editable tab.
  fetchTabData(tabIndex) {
    const { testID, testTypeID, pageSize } = this.state;
    let options = { testID, pageNumber: 1, pageSize };

    if (
      this.props.dirty ||
      this.props.dirtyNumOfSamp ||
      this.props.scoreDirty ||
      this.props.isColumnMarkerDirty
    ) {
      if (!confirm(this.state.dirtyMessage)) return null; // eslint-disable-line
      this.props.resetMarkerDirty();
      this.props.resetIsColumnMarker();
    } else {
      options = Object.assign(options, { filter: [] });
    }

    if (tabIndex === 0) {
      this.fileFetch(testID, false);
    } else if (tabIndex === 1) {
      this.props.clearFilterOnly();
      if (this.props.selectedFileSource === "External") {
        this.props.fetchMaterialDeterminationsForExternalTest(options);
      } else if (testTypeID === 6) {
        this.props.fetchS2SMark(options);
      } else if (testTypeID === 8) {
        this.props.fetchRDTmaterialwithtest(options);
        this.props.fetchRDTMaterialState();
      } else if (testTypeID === 7) {
        this.props.fetchCNTDataWithMarkers(options);
      } else if (testTypeID === 9) {
        // this.props.fetchLeafDiskSampleData(options);
      } else if (testTypeID === 10) {
      // code added on other place
      } else if (testTypeID !== 2 && testTypeID !== 4 && testTypeID !== 5) {
        this.props.fetchMaterials(options);
      } else {
        this.props.fetchThreeGBMark(options);
      }
    }
    this.setState({ selectedTabIndex: tabIndex });
    return null;
  }

  // 2018/08/15
  cropSelectFn = e => {
    const { value } = e.target;
    if (value !== "") {
      this.props.emptyRowColumns();
      this.props.cropSelect(value);
    }
    this.clearPollingForTestStatusUpdate();
  };

  breedingStationSelectionFn = e => {
    const { value } = e.target;
    if (value !== "") {
      this.props.emptyRowColumns();
      this.props.breedingStationSelect(value);
    }
    this.clearPollingForTestStatusUpdate();
  };

  sendtothreeGBCockpit = () => {
    if (confirm("Are you sure, send to 3GB Cockpit?")) {
      // eslint-disable-line
      this.props.sendTOThreeGBCockPit(this.state.testID, this.props.filter);
    }
  };

  sendtoS2S = () => {
    const {
      testID,
      fillRate: { maxPlants, filledPlants }
    } = this.state;
    if (filledPlants > maxPlants) {
      alert("No. of Transplant filled is more then Maximum number of plants.");
      return;
    }
    if (confirm("Are you sure, send to S2S?")) this.props.uploadS2S(testID); // eslint-disable-line
  };

  sendtolimsRDT = () => {
    const { testID } = this.state;
    this.props.reqRDTsampleTest(testID);
  };

  sendtolimsLeafDisk = () => {
    const { testID } = this.state;
    this.props.reqLeafDiskSampleTest(testID);
  };

  updateRDTtoLims = () => {
    const { testID } = this.state;
    this.props.reqRDTupdateSampleTest(testID);
  };

  exportToExcelSeedHealth = () => {
    const { testID, cropSelected, breedingStationSelected } = this.state;
    const { fileTitle } = this.props;

    this.props.postSeedHealthExportToExcel(testID, cropSelected + "_" + breedingStationSelected + "_" + fileTitle);
  }

  sendToABSSeedHealth = () => {
    const { testID } = this.state;
    this.props.postSeedHealthSendToABS(testID);
  }

  pollForTestStatusUpdate = () => {
    const _this = this;
    const { autoFetchTimer: time } = _this.state;
    _this.clearPollingForTestStatusUpdate();
    _this.watcher = setInterval(() => {
      const { breedingStationSelected, cropSelected } = _this.props;
      _this.props.fetch_testLookup(breedingStationSelected, cropSelected);
    }, time);
  };

  clearPollingForTestStatusUpdate = () => {
    if (this.watcher) {
      this.props.cancel_fetch_testLookup();
      clearInterval(this.watcher);
      this.watcher = null;
    }
  };

  /**
   * This function will handle / assign related to DNA and 3GB
   * Marker section button named Add to Plate
   */
  addToThreeGBList = (materialSelected = []) => {
    const { testID, filter } = this.props;
    if (materialSelected.length) {
      const materialsMarkers = {
        testID,
        materialWithMarker: materialSelected
      };
      this.props.saveMarkerSelected(materialsMarkers);
    } else {
      this.props.addToThreeGB(testID, filter);
    }
  };

  addToS2S = (materialSelected = []) => {
    const { testID, filter } = this.props;

    if (materialSelected.length) {
      const materialsMarkers = {
        testID,
        materialWithMarker: materialSelected
      };
      this.props.saveMarkerSelected(materialsMarkers);
    } else {
      this.props.addToS2S(testID, filter);
    }
  };

  exportVisibilityToggle = () => {
    const { exportVisibility } = this.state;
    this.setState({
      exportVisibility: !exportVisibility
    });
  };

  exportUI = () => {
    const { exportVisibility: visible } = this.state;
    return visible ? <Export close={this.exportVisibilityToggle} /> : null;
  };
  slotUI = () => {
    const { slotVisibility: visible, testID } = this.state;
    return visible ? (
      <Slot testID={testID} toggleVisibility={this.toggleSlotVisibility} />
    ) : null;
  };

  saveConfigUI = () => {
    const {
      saveConfigVisibility: visible,
      testID,
      sampleConfigName
    } = this.state;
    return visible ? (
      <SaveDialogue
        testID={testID}
        title="Configuration Name"
        value={sampleConfigName}
        toggleVisibility={this.toggleSaveConfigVisibility}
      />
    ) : null;
  };

  selectedAttributeUI = () => {
    const { testID, showError, testTypeList } = this.props;
    const {
      importedFilesAttributesVisibility,
      materialTypeList,
      testProtocolList,
      materialStateList,
      containerTypeList,
      isolationSelected,
      plannedDate,
      expectedDate,
      fileList,
      slotID,
      testTypeID,
      cropCode,
      breedingStationSelected,
      statusCode,
      cumulateSelected,
      siteID,
      sampleType
    } = this.state;

    return testID ? (
      <SelectedFileAttributes
        cumulate={cumulateSelected}
        visibility={importedFilesAttributesVisibility}
        materialTypeList={materialTypeList}
        testProtocolList={testProtocolList}
        materialStateList={materialStateList}
        containerTypeList={containerTypeList}
        isolationStatus={isolationSelected}
        plannedDate={plannedDate}
        expectedDate={expectedDate}
        testID={this.state.testID}
        fileList={fileList}
        slotID={slotID}
        testTypeID={testTypeID}
        cropCode={cropCode}
        breeding={breedingStationSelected}
        statusCode={statusCode}
        showError={showError}
        updateTestAttributes={this.props.updateTestAttributes}
        testTypeList={testTypeList}
        siteID={siteID}
        sampleType={sampleType}
      />
    ) : null;
  };

  filterClearUI = () => {
    const { filter: filterLength, RDTfilters, leafDiskFilters, seedHealthFilters } = this.props;
    if (Object.values(leafDiskFilters).length > 0 || Object.values(seedHealthFilters).length > 0) {
      return (
        <button className="with-i" onClick={this.clearFilter}>
          <i className="icon icon-cancel" />
          Filters
        </button>
      );
    }
    const { selectedTabIndex } = this.state;
    if (filterLength < 1 && selectedTabIndex !== 1) return null;
    // if (filterLength < 1) return null;
    if (RDTfilters.length < 1 && selectedTabIndex === 1) return null;
    if (RDTfilters.length > 0 && selectedTabIndex === 1) {
      let valuNotEmpty = true;
      RDTfilters.forEach(x => {
        if (x.value !== "") valuNotEmpty = false;
        return null;
      });
      if (valuNotEmpty) return null;
    }
    return (
      <button className="with-i" onClick={this.clearFilter}>
        <i className="icon icon-cancel" />
        Filters
      </button>
    );
  };

  importFormClose = () => {
    const { importForm } = this.state;
    if (importForm) this.setState({ importForm: false });
  };

  fillRateUI = () => {
    const {
      fillRate: {
        availPlants,
        dH0Location,
        maxPlants,
        capacitySlotName,
        cordysStatus,
        filledPlants
      }
    } = this.state;
    if (cordysStatus === "") return null;

    return (
      <Fragment>
        <div className="form-e status-txt">
          <label className="full">
            {capacitySlotName}
            {cordysStatus && `(${cordysStatus})`}
          </label>
        </div>
        <div className="form-e status-txt">
          <label className="full"> {dH0Location} </label>
        </div>
        <div className="form-e status-txt">
          <label className="full">
            Fill Rate
            {": "}
            {`${filledPlants}/${maxPlants}`}
          </label>
        </div>
        <div className="form-e status-txt">
          <label className="full">
            Available
            {": "}
            {availPlants}
          </label>
        </div>
      </Fragment>
    );
  };

  toggleCreateSampleModal = () => {
    this.setState({
      createSampleModalVisible: !this.state.createSampleModalVisible
    });
  };

  saveSample = payload => {
    const { testTypeID } = this.state;
    payload.testTypeID = testTypeID;

    this.props.saveSample(payload);
    this.setState({ createSampleModalVisible: false });
  };

  //Print label : leafdisk, seedhealth
  printLabel = (testID, testTypeID) => {
    if(testTypeID == 9)
      this.props.leafDiskPrintLabel(testID);
    else if (testTypeID == 10)
      this.props.seedHealthPrintLabel(testID);
  }

  render() {
    const { testID } = this.props;
    const {
      fixColumn,
      tblHeight,
      tblWidth,
      tblCellWidth,
      slotID,
      testTypeID,
      sourceSelected,
      sourceList,
      breedingStation,
      breedingStationSelected,
      importLevel,
      markerstatus,
      fileID,
      cropSelected,
      sampleType
    } = this.state;
    // dispaly state
    const { goToPlateFilling, phenomeDisplay } = this.state;
    const { statusCode, platePlanName } = this.props;
    const colRecords = this.state.columnLength;

    const secondTab = markerstatus || importLevel === "LIST";
    const TwoGBType = testTypeID === 1;
    // const TwoGBType = testTypeID === 1 || testTypeID === 8;
    const ThreeGBType = testTypeID === 4 || testTypeID === 5;
    const noThreeGBType = testTypeID !== 4 && testTypeID !== 5;
    const s2sType = testTypeID === 6;
    const cntType = testTypeID === 7;
    const leafDisk = testTypeID === 9;
    const seedHealthType = testTypeID === 10;
    const leafDiskOrSeedHealth = testTypeID === 9 || testTypeID === 10;
    const isPlot = importLevel === "Plot";

    const rdtType = testTypeID === 8;
    const rdtSendtoLimsReqBtn = statusCode === 100;
    const rdtUpdateToLimsReqBtn = statusCode === 450;
    // DNA save button and Mange DNA tab option remove as requeste
    const isDNA = testTypeID === 2;
    const ManageMarkersTab =
      secondTab || ThreeGBType || s2sType || isDNA || cntType || rdtType;

    const sendToABSVisibility = seedHealthType && statusCode < 500;

    const cropStationPhenome =
      sourceSelected === "Phenome" &&
      statusCode <= 200 &&
      cropSelected !== "" &&
      breedingStationSelected !== "" &&
      fileID !== null;

    if (goToPlateFilling) return <Redirect to="/platefilling" />;

    // getting slot name quick fix
    let slotName = "";
    if (slotID !== "") {
      this.props.slotList.map(s => {
        const { slotID: vSlotID, slotName: sname } = s;
        if (vSlotID === slotID) {
          slotName = sname;
        }
        return null;
      });
    }

    const navActionSlot =
      statusCode <= 150 && noThreeGBType && !s2sType && !cntType && !rdtType && !seedHealthType;
    const ddirty = this.props.dirty || this.props.dirtyNumOfSamp || this.props.isColumnMarkerDirty;
    const disableRdtSendToLims = this.props.dirty;

    //Create sample button for Seed health and Leafdisk
    const displaySampleBtn = statusCode <= 150 && ((seedHealthType && sampleType === "seedcluster") || (leafDisk && isPlot));
    const displayPunchList =
      importLevel === "CROSSES/SELECTION" && statusCode >= 150;
    const displayPrintLabel = (leafDisk && statusCode >= 150) || (seedHealthType && statusCode == 500);
    const saveConfigBtn =
      testTypeID === 9 && (statusCode <= 500);
    const ldSendtoLimsReqBtn = statusCode === 150;

    return (
      <div className="assign">
        <Prompt when={ddirty} message={this.state.dirtyMessage} />
        {this.exportUI()}
        {this.slotUI()}
        {this.saveConfigUI()}

        <section className="page-action">
          <div className="left">
            <div className="form-e">
              <label>Crops</label>
              <select
                name="crops"
                id="crops"
                onChange={this.cropSelectFn}
                value={this.state.cropSelected}
              >
                <option value="">Select</option>
                {this.props.crops.map(crop => (
                  <option value={crop} key={crop}>
                    {crop}
                  </option>
                ))}
              </select>
            </div>
            <div className="form-e">
              <label>Br.Station</label>
              <select
                name="breeding"
                id="breeding"
                onChange={this.breedingStationSelectionFn}
                value={breedingStationSelected}
              >
                <option value="">Select</option>
                {breedingStation.map(breed => {
                  const { breedingStationCode } = breed;
                  return (
                    <option
                      key={breedingStationCode}
                      value={breedingStationCode}
                    >
                      {breedingStationCode}
                    </option>
                  );
                })}
              </select>
            </div>
            <div className="form-e">
              <label>Imported</label>
              <select
                name="imported"
                className="w-200"
                value={this.state.testID || ""}
                onChange={this.fileChange}
                disabled={this.props.status > 0}
              >
                <option value="">Select</option>
                {this.props.fileList.map(file => (
                  <option key={shortid.generate()} value={file.testID}>
                    {file.fileTitle}
                  </option>
                ))}
              </select>
              <div
                style={{
                  display: `${this.state.testID ? "block" : "none"}`
                }}
                className="btn-detail"
                role="button"
                tabIndex={0}
                title="Toggle marker"
                onKeyPress={() => {}}
                onClick={this.toggleImportedFilesAttributesVisibility}
              >
                <i
                  className={
                    this.state.importedFilesAttributesVisibility
                      ? "icon icon-up-open"
                      : "icon icon-down-open"
                  }
                />
              </div>
            </div>
            {phenomeDisplay && (
              <div className="form-e">
                <label>Source</label>
                <select
                  name="source"
                  value={sourceSelected}
                  onChange={this.handleChangeSource}
                >
                  {sourceList.map(source => (
                    <option key={source.sourceID} value={source.code}>
                      {source.sourceName}
                    </option>
                  ))}
                </select>
              </div>
            )}

            <div className="fileUpload">
              <span
                id="import_btn"
                title="Import New File"
                className="import -file-icon"
                onClick={() => this.phenomeImportExistingFormUI(false)}
                role="button"
                onKeyDown={() => {}}
                tabIndex={0}
              >
                <img src={imgAdd} alt="" />

                {/* <i className="icon icon-doc-new-circled" /> */}
              </span>
              {sourceSelected === "External" && (
                <span
                  title="Export"
                  className="import -file-icon"
                  onClick={this.exportVisibilityToggle}
                  role="button"
                  onKeyDown={() => {}}
                  tabIndex={0}
                >
                  <img src={imgExport} alt="" />
                  {/* <i className="icon icon-export-alt" /> */}
                </span>
              )}
            </div>
            {cropStationPhenome && (
              <div className="fileUpload">
                <span
                  title="Import to Existing File"
                  className="import -file-icon"
                  id="importExistingFile"
                  onClick={() => this.phenomeImportExistingFormUI(true)}
                  role="button"
                  onKeyDown={() => {}}
                  tabIndex={0}
                >
                  <img src={imgAdd2} alt="" />
                </span>
              </div>
            )}
          </div>
        </section>

        <section
          className="page-action"
          style={{ display: testID ? "flex" : "none" }}
        >
          <div className="left">
            {this.filterClearUI()}
            {slotName !== "" && (
              <div className="form-e status-txt">
                <label className="full">
                  Slot
                  {": "}
                  {slotName}
                </label>
              </div>
            )}
            {platePlanName && (
              <div className="form-e status-txt">
                <label className="full">
                  Folder
                  {": "}
                  {platePlanName}
                </label>
              </div>
            )}
            {s2sType && this.fillRateUI()}
          </div>
          <div className="right">
            <div className="form-e status-txt">
              <label className="full">
                Status{" "}
                {getStatusName(this.state.statusCode, this.state.statusList)}
              </label>
            </div>
            {navActionSlot && (
              <button
                id="assignMarker_slot_btn"
                title="Slot"
                className="with-i"
                onClick={e => {
                  e.preventDefault();
                  this.toggleSlotVisibility();
                }}
              >
                <i className="icon icon-plus-squared" />
                <span>Slot</span>
              </button>
            )}

            {testID && displayPunchList && (
              <button
                title="Punch List"
                className="with-i full-btn"
                onClick={e => {
                  e.preventDefault();
                  this.props.history.push("/ld-punchlist");
                }}
              >
                <i className="icon icon-print" />
                Punch <span>List</span>
              </button>
            )}

            {testID && displayPrintLabel && (
              <button
                title="Plate Label"
                className="with-i full-btn"
                onClick={e => {
                  e.preventDefault();
                  this.printLabel(testID, testTypeID);
                }}
              >
                <i className="icon icon-print" />
                Print <span>Label</span>
              </button>
            )}

            {testID && (
              <Fragment>
                <button
                  id="assignMarker_delete_btn"
                  title="Delete"
                  className="with-i"
                  onClick={e => {
                    e.preventDefault();
                    if (confirm("Are you sure to delete test?")) {
                      // eslint-disable-line
                      this.props.deleteTest(testID);
                    }
                  }}
                >
                  <i className="icon icon-trash" />
                  <span>Delete</span>
                </button>
                <button
                  id="assignMarker_remark_btn"
                  title="Remarks"
                  className="with-i"
                  onClick={e => {
                    e.preventDefault();
                    this.props.showRemarks();
                  }}
                >
                  <i className="icon icon-commenting" />
                  <span>Remarks</span>
                </button>
              </Fragment>
            )}
            {ThreeGBType && (
              <button
                title="Send to 3GB Cockpit"
                className="with-i"
                onClick={this.sendtothreeGBCockpit}
              >
                <i className="icon icon-paper-plane" />
                Send to 3GB Cockpit
              </button>
            )}
            {s2sType && (
              <SendButton
                title="Send to 3GB Cockpit"
                text="Send to S2S"
                action={() => this.sendtoS2S()}
                status={this.props.status}
              />
            )}
            {rdtType && rdtSendtoLimsReqBtn && !disableRdtSendToLims && (
              <SendButton
                title="Send to LIMS (RDT)"
                text="Send to LIMS"
                action={() => this.sendtolimsRDT()}
                status={this.props.status}
              />
            )}

            {rdtType && rdtUpdateToLimsReqBtn && !disableRdtSendToLims && (
              <SendButton
                title="Update to LIMS (RDT)"
                text="Update to LIMS"
                action={() => this.updateRDTtoLims()}
                status={this.props.status}
              />
            )}
            {displaySampleBtn && (
              <Fragment>
                <SendButton
                  title="Sample"
                  text="Sample"
                  icon="icon-plus-squared"
                  action={this.toggleCreateSampleModal}
                  status={0}
                />
                {this.state.createSampleModalVisible && (
                  <CreateLeafDiskSampleModal
                    toggle={this.toggleCreateSampleModal}
                    save={this.saveSample}
                    sampleID={0}
                    testID={this.props.testID}
                  />
                )}
              </Fragment>
            )}
            {saveConfigBtn && (
              <button
                id="assignMarker_save_config"
                title="Save configuration name"
                className="with-i"
                onClick={e => {
                  e.preventDefault();
                  this.toggleSaveConfigVisibility();
                }}
              >
                <i className="icon icon-floppy" />
                <span>Config</span>
              </button>
            )}
            {leafDisk && ldSendtoLimsReqBtn && (
              <SendButton
                title="Send to LIMS (Leafdisk)"
                text="Send to LIMS"
                action={() => this.sendtolimsLeafDisk()}
                status={this.props.status}
              />
            )}
             {seedHealthType && (
              <button
                title="Export to Excel"
                className="with-i full-btn"
                onClick={e => {
                  e.preventDefault();
                  this.exportToExcelSeedHealth();
                }}
              >
                <i className="icon icon-file-excel" />
                <span>Export</span>
              </button>
            )}
            {sendToABSVisibility && (
              <SendButton
                title="Send to ABS"
                text="Send to ABS"
                action={() => this.sendToABSSeedHealth()}
                status={this.props.status}
              />
             )}
          </div>
        </section>

        <div className="container">{this.selectedAttributeUI()}</div>
        <div className="container">
          <div className="trow">
            <div className="tcell tabbedData" id="tableWrap">
              {testID && (
                <Tabs
                  className=""
                  onSelect={tabIndex => this.fetchTabData(tabIndex)}
                  selectedIndex={this.state.selectedTabIndex}
                >
                  <TabList>
                    <Tab>{leafDiskOrSeedHealth ? "Imported " : "Selected & Assigned"}</Tab>
                    {secondTab && TwoGBType && (
                      <Tab>Manage Markers &amp; Materials </Tab>
                    )}
                    {ThreeGBType && <Tab>Manage 3GB </Tab>}
                    {isDNA && <Tab>Manage DNA </Tab>}
                    {s2sType && <Tab>Manage S2S </Tab>}
                    {cntType && <Tab>Manage C&T</Tab>}
                    {rdtType && <Tab>Manage RDT</Tab>}
                    {leafDiskOrSeedHealth && <Tab>Sample Data</Tab>}
                    {leafDiskOrSeedHealth && <Tab>Manage Determination</Tab>}
                  </TabList>

                  <TabPanel>
                    <MarkerAssign
                      {...this.state}
                      testTypeID={testTypeID}
                      status={this.state.markerstatus}
                      show={this.state.markerShow}
                      collapse={this._markerShowToggle}
                      addToThreeGBList={this.addToThreeGBList}
                      addToS2S={this.addToS2S}
                      tableCellWidth={tblCellWidth}
                      tblHeight={tblHeight}
                      tblWidth={tblWidth}
                      fixColumn={fixColumn}
                      colRecords={colRecords}
                      visibility={this.state.importedFilesAttributesVisibility}
                      testID={this.props.testID}
                      pageNumber={this.props.pageNumber}
                      pageSize={this.props.pageSize}
                      records={this.props.records}
                      filter={this.props.filter}
                      onPageClick={this.props.pageClick}
                      isBlocking={false}
                      isBlockingChange={() => {}}
                      pageClicked={() => {}}
                      _fixColumn={this._fixColumn}
                      clearFilter={this.clearFilter}
                      filterLength={this.props.filterLength}
                      noDetermination
                    />
                  </TabPanel>

                  {ManageMarkersTab && (
                    <TabPanel>
                      <ManageMarkers
                        cropSelected={cropSelected}
                        tblHeight={tblHeight}
                        tblWidth={tblWidth}
                        tableCellWidth={tblCellWidth}
                        fixColumn={0}
                        testTypeID={testTypeID}
                        markerstatus={markerstatus}
                        importLevel={importLevel}
                        dirtyMessage={this.state.dirtyMessage}
                        visibility={
                          this.state.importedFilesAttributesVisibility
                        }
                        statusCode={this.props.statusCode}
                      />
                    </TabPanel>
                  )}
                  {leafDisk && (
                    <Fragment>
                      <TabPanel>
                        <ManageLeafDisk
                          cropSelected={cropSelected}
                          tblHeight={tblHeight}
                          tblWidth={tblWidth}
                          fixColumn={0}
                          testTypeID={testTypeID}
                          markerstatus={markerstatus}
                          importLevel={importLevel}
                          dirtyMessage={this.state.dirtyMessage}
                          visibility={
                            this.state.importedFilesAttributesVisibility
                          }
                          statusCode={this.props.statusCode}
                          resetSaveSampleSucceededFlag={
                            this.props.resetSaveSampleSucceededFlag
                          }
                        />
                      </TabPanel>
                      <TabPanel>
                        <ManageLeafDiskDetermination
                          cropSelected={cropSelected}
                          tblHeight={tblHeight}
                          tblWidth={tblWidth}
                          tableCellWidth={tblCellWidth}
                          fixColumn={0}
                          testTypeID={testTypeID}
                          markerstatus={markerstatus}
                          importLevel={importLevel}
                          dirtyMessage={this.state.dirtyMessage}
                          visibility={
                            this.state.importedFilesAttributesVisibility
                          }
                          statusCode={this.props.statusCode}
                          resetSaveSampleSucceededFlag={
                            this.props.resetSaveSampleSucceededFlag
                          }
                        />
                      </TabPanel>
                    </Fragment>
                  )}

                  {seedHealthType && (
                    <Fragment>
                      <TabPanel>
                        <ManageSeedHealth
                          cropSelected={cropSelected}
                          tblHeight={tblHeight}
                          tblWidth={tblWidth}
                          fixColumn={0}
                          testTypeID={testTypeID}
                          markerstatus={markerstatus}
                          sampleType={sampleType}
                          dirtyMessage={this.state.dirtyMessage}
                          visibility={
                            this.state.importedFilesAttributesVisibility
                          }
                          statusCode={this.props.statusCode}
                          resetSaveSampleSucceededFlag={
                            this.props.resetSaveSampleSucceededFlag
                          }
                        />
                      </TabPanel>
                      <TabPanel>
                        <ManageSeedHealthDetermination
                          cropSelected={cropSelected}
                          tblHeight={tblHeight}
                          tblWidth={tblWidth}
                          tableCellWidth={tblCellWidth}
                          fixColumn={0}
                          testTypeID={testTypeID}
                          markerstatus={markerstatus}
                          sampleType={sampleType}
                          dirtyMessage={this.state.dirtyMessage}
                          visibility={
                            this.state.importedFilesAttributesVisibility
                          }
                          statusCode={this.props.statusCode}
                          resetSaveSampleSucceededFlag={
                            this.props.resetSaveSampleSucceededFlag
                          }
                        />
                      </TabPanel>
                    </Fragment>
                  )}

                </Tabs>
              )}
            </div>
          </div>
        </div>

        {this.state.importForm && (
          <ImportData
            sourceSelected={sourceSelected}
            existFile={this.state.existingFlag}
            testType={this.state.testType}
            handleChangeTabIndex={this.handleChangeTabIndex}
            showError={this.props.showError}
            close={this.importFormClose}
          />
        )}
      </div>
    );
  }
}
HomeComponent.defaultProps = {
  RDTfilters: [],
  importLevel: "",
  sources: [],
  sourceSelected: "",
  cumulate: false,
  platePlanName: "",
  fileTitle: "",
  selectedFileSource: "",
  fileName: "",
  expectedDate: "",
  cropSelected: "",
  breedingStationSelected: "",
  breedingStation: [],
  slotList: [],
  crops: [],
  testTypeSelected: null,
  cropCode: null,
  statusCode: null,
  testTypeID: 1,
  fileID: null,
  isolated: null,
  testID: null,
  slotID: 0,
  tblCellWidth: 120,
  tblHeight: 400,
  tblWidth: 600,
  plannedDate: "",
  sampleConfigName: ""
};
HomeComponent.propTypes = {
  status: PropTypes.number, // .isRequired
  RDTfilters: PropTypes.array, // eslint-disable-line
  addToS2S: PropTypes.func.isRequired,
  saveMarkerSelected: PropTypes.func.isRequired,
  reqRDTsampleTest: PropTypes.func.isRequired,
  reqRDTupdateSampleTest: PropTypes.func.isRequired,
  reqLeafDiskSampleTest: PropTypes.func.isRequired,
  fetchCNTDataWithMarkers: PropTypes.func.isRequired,
  fetchRDTMaterialState: PropTypes.func.isRequired,
  fetchS2SMark: PropTypes.func.isRequired,
  clearFilterOnly: PropTypes.func.isRequired,
  scoreDirty: PropTypes.any, // eslint-disable-line
  clearRDTFilter: PropTypes.func.isRequired,
  fetchRDTmaterialwithtest: PropTypes.func.isRequired,
  dirtyNumOfSamp: PropTypes.any, // eslint-disable-line
  fetchS2SFillRate: PropTypes.func.isRequired,
  fillRate: PropTypes.any, // eslint-disable-line
  warningMessage: PropTypes.any, // eslint-disable-line
  warningFlag: PropTypes.any, // eslint-disable-line
  importPhemoneExisting: PropTypes.any, // eslint-disable-line
  importLevel: PropTypes.string,
  sources: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  sourceSelected: PropTypes.string,
  sourceSelected: PropTypes.string,
  siteID: PropTypes.number,
  sampelType: PropTypes.string,

  cumulate: PropTypes.bool,
  platePlanName: PropTypes.string,
  fileTitle: PropTypes.string,
  selectedFileSource: PropTypes.string,
  cropSelected: PropTypes.string,
  breedingStationSelected: PropTypes.string,
  slotList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  breedingStation: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  plannedDate: PropTypes.string,
  expectedDate: PropTypes.string,
  cropCode: PropTypes.string,
  fileName: PropTypes.string,
  statusCode: PropTypes.number,
  tblWidth: PropTypes.number,
  tblHeight: PropTypes.number,
  testID: PropTypes.number,
  slotID: PropTypes.number, // eslint-disable-line
  testTypeID: PropTypes.number,
  testTypeSelected: PropTypes.number,
  fileDataLength: PropTypes.number.isRequired,
  pageNumber: PropTypes.number.isRequired,
  pageSize: PropTypes.number.isRequired,
  tblCellWidth: PropTypes.number,
  columnLength: PropTypes.number.isRequired,
  filterLength: PropTypes.number.isRequired,
  records: PropTypes.number.isRequired,
  fileID: PropTypes.number,
  markerstatus: PropTypes.bool.isRequired,
  isolated: PropTypes.bool,
  dirty: PropTypes.bool.isRequired,
  crops: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  materialTypeList: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  testProtocolList: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  materialStateList: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  containerTypeList: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  statusList: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  fileList: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  filter: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  testTypeList: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  fetchSlotList: PropTypes.func.isRequired,
  fetchImportSource: PropTypes.func.isRequired,
  ImportSourceChange: PropTypes.func.isRequired,
  fetchMaterialDeterminationsForExternalTest: PropTypes.func.isRequired,
  emptyRowColumns: PropTypes.func.isRequired,
  breedingStationSelect: PropTypes.func.isRequired,
  fetchThreeGBMark: PropTypes.func.isRequired,
  addToThreeGB: PropTypes.func.isRequired,
  cropSelect: PropTypes.func.isRequired,
  sendTOThreeGBCockPit: PropTypes.func.isRequired,
  fetch_testLookup: PropTypes.func.isRequired,
  cancel_fetch_testLookup: PropTypes.func.isRequired,
  fetchBreeding: PropTypes.func.isRequired,
  pageTitle: PropTypes.func.isRequired,
  sidemenu: PropTypes.func.isRequired,
  getStatusList: PropTypes.func.isRequired,
  fetchMaterialType: PropTypes.func.isRequired,
  fetchTestProtocol: PropTypes.func.isRequired,
  fetchMaterialState: PropTypes.func.isRequired,
  fetchContainerType: PropTypes.func.isRequired,
  fetchFileList: PropTypes.func.isRequired,
  fetchTestType: PropTypes.func.isRequired,
  resetMarkerDirty: PropTypes.func.isRequired,
  selectFile: PropTypes.func.isRequired,
  assignData: PropTypes.func.isRequired,
  clearFilterFetch: PropTypes.func.isRequired,
  fetchMaterials: PropTypes.func.isRequired,
  showRemarks: PropTypes.func.isRequired,
  showError: PropTypes.func.isRequired,
  updateTestAttributes: PropTypes.func.isRequired,
  pageClick: PropTypes.func.isRequired,
  deleteTest: PropTypes.func.isRequired,
  fetchLeafDiskSampleData: PropTypes.func.isRequired,
  saveSample: PropTypes.func.isRequired,
  history: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  sampleSaved: PropTypes.bool.isRequired,
  resetSaveSampleSucceededFlag: PropTypes.func.isRequired,
  clearLDFilters: PropTypes.func.isRequired,
  leafDiskFilters: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  clearSHFilters: PropTypes.func.isRequired,
  seedHealthFilters: PropTypes.object.isRequired
};

export default HomeComponent;
