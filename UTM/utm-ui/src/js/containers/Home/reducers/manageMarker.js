// import { object } from "prop-types";
// import { combineReducers } from 'redux';

// Materials / Marker management

const initalState = {
  columns: [],
  tableData: [],
  totalRecords: 0,
  filters: {},
  markerMaterialMap: {},
  score: {},
  donerInfoMap: {},
  leafDiskMaterialMap: {},
  maxSelectInfoMap: {},
  rdtMaterialStatus: {},
  dirty: false,
  refresh: false,
  total: {}
};

const materials = (state = initalState, action = {}) => {
  switch (action.type) {
    case "FETCH_MATERIALS_SUCCEEDED": {
      const { data, total: totalRecords, totalCount } = action.materials;
      const total = {
        total: totalRecords,
        grandTotal: totalCount || totalRecords
      };
      const { markerMaterialMap } = action;
      return {
        ...state,
        columns: data.columns,
        tableData: data.data || data.dataResult,
        totalRecords,
        markerMaterialMap,
        total
      };
    }
    case "ADD_MARKER_FILTER": {
      const filters = { ...state.filters };
      filters[action.filter.name] = action.filter;
      return { ...state, filters };
    }
    case "CLEAR_MARKER_FILTER": {
      return { ...state, filters: {} };
    }
    case "TOGGLE_MATERIAL_MARKER": {
      const markerMaterialMap = { ...state.markerMaterialMap };
      action.markerMaterialList.forEach(marker => {
        markerMaterialMap[marker.key].newState = marker.value;
        markerMaterialMap[marker.key].changed =
          markerMaterialMap[marker.key].newState !==
          markerMaterialMap[marker.key].originalState;
      });
      const dirty = Object.keys(markerMaterialMap).some(
        key => markerMaterialMap[key].changed
      );
      return { ...state, markerMaterialMap, dirty };
    }
    case "TOGGLE_MARKER_OF_ALL_MATERIALS": {
      const markerMaterialMap = { ...state.markerMaterialMap };
      const { marker, checkedStatus } = action;
      state.tableData.forEach(material => {
        const key = `${material.materialID}-${marker}`;
        markerMaterialMap[key] = {
          ...markerMaterialMap[key],
          newState: checkedStatus,
          changed: markerMaterialMap[key].originalState !== checkedStatus
        };
      });
      const dirty = Object.keys(markerMaterialMap).some(
        key => markerMaterialMap[key].changed
      );
      return { ...state, markerMaterialMap, dirty };
    }
    case "MATERIALS_MARKER_SAVE_SUCCEEDED": {
      const markerMaterialMap = { ...state.markerMaterialMap };
      Object.keys(markerMaterialMap).forEach(key => {
        markerMaterialMap[key] = {
          ...markerMaterialMap[key],
          changed: false,
          originalState: markerMaterialMap[key].newState
        };
      });
      return { ...state, markerMaterialMap, dirty: false };
    }
    case "RESET_MARKER_DIRTY": {
      const markerMaterialMap = { ...state.markerMaterialMap };
      Object.keys(markerMaterialMap).forEach(key => {
        markerMaterialMap[key] = {
          ...markerMaterialMap[key],
          changed: false,
          newState: markerMaterialMap[key].originalState
        };
      });
      return { ...state, dirty: false, markerMaterialMap };
    }

    case "TOGGLE_MARKER_OF_ALL_3GB_MATERIALS": {
      const markerMaterialMap = { ...state.markerMaterialMap };
      const { checkedStatus } = action;
      state.tableData.forEach(material => {
        const key = `${material.materialID}-d_selected`;
        markerMaterialMap[key] = {
          ...markerMaterialMap[key],
          newState: checkedStatus ? 1 : 0,
          changed: markerMaterialMap[key].originalState !== checkedStatus
        };
      });
      const dirty = Object.keys(markerMaterialMap).some(
        key => markerMaterialMap[key].changed
      );
      return { ...state, markerMaterialMap, dirty };
    }
    // S2S Score map
    case "ADD_SCOREMAP":
      return {
        ...state,
        score: action.scores,
        donerInfoMap: action.donerInfoMap,
        refresh: action.refresh
      };
    case "ADD_MAXSELECTMAP":
      return {
        ...state,
        maxSelectInfoMap: action.maxSelectInfoMap
      };
    case "UPDATE_SOCREMAP": {
      const { score, refresh } = state;
      const { name, value } = action;
      Object.keys(score).forEach(key => {
        if (key === name) {
          score[key] = {
            ...score[key],
            changed: true,
            newState: value
          };
        }
      });
      return { ...state, score, dirty: true, refresh: !refresh };
    }
    case "UPDATE_SCOREMAP_ALL": {
      const { score, refresh, markerMaterialMap } = state;
      const { name, value } = action;
      const map = name.split("-")[1];

      Object.keys(score).forEach(key => {
        if (key.indexOf(map) >= 0) {
          const vv = key.replace("score_", "d_");
          const checkboxStatus = markerMaterialMap[vv].newState;
          if (checkboxStatus !== null) {
            score[key] = {
              ...score[key],
              changed: true,
              newState: value
            };
          }
        }
      });
      return { ...state, dirty: true, refresh: !refresh };
    }
    case "SUCCESS_SCOREMAP": {
      const { score, refresh } = state;
      Object.keys(score).forEach(key => {
        score[key] = {
          ...score[key],
          changed: false
        };
      });
      return { ...state, score, dirty: false, refresh: !refresh };
    }

    case "DONER_INFO_CHANGE": {
      const { materialID, name, value } = action;
      const { donerInfoMap, refresh } = state;

      Object.keys(donerInfoMap).forEach(key => {
        if (key === `${materialID}-doner`) {
          if (
            name === "remarks" ||
            name === "dH1ReturnDate" ||
            name === "requestedDate"
          ) {
            donerInfoMap[key] = {
              ...donerInfoMap[key],
              [name]: value,
              changed: true
            };
          } else {
            donerInfoMap[key] = {
              ...donerInfoMap[key],
              [name]: value,
              changed: true
            };
          }
        }
      });
      return { ...state, donerInfoMap, dirty: true, refresh: !refresh };
    }
    case "DONER_ALL_CHANGE": {
      const { name, value } = action;
      const { donerInfoMap, refresh } = state;

      Object.keys(donerInfoMap).forEach(key => {
        donerInfoMap[key] = {
          ...donerInfoMap[key],
          [name]: value,
          changed: true
        };
      });
      return { ...state, donerInfoMap, dirty: true, refresh: !refresh };
    }
    case "RDT_DATE_CHANGE": {
      const { name, value } = action;
      const { donerInfoMap, refresh } = state;

      Object.keys(donerInfoMap).forEach(key => {
        if (key === `${name}`) {
          donerInfoMap[key] = {
            ...donerInfoMap[key],
            newState: value,
            changed: true
          };
        }
      });
      return { ...state, donerInfoMap, dirty: true, refresh: !refresh };
    }
    case "UPDATE_RDTDATE_ALL": {
      const { name, colkey, selectedArray, rowIndex } = action;
      const { donerInfoMap, refresh } = state;
      const small = colkey.toLowerCase() || "test";
      const newValue = donerInfoMap[name].newState || "";

      const selectedObj = {};
      Object.keys(donerInfoMap).forEach(k => {
        if (k.includes(small)) {
          selectedObj[k] = {
            ...donerInfoMap[k]
          };
        }
      });
      if (selectedArray.length) {
        Object.keys(selectedObj).forEach((key, ind) => {
          if (key.includes(small)) {
            if (selectedArray.includes(ind)) {
              selectedObj[key] = {
                ...selectedObj[key],
                newState: newValue,
                changed: true
              };
            }
          }
        });
      } else {
        Object.keys(selectedObj).forEach((key, ind) => {
          if (key.includes(small)) {
            if (ind >= rowIndex) {
              selectedObj[key] = {
                ...selectedObj[key],
                newState: newValue,
                changed: true
              };
            }
          }
        });
      }
      return {
        ...state,
        donerInfoMap: { ...donerInfoMap, ...selectedObj },
        dirty: true,
        refresh: !refresh
      };
    }

    case "RDT_MAXSELECT_CHANGE": {
      const { name, value } = action;
      const { maxSelectInfoMap, refresh } = state;

      Object.keys(maxSelectInfoMap).forEach(key => {
        if (key === `${name}`) {
          maxSelectInfoMap[key] = {
            ...maxSelectInfoMap[key],
            newState: value,
            changed: true
          };
        }
      });
      return { ...state, maxSelectInfoMap, dirty: true, refresh: !refresh };
    }
    case "UPDATE_MAXSELECT_ALL": {
      const { name, colkey, selectedArray, rowIndex } = action;
      const { maxSelectInfoMap, refresh } = state;
      const newValue = maxSelectInfoMap[name].newState || "";

      const selectedObj = {};
      Object.keys(maxSelectInfoMap).forEach(k => {
        if (k.includes(colkey)) {
          selectedObj[k] = {
            ...maxSelectInfoMap[k]
          };
        }
      });
      if (selectedArray.length) {
        Object.keys(selectedObj).forEach((key, ind) => {
          if (key.includes(colkey)) {
            if (selectedArray.includes(ind)) {
              selectedObj[key] = {
                ...selectedObj[key],
                newState: newValue,
                changed: true
              };
            }
          }
        });
      } else {
        Object.keys(selectedObj).forEach((key, ind) => {
          if (key.includes(colkey)) {
            if (ind >= rowIndex) {
              selectedObj[key] = {
                ...selectedObj[key],
                newState: newValue,
                changed: true
              };
            }
          }
        });
      }
      return {
        ...state,
        maxSelectInfoMap: { ...maxSelectInfoMap, ...selectedObj },
        dirty: true,
        refresh: !refresh
      };
    }

    //Leafdisk
    case "ADD_LDMATERIAL_MAP":
      return {
        ...state,
        leafDiskMaterialMap: action.leafDiskMaterialMap,
        refresh: action.refresh
      };

    case "LEAF_DISK_NROFPLANT_CHANGE": {
      const { name, value } = action;
      const { leafDiskMaterialMap, refresh } = state;

      Object.keys(leafDiskMaterialMap).forEach(key => {
        if (key === `${name}`) {
          leafDiskMaterialMap[key] = {
            ...leafDiskMaterialMap[key],
            newState: value,
            changed: true
          };
        }
      });
      return { ...state, leafDiskMaterialMap, dirty: true, refresh: !refresh };
    }

    case "UPDATE_NROFPLANT_ALL": {
      const { name, colkey, selectedArray, rowIndex } = action;
      const { leafDiskMaterialMap, refresh } = state;
      const newValue = leafDiskMaterialMap[name].newState || "";

      const selectedObj = {};
      Object.keys(leafDiskMaterialMap).forEach(k => {
        if (k.includes(colkey)) {
          selectedObj[k] = {
            ...leafDiskMaterialMap[k]
          };
        }
      });
      if (selectedArray.length > 1) {
        Object.keys(selectedObj).forEach((key, ind) => {
          if (key.includes(colkey)) {
            if (selectedArray.includes(ind)) {
              selectedObj[key] = {
                ...selectedObj[key],
                newState: newValue,
                changed: true
              };
            }
          }
        });
      } else {
        Object.keys(selectedObj).forEach((key, ind) => {
          if (key.includes(colkey)) {
            if (ind >= rowIndex) {
              selectedObj[key] = {
                ...selectedObj[key],
                newState: newValue,
                changed: true
              };
            }
          }
        });
      }
      return {
        ...state,
        leafDiskMaterialMap: { ...leafDiskMaterialMap, ...selectedObj },
        dirty: true,
        refresh: !refresh
      };
    }

    case "SAVE_TEST_MATERIAL_SUCCEEDED": {
      const leafDiskMaterialMap = { ...state.leafDiskMaterialMap };
      Object.keys(leafDiskMaterialMap).forEach(key => {
        leafDiskMaterialMap[key] = {
          ...leafDiskMaterialMap[key],
          changed: false,
          originalState: leafDiskMaterialMap[key].newState
        };
      });
      return { ...state, leafDiskMaterialMap, dirty: false };
    }

    case "RDT_MATERIAL_STATUS_ADD": {
      const { RDTMaterialStatus } = action;

      return {
        ...state,
        rdtMaterialStatus: RDTMaterialStatus
      };
    }
    case "MATERIAL_ALL_CHANGE": {
      const { value, selectedArray, rowIndex } = action;
      const { rdtMaterialStatus, refresh } = state;

      if (selectedArray.length) {
        Object.keys(rdtMaterialStatus).forEach((key, ind) => {
          if (selectedArray.includes(ind)) {
            rdtMaterialStatus[key] = {
              ...rdtMaterialStatus[key],
              newState: value,
              changed: true
            };
          }
        });
      } else {
        Object.keys(rdtMaterialStatus).forEach((key, ind) => {
          if (ind >= rowIndex) {
            rdtMaterialStatus[key] = {
              ...rdtMaterialStatus[key],
              newState: value,
              changed: true
            };
          }
        });
      }
      return { ...state, rdtMaterialStatus, dirty: true, refresh: !refresh };
    }
    case "MATERIAL_CHANGE": {
      const { name, value } = action;
      const { rdtMaterialStatus, refresh } = state;

      Object.keys(rdtMaterialStatus).forEach(key => {
        if (key === `${name}`) {
          rdtMaterialStatus[key] = {
            ...rdtMaterialStatus[key],
            newState: value,
            changed: true
          };
        }
      });
      return { ...state, rdtMaterialStatus, dirty: true, refresh: !refresh };
    }
    case "RESET_SCORE":
      return initalState;
    default:
      return state;
  }
};

