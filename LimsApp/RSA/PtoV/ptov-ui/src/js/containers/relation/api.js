import axios from "axios";
import URLS from "../../urls";

export const getRelationApi = (pageNumber, pageSize, filter, sorting) =>
  axios({
    method: "post",
    url: URLS.gettraitScreening,
    data: {
      pageNumber,
      pageSize,
      filter,
      sorting
    }
  });

export const getRelationDeterminationApi = (screeningFieldLabel, cropCode) =>
  axios({
    method: "get",
    url: URLS.getRelationScreening,
    params: {
      screeningFieldLabel,
      cropCode
    }
  });

export const postRelationApi = data =>
  axios({
    method: "post",
    url: URLS.postRelation,
    data
  });
