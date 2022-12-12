import axios from "axios";
import urlConfig from "../../urlConfig";

export const planningYearAPI = () => {
  return axios({
    method: "get",
    url: urlConfig.planingYear,
  });
};

export const planningCapacityAPI = (action) =>
  axios({
    method: "get",
    url: urlConfig.planingCapacity,
    params: {
      year: action.year,
    },
  });

export const planningUpdateAPI = (action) =>
  axios({
    method: "post",
    url: urlConfig.postPlaningCapacity,
    data: action.data,
  });
