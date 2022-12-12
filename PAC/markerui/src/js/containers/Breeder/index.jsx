import { connect } from "react-redux";

import BreederComponent from "./component/BreederComponent";

import "./breeder.scss";
import {
  periodFetch,
  platesTestFetch,
  breederSumbit,
  breederReset,
  notificationShow,
  breederReserve,
  breederErrorClear,
  expectedBlank,
  breederFetchMaterialType,
  breederFieldFetch,
} from "./action/index";
import { sidemenuClose } from "../../action";

const mapState = (state) => ({
  breedingStation: state.breeder.fields.breedingStation,
  crop: state.breeder.fields.crop,
  testType: state.breeder.fields.testType,
  materialType: state.breeder.fields.materialType,
  materialState: state.breeder.fields.materialState,
  periodName: state.breeder.fields.period,

  currentPeriod: state.breeder.period.planned,
  expectedPeriod: state.breeder.period.expected,
  availPlates: state.breeder.period.availPlates,
  availTests: state.breeder.period.availTests,
  expectedDate: state.breeder.period.expectedDate,

  errorMsg: state.breeder.error.error,
  submit: state.breeder.error.submit,
  forced: state.breeder.error.forced,

  // list
  breedingStation2: state.breedingStation.station,
  breedingStationSelected: state.breedingStation.selected,

  sideMenu: state.sidemenuReducer,
  slotList: state.slotBreeder.slot || [],sadf
  total: state.slotBreeder.total.total,
  pagenumber: state.slotBreeder.total.pageNumber,
  pagesize: state.slotBreeder.total.pageSize,
  filter: state.slotBreeder.filter,
});
const mapDispatch = (dispatch) => ({
  sidemenu: () => dispatch(sidemenuClose()),
  period: (date, period) => dispatch(periodFetch(period, date)),
  plateTest: (plannedDate, cropCode, materialTypeID, isolated) =>
    dispatch(platesTestFetch(plannedDate, cropCode, materialTypeID, isolated)),
  fetchForm: () => dispatch(breederFieldFetch()),
  fetchMaterialType: (crop) => dispatch(breederFetchMaterialType(crop)),
  expectedBlank: () => dispatch(expectedBlank()),
  clearError: () => dispatch(breederErrorClear()),
  reserve: (obj) => dispatch(breederReserve(obj)),
  show_error: (obj) => dispatch(notificationShow(obj)),
  resetStoreBreeder: () => dispatch(breederReset()),
  submitToFalse: () => dispatch(breederSumbit(false)),
  clearPageData: () => {
    dispatch({
      type: "BREEDER_SLOT_PAGE_RESET",
    });
  },
});

export default connect(mapState, mapDispatch)(BreederComponent);
