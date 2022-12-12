import { combineReducers } from "redux";

import {
  YEAR_ADD,
  CAPACITY_YEAR_SELECT,
  PERIOD_FETCH,
  PERIOD_ADD,
  PERIOD_SELECT,
  CAPACITY_DATA_FETCH,
  CAPACITY_COLUMN_ADD,
  CAPACITY_DATA_ADD,
  CAPACITY_DATA_CHANGE,
  CAPACITY_DATA_UPDATE,
  CAPACITY_DATE_ROW_CHANGE,
  CAPACITY_EMPTY,
  CAPACITY_UPDATE_SUCCESS,
  CAPACITY_UPDATE_ERROR,
  CAPACITY_UPDATE_PROCESS,
  CAPACITY_FOCUS,
  CAPACITY_ERROR,
  CAPACITY_CLEAR,
} from "./capacitySOAction";
import { actionChannel } from "redux-saga/effects";

const selectedYear = (state = "", action) => {
  switch (action.type) {
    case CAPACITY_YEAR_SELECT: {
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
    case PERIOD_SELECT:
      return action.selected.toString();

    default:
      return state;
  }
};
const period = (state = [], action) => {
  switch (action.type) {
    case PERIOD_ADD:
      return action.data;
    default:
      return state;
  }
};

const column = (state = [], action) => {
  switch (action.type) {
    case CAPACITY_COLUMN_ADD: {
      return action.data;
    }
    case CAPACITY_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};

const data = (state = [], action) => {
  switch (action.type) {
    case CAPACITY_DATA_FETCH:
    case CAPACITY_DATA_UPDATE:
      return state;

    case CAPACITY_DATA_ADD:
      return action.data;

    case CAPACITY_DATA_CHANGE: {
      const { index, value } = action;
      let { key } = action;
      if (typeof key === "number") {
        key = key.toString();

        const update = state.map((cap, i) => {
          if (cap.id === index) {
            cap[key] = value; // eslint-disable-line
            return cap;
          }
          return cap;
        });
        return update;
      }
      const update2 = state.map((cap, i) => {
        if (cap.id === index) {
          cap[action.key] = value; // eslint-disable-line
          return cap;
        }
        return cap;
      });
      return update2;
    }
    case CAPACITY_DATE_ROW_CHANGE: {
      let k = action.key;
      const v = action.value;

      k = k.toString();
      const rowChange = state.map((cap) => {
        const tk = k.charAt(0).toLowerCase() + k.slice(1);
        cap[tk] = v * 1; // eslint-disable-line
        return cap;
      });
      return rowChange;
    }
    case CAPACITY_EMPTY:
      return [];

    default:
      return state;
  }
};

const calc = (state = [], action) => {
  switch (action.type) {
    case "CAL_DATA_ADD":
      return action.data;
    case "TOTAL_CHANGE":
      const { total, hybTotal, parTotal, ColumnID } = action;
      return state.map((s) => {
        const { Method } = s;
        if (Method.toLowerCase() === "hybrid plates") {
          s[ColumnID] = hybTotal || "";
        }
        if (Method.toLowerCase() === "total plates") {
          s[ColumnID] = total || "";
        }
        if (Method.toLowerCase() === "parentline plates") {
          s[ColumnID] = parTotal || "";
        }
        return s;
      });
      return state;
    case "CAL_DATA_REMOVE":
      return [];
    default:
      return state;
  }
};

const status = (state = "init", action) => {
  switch (action.type) {
    case CAPACITY_DATA_CHANGE:
      return "changed";
    case CAPACITY_DATA_UPDATE:
    case CAPACITY_UPDATE_PROCESS:
      return "processing";
    case CAPACITY_UPDATE_SUCCESS:
      return "success";
    case CAPACITY_UPDATE_ERROR:
      return "error";
    default:
      return state;
  }
};

const initFocus = { ref: "", focus: false };
const focus = (state = initFocus, action) => {
  switch (action.type) {
    case CAPACITY_FOCUS:
      return Object.assign({}, state, { ref: action.ref });
    case CAPACITY_ERROR:
      return Object.assign({}, state, { focus: !state.focus });
    case CAPACITY_CLEAR:
      return initFocus;
    default:
      return state;
  }
};

const errList = (state = [], action) => {
  switch (action.type) {
    case "ERRORLIST_ADD":
      if (state.includes(action.data)) {
        return state;
      }
      return [...state, action.data];
    case "ERRORLIST_REMOVE":
      return state.filter((s) => s !== action.data);
    case "CAPACITY_EMPTY":
      return [];
    default:
      return state;
  }
};

const capacity = combineReducers({
  year: combineReducers({
    selected: selectedYear,
    data: year,
  }),
  period: combineReducers({
    selected: selectedPeriod,
    data: period,
  }),
  column,
  data,
  calc,
  status,
  focus,
  errList,
});
export default capacity;
