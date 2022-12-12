import { combineReducers } from 'redux';

const screening = (state = [], action) => {
  switch (action.type) {
    case 'DETERMINATION_ADD':
      return action.data;
    default:
      return state;
  }
};

const relation = (state = [], action) => {
  switch (action.type) {
    case 'RELATION_ADD':
      return state;
    case 'RELATION_BULK':
      return action.data;
    default:
      return state;
  }
};

const filter = (state = [], action) => {
  switch (action.type) {
    case 'FILTER_TRAIT_ADD': {
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
    case 'FILTER_TRAIT_REMOVE':
      return state.filter(d => d.name !== action.name);
    case 'FILTER_TRAIT_CLEAR':
    case 'RESETALL':
      return [];
    case 'FETCH_TRAIT_FILTER_DATA':
    case 'FETCH_CLEAR_TRAIT_FILTER_DATA':
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
    case 'TRAIT_SORT': {
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

const initTotal = {
  total: 0,
  pageNumber: 1,
  pageSize: 100
};
const total = (state = initTotal, action) => {
  switch (action.type) {
    case 'TRAIT_RECORDS':
      return { ...state, total: action.total };
    case 'TRAIT_PAGE':
      return { ...state, pageNumber: action.pageNumber };
    case 'TRAIT_SIZE':
      return { ...state, pageSize: action.pageSize * 1 };
    default:
      return state;
  }
};

const traitrelaton = combineReducers({
  relation,
  sort,
  filter,
  total,
  screening
});
export default traitrelaton;
