import React from 'react';
import { connect } from 'react-redux';

import TotalPACComponent from './TotalPACComponent';
import { fetchPage, exportPage, totalPACPage, totalPACFilter, totalPACSorter, totalPACEmpty } from './TotalPACAction';

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  columns: state.totalPAC.column,
  data: state.totalPAC.data,
  filter: state.totalPAC.filter,
  sorter: state.totalPAC.sorter,
  total: state.totalPAC.total,
  page: state.totalPAC.page
});

const mapDispatch = dispatch => ({
  sidemenu: () => dispatch(sidemenuClose()),
  fetchfetch: (page, size, sortBy, sortOrder, filter) => {
    dispatch(fetchPage(page, size, sortBy, sortOrder, filter));
  },
  exportExcel: filter => dispatch(exportPage(filter)),
  pageChange: page => dispatch(totalPACPage(page)),
  filterChange: filter => dispatch(totalPACFilter(filter)),
  empty: () => dispatch(totalPACEmpty()),
  sortChange: sorter => dispatch(totalPACSorter(sorter))
});

export default connect(
  mapState,
  mapDispatch
)(TotalPACComponent);
