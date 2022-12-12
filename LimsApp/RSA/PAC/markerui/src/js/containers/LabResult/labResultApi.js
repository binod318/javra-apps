import axios from "axios";
import urlConfig from "../../urlConfig";

export const labResultfetchAPI = ({
  PageNr,
  PageSize,
  SortBy,
  SortOrder,
  Filters,
}) =>
  axios({
    method: "post",
    url: urlConfig.getPlanningDeterminationAssignmentOverview,
    data: {
      Filters,
      PageNr,
      PageSize,
      SortBy,
      SortOrder,
    },
  });

export const labResultPeriodAPI = (year) =>
  axios({
    method: "get",
    url: urlConfig.capacityPeriod,
    params: { year },
  });

// getDeterminationAssignments
export const determinationAssignmentsAPI = (id) =>
  axios({
    method: "get",
    url: urlConfig.getDeterminationAssignments,
    params: { id },
  });

// getDeterminationAssignments
export const determinationAssignmentsDecisionDetailAPI = (action) =>
  axios({
    method: "post",
    url: urlConfig.getDeterminationAssignmentsDecisionDetail,
    data:
    {
      detAssignmentID: action.id,
      sortBy: action.sortBy,
      sortOrder: action.sortOrder
    }
  });

export const approvalDetAssignmentAPI = (detAssignmentID) =>
  axios({
    method: "post",
    url: urlConfig.postApprovalDetAssignment,
    data: { detAssignmentID },
  });

export const reTestDetAssignmentAPI = (detAssignmentID) =>
  axios({
    method: "post",
    url: urlConfig.postReTestDetAssignment,
    data: { detAssignmentID },
  });

export const saveRemarksAPI = (payload) =>
  axios({
    method: "post",
    url: urlConfig.remarks,
    data: payload,
  })
    .then((response) => response)
    .catch((error) => error.response);

export const savePatternRemarksAPI = (payload) =>
  axios({
    method: "post",
    url: urlConfig.patternRemarks,
    data: payload,
  })
    .then((response) => response)
    .catch((error) => error.response);

export const labPlatePositionFetchAPI = (patternID) =>
  axios({
    method: "get",
    url: urlConfig.getLabPlatePosition,
    params: { patternID },
  });