import { combineReducers } from "redux";

import {
  YEAR_ADD,
  PLANNING_YEAR_SELECT,
  PLANNING_PERIOD_ADD,
  PLANNING_PERIOD_SELECT,
  PLANNING_PERIOD_BLANK,
  PLANNING_PERIOD_DATE,
  PLANNING_COLUMN_ADD,
  PLANNING_EMPTY,
  PLANNING_DATA_ADD,
  PLANNING_DATA_CHANGE,
  PLANNING_DATA_CHANGE_TOGGLE,
  PLANNING_DATA_PRIO_CHANGE_TOGGLE,  
  PLANNING_SET_FILLRATE_TOTALUSED,
  PLANNING_SET_FILLRATE_TOTALRESERVED
} from "./planningBatchesSOAction";
import { FileCoverage } from "istanbul-lib-coverage";

const selectedYear = (state = "", action) => {
  switch (action.type) {
    case PLANNING_YEAR_SELECT: {
      return action.selected.toString();
    }
    default:
      return state;
  }
};
const year = (state = [], action) => {
  switch (action.type) {
    case YEAR_ADD: {
      return action.data;
    }
    default:
      return state;
  }
};

const selectedPeriod = (state = "", action) => {
  switch (action.type) {
    case PLANNING_PERIOD_SELECT: {
      return action.selected.toString();
    }
    case PLANNING_PERIOD_BLANK:
      return "";
    default:
      return state;
  }
};
const selectedDate = (state = { StartDate: "", EndDate: "" }, action) => {
  switch (action.type) {
    case PLANNING_PERIOD_DATE:
      return action.date;
    default:
      return state;
  }
};
const period = (state = [], action) => {
  switch (action.type) {
    case PLANNING_PERIOD_ADD: {
      return action.data;
    }
    default:
      return state;
  }
};

const group = (state = [], action) => {
  switch (action.type) {
    case "GROUP_ADD":
      return action.group;
    case PLANNING_EMPTY:
      return [];
    default:
      return state;
  }
};

const column = (state = [], action) => {
  switch (action.type) {
    case PLANNING_COLUMN_ADD: {
      return action.data;
    }
    case PLANNING_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};

const data = (state = [], action) => {
  switch (action.type) {
    case PLANNING_DATA_ADD:
      return action.data;
    case PLANNING_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};

const change = (state = [], action) => {
  switch (action.type) {
    case PLANNING_DATA_CHANGE:
      return action.change;

    case PLANNING_DATA_CHANGE_TOGGLE:
      const {
        change: { DetAssignmentID },
        flag,
      } = action;
      return state.map((row) => {
        const change = row.init !== flag;
        return row.DetAssignmentID === DetAssignmentID
          ? {
              ...row,
              flag,
              change,
              IsLabPriority: !flag ? flag : row.IsLabPriority,
            }
          : row;
      });
    case PLANNING_DATA_PRIO_CHANGE_TOGGLE:
      const {
        change: { DetAssignmentID: daID },
        flag: fg,
      } = action;

      return state.map((row) => {
        return row.DetAssignmentID === daID
          ? {
              ...row,
              flag: fg ? fg : row.flag,
              change: fg ? row.init !== fg : row.change,
              IsLabPriority: fg,
              perioChange: row.perioInit !== fg,
            }
          : row;
      });
    case PLANNING_EMPTY: {
      return [];
    }
    default:
      return state;
  }
  return state;
};

const refresh = (state = false, action) => {
  switch (action.type) {
    case "CHANGE_REFRESH":
      return !state;
    case PLANNING_EMPTY: {
      return false;
    }
    default:
      return state;
  }
};

const totalUsed = (state = "", action) => {
  switch (action.type) {
    case PLANNING_SET_FILLRATE_TOTALUSED: {
      return action.TotalUsed;
    }
    default:
      return state;
  }
};
const totalReserved = (state = [], action) => {
  switch (action.type) {
    case PLANNING_SET_FILLRATE_TOTALRESERVED: {
      return action.TotalReserved;
    }
    default:
      return state;
  }
};


const planning = combineReducers({
  refresh,
  year: combineReducers({
    selected: selectedYear,
    data: year,
  }),
  period: combineReducers({
    selected: selectedPeriod,
    startEndDate: selectedDate,
    data: period,
  }),
  fillrate: combineReducers({
    totalUsed,
    totalReserved
  }),
  group,
  column,
  data,
  change,
});
export default planning;
