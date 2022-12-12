const init = {
  role: [],
  selectedCrop: "",
  crops: []
};
const user = (state = init, action) => {
  switch (action.type) {
    case "FETCH_USER_CROPS_SUCCEEDED": {
      const { crops } = action;
      return { ...state, crops };
    }
    case "RESET_ROLE":
      return init;
    case "ADD_SELECTED_CROP":
      return Object.assign({}, state, {
        selectedCrop: action.crop
      });
    case "SET_ROLES": {
      const { roles } = action;
      return { ...state, role: roles };
    }
    default:
      return state;
  }
};
export default user;
