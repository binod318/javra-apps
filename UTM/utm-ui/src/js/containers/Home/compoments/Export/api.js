import axios from "axios";
import urlConfig from "../../../../urlConfig";

export function fetchGetExternalTestsApi({ brStationCode, cropCode }) {
  return axios({
    method: "get",
    url: urlConfig.getExternalTests,
    params: { brStationCode, cropCode }
  });
}

export function fetchGetExportApi(action) {
  const { testID, mark, TraitScore } = action;
  return axios({
    method: "get",
    url: urlConfig.getExport,
    headers: {
      Accept: "application/vnd.ms-excel"
    },

    responseType: "arraybuffer",
    params: {
      testID,
      mark,
      TraitScore,
    },
  });
}
