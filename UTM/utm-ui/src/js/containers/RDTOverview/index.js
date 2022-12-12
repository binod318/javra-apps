import { connect } from "react-redux";
import RDTOverviewComponent from "./RDTOverview";

import { fetchRDTOverview, rdtActiveChange } from "./action";

const mapState = state => ({
  sideMenu: state.sidemenuReducer,

  rdt: state.rdtoverview.rdtOverviewData,
  total: state.rdtoverview.total.total,
  pagenumber: state.rdtoverview.total.pageNumber,
  pagesize: state.rdtoverview.total.pageSize,
  filter: state.rdtoverview.filter,
  active: state.rdtoverview.active,

  roles: state.user.role
});

const mapDispatch = dispatch => ({
  fetchDate: (pageNumber, pageSize, filter, active) => {
    dispatch(fetchRDTOverview(pageNumber, pageSize, filter, active));
  },
  activeChange: flag => {
    dispatch(rdtActiveChange(flag));
  },

  filterClear: () => {},
  filterAdd: () => {},
  deleteTest: testID => dispatch({ type: "POST_DELETE_TEST", testID }),
  pageChange: () => {},
  export: (testID, testInfo, isMarkerScore) => {
    dispatch({
      type: "REQUEST_RDT_OVERVIEW_EXCEL",
      testID,
      testName: testInfo.test,
      isMarkerScore
    });
  }
});

export default connect(
  mapState,
  mapDispatch
)(RDTOverviewComponent);
