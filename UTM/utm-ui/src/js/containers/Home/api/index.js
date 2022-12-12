import axios from "axios";
import urlConfig from "../../../urlConfig";

export function fetchFileListApi(breedingStationCode, cropCode, testTypeMenu) {
  return axios({
    method: "get",
    url: urlConfig.getFileList,

    params: {
      breedingStationCode,
      cropCode,
      testTypeMenu
    }
  });
}

export function fetchTestTypeApi() {
  return axios({
    method: "get",
    url: urlConfig.getTestType
  });
}

export function fetchMaterialTypeApi() {
  return axios({
    method: "get",
    url: urlConfig.getmaterialType
  });
}

export function fetchTestProtocolApi() {
  return axios({
    method: "get",
    url: urlConfig.getTestProtocols
  });
}

export function fetchMaterialStateApi() {
  return axios({
    method: "get",
    url: urlConfig.getmaterialState
  });
}

export function fetchContainerTypeApi() {
  return axios({
    method: "get",
    url: urlConfig.getContainerTypes
  });
}

export function fetchAssignDataApi(action) {
  /**
   * Future
   * testType condition to change
   * fetch urls
   */
  const { testTypeID } = action;
  const testTypeIsRDT = testTypeID === 8;
  const testTypeLeafDisk = testTypeID === 9;
  const testTypeIsSeedHealth = testTypeID === 10;

  return axios({
    method: "post",
    url: testTypeIsRDT        ? urlConfig.getRDTData          :
        (testTypeLeafDisk     ? urlConfig.getLeafDiskFileData :
        (testTypeIsSeedHealth ? urlConfig.getSeedHealthData   : urlConfig.getFileData)),

    data: {
      testTypeID: action.testTypeID,
      testID: action.testID,
      pageNumber: action.pageNumber,
      pageSize: action.pageSize,
      filter: action.filter
    }
  });
}

export function fetchMarkerApi(action) {
  /**
   * Future
   * testType condition to change
   * fetch urls
   */
  const markerURL =
    action.source === "External"
      ? urlConfig.getExternalDeterminations
      : urlConfig.getMarkers;
  return axios({
      method: "get",
      url: markerURL,

      params: {
        cropCode: action.cropCode,
        testTypeID: action.testTypeID,
        testID: action.testID
      }
    });
}

export function fetchAssignFilterDataApi(action) {
  const { testTypeID } = action;
  const testTypeIsRDT = testTypeID === 8;
  const testTypeLeafDisk = testTypeID === 9;
  const testTypeIsSeedHealth = testTypeID === 10;

  return axios({
    method: "post",
    url: testTypeIsRDT        ? urlConfig.getRDTData          :
        (testTypeLeafDisk     ? urlConfig.getLeafDiskFileData :
        (testTypeIsSeedHealth ? urlConfig.getSeedHealthData   : urlConfig.getFileData)),

    data: {
      testTypeID: action.testTypeID,
      testID: action.testID,
      pageNumber: action.pageNumber,
      pageSize: action.pageSize,
      filter: action.filter
    }
  });
}

export function fetchBreedingApi() {
  return axios({
    method: "get",
    url: urlConfig.getBreedingNew
  });
}

export function fetchImportSourceApi() {
  return axios({
    method: "get",
    url: urlConfig.getImportSource
  });
}

export function postSaveNrOfSamplesApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postSaveNrOfSamples,

    data: action
  });
}

/**
 * DELETE TEST
 * This api will change test status and don't show in list
 */
export function postDeleteTestApi(testID) {
  return axios({
    method: "post",
    url: urlConfig.postDeleteTest,

    data: {
      testID
    }
  });
}

// S2S
export function fetchS2SApi(action) {
  const { testID, pageNumber, pageSize, filter } = action;

  return axios({
    method: "get",
    url: urlConfig.getS2SMaterial,

    params: { testID, pageNumber, pageSize, filter }
  });
}

export function saveS2SMarkerApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postS2SAssign,

    data: {
      // TODO make correction
      testTypeID: action.testTypeID,
      testID: action.testID,
      materialWithMarkerAndScore: action.materialWithMarkerAndScore,
      donerInfo: action.donerInfo,
      filter: action.filter,
      pageNumber: action.pageNumber || 1,
      determinations: action.determinations
    }
  });
}

export function addToS2SApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postS2SAssign,

    data: {
      testID: action.testID,
      testTypeID: action.testTypeID,
      determinations: action.determinations,
      filter: action.filter
    }
  });
}

export function fetchS2SFillRateApi(action) {
  const { testID } = action;

  return axios({
    method: "get",
    url: urlConfig.getS2SFillRate,

    params: { testID }
  });
}

