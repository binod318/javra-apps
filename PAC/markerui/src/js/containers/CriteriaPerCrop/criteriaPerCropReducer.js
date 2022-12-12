import { combineReducers } from 'redux';

import {
  CRITERIA_PER_CROP_COLUMN_ADD,
  CRITERIA_PER_CROP_DATA_ADD,
  CRITERIA_PER_CROP_CROPS_ADD,
  CRITERIA_PER_CROP_MATERIALTYPES_ADD,
  CRITERIA_PER_CROP_EMPTY,
  CRITERIA_PER_CROP_TOTAL,
  CRITERIA_PER_CROP_PAGE,
  CRITERIA_PER_CROP_PAGESIZE,
  CRITERIA_PER_CROP_FILTER_ADD
} from './criteriaPerCropAction';

const columns = (state=[], action) => {
  switch(action.type) {
    case CRITERIA_PER_CROP_COLUMN_ADD:
      return action.data;
    case CRITERIA_PER_CROP_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};

const data = (state=[], action) => {
  switch(action.type) {
    case CRITERIA_PER_CROP_DATA_ADD:
      return action.data;
    case CRITERIA_PER_CROP_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};

const crops = (state=[], action) => {
  switch(action.type) {
    case CRITERIA_PER_CROP_CROPS_ADD:
      return action.data;
    case CRITERIA_PER_CROP_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};

const materialTypes = (state=[], action) => {
  switch(action.type) {
    case CRITERIA_PER_CROP_MATERIALTYPES_ADD:
      return action.data;
    case CRITERIA_PER_CROP_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};


const filter = (state = {}, action) => {
  switch (action.type) {
    case CRITERIA_PER_CROP_FILTER_ADD:
      return action.data;
    case CRITERIA_PER_CROP_EMPTY: {
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
    case "CRITERIA_PER_CROP_SORTER":
      return state;
    default:
      return state;
  }
};

const total = (state = 0, action) => {
  switch (action.type) {
    case CRITERIA_PER_CROP_TOTAL:
      return action.total;
    case CRITERIA_PER_CROP_EMPTY: {
      return 0;
    }
    default:
      return state;
  }
};

const page = (state = 1, action) => {
  switch (action.type) {
    case CRITERIA_PER_CROP_PAGE:
      return action.page;
    case CRITERIA_PER_CROP_EMPTY: {
      return 1;
    }
    default:
      return state;
  }
};

const pageSize = (state = 0, action) => {
  switch (action.type) {
    case CRITERIA_PER_CROP_PAGESIZE:
      return action.pageSize;
    // case CRITERIA_PER_CROP_PAGESIZE_DEFAULT: {
    //   return 50;
    // }
    default:
      return state;
  }
};

const criteriaPerCrop = combineReducers({
  columns, 
  data,
  crops,
  materialTypes,
  filter,
  sorter,
  total,
  page,
  pageSize
});
export default criteriaPerCrop;
