import { combineReducers } from 'redux';

import {
  FILTER_RDT_ADD,
  FILTER_RDT_CLEAR,
  RDT_REMOVE_FILE,
  RDT_BLUK,
  RDT_RECORS,
  RDT_PAGE,
  RDT_SIZE,
  RDT_CHANGE,
  FILTER_RDT_ADD_BLUK
} from './constant';

const rdtOverviewData = (state = [], action) => {
  switch (action.type) {
    case RDT_BLUK:
      return action.data;
    case RDT_REMOVE_FILE:
      return state.filter(x => x.testID !== action.testID);
    default:
      return state;
  }
};

const filter = (state = [], action) => {
  switch (action.type) {
    case FILTER_RDT_ADD_BLUK:
      return action.filter;
    case FILTER_RDT_ADD: {
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
    case FILTER_RDT_CLEAR:
    case 'RESETALL':
      return [];
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
    case RDT_RECORS:
      return { ...state, total: action.total };
    case RDT_PAGE:
      return { ...state, pageNumber: action.pageNumber };
    case RDT_SIZE:
      return { ...state, pageSize: action.pageSize * 1 };
    default:
      return state;
  }
};

const active = (state = true, action) => {
  switch (action.type) {
    case RDT_CHANGE:
      return action.flag;
    default:
      return state;
  }
};

const rdtOverview = combineReducers({
  rdtOverviewData,
  filter,
  total,
  active
});
export default rdtOverview;
