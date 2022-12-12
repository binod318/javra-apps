import { connect } from "react-redux";

import LeafDiskCapacityPlanningComponent from "./component/LeafDiskCapacityPlanning";

import "./breeder.scss";
import {
  setpageTitle,
  periodFetch,
  fetchAvailSamples,
  breederSumbit,
  breederReset,
  notificationShow,
  breederReserve,
  breederErrorClear,
  expectedBlank,
  breederFetchMaterialType,
  breederFieldFetch,
  leafDiskExportCapacityPlanning,
  addFilter,
  clearFilter,
  breederSlotFetch,
  breederUpdate
} from "./action/index";
import { locationFetch } from "../../action"
import { sidemenuClose } from "../../action";
import { leafDiskSlotDeleteAction } from "../../components/Slot/actions";

const mapState = state =>
  ({
    breedingStation: state.leafDiskCapacityPlanning.fields.breedingStation,
    crop: state.leafDiskCapacityPlanning.fields.crop,
    testType: state.leafDiskCapacityPlanning.fields.testType,
    materialType: state.leafDiskCapacityPlanning.fields.materialType,
    testProtocol: state.leafDiskCapacityPlanning.fields.testProtocol,
    siteLocation: state.leafDiskCapacityPlanning.fields.siteLocation,
    periodName: state.leafDiskCapacityPlanning.fields.period,
    columns: state.leafDiskCapacityPlanning.fields.columns,

    currentPeriod: state.leafDiskCapacityPlanning.period.planned,
    availTests: state.leafDiskCapacityPlanning.period.availTests,
    errorMsg: state.leafDiskCapacityPlanning.error.error,
    submit: state.leafDiskCapacityPlanning.error.submit,
    forced: state.leafDiskCapacityPlanning.error.forced,
    update: state.leafDiskCapacityPlanning.error.update,
    forceUpdate: state.leafDiskCapacityPlanning.error.forceUpdate,

    // list
    roles: state.user.role,
    crops: state.user.crops,
    cropSelected: state.user.selectedCrop,
    breedingStation2: state.breedingStation.station,
    breedingStationSelected: state.breedingStation.selected,

    sideMenu: state.sidemenuReducer,
    slotList: state.leafDiskCapacityPlanning.slot || [],
    total: state.leafDiskCapacityPlanning.total.total,
    pagenumber: state.leafDiskCapacityPlanning.total.pageNumber,
    pagesize: state.leafDiskCapacityPlanning.total.pageSize,
    filter: state.leafDiskCapacityPlanning.filter
  });
const mapDispatch = dispatch => ({
  pageTitle: () => dispatch(setpageTitle()),
  sidemenu: () => dispatch(sidemenuClose()),
  period: (date, period) => dispatch(periodFetch(period, date)),
  fetchAvailSamples: (testProtocolID, plannedDate, siteID) =>
    dispatch(
      fetchAvailSamples(
        testProtocolID,
        plannedDate,
        siteID
      )
    ),
  fetchForm: () => dispatch(breederFieldFetch()),
  fetchMaterialType: crop => dispatch(breederFetchMaterialType(crop)),
  expectedBlank: () => dispatch(expectedBlank()),
  clearError: () => dispatch(breederErrorClear()),
  reserve: obj => dispatch(breederReserve(obj)),
  show_error: obj => dispatch(notificationShow(obj)),
  resetStoreBreeder: () => dispatch(breederReset()),
  submitToFalse: () => dispatch(breederSumbit(false)),
  fetchSlot: (cropCode, brStationCode, pageNumber, pageSize, filter) =>
    dispatch(
      breederSlotFetch(cropCode, brStationCode, pageNumber, pageSize, filter)
    ),
  filterClear: () => dispatch(clearFilter()),
  filterAdd: obj => {
    const { name, value, dataType, traitID } = obj;
    const CONSTAINS = "contains";
    const OPT = "and";
    dispatch(addFilter(name, value, CONSTAINS, OPT, dataType, traitID));
  },
  clearPageData: () => dispatch({ type: "LEAF_DISK_BREEDER_SLOT_PAGE_RESET" }),
  slotDelete: (slotID, cropCode, brStationCode, slotName) =>
    dispatch(leafDiskSlotDeleteAction(slotID, cropCode, brStationCode, slotName)),
  slotEdit: obj =>
    dispatch({ type: "LEAF_DISK_CAPACITY_PLANNING_SLOT_EDIT", ...obj }),
  updateToFalse: () =>
    dispatch({
      type: "LEAF_DISK_CAPACITY_PLANNING_UPDATE_FORCED",
      forceUpdate: false
    }),
  changeUpdateMode: update =>
    dispatch(breederUpdate(update)),
  leafDiskExportCapacityPlanning: payload => dispatch(leafDiskExportCapacityPlanning(payload))
});

export default connect(
  mapState,
  mapDispatch
)(LeafDiskCapacityPlanningComponent);
