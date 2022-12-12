const init = {
  breedingStation: [],
  crop: [],
  materialState: [],
  materialType: [],
  period: [],
  testType: [],
  testProtocol: [],
  siteLocation: []
};
const Fields = (state = init, action) => {
  switch (action.type) {
    case "LEAF_DISK_CAPACITY_PLANNING_FORM_VALUE":
      {
        return Object.assign({}, state, {
          breedingStation: action.data.breedingStation,
          crop: action.data.crop,
          materialState: action.data.materialState,
          period: action.data.currentPeriod,
          testType: action.data.testType,
          materialType: action.data.materialType,
          testProtocol: action.data.testProtocol,
          columns: action.data.columns,
          siteLocation: action.data.siteLocation
        });
      }

    case "LEAF_DISK_CAPACITY_PLANNING_MATERIALTYPE":
      return Object.assign({}, state, {
        materialType: action.materialType
      });

    case "LEAF_DISK_CAPACITY_PLANNING_FORM_CLEAR":
      return [];

    case "LEAF_DISK_CAPACITY_PLANNING_FORM_FETCH":
    case "LEAF_DISK_CAPACITY_PLANNING_FETCH_MATERIALTYPE":
    case "LEAF_DISK_CAPACITY_PLANNING_RESERVE":
    default:
      return state;
  }
};
export default Fields;
