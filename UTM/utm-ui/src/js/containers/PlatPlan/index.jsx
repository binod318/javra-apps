import { connect } from "react-redux";

import PlatPlanComponent from "./PlatPlanComponent";

import {
  fetchPlatPlan,
  filterPlatPlanClear,
  filterPlatPlanAdd,
  platPlanExport
} from "./action";

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  relation: state.platPlan.platPlanData,
  total: state.platPlan.total.total,
  pagenumber: state.platPlan.total.pageNumber,
  pagesize: state.platPlan.total.pageSize,
  filter: state.platPlan.filter,
  active: state.platPlan.active,
  roles: state.user.role
});
const mapDispatch = dispatch => ({
  fetchDate: (pageNumber, pageSize, filter, active, btr) =>
    dispatch(fetchPlatPlan(pageNumber, pageSize, filter, active, btr)),
  activeChange: flag => dispatch({ type: "PLAT_PLAN_CHANGE", flag }),
  filterClear: () => dispatch(filterPlatPlanClear()),
  filterAdd: obj => dispatch(filterPlatPlanAdd(obj)),
  export: (testID, row, controlPosition) =>
    dispatch(platPlanExport(testID, row, controlPosition)),
  deleteTest: testID => dispatch({ type: "POST_DELETE_TEST", testID })
});

export default connect(
  mapState,
  mapDispatch
)(PlatPlanComponent);
