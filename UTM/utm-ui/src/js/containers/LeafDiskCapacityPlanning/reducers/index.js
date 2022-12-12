import { combineReducers } from "redux";

import error from "./error";
import fields from "./field";
import period from "./period";

const filter = (state = [], action) => {
  switch (action.type) {
    case 'LEAF_DISK_FILTER_BREEDER_ADD_BLUK':
      return action.filter;
    case "FILTER_LEAF_DISK_CAPACITY_PLANNING_ADD": {
      const check = state.find(d => d.name === action.name);
      if (check) {
        return state.map(item => {
          if (item.name === action.name) {
            return { ...item, value: action.value };
          }
          return item;
        });
      }
      return [
        ...state,
        {
          name: action.name,
          value: action.value,
          expression: action.expression,
          operator: action.operator,
          dataType: action.dataType
        }
      ];
    }
    case "LEAF_DISK_CAPACITY_PLANNING_PAGE_RESET":
    case "FILTER_LEAF_DISK_CAPACITY_PLANNING_CLEAR":
    case "RESETALL":
      return [];
    case "FETCH_LEAF_DISK_CAPACITY_PLANNING_FILTER_DATA":
    case "FETCH_CLEAR_LEAF_DISK_CAPACITY_PLANNING_FILTER_DATA":
    default:
      return state;
  }
};

const data = (state = [], action) => {
  switch (action.type) {
    case "LEAF_DISK_CAPACITY_PLANNING": {
      return action.data;
    }
    case "LEAF_DISK_CAPACITY_PLANNING_PAGE_RESET":
      return [];
    case "FETCH_LEAF_DISK_CAPACITY_PLANNING":
    default:
      return state;
  }
};
const init = {
  total: 0,
  pageNumber: 1,
  pageSize: 200
};

const total = (state = init, action) => {
  switch (action.type) {
    case "LEAF_DISK_CAPACITY_PLANNING_TOTAL":
      return { ...state, total: action.total };
    case "LEAF_DISK_CAPACITY_PLANNING_PAGE":
      return { ...state, pageNumber: action.pageNumber };
    case "LEAF_DISK_CAPACITY_PLANNING_SIZE":
      return { ...state, pageSize: action.pageSize * 1 };
    case "LEAF_DISK_CAPACITY_PLANNING_PAGE_RESET":
    case "RESETALL":
      return init;
    default:
      return state;
  }
};

const slot = (state = [], action) => {
  switch (action.type) {
    case "LEAF_DISK_BREEDER_SLOT": {
      return action.data;
    }
    case "LEAF_DISK_BREEDER_SLOT_PAGE_RESET":
      return [];
    case "LEAF_DISK_FETCH_BREEDER_SLOT":
    default:
      return state;
  }
};

const Breeder = combineReducers({
  fields,
  error,
  period,

  filter,
  data,
  total,
  slot
});

export default Breeder;
