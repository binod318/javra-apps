import axios from "axios";
import urlConfig from "../../urlConfig";

export const getCropApi = () =>
  axios({
    method: "get",
    url: urlConfig.getCrop
  });

export const getRelationTraitApi = (traitName, cropCode, source) =>
  axios({
    method: "get",
    url: urlConfig.getRelationTrait,

    params: {
      traitName,
      cropCode,
      source
    }
  });

export const getRelationDeterminationApi = (determinationName, cropCode) =>
  axios({
    method: "get",
    url: urlConfig.getRelationDetermination,

    params: {
      determinationName,
      cropCode
    }
  });

export const getRelationApi = (pageNumber, pageSize, filter) =>
  axios({
    method: "post",
    url: urlConfig.getRelation,
    data: {
      pageNumber,
      pageSize,
      filter
    }
  });

export const postRelationApi = data =>
  axios({
    method: "post",
    url: urlConfig.postRelation,
    data
  });
