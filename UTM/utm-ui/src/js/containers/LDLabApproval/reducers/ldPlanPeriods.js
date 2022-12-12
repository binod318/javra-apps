const ldPlanPeriods = (state = [], action) => {
  switch (action.type) {
    case 'GET_LD_PLAN_PERIODS_DONE':
      return action.data;
    default:
      return state;
  }
};
export default ldPlanPeriods;
