import { connect } from 'react-redux';
import LabProtocolComponent from './LabProtocolComponent';

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  result: state.labProtocol.maintain,
  filter: state.labProtocol.filter,
  total: state.labProtocol.total.total,
  pagenumber: state.labProtocol.total.pageNumber,
  pagesize: state.labProtocol.total.pageSize,
  refresh: state.labProtocol.refresh
});
const mapDispatch = dispatch => ({
  fetchProtocol: (pageNumber, pageSize, filter) => {
    dispatch({
      type: 'POST_PROTOCOL_LIST',
      pageNumber,
      pageSize,
      filter
    });
  },
  actionProtocol: indicator => {
    console.log(indicator);
  },
  filterAdd: obj => dispatch({ type: 'FILTER_PROTOCOL_ADD', ...obj }),
  filterClear: () => dispatch({ type: 'FILTER_PROTOCOL_CLEAR' })
});
const LabProtocol = connect(
  mapState,
  mapDispatch
)(LabProtocolComponent);
export default LabProtocol;
