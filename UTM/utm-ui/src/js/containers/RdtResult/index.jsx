import { connect } from 'react-redux';
import RDTResultComponent from './RDTResultComponent';

import { getResults, postData, resetFilter } from './action';

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  result: state.rdtResult.result,
  total: state.rdtResult.total.total,
  pagenumber: state.rdtResult.total.pageNumber,
  pagesize: state.rdtResult.total.pageSize,
  filter: state.rdtResult.filter,
  checkList: state.traitResult.checkValidation,
  role: state.user.role
});
const mapDispatch = dispatch => ({
  fetchData: (pageNumber, pageSize, filter) =>
    dispatch(getResults(pageNumber, pageSize, filter)),
  resultChanges: (cropCode, data, pageNumber, pageSize, filter) => {
    const newObj = {
      cropCode,
      data,
      pageNumber,
      pageSize,
      filter
    };
    dispatch(postData(newObj));
  },
  filterClear: () => dispatch(resetFilter()),
  filterAdd: obj => {
    dispatch({
      type: 'FILTER_RDT_RESULT_ADD',
      name: obj.name,
      value: obj.value,
      expression: 'contains',
      operator: 'and',
      dataType: obj.dataType,
      traitID: obj.traitID
    });
  }
});

export default connect(
  mapState,
  mapDispatch
)(RDTResultComponent);