const initSampleNumber = {
  samples: [],
  dirty: false,
  refresh: false
};
export const numberOfSamples = (state = initSampleNumber, action = {}) => {
  switch (action.type) {
    case "SAMPLE_NUMBER": {
      return { ...state, samples: action.samples };
    }
    case "SAMPLE_NUMBER_CHANGE": {
      const { samples } = state;
      const newSample = samples.map(row => {
        if (row.materialID === action.materialID) {
          return {
            ...row,
            nrOfSample: action.nrOfSample * 1,
            changed: true
          };
        }
        return row;
      });
      return {
        ...state,
        samples: newSample,
        dirty: true,
        refresh: !state.refresh
      };
    }
    case "SAMPLE_NUMBER_CHANGE_FALSE": {
      const { samples } = state;
      const newSample = samples.map(row => ({ ...row, changed: false }));
      return {
        ...state,
        samples: newSample,
        dirty: false,
        refresh: !state.refresh
      };
    }
    case "SAMPLE_NUMBER_REST":
      return initSampleNumber;
    default:
      return state;
  }
};

export const RDTFilter = (state = [], action) => {
  switch (action.type) {
    case "RDT_FILTER_ADD": {
      const check = state.find(d => d.name === action.name);
      if (check) {
        return state.map(filter => {
          if (filter.name === action.name) {
            return { ...filter, value: action.value };
          }
          return filter;
        });
      }
      return [
        ...state,
        {
          name: action.name,
          value: action.value,
          expression: action.expression,
          operator: action.operator,
          dataType: action.dataType
        }
      ];
    }
    case "RDT_FILTER_CLEAR":
    case "FILELIST_SELECTED":
    case "FETCH_CLEAR_FILTER_DATA":
    case "RESETALL":
      return [];
    default:
      return state;
  }
};

export const leafDiskFilters = (state = {}, action) => {
  switch (action.type) {
    case "ADD_LEAF_DISK_FILTER": {
      const { payload } = action;
      return { ...state, [payload.key]: payload.value };
    }
    case "CLEAR_LD_FILTERS":
    case "CLEAR_LEAF_DISK_FILTERS": {
      return {};
    }

    default:
      return state;
  }
};

export const seedHealthFilters = (state = {}, action) => {
  switch (action.type) {
    case "ADD_SEED_HEALTH_FILTER": {
      const { payload } = action;
      return { ...state, [payload.key]: payload.value };
    }
    case "CLEAR_SH_FILTERS":
    case "CLEAR_SEED_HEALTH_FILTERS": {
      return {};
    }

    default:
      return state;
  }
};

export default materials;
