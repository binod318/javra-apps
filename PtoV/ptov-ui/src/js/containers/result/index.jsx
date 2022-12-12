/*!
 *
 * RESULT SCREEN
 * ------------------------------
 *
 */

import { connect } from 'react-redux';
import resultComponent from './attribute';

import {
  getResults,
  filterAdd,
  filterRemove,
  filterClear,
  postData
} from './action';

const mapState = state => ({
  status: state.status,

  result: state.result.result,
  total: state.result.total.total,
  pageNumber: state.result.total.pageNumber,
  pageSize: state.result.total.pageSize,
  filterList: state.result.filter,
  sort: state.result.sort
});
const mapDispatch = dispatch => ({
  fetchDate: (pageNumber, pageSize, filter, sorting) => dispatch(getResults(pageNumber, pageSize, filter, sorting)),
  relationChange: obj => dispatch(postData(obj)),
  filterAdd: obj => dispatch(filterAdd(obj)),
  filterRemove: name => dispatch(filterRemove(name)),
  filterClear: () => dispatch(filterClear()),
  resetError: () => dispatch({ type: 'RESET_ERROR' })
});
export default connect(
  mapState,
  mapDispatch
)(resultComponent);
