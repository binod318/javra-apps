import { combineReducers } from 'redux';

const mail = (state = [], action) => {
  switch (action.type) {
    case 'MAIL_ADD':
      return state;
    case 'MAIL_BULK':
      return action.data;
    default:
      return state;
  }
};

const initTotal = {
  total: 0,
  pageNumber: 1,
  pageSize: 100
};
const total = (state = initTotal, action) => {
  switch (action.type) {
    case 'MAIL_RECORDS':
      return { ...state, total: action.total };
    case 'MAIL_PAGE':
      return { ...state, pageNumber: action.pageNumber };
    case 'MAIL_SIZE':
      return { ...state, pageSize: action.pageSize * 1 };
    default:
      return state;
  }
};

const refresh = (state = false, payload) => {
  switch (payload.type) {
    case 'MAIL_REFRESH':
      return !state;
    default:
      return state;
  }
}

const mailConfig = combineReducers({
  mail,
  refresh,
  total
});
export default mailConfig;