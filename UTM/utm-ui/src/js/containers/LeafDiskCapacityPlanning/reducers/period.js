const init = {
  planned: "",
  expected: "",
  availPlates: null,
  availTests: null,
  expectedDate: null
};
const Period = (state = init, action) => {
  switch (action.type) {
    case "LEAF_DISK_CAPACITY_PLANNING_ADD_PERIOD":
      return action.data;

    case "LEAF_DISK_CAPACITY_PLANNING_PERIOD_ADD":
      return Object.assign({}, state, {
        planned: action.period
      });

    case "LEAF_DISK_CAPACITY_PLANNING_EXPECTED_ADD":
      return Object.assign({}, state, {
        expected: action.period
      });

    case "LEAF_DISK_CAPACITY_PLANNING_AVAIPLATES_ADD":
      return Object.assign({}, state, {
        availPlates: action.availPlates
      });

    case "LEAF_DISK_CAPACITY_PLANNING_AVAITESTS_ADD":
      return Object.assign({}, state, {
        availTests: action.availTests
      });

    case "LEAF_DISK_CAPACITY_PLANNING_EXPECTED_DATE":
      return Object.assign({}, state, {
        expectedDate: action.expectedDate
      });
    case "LEAF_DISK_CAPACITY_PLANNING_EXPECTED_BLANK":
      return Object.assign({}, state, {
        expectedDate: "",
        expected: "",
        availPlates: null,
        availTests: null
      });
    case "LEAF_DISK_CAPACITY_PLANNING_RESET":
      return init;

    case "LEAF_DISK_CAPACITY_PLANNING_PERIOD_FETCH":
    case "LEAF_DISK_CAPACITY_PLANNING_AVAIL_SAMPLE_FETCH":
    default:
      return state;
  }
};
export default Period;
