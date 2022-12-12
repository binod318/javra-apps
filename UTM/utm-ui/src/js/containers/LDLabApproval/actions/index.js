export const getLDApprovalList = (periodID, siteID) => ({
  type: "GET_LD_APPROVAL_LIST",
  periodID,
  siteID
});

export const getLDApprovalListDone = data => ({
  type: "GET_LD_APPROVAL_LIST_DONE",
  data
});

export const getLDPlanPeriods = () => ({
  type: "GET_LD_PLAN_PERIODS"
});

export const getLDPlanPeriodsDone = data => ({
  type: "GET_LD_PLAN_PERIODS_DONE",
  data
});

export const approveLDSlot = (slotID, selectedPeriodID, siteID, forced) => ({
  type: "LD_APPROVE_SLOT",
  slotID,
  selectedPeriodID,
  siteID,
  forced
});

export const denyLDSlot = (slotID, selectedPeriodID, siteID) => ({
  type: "LD_DENY_SLOT",
  slotID,
  selectedPeriodID,
  siteID
});

export const updateLDSlotPeriod = (
  slotID,
  periodID,
  siteID,
  plannedDate
) => ({
  type: "UPDATE_LD_SLOT_PERIOD",
  slotID,
  periodID,
  siteID,
  plannedDate
});
