import axios from "axios";
import urlConfig from "../../urlConfig";

export const getRDTtestOverviewApi = (pageNumber, pageSize, filter, active) =>
  axios({
    method: "post",
    url: urlConfig.getRDTtestOverview,

    data: {
      pageNumber,
      pageSize,
      filter,
      active
    }
  });

export const postRDTsampleTestCBApi = data => {
  return true;
};

export const getRDToverviewExcelApi = (testID, markerScore, traitScore) =>
  axios({
    method: "get",
    responseType: "arraybuffer",
    url: urlConfig.getRDTOverviewExcelApi,

    headers: {
      Accept: "application/vnd.ms-excel"
    },
    params: { testID, markerScore, traitScore }
  });
