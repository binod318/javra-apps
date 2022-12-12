import axios from "axios";
import urlConfig from "../../urlConfig";

// FETCH
export function getCTProcessApi() {
  return axios({
    method: "get",
    url: urlConfig.getCTProcess
  });
}
export function postSaveCTProcessApi(processID, processName, active, action) {
  return axios({
    method: "post",
    url: urlConfig.postSaveCTProcess,

    data: [
      {
        processID: processID || null,
        processName,
        active,
        action
      }
    ]
  });
}

export function getCNTLabLocationsApi() {
  return axios({
    method: "get",
    url: urlConfig.getCNTLabLocations
  });
}
export function postCNTLabLocationsApi(
  labLocationID,
  labLocationName,
  active,
  action
) {
  return axios({
    method: "post",
    url: urlConfig.postCNTLabLocations,

    data: [
      {
        labLocationID: labLocationID || null,
        labLocationName,
        active,
        action
      }
    ]
  });
}

export function getCNTStartMaterialApi() {
  return axios({
    method: "get",
    url: urlConfig.getCNTStartMaterials
  });
}
export function postCNTStartMaterialApi(
  startMaterialID,
  startMaterialName,
  active,
  action
) {
  return axios({
    method: "post",
    url: urlConfig.postCNTStartMaterials,

    data: [
      {
        startMaterialID: startMaterialID || null,
        startMaterialName,
        active,
        action
      }
    ]
  });
}

export function getCNTTypesApi() {
  return axios({
    method: "get",
    url: urlConfig.getCNTTypes
  });
}
export function postCNTTypesApi(typeID, typeName, active, action) {
  return axios({
    method: "post",
    url: urlConfig.postCNTTTypes,

    data: [
      {
        typeID: typeID || null,
        typeName,
        active,
        action
      }
    ]
  });
}
