export const YEAR_FETCH = "YEAR_FETCH";
export const YEAR_ADD = "YEAR_ADD";
export const CAPACITY_YEAR_SELECT = "CAPACITY_YEAR_SELECT";

export const LAB_RESULT_PERIOD_FETCH = "LAB_RESULT_PERIOD_FETCH";
export const LAB_RESULT_PERIOD_ADD = "LAB_RESULT_PERIOD_ADD";
export const LAB_RESULT_PERIOD_SELECT = "LAB_RESULT_PERIOD_SELECT";

export const SAVE_REMARKS = "SAVE_REMARKS";
export const SAVE_REMARKS_SUCCEEDED = "SAVE_REMARKS_SUCCEEDED";

export const PATTERN_REMARK_CHANGE = "PATTERN_REMARK_CHANGE";
export const SAVE_PATTERN_REMARKS = "SAVE_PATTERN_REMARKS";
export const SAVE_PATTERN_REMARKS_SUCCEEDED = "SAVE_PATTERN_REMARKS_SUCCEEDED";
export const APPROVE_RETEST_SUCCEEDED = "APPROVE_RETEST_SUCCEEDED";
export const RESET_APPROVE_RETEST = "RESET_APPROVE_RETEST";

// SAGA
export const YearFetch = () => ({ type: YEAR_FETCH });

export const LAB_RESULT_YEAR_SELECT = "LAB_RESULT_YEAR_SELECT";
export const labResultYearSelected = (selected) => ({
  type: LAB_RESULT_YEAR_SELECT,
  selected,
});

export const LABRESULT_PEROID_FETCH = "LABRESULT_PEROID_FETCH";
export const labResultPeriodFetch = (year) => ({
  type: LABRESULT_PEROID_FETCH,
  year,
});

export const capacityYearData = (data) => ({ type: YEAR_ADD, data });
export const capacityPeriodData = (data) => ({
  type: LAB_RESULT_PERIOD_ADD,
  data,
});
export const capacityPeriodSelect = (selected) => ({
  type: LAB_RESULT_PERIOD_SELECT,
  selected: selected || "",
});

// labResultfetch
export const LAB_RESULT_FETCH = "LAB_RESULT_FETCH";
export const labResultfetchActionCreator = (periodID) => ({
  type: LAB_RESULT_FETCH,
  periodID,
});

// labPlatePostionfetch
export const LAB_PLATE_POSITION_FETCH = "LAB_PLATE_POSITION_FETCH";
export const labPlatePositionFetchAction = (patternID) => ({
  type: LAB_PLATE_POSITION_FETCH,
  patternID,
});

export const LAB_RESULT_DETERMINATION_ASS_FETCH =
  "LAB_RESULT_DETERMINATION_ASS_FETCH";
export const labResutDeterminationAss = (id) => ({
  type: LAB_RESULT_DETERMINATION_ASS_FETCH,
  id,
});

export const LAB_RESULT_DETERMINATION_ASS_DETAIL_FETCH =
  "LAB_RESULT_DETERMINATION_ASS_DETAIL_FETCH";
export const labResutDeterminationAssDetail = (id, sortBy, sortOrder) => ({
  type: LAB_RESULT_DETERMINATION_ASS_DETAIL_FETCH,
  id,
  sortBy,
  sortOrder
});

export const LAB_RESULT_DETAIL_APPROVE = "LAB_RESULT_DETAIL_APPROVE";
export const labResultDetailApprove = (id) => ({
  type: LAB_RESULT_DETAIL_APPROVE,
  id,
});
export const LAB_RESULT_DETAIL_RETEST = "LAB_RESULT_DETAIL_RETEST";
export const labResultDetailReTest = (id) => ({
  type: LAB_RESULT_DETAIL_RETEST,
  id,
});

export const saveRemarks = (payload) => ({
  type: SAVE_REMARKS,
  payload,
});

export const saveRemarksSucceeded = (remarks) => ({
  type: SAVE_REMARKS_SUCCEEDED,
  remarks,
});

export const patternRemarkChange = (index, key, value) => ({
  type: PATTERN_REMARK_CHANGE,
  index,
  key,
  value
});

export const savePatternRemarks = (payload) => ({
  type: SAVE_PATTERN_REMARKS,
  payload,
});

export const savePatternRemarksSucceeded = () => ({
  type: SAVE_PATTERN_REMARKS_SUCCEEDED
});

export const approveRetestSucceeded = () => ({
  type: APPROVE_RETEST_SUCCEEDED
});

export const resetApproveRetest = () => ({
  type: RESET_APPROVE_RETEST
});