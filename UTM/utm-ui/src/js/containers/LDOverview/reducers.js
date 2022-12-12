import { combineReducers } from 'redux';

import {
  FILTER_LD_ADD,
  FILTER_LD_CLEAR,
  LD_REMOVE_FILE,
  LD_BLUK,
  LD_RECORS,
  LD_PAGE,
  LD_SIZE,
  LD_CHANGE,
  FILTER_LD_ADD_BLUK,
  LD_COLUMN_BULK
} from './constant';

const ldOverviewData = (state = [], action) => {
  switch (action.type) {
    case LD_BLUK:
      return action.data;
    case LD_REMOVE_FILE: {
      return state.filter(x => x.testID !== action.testID);
    }
    default:
      return state;
  }
};

const columns = (state = [], action) => {
  switch (action.type) {
    case LD_COLUMN_BULK:
      return action.columns;
    default:
      return state;
  }
};

const filter = (state = [], action) => {
  switch (action.type) {
    case FILTER_LD_ADD_BLUK:
      return action.filter;
    case FILTER_LD_ADD: {
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
    case FILTER_LD_CLEAR:
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
    case LD_RECORS:
      return { ...state, total: action.total };
    case LD_PAGE:
      return { ...state, pageNumber: action.pageNumber };
    case LD_SIZE:
      return { ...state, pageSize: action.pageSize * 1 };
    default:
      return state;
  }
};

const active = (state = true, action) => {
  switch (action.type) {
    case LD_CHANGE:
      return action.flag;
    default:
      return state;
  }
};

const ldOverview = combineReducers({
  ldOverviewData,
  columns,
  filter,
  total,
  active
});
export default ldOverview;
