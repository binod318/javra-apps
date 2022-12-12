const testProtocol = (state = [], action) => {
  switch (action.type) {
    case 'STORE_TEST_PROTOCOL':
      return action.data.map(d => ({ ...d, selected: false }));
    case 'SELECT_TEST_PROTOCOL':
      return state.map(d => {
        if (d.testProtocolID === action.id) {
          return { ...d, selected: true };
        }
        return { ...d, selected: false };
      });
    case 'FETCH_TEST_PROTOCOL':
    default:
      return state;
  }
};
export default testProtocol;
