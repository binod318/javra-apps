import { YEAR_FETCH } from "../CapacitySO/capacitySOAction";
export const PLANNING_YEAR_SELECT = "PLANNING_YEAR_SELECT";

export const YEAR_ADD = "YEAR_ADD";
export const PLANNING_PEROID_FETCH = "PLANNING_PERIOND_FETCH";
export const PLANNING_PERIOD_ADD = "PLANNING_PERIOD_ADD";
export const PLANNING_PERIOD_SELECT = "PLANNING_PERIOD_SELECT";
export const PLANNING_PERIOD_BLANK = "PLANNING_PERIOD_BLANK";
export const PLANNING_PERIOD_DATE = "PLANNING_PERIOD_DATE";

export const PLANNING_COLUMN_ADD = "PLANNING_COLUMN_ADD";
export const PLANNING_EMPTY = "PLANNING_EMPTY";

export const PLANNING_DATA_ADD = "PLANNING_DATA_ADD";

export const PLANNING_DATA_CHANGE = "PLANNING_DATA_CHANGE";
export const PLANNING_DATA_CHANGE_TOGGLE = "PLANNING_DATA_CHANGE_TOGGLE";

export const PLANNING_DATA_PRIO_CHANGE_TOGGLE =
  "PLANNING_DATA_PRIO_CHANGE_TOGGLE";

export const PLANNING_DETERMINATION_FETCH = "PLANNING_DETERMINATION_FETCH";
export const AUTOPLAN_DETERMINATION_FETCH = "AUTOPLAN_DETERMINATION_FETCH";
export const PLANNING_CONFIRM_POST = "PLANNING_CONFIRM_POST";

export const YearFetch = () => ({ type: YEAR_FETCH });
export const planningYearSelected = (selected) => ({
  type: PLANNING_YEAR_SELECT,
  selected,
});

export const planningPeriodFetch = (year) => {
  return { type: PLANNING_PEROID_FETCH, year };
};
export const planningPeriodSelected = (selected) => ({
  type: PLANNING_PERIOD_SELECT,
  selected,
});

export const planningDataChange = (change, flag) => ({
  type: PLANNING_DATA_CHANGE_TOGGLE,
  change,
  flag,
});

export const planningDataPrioChange = (change, flag) => ({
  type: PLANNING_DATA_PRIO_CHANGE_TOGGLE,
  change,
  flag,
});

export const planningPeriodDate = (StartDate, EndDate) => ({
  type: PLANNING_PERIOD_DATE,
  date: {
    StartDate,
    EndDate,
  },
});

export const planningDeterminationFetch = (
  periodID,
  StartDate,
  EndDate,
  includeUnplanned
) => ({
  type: PLANNING_DETERMINATION_FETCH,
  periodID,
  StartDate,
  EndDate,
  includeUnplanned,
});

export const autoplanDeterminationFetch = (periodID, StartDate, EndDate) => ({
  type: AUTOPLAN_DETERMINATION_FETCH,
  periodID,
  StartDate,
  EndDate,
});

export const planningConfirmPost = (obj, periodID, startEndDate) => ({
  type: PLANNING_CONFIRM_POST,
  obj,
  periodID,
  startEndDate,
});

export const PLANNING_SET_FILLRATE_TOTALUSED = 'PLANNING_SET_FILLRATE_TOTALUSED';
export const  planningSetFillRateTotalUsed = TotalUsed => ({
  type: PLANNING_SET_FILLRATE_TOTALUSED,
  TotalUsed
});

export const PLANNING_SET_FILLRATE_TOTALRESERVED = 'PLANNING_SET_FILLRATE_TOTALRESERVED';
export const  planningSetFillRateTotalReserved = TotalReserved => ({
  type: PLANNING_SET_FILLRATE_TOTALRESERVED,
  TotalReserved
});