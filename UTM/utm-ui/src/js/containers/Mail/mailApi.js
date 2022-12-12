import axios from "axios";
import urlConfig from "../../urlConfig";

// FETCH
export function mailConfigFetchApi(pageNumber, pageSize, usedForMenu) {
  // return axios({
  //   method: "get",
  //   url: urlConfig.getEmailConfig,

  //   params: {
  //     pageNumber,
  //     pageSize,
  //     configGroup: "",
  //     cropCode: "",
  //     brStationCode: "",
  //     usedForMenu
  //     filter
  //   }
  // });

  return axios({
    method: "post",
    url: urlConfig.getEmailConfig,

    data: {
      pageNumber,
      pageSize,
      usedForMenu
    }
  });
}

// ADD
export function mailConfigAppendApi(
  configID,
  cropCode,
  configGroup,
  recipients,
  brStationCode
) {
  return axios({
    method: "post",
    url: urlConfig.postEmailConfig,

    data: {
      configID,
      cropCode,
      configGroup,
      recipients,
      brStationCode
    }
  });
}

// EDIT
export function mailConfigEditApi(pageNumber, pageSize, filter) {
  return axios({
    method: "post",
    url: urlConfig.getRelation,

    data: {
      pageNumber,
      pageSize,
      filter
    }
  });
}

// DELETE
export function mailConfigDeleteApi(configID) {
  return axios({
    method: "delete",
    url: urlConfig.deletEmailConfig,

    data: {
      configID
    }
  });
}
