import axios from "axios";
import urlConfig from "../../urlConfig";

export const getTraitDeterminationResultRDTApi = (
  pageNumber,
  pageSize,
  filter
) =>
  axios({
    method: "post",
    url: urlConfig.getTraitDeterminationResultRDT,
    data: {
      pageNumber,
      pageSize,
      filter
    }
  });

export const postTraitDeterminationResultRDTApi = ({
  cropCode,
  data,
  pageNumber,
  pageSize,
  filter
}) =>
  axios({
    method: "post",
    url: urlConfig.postTraitDeterminationResultRDT,
    data: {
      cropCode,
      data,
      pageNumber,
      pageSize,
      filter
    }
  });

export const getMaterialStatusApi = () =>
  axios({
    method: "get",
    url: urlConfig.getMaterialStatus
  });

export const getMappingColumnsApi = () =>
  axios({
    method: "get",
    url: urlConfig.getMappingColumns
  });
