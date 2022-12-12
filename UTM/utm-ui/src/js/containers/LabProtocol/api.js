import axios from "axios";
import urlConfig from "../../urlConfig";

export const getProtocolApi = () =>
  axios({
    method: "get",
    url: urlConfig.getTestProtocols,
  });

export const postProtocolApi = ({ pageNumber, pageSize, filter }) =>
  axios({
    method: "post",
    url: urlConfig.postMaterialTypeTestProtocols,

    data: {
      pageNumber,
      pageSize,
      filter,
    },
  });
// postMaterialTypeTestProtocols

export const postSaveProtocolApi = (data) =>
  axios({
    method: "post",
    url: urlConfig.postSaveProtocolData,
    data
  });
