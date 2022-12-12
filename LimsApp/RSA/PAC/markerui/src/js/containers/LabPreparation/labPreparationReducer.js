import { combineReducers } from "redux";
import labDescluster from "./desclusterReducer";

import {
  YEAR_ADD,
  LABPREPARATION_YEAR_SELECT,
  LABPREPARATION_PERIOD_ADD,
  LABPREPARATION_PERIOD_SELECT,
  LABPREPARATION_PERIOD_BLANK,
  LABPREPARATION_GROUP_ADD,
  LABPREPARATION_GROUP_TOGGLE,
  LABPREPARATION_DATA_ADD,
  LABPREPARATION_COLUMN_ADD,
  LABPREPARATION_EMPTY,
  LAB_SET_FILLRATE_TOTALUSED,
  LAB_SET_FILLRATE_TOTALRESERVED
} from "./labPreparationAction";

const selectedYear = (state = "", action) => {
  switch (action.type) {
    case LABPREPARATION_YEAR_SELECT: {
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
    case LABPREPARATION_PERIOD_SELECT: {
      return action.selected.toString();
    }
    case LABPREPARATION_PERIOD_BLANK:
      return "";
    default:
      return state;
  }
};
const period = (state = [], action) => {
  switch (action.type) {
    case LABPREPARATION_PERIOD_ADD: {
      return action.data;
    }
    default:
      return state;
  }
};

const group = (state = [], { type, payload }) => {
  switch (type) {
    case LABPREPARATION_GROUP_ADD:
      return payload;
    case LABPREPARATION_GROUP_TOGGLE:
      return state.map((s) => {
        if (s.id === payload) {
          return { ...s, open: !s.open };
        }
        return s;
      });
    case LABPREPARATION_PERIOD_BLANK:
      return [];
    default:
      return state;
  }
};

const column = (state = [], { type, payload }) => {
  switch (type) {
    case LABPREPARATION_COLUMN_ADD: {
      return payload;
    }
    case LABPREPARATION_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};

const data = (state = [], { type, payload }) => {
  switch (type) {
    case LABPREPARATION_DATA_ADD:
      return payload;
    case LABPREPARATION_PERIOD_BLANK:
      return [];
    default:
      return state;
  }
};

const status = (state = "", action) => {
  switch (action.type) {
    case "LAB_TEST_SET_STATUS":
      return action.StatusCode;

    default:
      return state;
  }
};

const daStatus = (state = "", action) => {
  switch (action.type) {
    case "LAB_TEST_SET_DA_STATUS":
      return action.StatusCode;

    default:
      return state;
  }
};

const totalUsed = (state = "", action) => {
  switch (action.type) {
    case LAB_SET_FILLRATE_TOTALUSED: {
      return action.TotalUsed;
    }
    default:
      return state;
  }
};
const totalReserved = (state = [], action) => {
  switch (action.type) {
    case LAB_SET_FILLRATE_TOTALRESERVED: {
      return action.TotalReserved;
    }
    default:
      return state;
  }
};

const labPreparation = combineReducers({
  year: combineReducers({
    selected: selectedYear,
    data: year,
  }),
  period: combineReducers({
    selected: selectedPeriod,
    data: period,
  }),
  fillrate: combineReducers({
    totalUsed,
    totalReserved
  }),
  status,
  daStatus,
  group,
  column,
  data,
  labDescluster,
});
export default labPreparation;
