import { combineReducers } from "redux";

const files = (state = "", action) => {
  switch (action.type) {
    case "FILE_SELECT":
      return action.cropSelected;
    case "FETCH_USER_CROPS_SUCCEEDED": {
      return action.crops[0];
    }
    default:
      return state;
  }
};

const filterWithout = (state = false, action) => {
  switch (action.type) {
    case "TOGGLE_WITHOUT":
      return !state;
    case "FILTER_WITHOUT_FALSE":
      return false;
    default:
      return state;
  }
};

const fileStatus = (state = 100, action) => {
  switch (action.type) {
    case "FILE_STATUS":
      return action.status;
    default:
      return state;
  }
};

const plant = (state = [], action) => {
  switch (action.type) {
    case "MAIN_ADD":
      return state;
    case "MAIN_BULK":
      return action.data;
    case "MAIN_CROP_UPDATE": {
      let productsegment = [];
      const { gid, columnKey, value } = action;
      if (columnKey.toLocaleLowerCase() === "prod.segment") {
        productsegment = [...action.productsegment];
      }
      return state.map(s => {
        let newValue = value;
        if (gid.includes(s.gid) && s.statusCode === 100) {
          if (columnKey.toLocaleLowerCase() === "prod.segment") {
            if (s.newCrop) {
              const ps = productsegment.filter(
                p => p.newCropCode === s.newCrop && p.prodSegCode === value
              );
              if (ps.length === 0 || ps === null) {
                if (s[columnKey].length === 0) {
                  newValue = "";
                } else {
                  newValue = s[columnKey];
                }
              }
            } else {
              newValue = "";
            }
          }
          Object.assign(s, {
            [columnKey]: newValue,
            change: true
          });

          if (columnKey.toLocaleLowerCase() === "newcrop") {
            Object.assign(s, {
              "prod.Segment": ""
            });
          }
        }
        return s;
      });
    }
    /**
     * TODO :: need to check if status / color of row change after
     * send to varmas
     */
    case "MAIN_ENUMBER_UPDATE": {
      const { result } = action;
      const processedVariety = result.map(r => r.varietyID);
      const newPlants = [];
      state.map(row => {
        if (!processedVariety.includes(row.varietyID)) {
          newPlants.push(row);
        }
        return null;
      });
      return newPlants;
    }
    case "MAIN_TEST_REMOVE_FIRST":
      return state.slice(1, state.length);
    case "UNDO_REPLACE_LOT_SUCCEEDED": {
      const { gid } = action;
      const plants = state.map(item => {
        if (item.gid === gid) {
          return { ...item, replacedLot: false };
        }
        return item;
      });
      return plants;
    }
    case "FETCH_MAIN":
    default:
      return state;
  }
};
const column = (state = [], action) => {
  switch (action.type) {
    case "COLUMN_BULK_ADD": {
      const { data } = action;

      return data.map(d => {
        const label = d.columnLabel;
        return Object.assign(d, {
          columnLabel: label
        });
      });
    }
    case "COLUMN_EMPTY":
    case "RESET_ASSIGN":
    case "RESETALL":
      return [];
    default:
      return state;
  }
};

const filter = (state = [], action) => {
  switch (action.type) {
    case "FILTER_MAIN_ADD": {
      const check = state.find(d => d.name === action.name);
      if (check) {
        return state.map(item => {
          if (item.name === action.name) {
            return { ...item, value: action.value };
          }
          return item;
        });
      }
      return [
        ...state,
        {
          display: action.display,
          name: action.name,
          value: action.value,
          expression: action.expression,
          operator: action.operator,
          dataType: action.dataType
        }
      ];
    }
    case "FILTER_MAIN_REMOVE":
      return state.filter(d => d.name !== action.name);
    case "FILTER_MAIN_CLEAR":
    case "RESETALL":
      return [];
    case "FETCH_MAIN_FILTER_DATA":
    case "FETCH_CLEAR_MAIN_FILTER_DATA":
    default:
      return state;
  }
};
const initSort = {
  name: "",
  direction: ""
};
const sort = (state = initSort, action) => {
  switch (action.type) {
    case "MAIN_SORT": {
      const { name, direction } = action;
      return Object.assign({}, state, {
        name,
        direction
      });
    }
    default:
      return state;
  }
};

