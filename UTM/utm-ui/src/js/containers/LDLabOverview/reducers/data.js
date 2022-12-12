const LEAF_DISK_LAB_OVERVIEW_DATA_FETCH = 'LEAF_DISK_LAB_OVERVIEW_DATA_FETCH';
const LEAF_DISK_LAB_OVERVIEW_DATA_ADD = 'LEAF_DISK_LAB_OVERVIEW_DATA_ADD';
const LEAF_DISK_LAB_OVERVIEW_DATA_EMPTY = 'LEAF_DISK_LAB_OVERVIEW_DATA_EMPTY';

const data = (state = [], action) => {
  switch (action.type) {
    case LEAF_DISK_LAB_OVERVIEW_DATA_FETCH:
      return state;

    case LEAF_DISK_LAB_OVERVIEW_DATA_ADD:
      return action.data;

    case LEAF_DISK_LAB_OVERVIEW_DATA_EMPTY:
      return [];

    default:
      return state;
  }
};
export default data;
