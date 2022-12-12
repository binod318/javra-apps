import axios from "axios";
import urlConfig from "../../urlConfig";

export const getSHTestOverviewApi = (pageNumber, pageSize, filter, active) =>
  axios({
    method: "post",
    url: urlConfig.getSeedHealthOverview,
    data: {
      pageNumber,
      pageSize,
      filter,
      active
    }
  });  

export const postSHSampleTestCBApi = data => {
  return true;
};

export const getSHOverviewExcelApi = (testID, markerScore, traitScore) =>
  axios({
    method: "get",
    responseType: "arraybuffer",
    url: urlConfig.getSeedHealthOverviewExcelApi,

    headers: {
      Accept: "application/vnd.ms-excel"
    },
    params: { testID }
  });
