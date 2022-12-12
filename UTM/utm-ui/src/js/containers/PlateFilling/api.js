import axios from "axios";
import urlConfig from "../../urlConfig";

export function createReplicaApi(data) {
  return axios({
    method: "patch",
    url: urlConfig.replicateMaterials,

    data
  });
}

export function deleteDeadMaterialsApi(action) {
  return axios({
    method: "delete",
    url: urlConfig.deleteDeadMaterials,

    data: {
      testID: action.testID
    }
  });
}

export function fetchWellApi(action) {
  return axios({
    method: "get",
    url: urlConfig.getWellPosition,

    params: {
      testID: action.testID
    }
  });
}

export function getStatusListApi() {
  return axios({
    method: "get",
    url: urlConfig.getStatusList
  });
}

export function deleteRowApi(action) {
  return axios({
    method: "delete",
    url: urlConfig.delMaterials,

    data: {
      testID: action.testID,
      wellIDs: action.wellIDs
    }
  });
}

export function undoDeadApi(action) {
  return axios({
    method: "delete",
    url: urlConfig.delMaterialsUndo,

    data: {
      testID: action.testID,
      wellIDs: action.wellIDs
    }
  });
}

export function deleteReplicateApi(action) {
  return axios({
    method: "delete",
    url: urlConfig.delDeleteReplicate,

    data: {
      testID: action.testID,
      materialID: action.materialID,
      wellID: action.wellID
    }
  });
}

export function getWellTypeApi() {
  return axios({
    method: "get",
    url: urlConfig.getWellType
  });
}

export function saveDBApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postWellSaveDB,

    data: {
      testID: action.testID,
      materialWell: action.materialIDs
    }
  });
}

export function reservePlateApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postReservePlate,

    data: {
      testID: action.testID,
      forced: action.forced
    }
  });
}

export function undoFixedPositionApi(action) {
  const data = { ...action };
  delete data.type;
  return axios({
    method: "post",
    url: urlConfig.postUndoFixedPosition,

    data
  });
}

export const postPlateFillingExcelApi = (testID, withControlPosition) =>
  axios({
    method: "get",
    responseType: "arraybuffer",
    url: urlConfig.postPlateFillingExcel,

    headers: {
      Accept: "application/vnd.ms-excel"
    },
    params: { testID, withControlPosition }
  });

export const getPlateFillingTotalMarkerApi = testID =>
  axios({
    method: "get",
    url: urlConfig.getPlateFillingTotalMarkers,

    params: { testID }
  });
