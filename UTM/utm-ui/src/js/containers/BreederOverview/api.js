import axios from "axios";
import urlConfig from "../../urlConfig";

export const fetchSlotAPi = (
  cropCode,
  brStationCode,
  pageNumber,
  pageSize,
  filter
) =>
  axios({
    method: "post",
    url: urlConfig.getSlotBreedingOverview,

    data: {
      cropCode,
      brStationCode,
      pageNumber,
      pageSize,
      filter
    }
  });
export const exportCapacityPlanningApi = payload =>
  axios({
    method: "post",
    url: urlConfig.exportCapacityPlanning,
    responseType: "arraybuffer",
    headers: {
      "Content-Type": "application/json"
    },
    data: payload
  });
