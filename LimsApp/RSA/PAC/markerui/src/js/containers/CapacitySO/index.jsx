import { connect } from 'react-redux';
import CapacitySOComponent from './CapacitySOComponent';

import {
  YearFetch,
  capacityYearSelect,
  periodFetch,
  capacityPeriodSelect,
  capacityFetch,
  capacityDataChange,
  capacityDataUpdate,
  capacitySOEmpty,
  CAPACITY_FOCUS
} from './capacitySOAction';
import { sidemenuClose } from '../../action';

const mapState = state => ({
  count: state.loader,
  sideMenu: state.sidemenuReducer,
  selected: state.capacity.year.selected,
  year: state.capacity.year.data,
  periodSelected: state.capacity.period.selected,
  period: state.capacity.period.data,
  data: state.capacity.data,
  calc: state.capacity.calc,
  columns: state.capacity.column,
  status: state.capacity.status,
  focusRef: state.capacity.focus.ref,
  focusStatus: state.capacity.focus.focus,
  errList: state.capacity.errList,
});
const mapDispatch = dispatch => ({
  sidemenu: () => dispatch(sidemenuClose()),

  capacityYearFetch: () => dispatch(YearFetch()),
  capacityYearSelect: year => dispatch(capacityYearSelect(year)),

  capacityPeriodFetch: year => dispatch(periodFetch(year)),
  capacityPeriodSelect: periodID => dispatch(capacityPeriodSelect(periodID)),
  capacityFetch: periodID => dispatch(capacityFetch(periodID)),
  capacityDataChange: (index, key, value, UsedFor, oldValue) =>
    dispatch(capacityDataChange(index, key, value, UsedFor, oldValue)),
  capacityEmpty: () => dispatch(capacitySOEmpty()),
  capacityDataUpdate: data => dispatch(capacityDataUpdate(data)),
  refFunc: ref => dispatch({ type: CAPACITY_FOCUS, ref }),
  totalChange: (total, hybTotal, parTotal, ColumnID) => {
    dispatch({
      type: 'TOTAL_CHANGE',
      total, hybTotal, parTotal, ColumnID
    });
  }
});

export default connect(
  mapState,
  mapDispatch
)(CapacitySOComponent);
