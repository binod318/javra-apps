import { combineReducers } from 'redux';

const traits = (state = [], action) => {
  switch (action.type) {
    case 'TRAITS_ADD':
      return action.data;
    case 'TRAITS_GET':
    case 'ATTRIBUTE_SAVE':
    default:
      return state;
  }
};

const traitList = (state = [], action) => {
  switch (action.type) {
    case 'TRAITLIST_ADD':
      return action.data;
    case 'TRAITLIST_GET':
    default:
      return state;
  }
};

const screeningList = (state = [], action) => {
  switch (action.type) {
    case 'SCREENINGLIST_ADD':
      return action.data;
    case 'SCREENINGLIST_GET':
    default:
      return state;
  }
};

const result = (state = [], action) => {
  switch (action.type) {
    case 'RESULT_ADD': {
      const {
        cropCode,
        determinationAlias,
        determinationID,
        determinationName,
        determinationValue,
        traitDeterminationResultID,
        traitID,
        traitName,
        traitValue
      } = action;
      return [
        ...state,
        {
          cropCode,
          determinationAlias,
          determinationID,
          determinationName,
          determinationValue,
          traitDeterminationResultID,
          traitID,
          traitName,
          traitValue
        }
      ];
    }
    case 'RESULT_BULK':
      return action.data;
    default:
      return state;
  }
};

const filter = (state = [], action) => {
  switch (action.type) {
    case 'FILTER_TRAITRESULT_ADD': {
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
    case 'FILTER_TRAITRESULT_REMOVE':
      return state.filter(d => d.name !== action.name);
    case 'FILTER_TRAITRESULT_CLEAR':
    case 'RESETALL':
      return [];
    case 'FETCH_TRAITRESULT_FILTER_DATA':
    case 'FETCH_CLEAR_TRAITRESULT_FILTER_DATA':
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
    case 'RESULT_SORT': {
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
    case 'RESULT_TOTAL':
      return { ...state, total: action.total };
    case 'RESULT_PAGE':
      return { ...state, pageNumber: action.pageNumber };
    case 'RESULT_SIZE':
      return { ...state, pageSize: action.pageSize * 1 };
    default:
      return state;
  }
};

const crops = (state = [], action) => {
  switch (action.type) {
    case 'CROPS_BULK':
      return action.crops;
    case 'FETCH_CROPS':
    default:
      return state;
  }
};

const traitresult = combineReducers({
  traits,
  traitList,
  screeningList,
  result,
  sort,
  filter,
  total,
  crops
});
export default traitresult;
