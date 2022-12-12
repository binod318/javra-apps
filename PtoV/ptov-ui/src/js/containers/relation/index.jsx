/*!
 *
 * RELATION SCREEN
 * ------------------------------
 * Connecting traits to screening fields
 * Translate trait attributes to screening fields attributes
 *
 */
import { connect } from 'react-redux';
import RelationComponent from './relation';
import { fetchRelation, postRelation, filterAdd, filterRemove, filterClear } from './action';

const mapState = state => ({
  status: state.status,
  relation: state.relation.relation,
  total: state.relation.total.total,
  pageNumber: state.relation.total.pageNumber,
  pageSize: state.relation.total.pageSize,
  filterList: state.relation.filter,
  sort: state.relation.sort
});
const mapDispatch = dispatch => ({
  fetchDate: (pageNumber, pageSize, filter, sorting) => dispatch(fetchRelation(pageNumber, pageSize, filter, sorting)),
  relationChange: obj => dispatch(postRelation(obj)),
  filterAdd: obj => dispatch(filterAdd(obj)),
  filterRemove: name => dispatch(filterRemove(name)),
  filterClear: () => dispatch(filterClear()),
  resetError: () => dispatch({ type: 'RESET_ERROR' })
});
export default connect(
  mapState,
  mapDispatch
)(RelationComponent);
