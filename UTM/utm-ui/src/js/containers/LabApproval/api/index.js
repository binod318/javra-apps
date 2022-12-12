/**
 * Created by sushanta on 3/14/18.
 */
import axios from "axios";
import urlConfig from "../../../urlConfig";

export const getApprovalListApi = periodID =>
  axios({
    method: "get",
    url: urlConfig.getApprovalListForLab,

    params: {
      periodID
    }
  });

export const getPlanPeriodsApi = () =>
  axios({
    method: "get",
    url: urlConfig.getPlanPeriods
  });

export const approveSlotApi = (slotID, forced) =>
  axios({
    method: "post",
    url: urlConfig.approveSlot,
    data: {
      slotID,
      forced
    }
  });

export const denySlotApi = slotID =>
  axios({
    method: "post",
    url: urlConfig.denySlot,

    params: {
      slotID
    }
  });

export const updateSlotPeriodApi = (slotID, plannedDate, expectedDate) =>
  axios({
    method: "put",
    url: urlConfig.updateSlotPeriod,

    data: {
      slotID,
      plannedDate,
      expectedDate
    }
  });
