import { combineReducers } from 'redux';
import data from './data';

const refresh = (state = false, action) => {
  switch (action.type) {
    case 'LABOVERVIEW_REFRESH':
      return !state;
    default:
      return state;
  }
};

const initLab = {
  error: '',
  submit: false,
  forced: false
};
const error = (state = initLab, action) => {
  switch (action.type) {
    case 'LABOVERVIEW_ERROR':
      return {
        error: action.message,
        submit: action.submit,
        forced: action.forced
      };
    case 'LABOVERVIEW_ERROR_ADD':
      return Object.assign({}, state, { error: action.message });
    case 'LABOVERVIEW_SUBMIT':
      return Object.assign({}, state, { submit: action.flag });
    case 'LABOVERVIEW_FORCED':
      return Object.assign({}, state, { forced: action.forced });
    case 'LABOVERVIEW_ERROR_RESET':
      return initLab;
    default:
      return state;
  }
};

const filter = (state = [], action) => {
  switch (action.type) {
    case 'FILTER_LABOVERVIEW_ADD_BLUK':
      return action.filter;
    case 'FILTER_LABOVERVIEW_ADD': {
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
    case 'FILTER_LABOVERVIEW_CLEAR':
      return [];
    default:
      return state;
  }
};

const LabOverview = combineReducers({
  data,
  refresh,
  error,
  filter
});
export default LabOverview;