const selectedMap = (state = [], action) => {
  switch (action.type) {
    case "SELECT_ALL": {
      const { data, selected } = action;
      if (data.length === selected.length) {
        return [];
      }
      return data.map(d => d.varietyID);
    }
    case "SELECT_ADD": {
      const { index, shift, ctrl, ctrlIndex } = action;
      const match = state.includes(index);

      if (match) {
        if (ctrl) {
          return state.filter(i => i !== index);
        }
        return [];
      }

      if (shift) {
        const newState = state.slice();
        newState.push(index);
        newState.sort((a, b) => a - b);
        const preArray = [];
        if (ctrlIndex === null) {
          for (
            let i = newState[0];
            i <= newState[newState.length - 1];
            i += 1
          ) {
            preArray.push(i);
          }
        } else {
          const sm = index > ctrlIndex ? ctrlIndex : index;
          const gm = index < ctrlIndex ? ctrlIndex : index;
          for (let j = sm; j <= gm; j += 1) {
            preArray.push(j);
          }
        }
        return preArray;
      } else if (ctrl) {
        return [...state, index];
      }
      return [index];
    }
    case "SELECT_POP_LAST":
      return state.slice(0, state.length - 1) || [];
    case "SELECT_BLANK":
      return [];
    default:
      return state;
  }
};

const init = {
  total: 0,
  pageNumber: 1,
  pageSize: 100
};
const total = (state = init, action) => {
  switch (action.type) {
    case "MAIN_RECORDS":
      return { ...state, total: action.total };
    case "MAIN_PAGE":
      return { ...state, pageNumber: action.pageNumber };
    case "MAIN_SIZE":
      return { ...state, pageSize: action.pageSize * 1 };
    default:
      return state;
  }
};

const newcrop = (state = [], action) => {
  switch (action.type) {
    case "NEW_CROP_BULK":
      return action.data;
    case "FETCH_NEW_CROP":
    default:
      return state;
  }
};

const productsegment = (state = [], action) => {
  switch (action.type) {
    case "PRODUCT_SEGMENT_BULK":
      return action.data;
    default:
      return state;
  }
};

const origin = (state = [], action) => {
  switch (action.type) {
    case "COUNTRY_ORIGIN_BULK":
      return action.data;
    default:
      return state;
  }
};

const replace = (state = [], action) => {
  switch (action.type) {
    case "REPLACE_BULK":
      return action.data;
    case "REPLACE_LIST_EMPTY":
      return [];
    default:
      return state;
  }
};

const flag = (state = false, action) => {
  switch (action.type) {
    case "FLAG_TOGGLE":
      return !state;
    default:
      return state;
  }
};

const renderChangeMain = (state = false, action) => {
  switch (action.type) {
    case "RENDER_MAIN_TOGGLE":
      return !state;
    default:
      return state;
  }
};

const opasparent = (state = [], action) => {
  switch (action.type) {
    case "OP_SET":
      return action.opasparent;
    case "OP_RESET":
      return [];
    case "OP_TOGGLE": {
      return state.map(row => {
        if (row.varietyID === action.varietyID) {
          return Object.assign({}, row, {
            checked: !row.checked
          });
        }
        return row;
      });
    }
    default:
      return state;
  }
};

const sendToVarmasFlag = (state = false, action) => {
  switch (action.type) {
    case "SEND_TRUE":
      return true;
    case "SEND_FALSE":
      return false;
    default:
      return state;
  }
};
const sendToVarmasStage = (state = "i", action) => {
  switch (action.type) {
    case "CHANGE_SENDTO_STAGE":
      return action.stage;
    default:
      return state;
  }
};

const initConfirmSend = {
  msg: "",
  mainGID: "",
  data: [],
  obj: {},
  skipGID: []
};
const initConfirmSend1 = {
  msg: "Varieties 54321, 54321, 54321 already exists with stem 30074.",
  mainGID: 1676594,
  data: [
    {
      varietyID: 102479,
      varietyNr: 12345,
      eNumber: "54321",
      statusCode: 250,
      statusName: null,
      gid: 2067127
    },
    {
      varietyID: 102482,
      varietyNr: 12345,
      eNumber: "54321",
      statusCode: 250,
      statusName: null,
      gid: 2079201
    },
    {
      varietyID: 102483,
      varietyNr: 12345,
      eNumber: "54321",
      statusCode: 250,
      statusName: null,
      gid: 2101589
    }
  ]
};
const sendToVarmasConfirm = (state = initConfirmSend, action) => {
  switch (action.type) {
    case "SEND_TO_VARMAS_CONFIRM":
      return {
        msg: action.msg,
        mainGID: action.mainGID,
        data: action.data,
        obj: action.obj,
        skipGID: action.skipGID
      };
    case "two":
      return state;
    default:
      return state;
  }
};

export const main = combineReducers({
  files,
  filterWithout,
  fileStatus,
  plant,
  column,
  filter,
  sort,
  newcrop,
  productsegment,
  origin,
  total,
  replace,
  flag,
  renderChangeMain,
  opasparent,
  selectedMap,

  sendToVarmasFlag,
  sendToVarmasStage,
  sendToVarmasConfirm
});

