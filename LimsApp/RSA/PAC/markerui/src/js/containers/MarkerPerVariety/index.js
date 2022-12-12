import React from "react";
import { connect } from "react-redux";

import MarkerPerVarietyComponent from "./MarkerPerVarietyComponent";
import {
  markerPerVarietyFetch,
  getMarkersFetch,
  getCropsFetch,
  getVarietiesFetch,
  postMarkerPerVariety,
  markerPerVarietyPage,
  markerPerVarietyPageSize,
  markerPerVarietyFilter,
  markerPerVarietyEmpty
} from "./markerPerVarietyAction";

const mapState = (state) => ({
  sideMenu: state.sidemenuReducer,
  role: state.user.role.includes("pac_handlelabcapacity"),
  columns: state.markerPerVariety.column,
  data: state.markerPerVariety.data,
  markers: state.markerPerVariety.markers,
  varieties: state.markerPerVariety.varieties,
  crops: state.markerPerVariety.crops,
  filter: state.markerPerVariety.filter,
  total: state.markerPerVariety.total,
  page: state.markerPerVariety.page,
  pageSize: state.markerPerVariety.size
});
const mapDispatch = (dispatch) => ({
  sidemenu: () => dispatch(sidemenuClose()),
  fetchMarkerPerVariety: (page, size, sortBy, sortOrder, filter) => {
    dispatch(markerPerVarietyFetch(page, size, sortBy, sortOrder, filter));
  },
  empty: () => dispatch(markerPerVarietyEmpty()),
  pageChange: page => dispatch(markerPerVarietyPage(page)),
  pageSizeChange: pageSize => dispatch(markerPerVarietyPageSize(pageSize)),
  filterChange: filter => dispatch(markerPerVarietyFilter(filter)),
  getMarkerFunc: (value, cropCode, showPacMarkers) => dispatch(getMarkersFetch(value, cropCode, showPacMarkers)),
  getVarietiesFunc: (value, cropCode) => dispatch(getVarietiesFetch(value, cropCode)),
  getCropsFunc: () => dispatch(getCropsFetch()),
  postMarkerPerVarietyFunc: (
    MarkerPerVarID,
    MarkerID,
    VarietyNr,
    Remarks,
    ExpectedResult,
    action
  ) =>
    dispatch(
      postMarkerPerVariety(
        MarkerPerVarID,
        MarkerID,
        VarietyNr,
        Remarks,
        ExpectedResult,
        action
      )
    ),
});

export default connect(mapState, mapDispatch)(MarkerPerVarietyComponent);
