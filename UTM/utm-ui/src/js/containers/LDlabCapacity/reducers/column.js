const LAB_COLUMN_ADD = "LD_LAB_COLUMN_ADD";
const LAB_COLUMN_EMPTY = "LD_LAB_COLUMN_EMPTY";

const column = (state = [], action) => {
  switch (action.type) {
    case LAB_COLUMN_ADD: {
      return action.data;
    }
    case LAB_COLUMN_EMPTY: {
      return [];
    }
    default:
      return state;
  }
};
export default column;
