import { connect } from 'react-redux';

import LabComponent from './LabComponent';
// import './labCapacity.scss';
import {
  YearFetch,
  labFetch,
  labYearSelect,
  labDataChange,
  labDataRowChange,
  labDataUpdate
} from './labAction';
import { sidemenuClose } from '../../action';

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  selected: state.lab.year.selected,
  year: state.lab.year.data,
  data: state.lab.data,
  columns: state.lab.column,
  status: state.lab.status
});
const mapDispatch = dispatch => ({
  sidemenu: () => dispatch(sidemenuClose()),

  labYearFetch: () => dispatch(YearFetch()),
  labYearSelect: year => dispatch(labYearSelect(year)),

  labFetch: year => dispatch(labFetch(year)),

  labDataChange: (index, key, value) =>
    dispatch(labDataChange(index, key, value)),
  labDataRowChange: (key, value) => dispatch(labDataRowChange(key, value)),
  labDataUpdate: (data, year) => dispatch(labDataUpdate(data, year)),

  labDataChange: (index, key, value) => {
    dispatch({
      type: 'LAB_DATA_CHANGE',
      index,
      key,
      value
    });
  }
});

export default connect(
  mapState,
  mapDispatch
)(LabComponent);
