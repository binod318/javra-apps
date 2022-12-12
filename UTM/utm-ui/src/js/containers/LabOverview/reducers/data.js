const LAB_OVERVIEW_DATA_FETCH = 'LAB_OVERVIEW_DATA_FETCH';
const LAB_OVERVIEW_DATA_ADD = 'LAB_OVERVIEW_DATA_ADD';
const LAB_OVERVIEW_DATA_EMPTY = 'LAB_OVERVIEW_DATA_EMPTY';

const data = (state = [], action) => {
  switch (action.type) {
    case LAB_OVERVIEW_DATA_FETCH:
      return state;

    case LAB_OVERVIEW_DATA_ADD:
      return action.data;

    case LAB_OVERVIEW_DATA_EMPTY:
      return [];

    default:
      return state;
  }
};
export default data;
