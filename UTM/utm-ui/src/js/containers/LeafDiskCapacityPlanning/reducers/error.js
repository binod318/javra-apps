const init = {
  error: "",
  submit: false,
  forced: false,
  update: false,
  forceUpdate: false
};

const Error = (state = init, action) => {
  switch (action.type) {
    case "LEAF_DISK_CAPACITY_PLANNING_ERROR_ADD":
      return Object.assign({}, state, {
        error: action.message
      });

    case "LEAF_DISK_CAPACITY_PLANNING_SUBMIT":
      return Object.assign({}, state, {
        submit: action.submit
      });

    case "LEAF_DISK_CAPACITY_PLANNING_UPDATE":
      return Object.assign({}, state, {
        update: action.update
      });

    case "LEAF_DISK_CAPACITY_PLANNING_UPDATE_FORCED":
      return Object.assign({}, state, {
        forceUpdate: action.forceUpdate
      });

    case "LEAF_DISK_CAPACITY_PLANNING_FORCED":
      return Object.assign({}, state, {
        forced: action.forced
      });

    case "LEAF_DISK_CAPACITY_PLANNING_ERROR_CLEAR":
      return "";

    case "LEAF_DISK_CAPACITY_PLANNING_ERROR_TYPE":
    case "LEAF_DISK_CAPACITY_PLANNING_FETCH":
    default:
      return state;
  }
};
export default Error;
