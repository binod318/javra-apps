// @flow
import { combineReducers } from 'redux';
import { TotalType } from './mailType';

const initMail = [];
const data = (state = initMail, action: Object) => {
  switch (action.type) {
    case 'MAIL_ADD': {
      return action.data;
    }
    case 'MAIL_BULK':
      return action.data;
    default:
      return state;
  }
};

const init: TotalType = {
  total: 0,
  pageNumber: 1,
  pageSize: 50,
  refresh: false
};
const total = (state = init, action: Object) => {
  switch (action.type) {
    case 'MAIL_RECORDS':
      return { ...state, total: action.total };
    case 'MAIL_PAGE':
      return { ...state, pageNumber: action.pageNumber };
    case 'MAIL_SIZE':
      return { ...state, pageSize: action.pageSize * 1 };

    case 'MAIL_BULK':
      return { ...state, refresh: !state.refresh };
    default:
      return state;
  }
};

const filter = (state = [], action) => {

  switch (action.type) {
    case 'FILTER_MAIL_ADD_BLUK':
      return action.filter;
    case 'FILTER_MAIL_ADD': {
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
    case 'FILTER_MAIL_CLEAR':
      return [];
    default:
      return state;
  }
};

const mailRecipients = combineReducers({
  data,
  total,
  filter
});
export default mailRecipients;
