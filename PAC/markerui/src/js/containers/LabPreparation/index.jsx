import React from "react";
import { connect } from "react-redux";

import LabPreparationComponent from "./LabPreparationComponent";
import Prepaaration from "./Preparation";

import {
  YearFetch,
  labPreparationYearSelected,
  labPreparationPeriodFetch,
  labPreparationPeriodBlank,
  labPreparationPeriodSelected,
  labPreparationFolderFetch,
  labPreparationGroupToggle,
  labPreparationEmpty,
  labDeclusterFetch,
  printPlateLabel,
} from "./labPreparationAction";

import { sidemenuClose } from "../../action";

const mapState = (state) => ({
  sideMenu: state.sidemenuReducer,
  role: (state.user && state.user.role) || null,
  selected: state.labPreparation.year.selected,
  year: state.capacity.year.data,
  periodSelected: state.labPreparation.period.selected,
  period: state.labPreparation.period.data,
  status: state.labPreparation.status,
  daStatus: state.labPreparation.daStatus,
  totalUsed: state.labPreparation.fillrate.totalUsed,
  totalReserved: state.labPreparation.fillrate.totalReserved,
  groups: state.labPreparation.group,
  columns: state.labPreparation.column,
  data: state.labPreparation.data,

  dcolumns: state.labPreparation.labDescluster.column,
  ddata: state.labPreparation.labDescluster.data,
});

const mapDispatch = (dispatch) => ({
  sidemenu: () => dispatch(sidemenuClose()),
  labPreparationYearFetch: () => dispatch(YearFetch()),
  labPreparationYearSelect: (year) =>
    dispatch(labPreparationYearSelected(year)),
  labPreparationPeriodFetch: (year) =>
    dispatch(labPreparationPeriodFetch(year)),
  labPreparationPeriodSelect: (periodID, row) => {
    dispatch(labPreparationPeriodSelected(periodID));
  },
  labPreparationPeriodBlank: () => {
    dispatch(labPreparationPeriodBlank());
  },
  labPreparationFolderFetch: (periodID) =>
    dispatch(labPreparationFolderFetch(periodID)),
  groupToggle: (index) => dispatch(labPreparationGroupToggle(index)),
  labEmpty: () => dispatch(labPreparationEmpty()),

  labDeclusterFetch: (periodID, detAssignmentID) =>
    dispatch(labDeclusterFetch(periodID, detAssignmentID)),
  reservePlates: (periodID) => {
    dispatch({
      type: "RESERVE_PLATES_LIMS",
      periodID,
    });
  },
  sendToLims: (periodID) => {
    dispatch({
      type: "PLANNING_SEND_TO_LIMS",
      periodID,
    });
  },
  getTestStatus: (periodID) =>
    dispatch({ type: "TEST_STATUS_FETCH", periodID }),
  postPrintPlateLabel: (period, testID) =>
    dispatch(printPlateLabel(period, testID)),
});

export default connect(mapState, mapDispatch)(LabPreparationComponent);
// ) (Prepaaration);
