import { combineReducers } from "redux";

const FILELIST_ADD_NEW = "FILELIST_ADD_NEW";
const FETCH_FILELIST = "FILELIST_FETCH";
const FILELIST_ALL = "FILELIST_ADD";

const init = {
  testID: "",
  cropCode: null,
  fileID: null,
  testTypeID: "",
  fileTitle: "",
  remark: "",
  remarkRequired: "",
  statusCode: "",
  isolated: false,
  plannedDate: "",
  updateAttributesFailed: false,
  cumulate: false,
  importLevel: "PLT"
};
const selected = (state = init, action) => {
  switch (action.type) {
    case "FILELIST_ADD_NEW":
    case "FILELIST_SELECTED":
      if (action.file) return action.file;
      return state;
    case "FILELIST_SET_REMARK":
      return { ...state, remark: action.remark };
    case "FILELIST_SET_CONFIGNAME":
      return { ...state, sampleConfigName: action.name };
    case "ROOT_STATUS":
      if (state.id === action.testid)
        return { ...state, statusCode: action.statusCode };
      return state;
    case "ROOT_SLOTID":
      if (state.id === action.testid)
        return { ...state, slotID: action.slotID };
      return state;
    case "FILELIST_SELECTED_EMPTY":
    case "RESET_ALL":
      return {};
    case "CHANGE_CUMULATE_STATUS":
      return { ...state, cumulate: action.cumulate };
    case "CHANGE_ISOLATION_STATUS":
      return { ...state, isolated: action.isolationStatus };
    case "CHANGE_PLANNED_DATE":
      return { ...state, plannedDate: action.plannedDate };
    case "CHANGE_EXPECTED_DATE":
      return { ...state, expectedDate: action.expectedDate };
    case "UPDATE_ATTRIBUTES_FAILURE":
      return { ...state, updateAttributesFailed: true };
    case "RESET_UPDATE_ATTRIBUTES_FAILURE":
      return { ...state, updateAttributesFailed: false };
    default:
      return state;
  }
};

const filelist = (state = [], action) => {
  switch (action.type) {
    case FILELIST_ADD_NEW:
      return [
        ...state,
        {
          cropCode: action.cropCode,
          fileID: action.fileID,
          fileTitle: action.fileTitle,
          testID: action.testID,
          importDateTime: action.importDateTime,
          userID: action.userID,
          remark: action.remark,
          plannedDate: action.plannedDate,
          slotID: null
        }
      ];
    case "FILELIST_SET_REMARK":
      return state.map(test => {
        if (test.testID === action.testID) {
          return { ...test, remark: action.remark };
        }
        return test;
      });
    case "ROOT_STATUS":
      return state.map(test => {
        if (test.testID === action.testID) {
          return { ...test, statusCode: action.statusCode };
        }
        return { ...test };
      });
    case "ROOT_SLOTID":
      return state.map(slot => {
        if (slot.testID === action.testID) {
          return { ...slot, slotID: action.slotID };
        }
        return slot;
      });
    case FILELIST_ALL:
      return action.data;
    case "REMOVE_FILE_AFTER_SENDTO_3GB":
      return state.filter(x => x.testID !== action.testID);
    case "REMOVE_FILE_AFTER_DELETE":
      return state.filter(x => x.testID !== action.testID);
    case FETCH_FILELIST:
    default:
      return state;
  }
};

const initFillRate = {
  availPlants: 0,
  capacitySlotName: "",
  cordysStatus: "",
  dH0Location: "",
  filledPlants: 0,
  maxPlants: 0,
  change: false
};
const fillRate = (state = initFillRate, action) => {
  switch (action.type) {
    case "FILLRATE_INSERT": {
      const { change } = state;
      if (action.data === null) return initFillRate;

      return { ...state, ...action.data, change: !change };
    }
    case "FILLRATE_REMOVE":
      return initFillRate;
    default:
      return state;
  }
};
const file = combineReducers({
  filelist,
  selected,
  fillRate
});
export default file;
