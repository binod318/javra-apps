const ASSIGN_TOTAL_RECORD = "TOTAL_RECORD";
const ASSIGN_SIZE = "SIZE_RECORD";
const ASSIGN_DEFAULT_SIZE = "DEFAULT_SIZE_RECORD";
const ASSIGN_PAGE = "PAGE_RECORD";

const iniAssignMarker = {
  total: 0,
  pageNumber: 1,
  defaultPageSize: 200,
  pageSize: 200,
  grandTotal: 0
};
const total = (state = iniAssignMarker, action) => {
  switch (action.type) {
    case ASSIGN_TOTAL_RECORD:
      return Object.assign({}, state, { total: action.total });
    case ASSIGN_PAGE:
      return Object.assign({}, state, { pageNumber: action.pageNumber });
    case ASSIGN_DEFAULT_SIZE:
      return Object.assign({}, state, { pageSize: state.defaultPageSize });
    case ASSIGN_SIZE:
      return Object.assign({}, state, { pageSize: action.pageSize });
    case "RESET_ASSIGNMARKER_TOTAL":
    case "RESETALL":
      return iniAssignMarker;
    case "FILTERED_TOTAL_RECORD": {
      const { grandTotal } = action;

      return { ...state, grandTotal };
    }
    case "NEW_PAGE":
    default:
      return state;
  }
};
export default total;
