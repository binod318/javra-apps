/**
 * Created by sushanta on 4/12/18.
 */
 import axios from "axios";
 import shortid from "shortid";
 import urlConfig from "../../../urlConfig";
 
 export function phenomeLoginApi({ user, pwd }) {
   return axios({
     method: "post",
     url: urlConfig.phenomeLogin,
 
     params: {
       userName: user,
       password: pwd
     }
   });
 }
 export function phenomeLoginSSOApi({ token }) {
   return axios({
     method: "post",
     url: urlConfig.phenomeSSOLogin,
     params: {
       token
     }
   });
 }
 export function getResearchGroupsApi() {
   return axios({
     method: "get",
     url: urlConfig.getResearchGroups,
     headers: {
       "Cache-Control": "no-cache"
     }
   });
 }
 export function getFoldersApi(id) {
   return axios({
     method: "get",
     url: urlConfig.getFolders,
 
     params: {
       id
     }
   });
 }
 export function importPhenomeApi(data) {
   return axios({
     method: "post",
     url: urlConfig.importPhenome,
 
     data: {
       ...data,
       pageNumber: 1,
       gridID: shortid.generate().substr(1, 8),
       pageSize: 200,
       positionStart: "0"
     }
   });
 }
 
 export function getThreeGBavailableProjectsApi(
   cropCode,
   brStationCode,
   testTypeCode
 ) {
   return axios({
     method: "get",
     url: urlConfig.getThreeGBavailableProjects,
 
     params: {
       cropCode,
       brStationCode,
       testTypeCode
     }
   });
 }
 
 export function importPhenomeThreegbApi(data) {
   return axios({
     method: "post",
     url: urlConfig.postThreeGBimport,
 
     data: {
       ...data,
       pageNumber: 1,
       gridID: shortid.generate().substr(1, 8),
       pageSize: 200,
       positionStart: "0"
     }
   });
 }
 
 export function sendToThreeGBCockPitApi(testID) {
   // filter
   // const data
   // url: "http://10.0.0.78:8888/Services/api/v1/threeGB/sendTo3GBCockpit?testID=123",
   return axios({
     method: "post",
     url: urlConfig.postSendToThreeGBCockpit,
 
     data: {
       testID
     }
   });
 }
 
 //Leafdisk
 export function importPhenomeLeafDiskApi(data) {
  return axios({
    method: "post",
    url: urlConfig.importLeafDisk,

    data: {
      ...data,
      pageNumber: 1,
      gridID: shortid.generate().substr(1, 8),
      pageSize: 200,
      positionStart: "0"
    },
    withCredentials: true
  });
}

export function importPhenomeLeafDiskConfigApi(data) {
  return axios({
  method: "post",
  url: urlConfig.importfromconfigurationLeafDisk,

  data: {
    ...data,
    pageNumber: 1,
    pageSize: 200,
    positionStart: "0"
  },
  withCredentials: true
  });
}

// IMPORT CNT API
export function importPhenomeCNTApi(data) {
  return axios({
    method: "post",
    url: urlConfig.postImportCNT,

    data: {
      ...data,
      pageNumber: 1,
      gridID: shortid.generate().substr(1, 8),
      pageSize: 200,
      positionStart: "0"
    }
  });
}

// IMPORT Seed Health API
export function importPhenomeSeedHealthApi(data) {
  var payload = {
    cropID: data.cropID,
    folderID: data.folderID,
    folderObjectType: data.folderObjectType,
    forcedImport: data.forcedImport,
    objectID: data.objectID,
    objectType: data.objectType,
    fileID: data.fileID,
    siteID: data.siteID,
    sampleType: data.sampleType,
    testName : data.testName,
    testTypeID: data.testTypeID
  };

  return axios({
    method: "post",
    url: urlConfig.postImportSeedHealth,
    data: {
      ...payload,
      pageNumber: 1,
      gridID: shortid.generate().substr(1, 8),
      pageSize: 200,
      positionStart: "0"
    }
  });
}

// S2S
export function getS2SCapacityApi({
  crop,
  year,
  importLevel,
  breEzysAdministration
}) {
  return axios({
    method: "get",
    url: urlConfig.getS2SCapacity,

    params: { crop, year, importLevel, breEzysAdministration }
  });
}
export function postS2SImportApi(data) {
  return axios({
    method: "post",
    url: urlConfig.postS2SImport,

    data: {
      ...data,
      pageNumber: 1,
      gridID: shortid.generate().substr(1, 8),
      pageSize: 200,
      positionStart: "0"
    }
  });
}
export function postS2SGetDataApi(data) {
  return axios({
    method: "post",
    url: urlConfig.postS2SImport,

    data: {
      ...data
    }
  });
}
export function postRDTImportApi(data) {
  return axios({
    method: "post",
    url: urlConfig.postRDTImport,

    data: {
      ...data,
      pageNumber: 1,
      gridID: shortid.generate().substr(1, 8),
      pageSize: 200,
      positionStart: "0"
    }
  });
}
export function postRDTSGetDataApi(data) {
  return axios({
    method: "post",
    url: urlConfig.getRDTData,

    data: {
      ...data
    }
  });
}
export function fetchPhenomTokenApi() {
  return axios({
    method: "post",
    url: urlConfig.phenomeAccessToken
  });
}
