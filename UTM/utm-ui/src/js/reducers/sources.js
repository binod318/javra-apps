import { combineReducers } from 'redux';

const defaultSource = 'Phenome';
// 'External';
const selected = (state = defaultSource, action) => {
  switch (action.type) {
    case 'FILELIST_SELECTED':
      if (action.file && action.file.source) return action.file.source;
      return state;
    case 'CHANGE_IMPORTSOURCE':
      return action.source;
    default:
      return state;
  }
};

const list = (state = [], action) => {
  switch (action.type) {
    case 'ADD_SOURCE':
      return action.data;
    default:
      return state;
  }
};

export default combineReducers({
  list,
  selected
});
