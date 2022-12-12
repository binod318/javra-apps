import axios from "axios";
import urlConfig from "../../urlConfig";

export const labResultfetchAPI = (
  PageNr,
  PageSize,
  SortBy,
  SortOrder,
  Filters
) =>
  axios({
    method: "post",
    url: urlConfig.postBatchOverView,
    data: {
      Filters,
      PageNr,
      PageSize,
      SortBy,
      SortOrder,
    },
  });

export const fetchGetExportAPI = (Filters, token) => {
  return axios({
    method: "post",
    url: urlConfig.exportExcel,
    headers: {
      Accept: "application/vnd.ms-excel",
    },
    responseType: "arraybuffer",
    data: {
      Filters,
    },
  });
};
