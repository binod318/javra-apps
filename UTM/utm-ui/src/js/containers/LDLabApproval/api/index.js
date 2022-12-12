import axios from "axios";
import urlConfig from "../../../urlConfig";

export const getLDApprovalListApi = (periodID, siteID) =>
  axios({
    method: "get",
    url: urlConfig.getLDApprovalListForLab,

    params: {
      periodID,
      siteID
    }
  });

export const getLDPlanPeriodsApi = () =>
  axios({
    method: "get",
    url: urlConfig.getPlanPeriods
  });

export const approveLDSlotApi = (slotID, forced) =>
  axios({
    method: "post",
    url: urlConfig.approveSlot,
    data: {
      slotID,
      forced
    }
  });

export const denyLDSlotApi = slotID =>
  axios({
    method: "post",
    url: urlConfig.denySlot,

    params: {
      slotID
    }
  });

export const updateLDSlotPeriodApi = (slotID, plannedDate) =>
  axios({
    method: "put",
    url: urlConfig.updateSlotPeriodLeafDisk,

    data: {
      slotID,
      plannedDate
    }
  });
