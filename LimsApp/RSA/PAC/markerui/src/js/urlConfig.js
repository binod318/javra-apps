const serverUrl = `${window.services.ServiceUrl}/api/v1/`;

const urlConfig = {
  // ## From Master Section
  planingYear: `${serverUrl}Master/GetYear`,
  capacityPeriod: `${serverUrl}Master/Getperiod`,
  getCrops: `${serverUrl}Master/getCrops`,
  getMarker: `${serverUrl}Master/GetMarkers`,
  getVarieties: `${serverUrl}Master/GetVarieties`,

  // ## Lab Capacity
  planingCapacity: `${serverUrl}PacCapacity/GetPACLabCapacity`,
  postPlaningCapacity: `${serverUrl}PacCapacity/SavePACLabCapacity`,

  // ## Lab Preparation
  labPreparationGet: `${serverUrl}Test/GetFolderDetails`,
  labDeclusterResult: `${serverUrl}Test/GetDeclusterResult`,
  reservePlatestInLIMS: `${serverUrl}Test/ReservePlatesInLIMS`,
  getMinimumTestStatus: `${serverUrl}Test/GetMinimumTestStatus`,
  postSendToLMS: `${serverUrl}Test/SendToLIMS`,
  getPlatePlanOverview: `${serverUrl}Test/PlatePlanOverview`,
  postPrintPlateLabel: `${serverUrl}Test/printPlateLabels`,

  // ## Capacity Planning SO
  planningCapacitySO: `${serverUrl}PacCapacity/GetPACPlanningCapacitySO`,
  postPlanningCapacitySO: `${serverUrl}PacCapacity/SavePACPlanningCapacitySO`,

  getPlanningDeterminationAssignment: `${serverUrl}DeterminationAssignments`,
  postDeterminationAssignmentsAutoPlan: `${serverUrl}DeterminationAssignments/AutomaticalPlan`,
  postDeterminationAssignmentsConfirmPlan: `${serverUrl}DeterminationAssignments/confirmplanning`,

  // ## Marker Per Varieties
  getMarkerPerVarieties: `${serverUrl}MarkerPerVariety/GetMarkerPerVarieties`,
  postMarkerPerVarieties: `${serverUrl}MarkerPerVariety/SaveMarkerPerVarieties`,

  // ## Criteria Per Crop
  getCriteriaPerCrop: `${serverUrl}criteriapercrop/getdata`,
  postCriteriaPerCrop: `${serverUrl}criteriapercrop`,

  // ## Lab Results
  getPlanningDeterminationAssignmentOverview: `${serverUrl}DeterminationAssignments/Overview`,
  getDeterminationAssignments: `${serverUrl}DeterminationAssignments/decision`,
  getDeterminationAssignmentsDecisionDetail: `${serverUrl}DeterminationAssignments/decisiondetail`,
  postApprovalDetAssignment: `${serverUrl}DeterminationAssignments/ApproveDetAssignment`,
  postReTestDetAssignment: `${serverUrl}DeterminationAssignments/ReTestDetAssignment`,
  remarks: `${serverUrl}DeterminationAssignments/UpdateRemarks`,
  patternRemarks: `${serverUrl}DeterminationAssignments/savepatternremarks`,
  getLabPlatePosition: `${serverUrl}DeterminationAssignments/platespositions`,

  // ## POST Batch Over View
  postBatchOverView: `${serverUrl}Test/BatchOverview`,
  exportExcel: `${serverUrl}Test/GetExcel`,
};
export default urlConfig;
