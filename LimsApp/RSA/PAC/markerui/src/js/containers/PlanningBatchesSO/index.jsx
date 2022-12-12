import React from "react";
import { connect } from "react-redux";

import PlanningBatchesSOComponent from "./PlanningBatchesSOComponent";

import {
  YearFetch,
  PLANNING_YEAR_SELECT,
  planningYearSelected,
  planningPeriodFetch,
  planningDataChange,
  planningDataPrioChange,
  planningPeriodDate,
  planningDeterminationFetch,
  autoplanDeterminationFetch,
  planningConfirmPost,
} from "./planningBatchesSOAction";
import { sidemenuClose } from "../../action";

const mapState = (state) => ({
  sideMenu: state.sidemenuReducer,
  selected: state.planning.year.selected,
  year: state.capacity.year.data,
  periodSelected: state.planning.period.selected,
  period: state.planning.period.data,
  dateStart: state.planning.period.startEndDate.StartDate,
  dateEnd: state.planning.period.startEndDate.EndDate,
  group: state.planning.group,
  data: state.planning.data,
  columns: state.planning.column,
  changes: state.planning.change,
  refresh: state.planning.refresh,
  totalUsed: state.planning.fillrate.totalUsed,
  totalReserved: state.planning.fillrate.totalReserved
});
const mapDispatch = (dispatch) => ({
  sidemenu: () => dispatch(sidemenuClose()),

  planningYearFetch: () => dispatch(YearFetch()),
  planningYearSelect: (year) => dispatch(planningYearSelected(year)),
  planningPeriodFetch: (year) => dispatch(planningPeriodFetch(year)),
  planningPeriodSelect: (periodID, row) => {
    dispatch({ type: "PLANNING_PERIOD_SELECT", selected: periodID });
    const { StartDate, EndDate } = row;
    dispatch(planningPeriodDate(StartDate, EndDate));
  },
  planningPeriodBlank: () => dispatch({ type: "PLANNING_PERIOD_BLANK" }),
  planningDeterminationFetch: (
    periodID,
    StartDate,
    EndDate,
    includeUnplanned
  ) => {
    dispatch(
      planningDeterminationFetch(periodID, StartDate, EndDate, includeUnplanned)
    );
  },

  autoPlanDeterminationFetch: (periodID, StartDate, EndDate) => {
    dispatch(autoplanDeterminationFetch(periodID, StartDate, EndDate));
  },
  planningDataChangePost: (change, flag) => {
    dispatch(planningDataChange(change, flag));
    dispatch({ type: "CHANGE_REFRESH" });
  },
  planningDataPrioChangePost: (change, flag) =>
    dispatch(planningDataPrioChange(change, flag)),
  planningDeterminationConfirmPost: (obj, periodID, startEndDate) =>
    dispatch(planningConfirmPost(obj, periodID, startEndDate)),
  show: (msg) => {
    dispatch({
      type: "NOTIFICATION_SHOW",
      status: true,
      message: msg || "",
      messageType: 2,
      notificationType: 0,
      code: "",
    });
  },
  clearPage: () => dispatch({ type: "PLANNING_EMPTY" }),
});

export default connect(mapState, mapDispatch)(PlanningBatchesSOComponent);
