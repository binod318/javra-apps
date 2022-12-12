import { combineReducers } from 'redux';

import {
  FILTER_SH_ADD,
  FILTER_SH_CLEAR,
  SH_REMOVE_FILE,
  SH_BLUK,
  SH_RECORS,
  SH_PAGE,
  SH_SIZE,
  SH_CHANGE,
  FILTER_SH_ADD_BLUK,
  SH_COLUMN_BULK
} from './constant';

const shOverviewData = (state = [], action) => {
  switch (action.type) {
    case SH_BLUK:
      return action.data;
    case SH_REMOVE_FILE: {
      return state.filter(x => x.testID !== action.testID);
    }
    default:
      return state;
  }
};

const columns = (state = [], action) => {
  switch (action.type) {
    case SH_COLUMN_BULK:
      return action.columns;
    default:
      return state;
  }
};

const filter = (state = [], action) => {
  switch (action.type) {
    case FILTER_SH_ADD_BLUK:
      return action.filter;
    case FILTER_SH_ADD: {
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
    case FILTER_SH_CLEAR:
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
    case SH_RECORS:
      return { ...state, total: action.total };
    case SH_PAGE:
      return { ...state, pageNumber: action.pageNumber };
    case SH_SIZE:
      return { ...state, pageSize: action.pageSize * 1 };
    default:
      return state;
  }
};

const active = (state = true, action) => {
  switch (action.type) {
    case SH_CHANGE:
      return action.flag;
    default:
      return state;
  }
};

const shOverview = combineReducers({
  shOverviewData,
  columns,
  filter,
  total,
  active
});
export default shOverview;
