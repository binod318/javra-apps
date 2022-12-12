import { connect } from "react-redux";
import LDLabOverviewComponent from "./components/LDLabOverviewComponent";
import "./LDlabOverview.scss";
import { pageTitle, fetchYearPeriod, fetchYearPeriodUpdate } from "./actions";
import { locationFetch } from "../../action"

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  data: state.ldlaboverview.data,
  columns: state.ldlaboverview.columns,
  refresh: state.ldlaboverview.refresh,
  filter: state.ldlaboverview.filter,
  errorMsg: state.ldlaboverview.error.error,
  submit: state.ldlaboverview.error.submit,
  forced: state.ldlaboverview.error.forced,
  location: state.location 
});
const mapDispatch = dispatch => ({
  pageTitle: () => dispatch(pageTitle()),
  labFetch: (year, period, siteID, filter) => dispatch(fetchYearPeriod(year, period, siteID, filter)),
  labDataUpdate: (data, year) => dispatch(fetchYearPeriodUpdate(data, year)),  
  locationFetch: () => dispatch(locationFetch()),
  slotEdit: obj => dispatch({ type: "LEAF_DISK_SLOT_EDIT", ...obj }),
  errorReset: () => dispatch({ type: "LABOVERVIEW_ERROR_RESET" }),
  filterAdd: obj =>
    dispatch({ type: "FILTER_LABOVERVIEW_ADD_BLUK", filter: obj }),
  filterClear: () => dispatch({ type: "FILTER_LABOVERVIEW_CLEAR" }),
  export: (periodID, year, siteID, filter) =>
    dispatch({ type: "LEAF_DISK_EXPORT_LABOVERVIEW", periodID, year, siteID, filter })
});

const LDLabOverview = connect(
  mapState,
  mapDispatch
)(LDLabOverviewComponent);

export default LDLabOverview;
