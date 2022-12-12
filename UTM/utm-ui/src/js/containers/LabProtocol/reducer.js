import { combineReducers } from 'redux';

const maintain = (state = [], action) => {
  switch (action.type) {
    case 'MANITAIN_LIST_BULK':
      return action.data;
    default:
      return state;
  }
};

const protocolList = (state = [], action) => {
  switch (action.type) {
    case 'PROTOCOL_BULK':
      return action.data;
    default:
      return state;
  }
};

const filter = (state = [], action) => {
  switch (action.type) {
    case 'FILTER_PROTOCOL_ADD_BLUK':
      return action.filter;
    case 'FILTER_PROTOCOL_ADD': {
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
    case 'FILTER_PROTOCOL_CLEAR':
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
    case 'MAINTAIN_RECORDS':
      return { ...state, total: action.total };
    case 'MAINTAIN_PAGE':
      return { ...state, pageNumber: action.pageNumber };
    case 'MAINTAIN_SIZE':
      return { ...state, pageSize: action.pageSize * 1 };
    default:
      return state;
  }
};

const refresh = (state = false, action) => {
  switch (action.type) {
    case 'MAINTAIN_REFRESH_TOGGLE':
      return !state;
    default:
      return state;
  }
};

const protocol = combineReducers({
  maintain,
  protocolList,
  filter,
  total,
  refresh
});
export default protocol;
