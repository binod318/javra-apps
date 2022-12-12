import axios from "axios";
import urlConfig from "../../urlConfig";

export const capacityPeriodAPI = (action) =>
  axios({
    method: "get",
    url: urlConfig.capacityPeriod,
    params: {
      year: action.year,
    },
  });

export const capacitySOAPI = (action) =>
  axios({
    method: "get",
    url: urlConfig.planningCapacitySO,
    params: {
      periodID: action.periodID,
    },
  });
// postPlanningCapacitySO
export const capacitySOUpdateAPI = (action) =>
  axios({
    method: "post",
    url: urlConfig.postPlanningCapacitySO,
    data: action.data,
  });
