import { connect } from 'react-redux';
import SHResultComponent from './SHResultComponent';

import { getResults, postData, resetFilter } from './action';

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  result: state.shResult.result,
  total: state.shResult.total.total,
  pagenumber: state.shResult.total.pageNumber,
  pagesize: state.shResult.total.pageSize,
  filter: state.shResult.filter,
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
      type: 'FILTER_SH_RESULT_ADD',
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
)(SHResultComponent);