const loader = (state = 0, action) => {
  let source = "";
  if (action.func) source = action.func;
  else source = "undefine";

  switch (action.type) {
    case "LOADER_RESET":
      return 0;
    case "LOADER_SHOW":
      return state + 1;
    case "LOADER_HIDE":
      if (state > 0) {
        return state - 1;
      }
      break;
    default:
      return state;
  }
  return null;
};
export default loader;
