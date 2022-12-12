import { combineReducers } from "redux";
import file from "./filelistReducer";
import column from "./column";
import data from "./data";
import filter from "./filter";
import total from "./total";
import testType from "../compoments/TestType/testTypeReducer";
import marker from "../compoments/Marker/markerReducer";
import materials, {
  numberOfSamples,
  RDTFilter,
  leafDiskFilters,
  seedHealthFilters
} from "./manageMarker";
import threegb from "./threegb";
import ldPunchList from "./ld-punchlist";

const s2sCapacitySlot = (state = [], action) => {
  switch (action.type) {
    case "STORE_S2S_CAPACITY":
      return action.data;
    default:
      return state;
  }
};

const project = (state = [], action) => {
  switch (action.type) {
    case "BULK_S2S_PROJECT_LIST":
      return action.data;
    default:
      return state;
  }
};

const slotList = (state = [], action) => {
  switch (action.type) {
    case "BULK_SLOT_LIST":
      return action.data;
    default:
      return state;
  }
};

const materialStateRDT = (state = [], action) => {
  switch (action.type) {
    case "DATA_RDT_STATUS_ADD":
      return action.data;
    default:
      return state;
  }
};

const getSites = (state = [], action) => {
  switch (action.type) {
    case "DATA_GETSITES_ADD":
      return action.data;
    default:
      return state;
  }
};

const rdtPrint = (state = false, action) => {
  switch (action.type) {
    case "RDT_PRINT_SHOW":
      return true;
    case "RDT_PRINT_HIDE":
      return false;
    default:
      return state;
  }
};

const rdtPrintData = (state = {}, action) => {
  switch (action.type) {
    case "RDT_PRINT_DATA":
      return action.data;
    case "RDT_PRINT_HIDE":
    case "RDT_PRINT_CLEAR":
      return {};
    default:
      return state;
  }
};

const samples = (
  state = {
    samples: [],
    sampleSaved: false,
    tableData: [],
    columns: [],
    pageInfo: {
      total: 0,
      pageNumber: 1,
      pageSize: 2,
      grandTotal: 0
    }
  },
  action
) => {
  switch (action.type) {
    case "FETCH_LEAF_DISK_SAMPLE_DATA_SUCCEEDED": {
      const tableData = action.data.dataResult.data.map(item => ({
        ...item,
        originals: { ...item },
        determinationsChanged: []
      }));
      const { pageInfo } = action;
      const { columns } = action.data.dataResult;
      const { total: totalRecord, totalCount: grandTotal } = action.data;
      return {
        ...state,
        tableData,
        columns,
        pageInfo: {
          ...state.pageInfo,
          ...pageInfo,
          total: totalRecord,
          grandTotal
        }
      };
    }
    case "FETCH_SAMPLES_SUCCEEDED":
      return { ...state, samples: action.data };
    case "DELETE_LD_SAMPLE_SUCCEEDED":
    case "SAVE_SAMPLE_SUCCEEDED":
    case "RELOAD_LD_SAMPLE_DATA":
      return { ...state, sampleSaved: true };
    case "RESET_SAVE_SAMPLE_SUCCEEDED_FLAG":
      return { ...state, sampleSaved: false };

    //Seed Health
    case "FETCH_SEED_HEALTH_SAMPLE_DATA_SUCCEEDED": {
      const tableData = action.data.dataResult.data.map(item => ({
        ...item,
        originals: { ...item },
        determinationsChanged: []
      }));
      const { pageInfo } = action;
      const { columns } = action.data.dataResult;
      const { total: totalRecord, totalCount: grandTotal } = action.data;
      return {
        ...state,
        tableData,
        columns,
        pageInfo: {
          ...state.pageInfo,
          ...pageInfo,
          total: totalRecord,
          grandTotal
        }
      };
    }
    case "DELETE_SEED_HEALTH_SAMPLE_SUCCEEDED":
    case "SAVE_SEED_HEALTH_SAMPLE_SUCCEEDED":
    case "RELOAD_SEED_HEALTH_SAMPLE_DATA":
      return { ...state, sampleSaved: true };

    default:
      return state;
  }
};

