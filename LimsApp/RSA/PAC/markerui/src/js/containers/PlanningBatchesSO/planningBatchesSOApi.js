import axios from "axios";
import urlConfig from "../../urlConfig";

export const planningPeriodAPI = (year) => {
  return axios({
    method: "get",
    url: urlConfig.capacityPeriod,
    params: { year },
  });
};

export const planningDeterminationAssignmentAPI = (
  periodID,
  startDate,
  endDate,
  includeUnplanned
) => {
  return axios({
    method: "get",
    url: `${urlConfig.getPlanningDeterminationAssignment}`,
    params: {
      periodID,
      startDate,
      endDate,
      includeUnplanned,
    },
  });
};

export const postDeterminationAssignmentsAutoPlanAPI = (
  periodID,
  startDate,
  endDate
) => {
  return axios({
    method: "post",
    url: `${urlConfig.postDeterminationAssignmentsAutoPlan}`,
    data: {
      periodID,
      startDate,
      endDate,
    },
  });
};

export const postDeterminationAssignmentsChangePlanAPI = (
  periodID,
  DeterminationIDs
) => {
  return axios({
    method: "post",
    url: `${urlConfig.postDeterminationAssignmentsConfirmPlan}`,
    data: {
      periodID,
      Details: [...DeterminationIDs],
    },
  });
};
