import { combineReducers } from 'redux';

const plant = (state = [], action) => {
  switch (action.type) {
    case 'CONVERT_ADD':
      return state;
    case 'CONVERT_BULK':
      return action.data;
    case 'FETCH_CONVERT':
    default:
      return state;
  }
};
const column = (state = [], action) => {
  switch (action.type) {
    case 'CONVERT_COL_BULK_ADD':
      if (action.data === null) return state;
      return action.data;
     
    case 'CONVERT_COL_EMPTY':
      return [];
    case 'CONVERT_COL_DELETION':
      const { columns }  = action;
      const columnLabel = columns.map(x => x.columnLabel);
      return state.filter(x => !columnLabel.includes(x.columnLabel));

    default:
      return state;
  }
};

const filter = (state = [], action) => {
  switch (action.type) {
    case 'FILTER_CONVERT_ADD': {
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
          display: action.display,
          name: action.name,
          value: action.value,
          expression: action.expression,
          operator: action.operator,
          dataType: action.dataType
        }
      ];
    }
    case 'FILTER_CONVERT_REMOVE':
      return state.filter(d => d.name !== action.name);
    case 'FILTER_CONVERT_CLEAR':
    case 'RESETALL':
      return [];
    case 'FETCH_CONVERT_FILTER_DATA':
    case 'FETCH_CLEAR_CONVERT_FILTER_DATA':
    default:
      return state;
  }
};
const initSort = {
  name: '',
  direction: ''
};
const sort = (state = initSort, action) => {
  switch (action.type) {
    case 'CONVERT_SORT': {
      const { name, direction } = action;
      return Object.assign({}, state, {
        name,
        direction
      });
    }
    default:
      return state;
  }
};

const init = {
  total: 0,
  pageNumber: 1,
  pageSize: 100
};
const total = (state = init, action) => {
  switch (action.type) {
    case 'CONVERT_RECORDS':
      return { ...state, total: action.total };
    case 'CONVERT_PAGE':
      return { ...state, pageNumber: action.pageNumber };
    case 'CONVERT_SIZE':
      return { ...state, pageSize: action.pageSize * 1 };
    default:
      return state;
  }
};

const convert = combineReducers({
  plant,
  column,
  filter,
  sort,
  total
});
export default convert;
