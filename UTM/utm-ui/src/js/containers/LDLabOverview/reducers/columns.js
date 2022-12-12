const LEAF_DISK_LAB_OVERVIEW_COLUMN_ADD = "LEAF_DISK_LAB_OVERVIEW_COLUMN_ADD";
const LEAF_DISK_LAB_OVERVIEW_COLUMN_EMPTY = "LEAF_DISK_LAB_OVERVIEW_COLUMN_EMPTY";

const column = (state = [], action) => {
  switch (action.type) {
    case LEAF_DISK_LAB_OVERVIEW_COLUMN_ADD: {
      return action.columns;
    }
    case LEAF_DISK_LAB_OVERVIEW_COLUMN_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};
export default column;
