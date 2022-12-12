import { connect } from "react-redux";

import { sidemenuClose } from "../../action/index";
import { remarkShow } from "../../components/Remarks/remarkAction";

import HomeComponent from "./compoments/HomeComponent";
import {
  fetchS2S,
  fetchThreeGB,
  fetchMaterials,
  updateTestAttributes,
  resetMarkerDirty,
  fetchCNTDataWithMarkers,
  fetchRDTMateriwithTests
} from "./actions";
import "./Home.scss";

const mapStateToProps = state => ({
  status: state.loader,
  cumulate: state.assignMarker.file.selected.cumulate,
  sources: state.sources.list,
  sourceSelected: state.sources.selected,
  selectedFileSource: state.assignMarker.file.selected.source,

  crops: state.user.crops,
  cropSelected: state.user.selectedCrop,
  breedingStation: state.breedingStation.station,
  breedingStationSelected: state.breedingStation.selected,

  fileList: state.assignMarker.file.filelist,
  fillRate: state.assignMarker.file.fillRate,
  testTypeList: state.assignMarker.testType.list,
  materialTypeList: state.materialType,
  testProtocolList: state.testProtocol,
  materialStateList: state.materialState,
  containerTypeList: state.containerType,
  importLevel: state.rootTestID.importLevel,
  testID: state.rootTestID.testID,
  slotID: state.rootTestID.slotID,
  slotList: state.slot,
  rootTestTypeID: state.rootTestID.testTypeID,
  fileID: state.assignMarker.file.selected.fileID,
  testTypeID: state.rootTestID.testTypeID,
  siteID: state.assignMarker.file.selected.siteID,
  sampleType: state.assignMarker.file.selected.sampleType,
  sampleConfigName: state.assignMarker.file.selected.sampleConfigName,
  isolated: state.assignMarker.file.selected.isolated,
  plannedDate: state.assignMarker.file.selected.plannedDate,
  expectedDate: state.assignMarker.file.selected.expectedDate,
  platePlanName:
    state.assignMarker.file.selected.platePlanName ||
    state.rootTestID.platePlanName,
  fileTitle: state.assignMarker.file.selected.fileTitle,
  cropCode: state.assignMarker.file.selected.cropCode,
  pageSize: state.assignMarker.total.pageSize,
  defaultPageSize: state.assignMarker.total.defaultPageSize,
  pageNumber: state.assignMarker.total.pageNumber,
  markerstatus: !!state.assignMarker.marker.length,
  fileDataLength: state.assignMarker.total.total,
  columnLength: state.assignMarker.column.length,
  records: state.assignMarker.total.total,
  filter: state.assignMarker.filter,
  filterLength: state.assignMarker.filter.length,
  markerStateList: state.assignMarker.marker,
  statusList: state.statusList,
  statusCode: state.rootTestID.statusCode,
  dirty: state.assignMarker.materials.dirty,
  dirtyNumOfSamp: state.assignMarker.numberOfSamples.dirty,
  warningFlag: state.phenome.warningFlag,
  warningMessage: state.phenome.warningMessage,
  importPhemoneExisting: state.phenome.existingImport,
  RDTfilters: state.assignMarker.RDTFilter,
  sampleSaved: state.assignMarker.samples.sampleSaved,
  leafDiskFilters: state.assignMarker.leafDiskFilters,
  seedHealthFilters: state.assignMarker.seedHealthFilters,
  isColumnMarkerDirty: state.assignMarker.determinations.isColumnMarkerDirty,
  selectedMenu: state.selectedMenu
});
const mapDispatchToProps = dispatch => ({
  fetchMaterialDeterminationsForExternalTest: options =>
    dispatch({ type: "FETCH_MATERIAL_EXTERNAL", ...options }),
  sendTOThreeGBCockPit: (testID, filter) =>
    dispatch({ type: "THREEGB_SEND_COCKPIT", testID, filter }),
  cropSelect: crop => dispatch({ type: "ADD_SELECTED_CROP", crop }),
  fetchBreeding: () => dispatch({ type: "FETCH_BREEDING_STATION" }),
  breedingStationSelect: selected =>
    dispatch({ type: "BREEDING_STATION_SELECTED", selected }),
  emptyRowColumns: () => {
    dispatch({ type: "RESETALL_PLATEFILLING" });
    dispatch({ type: "RESET_ASSIGNMARKER_TOTAL" });
    dispatch({ type: "DATA_BULK_ADD", data: [] });
    dispatch({ type: "COLUMN_BULK_ADD", data: [] });
  },
  fetchSlotList: testID => dispatch({ type: "FETCH_SLOT", testID }),
  pageTitle: () => dispatch({ type: "SET_PAGETITLE", title: "Assign Markers" }),
  sidemenu: () => dispatch(sidemenuClose()),
  getStatusList: () => dispatch({ type: "FETCH_STATULSLIST" }),

  fetch_testLookup: (breedingStationCode, cropCode, testTypeMenu) => {
    dispatch({
      type: "FETCH_TESTLOOKUP",
      breedingStationCode,
      cropCode,
      testTypeMenu
    });
  },
  cancel_fetch_testLookup: () => {
    dispatch({
      type: "CANCEL_FETCH_TESTLOOKUP"
    });
  },
  fetchFileList: (breeding, crop, testTypeMenu) =>
    dispatch({ type: "FILELIST_FETCH", breeding, crop, testTypeMenu }),
  fetchTestType: () => dispatch({ type: "FETCH_TESTTYPE", testTypeID: "" }),
  fetchMaterialType: () => dispatch({ type: "FETCH_MATERIAL_TYPE" }),
  fetchMaterialState: () => dispatch({ type: "FETCH_MATERIAL_STATE" }),
  fetchContainerType: () => dispatch({ type: "FETCH_CONTAINER_TYPE" }),
  fetchTestProtocol: () => dispatch({ type: "FETCH_TEST_PROTOCOL" }),

  selectFile: selectedFile => {
    dispatch({ type: "FILELIST_SELECTED", file: selectedFile });
    dispatch({
      type: "SELECT_MATERIAL_TYPE",
      id: selectedFile.materialTypeID
    });
    dispatch({
      type: "SELECT_TEST_PROTOCOL",
      id: selectedFile.testProtocolID
    });
    dispatch({
      type: "SELECT_MATERIAL_STATE",
      id: selectedFile.materialstateID
    });
    dispatch({
      type: "SELECT_CONTAINER_TYPE",
      id: selectedFile.containerTypeID
    });
    dispatch({
      type: "CHANGE_PLANNED_DATE",
      plannedDate: selectedFile.plannedDate
    });
    dispatch({
      type: "ROOT_SET_ALL",
      testID: selectedFile.testID,
      testTypeID: selectedFile.testTypeID,
      remark: selectedFile.remark || "",
      statusCode: selectedFile.statusCode,
      remarkRequired: selectedFile.remarkRequired,
      slotID: selectedFile.slotID,
      importLevel: selectedFile.importLevel
    });
  },
  assignData: (selectedFile, filechange = false) => {
    if (filechange) {
      dispatch({ type: "FILTER_CLEAR" });
      dispatch({ type: "FILTER_PLATE_CLEAR" });
      dispatch({ type: "PAGE_PLATE_RECORD", pageNumber: 1 });
    }
    dispatch({
      type: "ASSIGNDATA_FETCH",
      file: { ...selectedFile, filter: [], pageNumber: 1 }
    });

    // fort selected plate filling
    dispatch({
      type: "TESTSLOOKUP_SELECTED",
      ...selectedFile
    });
    dispatch({
      type: "ASSIGN_WELL_SIZE",
      wellsPerPlate: selectedFile.wellsPerPlate || 92
    });
  },
  clearFilterFetch: obj => {
    dispatch({
      type: "FETCH_CLEAR_FILTER_DATA",
      testID: obj.testID,
      testTypeID: obj.testTypeID,
      filter: obj.filter,
      pageNumber: obj.pageNumber,
      pageSize: obj.pageSize
    });
    dispatch({ type: "MARKER_TO_FALSE" });
  },
  clearFilterOnly: () => dispatch({ type: "FILTER_CLEAR" }),
  pageClick: obj => dispatch({ ...obj, type: "NEW_PAGE" }),
  showRemarks: () => dispatch(remarkShow()),
  fetchMaterials: options => dispatch(fetchMaterials(options)),
  showError: obj => dispatch(obj),
  updateTestAttributes: attributes =>
    dispatch(updateTestAttributes(attributes)),
  resetMarkerDirty: () => dispatch(resetMarkerDirty()),
  resetIsColumnMarker: () => dispatch({ type: "RESET_ISCOLUMN_MARKER_DIRTY" }),
  addToThreeGB: (testID, filter) =>
    dispatch({ type: "ADD_TO_THREEGB", testID, filter }),
  fetchThreeGBMark: options => dispatch(fetchThreeGB(options)),

  addToS2S: (testID, filter) => {
    dispatch({ type: "ADD_TO_THREEGB", testID, filter });
  },
  fetchS2SMark: options => dispatch(fetchS2S(options)),
  fetchS2SFillRate: testID => dispatch({ type: "FETCH_S2S_FILLRATE", testID }),

  fetchImportSource: () => dispatch({ type: "FETCH_IMPORTSOURCE" }),
  ImportSourceChange: source =>
    dispatch({ type: "CHANGE_IMPORTSOURCE", source }),
  deleteTest: testID => dispatch({ type: "POST_DELETE_TEST", testID }),
  existingImportFunc: flag =>
    dispatch({ type: "PHENOME_EXISTING_IMPORT", flag }),
  uploadS2S: testID => {
    dispatch({ type: "POST_S2S_UPLOAD", testID });
  },
  fetchCNTDataWithMarkers: options => {
    dispatch(fetchCNTDataWithMarkers(options));
  },
  saveMarkerSelected: materialsMarkers => {
    dispatch({ type: "SAVE_3GB_MATERIAL_MARKER", materialsMarkers });
  },
  fetchRDTmaterialwithtest: options => {
    dispatch(fetchRDTMateriwithTests(options));
  },
  fetchRDTMaterialState: () => dispatch({ type: "FETCH_RDT_MATERIAL_STATE" }),
  clearRDTFilter: () => dispatch({ type: "RDT_FILTER_CLEAR" }),
  reqRDTsampleTest: testID => dispatch({ type: "POST_RDT_REQ_SAMPLE", testID }),
  reqRDTupdateSampleTest: testID => {
    dispatch({ type: "UPDATE_RDT_REQ_SAMPLE", testID });
  },
  reqLeafDiskSampleTest: testID => dispatch({ type: "POST_LEAF_DISK_REQ_SAMPLE", testID }),
  fetchLeafDiskSampleData: options => {
    dispatch({ type: "FETCH_LEAF_DISK_SAMPLE_DATA", options });
  },
  leafDiskPrintLabel: testID => dispatch({ type: "LEAF_DISK_PRINT_LABEL", testID }),
  seedHealthPrintLabel: testID => dispatch({ type: "SEED_HEALTH_PRINT_LABEL", testID }),
  saveSample: payload => {
    dispatch({ type: "SAVE_SAMPLE", payload });
  },
  resetSaveSampleSucceededFlag: () =>
    dispatch({ type: "RESET_SAVE_SAMPLE_SUCCEEDED_FLAG" }),
  clearLDFilters: () => dispatch({ type: "CLEAR_LD_FILTERS" }),
  reloadSampleData: () => dispatch({ type: "RELOAD_LD_SAMPLE_DATA" }),
  reloadManageDeterminations: () =>
    dispatch({ type: "RELOAD_LD_MANAGE_DETERMINATION" }),

  //Seed Health
  fetchSeedHealthSampleData: options => {
    dispatch({ type: "FETCH_SEED_HEALTH_SAMPLE_DATA", options });
  },
  reqSeedHealthSampleTest: testID => dispatch({ type: "POST_SEED_HEALTH_REQ_SAMPLE", testID }),
  clearSHFilters: () => dispatch({ type: "CLEAR_SEED_HEALTH_FILTERS" }),
  reloadSHSampleData: () => dispatch({ type: "RELOAD_SEED_HEALTH_SAMPLE_DATA" }),
  reloadSHManageDeterminations: () =>
    dispatch({ type: "RELOAD_SEED_HEALTH_MANAGE_DETERMINATION" }),
  postSeedHealthExportToExcel: (testID, fileTitle) => dispatch({ type: "POST_SEED_HEALTH_EXPORT_TO_EXCEL", testID, fileTitle }),
  postSeedHealthSendToABS: testID => dispatch({ type: "POST_SEED_HEALTH_SEND_TO_ABS", testID }),
});

const Home = connect(
  mapStateToProps,
  mapDispatchToProps
)(HomeComponent);
export default Home;
