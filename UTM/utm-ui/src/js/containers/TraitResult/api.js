import axios from "axios";
import urlConfig from "../../urlConfig";

export const getTraitRelationApi = (pageNumber, pageSize, filter) =>
  axios({
    method: "post",
    url: urlConfig.getTraitResults,

    data: {
      pageNumber,
      pageSize,
      filter
    }
  });

export const postTraitRelationApi = data =>
  axios({
    method: "post",
    url: urlConfig.postTraitResults,

    data
  });

export const getTraitValuesApi = cropTraitID =>
  axios({
    method: "get",
    url: urlConfig.getTraitValues,

    params: {
      cropTraitID
    }
  });

export const getCheckValidationApi = source =>
  axios({
    method: "get",
    url: urlConfig.checkValidation,

    params: {
      source
    }
  });