const determinations = (
  state = {
    determinations: [],
    tableData: [],
    columns: [],
    isColumnMarkerDirty: false,
    pageInfo: {
      total: 0,
      pageNumber: 1,
      pageSize: 200,
      grandTotal: 0
    },
    determinationChangedSaved: false,
    assignLDDetermationSucceeded: false,
    assignSHDetermationSucceeded: false,
    filterCleared: false,
    tableDataUpdated: false
  },
  action
) => {
  switch (action.type) {
    case "FETCH_MATERIAL_DETERMINATIONS_SUCCEEDED": {
      const tableData = action.data.dataResult.data.map(item => ({
        ...item,
        originals: { ...item },
        determinationsChanged: []
      }));
      const { pageInfo } = action;
      const { columns } = action.data.dataResult;
      const { total: totalRecord, totalCount: grandTotal } = action.data;
      return {
        ...state,
        tableData,
        columns,
        pageInfo: {
          ...state.pageInfo,
          ...pageInfo,
          total: totalRecord,
          grandTotal
        }
      };
    }
    case "FETCH_LEAF_DISK_DETERMINATIONS_SUCCEEDED": {
      return {
        ...state,
        determinations: action.data.map(item => ({ ...item, selected: false }))
      };
    }
    case "TOGGLE_DETERMINATION": {
      const updatedDeterminations = state.determinations.map(item => {
        if (item.determinationID === action.determinationID) {
          return { ...item, selected: !item.selected };
        }
        return item;
      });
      return { ...state, determinations: updatedDeterminations };
    }

    case "ASSIGN_LD_DETERMINATIONS_SUCCEEDED": {
      const tableData = action.data.dataResult.data.map(item => ({
        ...item,
        originals: { ...item },
        determinationsChanged: []
      }));
      const { columns } = action.data.dataResult;
      const { total: grandTotal } = action.data;
      // reset selected state of all determinations
      const updatedDeterminations = state.determinations.map(item => ({
        ...item,
        selected: false
      }));
      return {
        ...state,
        tableData,
        columns,
        pageInfo: { ...state.pageInfo, total: tableData.length, grandTotal },
        determinations: updatedDeterminations
      };
    }
    case "SET_ASSIGN_LD_DETERMINATION_SUCCEEDED_FLAG": {
      return { ...state, assignLDDetermationSucceeded: true };
    }
    case "RESET_ASSIGN_LD_DETERMINATION_SUCCEEDED_FLAG": {
      return { ...state, assignLDDetermationSucceeded: false };
    }
    case "TOGGLE_ALL_LD_MARKERS": {
      const { marker: col, checkedStatus } = action;

      const tableData = state.tableData.map(item => {
        let { determinationsChanged } = item;
        // if new status is same as original
        if (!!item.originals[col] === checkedStatus) {
          // if the column is already added in the changed array
          // with previous toggle operation then remove it
          if (determinationsChanged.indexOf(col) > -1)
            determinationsChanged = item.determinationsChanged.filter(
              columnID => columnID !== col
            );
        } else if (determinationsChanged.indexOf(col) === -1) {
          // if new status is changed and it's not already there then add it to changed array
          determinationsChanged.push(col);
        }
        return {
          ...item,
          [col]: checkedStatus ? 1 : 0,
          determinationsChanged
        };
      });
      return { ...state, tableData, isColumnMarkerDirty: true };
    }
    case "TOGGLE_DETERMINATION_OF_SAMPLE": {
      const { rowIndex, columnKey, checkedStatus } = action;
      const tableData = state.tableData.map((item, index) => {
        if (index === rowIndex) {
          // add changed property for change detection
          let { determinationsChanged } = item;
          // check if changed
          if (checkedStatus !== !!item.originals[columnKey]) {
            determinationsChanged.push(columnKey);
          } else {
            determinationsChanged = item.determinationsChanged.filter(
              col => col !== columnKey
            );
          }
          return {
            ...item,
            [columnKey]: checkedStatus ? 1 : 0,
            determinationsChanged
          };
        }
        return { ...item };
      });

      return { ...state, tableData };
    }
    case "SAVE_LD_DETERMINATIONS_CHANGED_SUCCEEDED": {
      const tableData = action.data.dataResult.data.map(item => ({
        ...item,
        originals: { ...item },
        determinationsChanged: []
      }));
      const { columns } = action.data.dataResult;
      const { total: grandTotal } = action.data;
      return {
        ...state,
        tableData,
        columns,
        pageInfo: { ...state.pageInfo, total: tableData.length, grandTotal }
      };
    }
    case "RELOAD_LD_MANAGE_DETERMINATION": {
      return { ...state, filterCleared: true };
    }
    case "RESET_FILTER_CLEARED_FLAG": {
      return { ...state, filterCleared: false };
    }
    case "SET_DETERMINATION_CHANGED_SAVED_FLAG": {
      return { ...state, determinationChangedSaved: true };
    }
    case "RESET_DETERMINATION_CHANGED_SAVED_FLAG": {
      return { ...state, determinationChangedSaved: false };
    }
    case "HANDLE_DYNAMIC_INPUT_CHANGE": {
      const { rowIndex, columnKey, value } = action;
      const tableData = state.tableData.map((item, index) => {
        if (index === rowIndex) {
          // add changed property for change detection
          let { determinationsChanged } = item;
          // check if changed
          if (value !== item.originals[columnKey]) {
            // if the change for the field is not already seen, then register its column for change.
            if (determinationsChanged.indexOf(columnKey) === -1)
              determinationsChanged.push(columnKey);
          } else {
            determinationsChanged = item.determinationsChanged.filter(
              col => col !== columnKey
            );
          }
          return {
            ...item,
            [columnKey]: value,
            determinationsChanged
          };
        }
        return { ...item };
      });

      return { ...state, tableData, isColumnMarkerDirty: true };
    }

    //Seed Health
    case "FETCH_SEED_HEALTH_MATERIAL_DETERMINATIONS_SUCCEEDED": {
      const tableData = action.data.dataResult.data.map(item => ({
        ...item,
        originals: { ...item },
        determinationsChanged: []
      }));
      const { pageInfo } = action;
      const { columns } = action.data.dataResult;
      const { total: totalRecord, totalCount: grandTotal } = action.data;
      return {
        ...state,
        tableData,
        columns,
        pageInfo: {
          ...state.pageInfo,
          ...pageInfo,
          total: totalRecord,
          grandTotal
        }
      };
    }
    case "FETCH_SEED_HEALTH_DETERMINATIONS_SUCCEEDED": {
      return {
        ...state,
        determinations: action.data.map(item => ({ ...item, selected: false }))
      };
    }

    case "ASSIGN_SEED_HEALTH_DETERMINATIONS_SUCCEEDED": {
      const tableData = action.data.dataResult.data.map(item => ({
        ...item,
        originals: { ...item },
        determinationsChanged: []
      }));
      const { columns } = action.data.dataResult;
      const { total: grandTotal } = action.data;
      // reset selected state of all determinations
      const updatedDeterminations = state.determinations.map(item => ({
        ...item,
        selected: false
      }));
      return {
        ...state,
        tableData,
        columns,
        pageInfo: { ...state.pageInfo, total: tableData.length, grandTotal },
        determinations: updatedDeterminations
      };
    }
    case "SET_ASSIGN_SEED_HEALTH_DETERMINATION_SUCCEEDED_FLAG": {
      return { ...state, assignSHDetermationSucceeded: true };
    }
    case "RESET_ASSIGN_SEED_HEALTH_DETERMINATION_SUCCEEDED_FLAG": {
      return { ...state, assignSHDetermationSucceeded: false };
    }
    case "TOGGLE_ALL_SEED_HEALTH_MARKERS": {
      const { marker: col, checkedStatus } = action;

      const tableData = state.tableData.map(item => {
        let { determinationsChanged } = item;
        // if new status is same as original
        if (!!item.originals[col] === checkedStatus) {
          // if the column is already added in the changed array
          // with previous toggle operation then remove it
          if (determinationsChanged.indexOf(col) > -1)
            determinationsChanged = item.determinationsChanged.filter(
              columnID => columnID !== col
            );
        } else if (determinationsChanged.indexOf(col) === -1) {
          // if new status is changed and it's not already there then add it to changed array
          determinationsChanged.push(col);
        }
        return {
          ...item,
          [col]: checkedStatus ? 1 : 0,
          determinationsChanged
        };
      });
      return { ...state, tableData, isColumnMarkerDirty: true };
    }
    case "SAVE_SEED_HEALTH_DETERMINATIONS_CHANGED_SUCCEEDED": {
      const tableData = action.data.dataResult.data.map(item => ({
        ...item,
        originals: { ...item },
        determinationsChanged: []
      }));
      const { columns } = action.data.dataResult;
      const { total: grandTotal } = action.data;
      return {
        ...state,
        tableData,
        columns,
        pageInfo: { ...state.pageInfo, total: tableData.length, grandTotal }
      };
    }
    case "RELOAD_SEED_HEALTH_MANAGE_DETERMINATION": {
      return { ...state, filterCleared: true };
    }
    case "RESET_ISCOLUMN_MARKER_DIRTY": {
      return { ...state, isColumnMarkerDirty: false };
    }

    //Quantity
    case "APPLY_TO_ALL_BELOW": {

      const { rowIndex, columnKey, value } = action;
      const tableData = state.tableData.map((item, index) => {
        if (index >= rowIndex) {
          // add changed property for change detection
          let { determinationsChanged } = item;
          // check if changed
          if (value !== item.originals[columnKey]) {
            // if the change for the field is not already seen, then register its column for change.
            if (determinationsChanged.indexOf(columnKey) === -1)
              determinationsChanged.push(columnKey);
          } else {
            determinationsChanged = item.determinationsChanged.filter(
              col => col !== columnKey
            );
          }
          return {
            ...item,
            [columnKey]: value,
            determinationsChanged
          };
        }

        return { ...item };
      });

      return { ...state, tableData, isColumnMarkerDirty: true };
    }

    default:
      return state;
  }
};

const configurationList = (state = [], action) => {
  switch (action.type) {
    case "DATA_GETCONFIGURATION_ADD":
      return action.data;
    default:
      return state;
  }
};

// const leafDisk = combineReducers({ samples, determinations })
const assignMarker = combineReducers({
  file,
  column,
  data,
  filter,
  total,
  testType,
  marker,
  materials,
  threegb,
  numberOfSamples,
  // scoreMap,
  s2sCapacitySlot,
  project,
  slotList,
  materialStateRDT,
  RDTFilter,
  rdtPrint,
  rdtPrintData,
  getSites,
  leafDiskFilters,
  seedHealthFilters,
  samples,
  determinations,
  configurationList,
  ldPunchList
});
// threeGBmark

export default assignMarker;
