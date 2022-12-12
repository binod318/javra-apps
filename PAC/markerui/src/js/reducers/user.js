const init = {
  role: [],
  name: "",
};
const user = (state = init, action) => {
  switch (action.type) {
    case "RESET_ROLE":
      return init;
    case "SET_ROLES": {
      return Object.assign({}, state, {
        role: action.data.roles,
        name: action.data.name,
      });
    }
    default:
      return state;
  }
};
export default user;
