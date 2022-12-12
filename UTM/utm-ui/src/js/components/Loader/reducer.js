const loader = (state = 0, action) => {
  switch (action.type) {
    case 'LOADER_RESET':
      return 0;
    case 'LOADER_SHOW':
      // concon(action, state, '++');
      return state + 1;
    case 'LOADER_HIDE':
      // concon(action, state, '--');
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
