import axios from "axios";
import urlConfig from "../../urlConfig";

export const leafDiskFetchSlotApi = (
  cropCode,
  brStationCode,
  pageNumber,
  pageSize,
  filter
) =>
  axios({
    method: "post",
    url: urlConfig.getLeafDiskSlotBreedingOverview,

    data: {
      cropCode,
      brStationCode,
      pageNumber,
      pageSize,
      filter
    }
  });

export function breederApi() {
  return axios({
    method: "get",
    url: urlConfig.getLDreserveCapacityLookup
  });
}

export function cropChangeApi(action) {
  return axios({
    method: "get",
    url: urlConfig.getMaterialType,
    params: {
      crop: action.crop
    }
  });
}

export function breederReserveApi(action) {
  const {
    breedingStationCode,
    cropCode,
    testTypeID,
    materialTypeID,
    plannedDate,
    nrOfSample,
    remark,
    forced,
    testProtocolID,
    siteID
  } = action;
  return axios({
    method: "post",
    url: urlConfig.postLDReserve,

    data: {
      breedingStationCode,
      cropCode,
      testTypeID,
      materialTypeID,
      plannedDate,
      nrOfSample,
      remark,
      forced,
      protocolID: testProtocolID,
      siteID
    }
  });
}

export function periodApi(action) {
  return axios({
    method: "get",
    url: urlConfig.getPeriod,

    params: {
      args: action.period
    }
  });
}

export function getAvailableSampleApi(action) {
  const {
    testProtocolID,
    plannedDate,
    siteID
  } = action;
  return axios({
    method: "get",
    url: urlConfig.getAvailSamples,

    params: {
      testProtocolID,
      plannedDate,
      siteID
    }
  });
}

export function slotDeleteApi(slotID) {
  return axios({
    method: "post",
    url: urlConfig.deleteSlot,

    params: {
      slotID
    }
  });
}

export function postSlotEditApi(action) {
  const {
    slotID,
    nrOfTests,
    forced,
    plannedDate
  } = action;
  return axios({
    method: "post",
    url: urlConfig.postSlotEditLeafDisk,

    data: {
      slotID,
      nrOfTests,
      forced,
      plannedDate
    }
  });
}

export const leafDiskExportCapacityPlanningApi = payload =>
  axios({
    method: "post",
    url: urlConfig.exportCapacityPlanningLeafDisk,
    responseType: "arraybuffer",
    headers: {
      "Content-Type": "application/json"
    },
    data: payload
  });
