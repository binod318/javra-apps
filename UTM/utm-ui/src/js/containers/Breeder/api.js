import axios from "axios";
import urlConfig from "../../urlConfig";

export function breederApi() {
  return axios({
    method: "get",
    url: urlConfig.getBreeder
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
    materialStateID,
    isolated,
    plannedDate,
    expectedDate,
    nrOfPlates,
    nrOfTests,
    remark,
    forced
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
      remark,
      forced
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

export function plantsTestsApi(action) {
  const {
    plannedDate,
    cropCode,
    materialTypeID,
    isolated,
    expectedDate
  } = action;
  return axios({
    method: "get",
    url: urlConfig.getPlatestTest,

    params: {
      plannedDate,
      cropCode,
      materialTypeID,
      isolated,
      expectedDate
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
    nrOfPlates,
    nrOfTests,
    forced,
    expectedDate,
    plannedDate
  } = action;
  return axios({
    method: "post",
    url: urlConfig.postSlotEdit,

    data: {
      slotID,
      nrOfPlates,
      nrOfTests,
      forced,
      expectedDate,
      plannedDate
    }
  });
}
