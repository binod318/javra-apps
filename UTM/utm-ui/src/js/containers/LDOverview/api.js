import axios from "axios";
import urlConfig from "../../urlConfig";

export const getLDtestOverviewApi = (pageNumber, pageSize, filter, active) =>
  axios({
    method: "post",
    url: urlConfig.getLeafDiskOverview,
    data: {
      pageNumber,
      pageSize,
      filter,
      active
    }
  });

export const postLDsampleTestCBApi = data => {
  return true;
};

export const getLDoverviewExcelApi = (testID, markerScore, traitScore) =>
  axios({
    method: "get",
    responseType: "arraybuffer",
    url: urlConfig.getLeafDiskOverviewExcelApi,

    headers: {
      Accept: "application/vnd.ms-excel"
    },
    params: { testID }
  });