export function postUploadS2SApi(testID) {
  return axios({
    method: "post",
    url: urlConfig.postUploadS2S,

    data: {
      testID
    }
  });
}

export function postProjectListApi(crop) {
  return axios({
    method: "get",
    url: urlConfig.projectS2S,

    params: {
      crop
    }
  });
}

export function postS2SmanageMarkerApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postS2SmanageMarker,

    data: {
      testID: action.testID,
      details: action.details
    }
  });
}

// CNT
export function fetchCNTApi(action) {
  const { testID, pageNumber, pageSize, filter } = action;

  return axios({
    method: "get",
    url: urlConfig.getCNTData,

    params: { testID, pageNumber, pageSize, filter }
  });
}
export function saveCNTMarkerApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postCNTAssignMarkers,

    data: {
      testID: action.testID,
      determinations: action.determinations,
      filter: action.filter
    }
  });
}

export function fetchCNTDataWithMarkersApi(action) {
  return axios({
    method: "get",
    url: urlConfig.getCNTgetDataWithMarkers,

    params: {
      testID: action.testID,
      pageNumber: action.pageNumber,
      pageSize: action.pageSize
    }
  });
}

export function postCNTManageMarkersApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postCNTManageMarkers,

    data: {
      testID: action.testID,
      markers: action.markers
    }
  });
}
export function postCNTManageInfoApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postCNTManageInfo,

    data: {
      testID: action.testID,
      materials: action.materials,
      details: action.details
    }
  });
}

export function getCNTExportApi(action) {
  const { testID } = action;
  return axios({
    method: "get",
    url: urlConfig.getCNTExport,
    headers: {
      Accept: "application/vnd.ms-excel"
    },

    responseType: "arraybuffer",
    params: {
      testID
    }
  });
}

export function getApprovedSlotsApi(slotName, testType, userSlotsOnly) {
  return axios({
    method: "get",
    url: testType === "LDISK" ? urlConfig.getApprovedSlotsLeafDisk : urlConfig.getApprovedSlots,

    params: { slotName, userSlotsOnly }
  });
}
export function postRDTMaterialWithTestsApi(action) {
  return axios({
    method: "post",
    url: urlConfig.getRDTMaterial,

    data: {
      testID: action.testID,
      pageNumber: action.pageNumber,
      pageSize: action.pageSize,
      filter: action.filter || []
    }
  });
}

export function saveRDTAssignTestsApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postRDTAssignTests,

    data: {
      testTypeID: action.testTypeID,
      testID: action.testID,
      materialWithMarkerAndExpectedDate:
        action.materialWithMarkerAndExpectedDate || [],
      propertyValue: action.propertyValue || [],
      filter: action.filter,
      pageNumber: action.pageNumber || 1,
      determinations: action.determinations || []
    }
  });
}
export function getRDTMaterialStateApi() {
  return axios({
    method: "get",
    url: urlConfig.getRDTMaterialState
  });
}
export function postRDTrequestSampleTestApi(testID) {
  return axios({
    method: "post",
    url: urlConfig.postRDTrequestSampleTest,

    data: {
      testID
    }
  });
}

export function postRDTupdateRequestSampleTestApi(testID) {
  return axios({
    method: "post",
    url: urlConfig.postRdtUpdateRequestSampleTest,
    data: {
      testID
    }
  });
}

export function postRDTprintApi(obj) {
  const { testID, materialStatus, materialDeterminations = [] } = obj;
  const value =
    materialStatus && materialStatus.length > 0 ? [materialStatus] : [];
  return axios({
    method: "post",
    url: urlConfig.postRDTprint,

    data: {
      testID,
      materialStatus: value,
      materialDeterminations: materialDeterminations || []
    }
  });
}

export function getMasterGetSitesApi() {
  return axios({
    method: "get",
    url: urlConfig.getMasterGetSites
  });
}

export function fetchUserCropsApi() {
  return axios({
    method: "get",
    url: urlConfig.getUserCrops
  });
}

//Leafdisk
export function fetchConfigurationListApi() {
  return axios({
    method: "get",
    url: urlConfig.getConfigurationList,
  });
}

export function postLeafDiskrequestSampleTestApi(testID) {
  return axios({
    method: "post",
    url: urlConfig.leafDiskRequestSampleTest,

    data: {
      testID
    }
  });
}

export function leafDiskPrintLabelApi(action) {
  const { testID } = action;
  return axios({
    method: "post",
    url: urlConfig.getLDPrintlabels,
    data: {
      testID
    }
  });
}

export function seedHealthPrintLabelApi(action) {
  const { testID } = action;
  return axios({
    method: "post",
    url: urlConfig.seedHealthPrintlabels,
    data: {
      testID
    }
  });
}