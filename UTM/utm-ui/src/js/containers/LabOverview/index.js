import { connect } from "react-redux";
import LabOverviewComponent from "./components/LabOverviewComponent";
import "./labOverview.scss";
import { pageTitle, fetchYearPeriod, fetchYearPeriodUpdate } from "./actions";

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  data: state.laboverview.data,
  refresh: state.laboverview.refresh,
  filter: state.laboverview.filter,
  errorMsg: state.laboverview.error.error,
  submit: state.laboverview.error.submit,
  forced: state.laboverview.error.forced
});
const mapDispatch = dispatch => ({
  pageTitle: () => dispatch(pageTitle()),
  labFetch: (year, period) => dispatch(fetchYearPeriod(year, period)),
  labDataUpdate: (data, year) => dispatch(fetchYearPeriodUpdate(data, year)),
  slotEdit: obj => dispatch({ type: "SLOT_EDIT", ...obj }),
  errorReset: () => dispatch({ type: "LABOVERVIEW_ERROR_RESET" }),
  filterAdd: obj =>
    dispatch({ type: "FILTER_LABOVERVIEW_ADD_BLUK", filter: obj }),
  filterClear: () => dispatch({ type: "FILTER_LABOVERVIEW_CLEAR" }),
  export: (periodID, year, filter) =>
    dispatch({ type: "EXPORT_LABOVERVIEW", periodID, year, filter })
});

const LabOverview = connect(
  mapState,
  mapDispatch
)(LabOverviewComponent);

export default LabOverview;
