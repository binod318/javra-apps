import { combineReducers } from "redux";

import {
  YEAR_ADD,
  LAB_YEAR_SELECT,
  LAB_DATA_FETCH,
  LAB_DATA_ADD,
  LAB_COLUMN_ADD,
  LAB_DATA_CHANGE,
  LAB_DATA_UPDATE,
  LAB_DATE_ROW_CHANGE,
  LAB_EMPTY,
  LAB_UPDATE_SUCCESS,
  LAB_UPDATE_ERROR,
} from "./labAction";

const selected = (state = "", action) => {
  switch (action.type) {
    case LAB_YEAR_SELECT: {
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

const column = (state = [], action) => {
  switch (action.type) {
    case LAB_COLUMN_ADD: {
      return action.data;
    }
    case LAB_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};

const data = (state = [], action) => {
  switch (action.type) {
    case LAB_DATA_FETCH:
    case LAB_DATA_UPDATE:
      return state;

    case LAB_DATA_ADD:
      return action.data;

    case LAB_DATA_CHANGE: {
      const { index, value } = action;
      let { key } = action;
      if (typeof key === "number") {
        key = key.toString();

        const update = state.map((cap, i) => {
          if (i === index) {
            cap[key] = value; // eslint-disable-line
            return cap;
          }
          return cap;
        });
        return update;
      }
      const update2 = state.map((cap, i) => {
        if (i === index) {
          cap[key] = value; // eslint-disable-line
          return cap;
        }
        return cap;
      });
      return update2;
    }
    case LAB_DATE_ROW_CHANGE: {
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
    case LAB_EMPTY:
      return [];

    default:
      return state;
  }
};

const status = (state = "init", action) => {
  switch (action.type) {
    case LAB_DATE_ROW_CHANGE:
    case LAB_DATA_CHANGE:
      return "changed";
    case LAB_DATA_UPDATE:
      return "processing";
    case LAB_UPDATE_SUCCESS:
      return "success";
    case LAB_UPDATE_ERROR:
      return "error";
    default:
      return state;
  }
};

const Lab = combineReducers({
  year: combineReducers({
    selected,
    data: year,
  }),
  column,
  data,
  status,
});
export default Lab;
