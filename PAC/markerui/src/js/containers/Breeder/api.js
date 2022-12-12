import axios from "axios";
import urlConfig from "../../urlConfig";

export function breederApi() {
  return axios({
    method: "get",
    url: urlConfig.getBreeder,
  });
}

export function cropChangeApi(action) {
  return axios({
    method: "get",
    url: urlConfig.getMaterialType,
    params: {
      crop: action.crop,
    },
  });
}

export function breederReserveApi(action) {
  const {
    breedingStationCode,
    cropCode,
    testTypeID,
    materialTypeID,
    materialStateID,
    isolated,
    plannedDate,
    expectedDate,
    nrOfPlates,
    nrOfTests,
    forced,
  } = action;
  return axios({
    method: "post",
    url: urlConfig.postBreeder,
    data: {
      breedingStationCode,
      cropCode,
      testTypeID,
      materialTypeID,
      materialStateID,
      isolated,
      plannedDate,
      expectedDate,
      nrOfPlates,
      nrOfTests,
      forced,
    },
  });
}

export function periodApi(action) {
  return axios({
    method: "get",
    url: urlConfig.getPeriod,
    params: {
      args: action.period,
    },
  });
}

export function plantsTestsApi(action) {
  const { plannedDate, cropCode, materialTypeID, isolated } = action;
  return axios({
    method: "get",
    url: urlConfig.getPlatestTest,
    params: {
      plannedDate,
      cropCode,
      materialTypeID,
      isolated,
    },
  });
}

export function slotDeleteApi(slotID) {
  return axios({
    method: "post",
    url: urlConfig.deleteSlot,
    params: {
      slotID,
    },
  });
}
