const LAB_LOCATION_FETCH = "LAB_LOCATION_FETCH";
const LAB_LOCATION_ADD = "LAB_LOCATION_ADD";

const location = (state = [], action) => {

  switch (action.type) {
    case LAB_LOCATION_FETCH:
      {
        return state;
      }
    case LAB_LOCATION_ADD:
      {
        return action.data;
      }

    default:
      return state;
  }
};
export default location;
