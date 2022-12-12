import { connect } from "react-redux";
import LDOverviewComponent from "./LDOverview";

import { fetchLDOverview, ldActiveChange } from "./action";

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  data: state.ldOverview.ldOverviewData,
  columns: state.ldOverview.columns,
  total: state.ldOverview.total.total,
  pagenumber: state.ldOverview.total.pageNumber,
  pagesize: state.ldOverview.total.pageSize,
  filter: state.ldOverview.filter,
  active: state.ldOverview.active,

  roles: state.user.role
});

const mapDispatch = dispatch => ({
  fetchData: (pageNumber, pageSize, filter, active) => {
    dispatch(fetchLDOverview(pageNumber, pageSize, filter, active));
  },
  activeChange: flag => {
    dispatch(ldActiveChange(flag));
  },
  filterClear: () => {},
  filterAdd: () => {},
  deleteTest: testID => dispatch({ type: "POST_DELETE_TEST", testID }),
  pageChange: () => {},
  export: (testID, testInfo) => {
    dispatch({
      type: "REQUEST_LD_OVERVIEW_EXCEL",
      testID,
      testName: testInfo.testName
    });
  }
});

export default connect(
  mapState,
  mapDispatch
)(LDOverviewComponent);
