import axios from "axios";
import URLS from "../../urls";

export const getResultsApi = (pageNumber, pageSize, filter, sorting) =>
  axios({
    method: "post",
    url: URLS.getTraitResults,
    data: {
      pageNumber,
      pageSize,
      filter,
      sorting
    }
  });

export const getTraitsApi = (traitName, cropCode) =>
  axios({
    method: "get",
    url: URLS.getTraits,
    params: {
      traitName,
      cropCode
    }
  });

export const getTraitListApi = traitID =>
  axios({
    method: "get",
    url: URLS.getTraitList,
    params: {
      traitID
    }
  });

export const getScreeningListApi = screeningFieldID =>
  axios({
    method: "get",
    url: URLS.getScreeningList,
    params: {
      screeningFieldID
    }
  });

export const postTraitScreenResultApi = data =>
  axios({
    method: "post",
    url: URLS.postSaveTraitScreeningResult,
    data
  });

export const getCropsApi = () =>
  axios({
    method: "get",
    url: URLS.getCrops
  });
