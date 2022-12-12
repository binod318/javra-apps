const init = {
  exp: 0,
  crops: [],
};
const user = (state = init, action) => {
  switch (action.type) {
    case "RESET_ROLE":
      return init;
    case "FETCH_USER_CROPS_SUCCEEDED": {
      const { crops } = action;
      return { ...state, crops };
    }
    default:
      return state;
  }
};
export default user;
