import React from "react";
import { connect } from "react-redux";

import LabResultComponent from "./LabResultComponent";
import {
  YearFetch,
  labResultYearSelected,
  labResultPeriodFetch,
  planningDeterminationFetch,
  fetchListActionCreator,
} from "./labResultAction";

import { sidemenuClose } from "../../action";

const mapState = (state) => ({
  sideMenu: state.sidemenuReducer,
  columns: state.labResults.column,
  data: state.labResults.data,
  filter: state.labResults.filter,
  sorter: state.labResults.sorter,
  total: state.labResults.total,
  page: state.labResults.page
});
const mapDispatch = (dispatch) => ({
  sidemenu: () => dispatch(sidemenuClose()),
  labResultFetch: (page, size, sortBy, sortOrder, filter) =>
    dispatch({
      type: "LAB_RESULT_FETCH",
      PageNr: page,
      PageSize: size,
      SortBy: sortBy,
      SortOrder: sortOrder,
      Filters: filter,
    }),
  empty: () => dispatch({ type: "LAB_RESULT_EMPTY" }),
  pageChange: (page) =>
    dispatch({ type: "LABRESULT_PAGE", page }),
  filterChange: (filter) =>
    dispatch({ type: "LABRESULT_FILTER_ADD", data: filter }),
  sortChange: (sorter) =>
    dispatch({ type: "LABRESULT_SORTER", data: sorter })
});
export default connect(mapState, mapDispatch)(LabResultComponent);
