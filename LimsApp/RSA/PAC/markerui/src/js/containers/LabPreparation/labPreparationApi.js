import axios from "axios";
import urlConfig from "../../urlConfig";

export const labPreparationPeriodAPI = (year) => {
  return axios({
    method: "get",
    url: urlConfig.capacityPeriod,

    params: { year },
  });
};

export const labPreparationFolderAPI = (periodID) => {
  return axios({
    method: "get",
    url: urlConfig.labPreparationGet,
    params: { periodID },
  });
};

export const labDeclusterResultAPI = (periodID, detAssignmentID) => {
  return axios({
    method: "get",
    url: urlConfig.labDeclusterResult,
    params: { periodID, detAssignmentID },
  });
};

export const reservePlatestInLIMSAPI = (periodID) => {
  return axios({
    method: "post",
    url: urlConfig.reservePlatestInLIMS,
    data: { periodID },
  });
};

export const getMinimumTestStatusAPI = (periodID) => {
  return axios({
    method: "get",
    url: urlConfig.getMinimumTestStatus,
    params: { periodID },
  });
};

export const sendToLimsAPI = (PeriodID) =>
  axios({
    method: "post",
    url: urlConfig.postSendToLMS,
    data: { PeriodID },
  });

/**
 * This opens a new tap / window with arrange url below
 * @param {period id} periodID
 */
export const platePlanOverViewAPI = (periodID) => {
  window.open(
    `${urlConfig.getPlatePlanOverview}?periodID=${periodID}`,
    "_blank"
  );
};

export const printPlateLabelsAPI = ({ PeriodID, TestID }) =>
  axios({
    method: "post",
    url: urlConfig.postPrintPlateLabel,
    data: { PeriodID, TestID },
  });
