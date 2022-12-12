import { combineReducers } from "redux";

const column = (state = [], action) => {
  switch (action.type) {
    case "LAB_RESULT_COLUMN_ADD": {
      return action.data;
    }
    case "LAB_RESULT_EMPTY": {
      return [];
    }
    default:
      return state;
  }
};

const data = (state = [], action) => {
  switch (action.type) {
    case "LAB_RESULT_DATA_ADD": {
      return action.data;
    }
    case "LAB_RESULT_EMPTY": {
      return [];
    }
    default:
      return state;
  }
};

const validationInfo = (state = {}, action) => {
  switch (action.type) {
    case "LAB_RESULT_VALIDATION_ADD": {
      if (action.data === undefined) return state;
      return action.data;
    }
    case "LAB_RESULT_THREE_EMPTY": {
      return {};
    }
    default:
      return state;
  }
};
const testInfo = (state = {}, action) => {
  switch (action.type) {
    case "LAB_RESULT_TESTINFO_ADD": {
      if (action.data === undefined) return state;
      return action.data;
    }
    case "LAB_RESULT_THREE_EMPTY": {
      return {};
    }
    default:
      return state;
  }
};
const resultInfo = (state = {}, action) => {
  switch (action.type) {
    case "LAB_RESULT_RESULTIFNO_ADD": {
      if (action.data === undefined) return state;
      return action.data;
    }
    case "LAB_RESULT_THREE_EMPTY": {
      return {};
    }
    default:
      return state;
  }
};
const detAssignmentInfo = (state = {}, action) => {
  switch (action.type) {
    case "LAB_RESULT_DETASSOGM<EMTOMFP_ADD": {
      if (action.data === undefined) return state;
      return action.data;
    }
    case "LAB_RESULT_THREE_EMPTY": {
      return {};
    }
    case "SAVE_REMARKS_SUCCEEDED": {
      return { ...state, Remarks: action.remarks };
    }
    default:
      return state;
  }
};

const column2 = (state = [], action) => {
  switch (action.type) {
    case "LAB_RESULT_DETAIL_COLUMN_ADD": {
      if (action.data === undefined) return state;
      return action.data;
    }
    case "LAB_RESULT_THREE_EMPTY": {
      return [];
    }
    default:
      return state;
  }
};

const data2 = (state = [], action) => {
  switch (action.type) {
    case "LAB_RESULT_DETAIL_DATA_ADD": {
      if (action.data === undefined) return state;
      return action.data;
    }
    case "LAB_RESULT_THREE_EMPTY": {
      return [];
    }
    default:
      return state;
  }
};

const column3 = (state = [], action) => {
  switch (action.type) {
    case "LAB_RESULT_DETAIL2_COLUMN_ADD": {
      if (action.data === undefined) return state;
      return action.data;
    }
    case "LAB_RESULT_THREE_EMPTY": {
      return [];
    }
    default:
      return state;
  }
};

const data3 = (state = [], action) => {

  switch (action.type) {
    case "LAB_RESULT_DETAIL2_DATA_ADD": {
      if (action.data === undefined) return state;
      return action.data;
    }
    case "LAB_RESULT_THREE_EMPTY": {
      return [];
    }

    case "PATTERN_REMARK_CHANGE": {
       console.log('data3',action);
      const { index, value } = action;
      let { key } = action;

      const update = state.map((cap, i) => {
        if (i === index) {
          cap[key] = value; // eslint-disable-line
          return cap;
        }
        return cap;
      });
      return update;
    }

    default:
      return state;
  }
};

// new change 208 feb 2020
const filter = (state = {}, action) => {
  switch (action.type) {
    case "LABRESULT_FILTER_ADD":
      return action.data;
    case "LAB_RESULT_EMPTY": {
      return {};
    }
    default:
      return state;
  }
};

const sorter = (
  state = {
    sortBy: "",
    sortOrder: "",
  },
  action
) => {
  switch (action.type) {
    case "LABRESULT_SORTER":
      return action.data;
    case "LAB_RESULT_EMPTY": {
      return {
        sortBy: "",
        sortOrder: "",
      };
    }
    default:
      return state;
  }
};
const total = (state = 0, action) => {
  switch (action.type) {
    case "LABRESULT_TOTAL":
      return action.total;
    case "LABRESULT_EMPTY": {
      return 0;
    }
    default:
      return state;
  }
};
const page = (state = 1, action) => {
  switch (action.type) {
    case "LABRESULT_PAGE":
      return action.page;
    case "LABRESULT_EMPTY": {
      return 1;
    }
    default:
      return state;
  }
};

const saveSuccess = (state = false, action) => {
  switch (action.type) {
    case "SAVE_PATTERN_REMARKS_SUCCEEDED": {
      return true;
    }
    case "RESET_SAVE_SUCCESS": {
      return false;
    }
    default:
      return state;
  }
}

const platePosition = (state = [], action) => {
  switch (action.type) {
    case "PLATE_POSITION_ADD": {
      const { patternID } = action.data;

      let update = state.map((obj) => {
        if(obj.patternID === patternID)
          return {...obj, data: action.data.data, columns: action.data.columns};

        return obj;
      });

      if(update.findIndex(o => o.patternID === patternID) < 0)
        update.push(action.data);

      return update;
    }
    case "PLATE_POSIITON_EMPTY": {
      return [];
    }
    default:
      return state;
  }
};

const approveRetestSuccess = (state = false, action) => {
  switch (action.type) {
    case "APPROVE_RETEST_SUCCEEDED": {
      return true;
    }
    case "RESET_APPROVE_RETEST": {
      return false;
    }
    default:
      return state;
  }
}

const LabResults = combineReducers({
  column,
  data,
  validationInfo,
  testInfo,
  resultInfo,
  detAssignmentInfo,
  column2,
  data2,
  column3,
  data3,
  filter,
  sorter,
  total,
  page,
  saveSuccess,
  platePosition,
  approveRetestSuccess
});
export default LabResults;
