const remarks = (state = false, action) => {
  switch (action.type) {
    case 'REMARKS_SHOW':
      return true;
    case 'REMARKS_HIDE':
      return false;
    default:
      return state;
  }
};
export default remarks;
