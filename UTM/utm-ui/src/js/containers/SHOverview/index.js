import { connect } from "react-redux";
import SHOverviewComponent from "./SHOverview";

import { fetchSHOverview, shActiveChange } from "./action";

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  data: state.shOverview.shOverviewData,
  columns: state.shOverview.columns,
  total: state.shOverview.total.total,
  pagenumber: state.shOverview.total.pageNumber,
  pagesize: state.shOverview.total.pageSize,
  filter: state.shOverview.filter,
  active: state.shOverview.active,

  roles: state.user.role
});

const mapDispatch = dispatch => ({
  fetchData: (pageNumber, pageSize, filter, active) => {
    dispatch(fetchSHOverview(pageNumber, pageSize, filter, active));
  },
  activeChange: flag => {
    dispatch(shActiveChange(flag));
  },
  filterClear: () => {},
  filterAdd: () => {},
  deleteTest: testID => dispatch({ type: "POST_DELETE_TEST", testID }),
  pageChange: () => {},
  export: (testID, testInfo) => {
    dispatch({
      type: "REQUEST_SH_OVERVIEW_EXCEL",
      testID,
      testName: testInfo.testName
    });
  }
});

export default connect(
  mapState,
  mapDispatch
)(SHOverviewComponent);
