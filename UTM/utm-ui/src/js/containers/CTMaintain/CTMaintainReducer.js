import { combineReducers } from 'redux';

const process = (state = [], action: Object) => {
  switch (action.type) {
    case 'CT_PROCESS_ADD':
      return action.data;
    default:
      return state;
  }
};

const location = (state = [], action: Object) => {
  switch (action.type) {
    case 'CT_LOCATION_ADD':
      return action.data;
    default:
      return state;
  }
};

const startMaterial = (state = [], action: Object) => {
  switch (action.type) {
    case 'CT_STARTMATERIAL_ADD':
      return action.data;
    default:
      return state;
  }
};

const type = (state = [], action: Object) => {
  switch (action.type) {
    case 'CT_TYPE_ADD':
      return action.data;
    default:
      return state;
  }
};

const ctMaintain = combineReducers({
  process,
  location,
  startMaterial,
  type
});
export default ctMaintain;
