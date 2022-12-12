import { combineReducers } from 'redux';
import {
  TOTALPAC_COLUMN_ADD,
  TOTALPAC_EMPTY,
  TOTALPAC_DATA_ADD,
  TOTALPAC_TOTAL,
  TOTALPAC_PAGE,
  TOTALPAC_FILTER_ADD,
  TOTALPAC_SORTER_ADD
} from './TotalPACAction';

const column = (state = [], action) => {
  switch (action.type) {
    case TOTALPAC_COLUMN_ADD: {
      return action.data;
    }
    case TOTALPAC_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};

const data = (state = [], action) => {
  switch (action.type) {
    case TOTALPAC_DATA_ADD:
      return action.data;
    case TOTALPAC_EMPTY: {
      return [];
    }
    default:
      return state;
  }
}

const filter = (state = {}, action) => {
  switch (action.type) {
    case TOTALPAC_FILTER_ADD:
      return action.data;
    case TOTALPAC_EMPTY: {
      return {};
    }
    default:
      return state;
  }
}

const sorter = (state = {
  sortBy: '',
  sortOrder: ''
}, action) => {
  switch(action.type) {
    case TOTALPAC_SORTER_ADD:
      return action.data;
    case TOTALPAC_EMPTY: {
      return {
        sortBy: "",
        sortOrder: "",
      };
    }
    default:
      return state;
  }
}

const total = (state = 0, action) => {
  switch (action.type) {
    case TOTALPAC_TOTAL:
      return action.total;
    case TOTALPAC_EMPTY: {
      return 0;
    }
    default:
      return state;
  }
}

const page = (state = 1, action) => {
  switch (action.type) {
    case TOTALPAC_PAGE:
      return action.page;
    case TOTALPAC_EMPTY: {
      return 1;
    }
    default:
      return state;
  }
}

const totalPAC = combineReducers({
  column,
  data,
  filter,
  sorter,
  total,
  page
});
export default totalPAC;
