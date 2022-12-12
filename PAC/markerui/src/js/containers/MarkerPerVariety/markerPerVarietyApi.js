import axios from "axios";
import urlConfig from "../../urlConfig";

export const markerPerVarietyAPI = (
  PageNr,
  PageSize,
  SortBy,
  SortOrder,
  Filters
) =>
  axios({
    method: "post",
    url: urlConfig.getMarkerPerVarieties,
    data: {
      PageNr,
      PageSize,
      SortBy,
      SortOrder,
      Filters
    }
  });

export const getMarkersAPI = (action) => {
  const { markerName, cropCode, showPacMarkers } = action;
  return axios({
    method: "get",
    url: urlConfig.getMarker,
    params: {
      markerName,
      cropCode,
      showPacMarkers
    },
  });
};

export const getVarietiesAPI = (action) => {
  const { varietyName, cropCode } = action;
  return axios({
    method: "get",
    url: urlConfig.getVarieties,
    params: {
      varietyName,
      cropCode
    },
  });
};

export const getCropsAPI = () =>
  axios({
    method: "get",
    url: urlConfig.getCrops,
  });

export const postMarkerPerVarietiesAPI = (
  MarkerPerVarID,
  MarkerID,
  VarietyNr,
  Remarks,
  ExpectedResult,
  Action
) => {
  const obj = [
    {
      MarkerPerVarID,
      MarkerID,
      VarietyNr,
      Remarks,
      ExpectedResult,
      Action,
    },
  ];
  return axios({
    method: "post",
    url: urlConfig.postMarkerPerVarieties,
    data: obj,
  });
};
