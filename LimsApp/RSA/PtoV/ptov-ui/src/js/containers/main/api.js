import axios from "axios";
import shortid from "shortid";
import URLS from "../../urls";

export function reciprocalRecordApi({ varietyID }) {
  return axios({
    method: "post",
    url: URLS.recipcalRecord,
    data: [varietyID]
  });
}

export function phenomeLoginSSOApi({ token }) {
  return axios({
    method: "post",
    url: URLS.phenomeSSOLogin,
    params: {
      token
    }
  });
}
export function phenomeLoginApi({ user, pwd }) {
  return axios({
    method: "post",
    url: URLS.phenomeLogin,
    params: {
      userName: user,
      password: pwd
    }
  });
}
export function getResearchGroupsApi() {
  return axios({
    method: "get",
    url: URLS.getResearchGroups,
    headers: {
      "Cache-Control": "no-cache"
    }
  });
}
export function getFoldersApi(id) {
  return axios({
    method: "get",
    url: URLS.getFolders,
    params: {
      id
    }
  });
}
export function importPhenomeApi(
  cropID,
  objectID,
  objectType,
  pageSize,
  folderID,
  folderObjectType,
  researchGroupObjectType,
  withoutHierarchy
) {
  return axios({
    method: "post",
    url: URLS.importPhenome,
    data: {
      cropID,
      objectID,
      objectType,
      pageNumber: 1,
      pageSize,
      gridID: shortid.generate().substr(1, 8),
      positionStart: "0",
      folderID,
      folderObjectType,
      researchGroupObjectType,
      isHybrid: !withoutHierarchy
    }
  });
}

export const germplasmApi = (
  fileName,
  pageNumber,
  pageSize,
  filter,
  sorting,
  isHybrid
) =>
  axios({
    method: "post",
    url: URLS.getgermplasm,
    data: {
      fileName,
      pageNumber,
      pageSize,
      filter,
      sorting,
      isHybrid: !isHybrid
    }
  });

export function getNewCropsAndProductApi(cropCode) {
  return axios({
    method: "get",
    url: URLS.getNewCropsAndProduct,
    params: {
      cropCode
    }
  });
}

export function getCountryOriginApi() {
  return axios({
    method: "get",
    url: URLS.getCountryOfOrigin
  });
}

export function postProductSegmentsApi(data) {
  return axios({
    method: "post",
    url: URLS.postProductSegments,
    data
  });
}

export const postVarmasApi = data =>
  axios({
    method: "post",
    url: URLS.postVarmas,
    data
  });

export const deleteApi = varietyID =>
  axios({
    method: "post",
    url: URLS.postDelete,
    data: {
      germplasm: varietyID,
      deleteParent: true
    }
  });

export const postReplaceLOTLookupApi = GID =>
  axios({
    method: "get",
    url: URLS.postReplaceLOTLookup,
    params: {
      GID
    }
  });

export const postReplaceLOTApi = ({ GID, LotGID, PhenomeLotID, Level, Data }) =>
  axios({
    method: "post",
    url: URLS.postReplaceLOT,

    data: {
      PhenomeLotID,
      LotGID,
      GID,
      Level,
      Data
    }
  });

// PEDIGREE API
export const pedigreeApi = ({ gid, baseGid, backwardGen, forwardGen }) =>
  axios({
    method: "post",
    url: URLS.getPedigree,
    // api with post data was not giving response to change to get (params)
    data: {
      gid,
      baseGid,
      backwardGen,
      forwardGen
    }
  });

export function fetchPhenomTokenApi() {
  return axios({
    method: "post",
    url: URLS.phenomeAccessToken
  });
}

export function fetchUserCropsApi() {
  return axios({
    method: "get",
    url: URLS.getUserCrops
  });
}

export function undoReplaceLotApi(payload) {
  return axios({
    method: "post",
    url: URLS.undoReplace,
    data: payload
  });
}