const initialState = {
  isLoggedIn: false, // !!sessionStorage.getItem('isLoggedIn'),
  importView: false,
  treeData: {}
};
export const phenome = (state = initialState, action) => {
  switch (action.type) {
    case "PHENOME_LOGIN_DONE":
      sessionStorage.setItem("isLoggedIn", true);
      return { ...state, isLoggedIn: true };
    case "GET_RESEARCH_GROUPS_DONE":
    case "GET_FOLDERS_DONE":
      return { ...state, treeData: action.data };
    case "PHENOME_LOGOUT":
      return { ...state, isLoggedIn: false };
    case "IMPORT_VIEW_FLAG":
      return { ...state, importView: action.flag };
    default:
      return state;
  }
};

const pedigreeData = (state = [], action) => {
  switch (action.type) {
    case "PEDIGREE_BULK":
      return action.pedigree;
    case "PEDIGREE_RESET":
      return [];
    default:
      return state;
  }
};

const pedigreeColumn = (state = [], action) => {
  switch (action.type) {
    case "PEDIGREE_COLUMN_BULK": {
      const lotColumn = [
        { ID: "GID", desc: "GID", exclude: true },
        { ID: "lotID", desc: "Lot", exclude: true }
      ];
      const columns = [...lotColumn, ...action.columns];
      return columns.map(c =>
        Object.assign({
          ID: c.ID,
          desc: c.desc,
          columnLabel2: c.ID,
          columnLabel: c.desc,
          exclude: c.exclude || false
        })
      );
    }
    case "PEDIGREE_RESET":
      return [];
    default:
      return state;
  }
};
const pedigreeRefresh = (state = false, action) => {
  switch (action.type) {
    case "PEDIGREE_REFRESH":
      return !state;
    default:
      return state;
  }
};
const initPedigree = {
  total: 0,
  pageNumber: 1,
  pageSize: 100,
  filterChange: false
};
const pedigreeTotal = (state = initPedigree, action) => {
  switch (action.type) {
    case "PEDIGREE_RECORDS":
      return { ...state, total: action.total };
    case "PEDIGREE_PAGE":
      return { ...state, pageNumber: action.pageNumber };
    case "PEDIGREE_SIZE":
      return { ...state, pageSize: action.pageSize * 1 };
    case "PEDIGREE_FILTER_CHANGE":
      return { ...state, filterChange: !state.filterChange };
    case "PEDIGREE_RESET":
      return initPedigree;
    default:
      return state;
  }
};
const pedigreeM = {
  pedigreeView: false,
  replaceNode: "",
  stem: "",
  stemKey: "",
  selectedNodes: []
};
const pedigreeNode = (state = pedigreeM, action) => {
  switch (action.type) {
    case "PEDIGREE_REPLACENODE":
      return { ...state, replaceNode: action.replaceNode };
    case "PEDIGREE_REPLACENODE_RESET":
      return pedigreeM;
    case "PEIGREE_VIEW_FLAG":
      return { ...state, pedigreeView: action.flag };
    case "PEDIGREE_VIEW_STEM":
      return { ...state, stem: action.stem };
    case "PEDIGREE_VIEW_STEMKEY":
      return { ...state, stemKey: action.stemKey };
    case "PEDIGREE_VIEW_SELECTEDNODES":
      return { ...state, selectedNodes: action.selectedNodes };
    default:
      return state;
  }
};

const pedigreeFilter = (state = [], action) => {
  switch (action.type) {
    case "FILTER_PEDIGREE_ADD": {
      const check = state.find(d => d.name === action.name);
      if (check) {
        return state.map(item => {
          if (item.name === action.name) {
            return { ...item, value: action.value };
          }
          return item;
        });
      }
      return [
        ...state,
        {
          display: action.display,
          name: action.name,
          value: action.value,
          expression: action.expression,
          operator: action.operator,
          dataType: action.dataType
        }
      ];
    }
    case "FILTER_PEDIGREE_REMOVE":
      return state.filter(d => d.name !== action.name);
    case "FILTER_PEDIGREE_CLEAR":
    case "PEDIGREE_RESET":
      return [];
    default:
      return state;
  }
};
const pedigreeSort = (
  state = {
    name: "",
    direction: ""
  },
  action
) => {
  switch (action.type) {
    case "PEDIGREE_SORT": {
      const { name, direction } = action;
      return Object.assign({}, state, {
        name,
        direction
      });
    }
    default:
      return state;
  }
};

export const pedigree = combineReducers({
  refresh: pedigreeRefresh,
  total: pedigreeTotal,
  pedigree: pedigreeData,
  column: pedigreeColumn,
  filter: pedigreeFilter,
  sort: pedigreeSort,
  pedigreeNode
});
