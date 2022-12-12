const data = (state = [], action) => {
  switch (action.type) {
    case 'LAB_DATA_FETCH':
    case 'LAB_DATA_UPDATE':
      return state;

    case 'LAB_DATA_ADD':
      return action.data;

    case 'LAB_DATA_CHANGE': {
      const { index, value } = action;
      let { key } = action;
      if (typeof key === 'number') {
        key = key.toString();

        const update = state.map((cap, i) => {
          if (i === index) {
            cap[key] = value; // eslint-disable-line
            return cap;
          }
          return cap;
        });
        return update;
      }
      const update2 = state.map((cap, i) => {
        if (i === index) {
          const testKey = key.charAt(0).toLowerCase() + key.slice(1);
          cap[testKey] = value; // eslint-disable-line
          return cap;
        }
        return cap;
      });
      return update2;
    }
    case 'LAB_DATE_ROW_CHANGE': {
      let k = action.key;
      const v = action.value;

      k = k.toString();
      const rowChange = state.map(cap => {
        const tk = k.charAt(0).toLowerCase() + k.slice(1);
        cap[tk] = v * 1; // eslint-disable-line
        return cap;
      });
      return rowChange;
    }
    case 'LAB_DATA_EMPTY':
      return [];

    default:
      return state;
  }
};
export default data;
