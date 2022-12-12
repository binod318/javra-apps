import { combineReducers } from "redux";
import column from "./column";
import data from "./data";
import filter from "./filter";
import total from "./total";
import testsLookup from "./testsLookup";
import plant from "./plant";
import well from "./well";
import punchlist from "./punchlist";

const totMarker = (state = 0, action) => {
  switch (action.type) {
    case "ADD_TOTAL_MARKER":
      return action.total;
    default:
      return state;
  }
};

const reservePlateBtnDisable = (state = false, action) => {
  switch (action.type) {
    case "RPBDisable":
      return true;
    case "FILELIST_SELECTED":
    case "FETCH_WELL":
    case "RPBEnable":
      return false;
    default:
      return state;
  }
};

const initialState = {
  warningFlag: false,
  warningMessage: []
};

const reservePlates = (state = initialState, action) => {
  switch(action.type) {
    case 'RESERVE_PLATES_WARNING': {
      return Object.assign({}, state, {
        warningFlag: true,
        warningMessage: action.warningMessage
      });
    }
    case 'RESERVE_PLATES_WARNING_FALSE':
      return Object.assign({}, state, {
        warningFlag: false,
        warningMessage: []
      });
    default:
      return state;
  }
}

const plateFilling = combineReducers({
  column,
  data,
  filter,
  total,
  testsLookup,
  plant,
  well,
  punchlist,
  totMarker,
  reservePlateBtnDisable,
  reservePlates
});
export default plateFilling;
