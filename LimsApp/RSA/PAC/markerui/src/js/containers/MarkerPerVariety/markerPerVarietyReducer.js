import { combineReducers } from 'redux';

import {
  MARKERPERVARIETY_COLUMN_ADD,
  MARKERPERVARIETY_DATA_ADD,
  MARKER_DATA,
  VARIETIES_DATA,
  CROPS_DATA,
  MARKERPERVARIETY_EMPTY,
  MARKERPERVARIETY_TOTAL,
  MARKERPERVARIETY_PAGE,
  MARKERPERVARIETY_PAGESIZE,
  MARKERPERVARIETY_FILTER_ADD
} from './markerPerVarietyAction';

const column = (state=[], action) => {
  switch(action.type) {
    case MARKERPERVARIETY_COLUMN_ADD:
      return action.data;
    case MARKERPERVARIETY_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};

const data = (state=[], action) => {
  switch(action.type) {
    case MARKERPERVARIETY_DATA_ADD: {
      const { data } = action;
      const updatedData = data.map((item) => {
        var localDate = "";

        if(item.ModifiedOn) {

          let utcDate = item.ModifiedOn + " UTC"; //adding 'UTC' at the end makes datetime UTC
          localDate = new Date(utcDate).toLocaleString();

        }
        return {...item, ModifiedOn: localDate};
      });

      return updatedData;
    }
    case MARKERPERVARIETY_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};

const markers = (state=[], action) => {
  switch(action.type) {
    case MARKER_DATA:
      return action.data;
    default:
      return state;
  }
};

const varieties = (state=[], action) => {
  switch(action.type) {
    case VARIETIES_DATA:
      return action.data;
    default:
      return state;
  }
};

const crops = (state=[], action) => {
  switch(action.type) {
    case CROPS_DATA:
      return action.data;
    default:
      return state;
  }
};

const filter = (state = {}, action) => {
  switch (action.type) {
    case MARKERPERVARIETY_FILTER_ADD:
      return action.data;
    case MARKERPERVARIETY_EMPTY: {
      return {};
    }
    default:
      return state;
  }
};

const sorter = (state = {
  sortBy: '',
  sortOrder: ''
}, action) => {
  switch(action.type) {
    case "MARKERPERVARIETY_SORTER":
      return state;
    default:
      return state;
  }
};

const total = (state = 0, action) => {
  switch (action.type) {
    case MARKERPERVARIETY_TOTAL:
      return action.total;
    case MARKERPERVARIETY_EMPTY: {
      return 0;
    }
    default:
      return state;
  }
};

const page = (state = 1, action) => {
  switch (action.type) {
    case MARKERPERVARIETY_PAGE:
      return action.page;
    case MARKERPERVARIETY_EMPTY: {
      return 1;
    }
    default:
      return state;
  }
};

const pageSize = (state = 0, action) => {
  switch (action.type) {
    case MARKERPERVARIETY_PAGESIZE:
      return action.pageSize;
    // case MARKERPERVARIETY_PAGESIZE_DEFAULT: {
    //   return 50;
    // }
    default:
      return state;
  }
};

const markerPerVariety = combineReducers({
  column,
  data,
  markers,
  varieties,
  crops,
  filter,
  sorter,
  total,
  page,
  pageSize
});
export default markerPerVariety;
