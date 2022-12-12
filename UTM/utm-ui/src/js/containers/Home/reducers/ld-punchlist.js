const ldPunchList = (state = [], action) => {
  switch (action.type) {
    case "LD_ADD_PUNCHLIST":
      return action.data;
    case "LD_FETCH_PUNCHLIST":
    case "LD_RESETALL":
      return [];
    default:
      return state;
  }
};
export default ldPunchList;
