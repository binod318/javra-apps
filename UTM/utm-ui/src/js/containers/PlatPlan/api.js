import axios from "axios";
import urlConfig from "../../urlConfig";

export const getPlatPlanApi = (pageNumber, pageSize, filter, active, btr) =>
  axios({
    method: "post",
    url: urlConfig.getPlatPlan,
    data: {
      pageNumber,
      pageSize,
      filter,
      active,
      btr
    }
  });

export const postPlatPlanExcelApi = (testID, withControlPosition) =>
  axios({
    method: "get",
    url: urlConfig.postPlatPlanExcel,
    responseType: "arraybuffer",
    headers: {
      Accept: "application/vnd.ms-excel"
    },
    params: { testID, withControlPosition }
  });
