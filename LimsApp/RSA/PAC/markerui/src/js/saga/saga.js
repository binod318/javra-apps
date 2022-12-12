import { all, takeLatest, takeEvery } from "redux-saga/effects"; // take

import {
  planningYear,
  planningCapacity,
  planningUpdate,
} from "../containers/LabCapacity/labSaga";
import {
  YEAR_FETCH,
  LAB_DATA_FETCH,
  LAB_DATA_UPDATE,
} from "../containers/LabCapacity/labAction";

import { PLANNING_PRINT_PLATE_LABEL } from "../containers/LabPreparation/labPreparationAction";
import {
  labPreparationPeriod,
  labPreparationFolder,
  labDeclusterResult,
  reservePlatestInLIMS,
  getMinimumTestStatus,
  sendToLims,
  printPlateLabels,
} from "../containers/LabPreparation/labPreparationSaga";

import {
  capacitySOPeriod,
  capacitySO,
  capacitySOUpdate,
} from "../containers/CapacitySO/capacitySOSaga";
import {
  PERIOD_FETCH,
  CAPACITY_DATA_FETCH,
  CAPACITY_DATA_UPDATE,
} from "../containers/CapacitySO/capacitySOAction";

import {
  planningSOPeriod,
  planningDeterminationAssignment,
  planningAutoplan,
  planningDeterminationConfirmPlan,
} from "../containers/PlanningBatchesSO/planningBatchesSOSaga";

import {
  markerPerVariety,
  getMarkers,
  getVarieties,
  getCrops,
  postMarkerPerVarieties,
} from "../containers/MarkerPerVariety/markerPerVarietySaga";
import {
  MARKER_PER_VARIETY_FETCH,
  GET_MARKER_FETCH,
  GET_VARIETIES_FETCH,
  GET_CROPS_FETCH,
  POST_MARKERPERVARIETY,
} from "../containers/MarkerPerVariety/markerPerVarietyAction";

import {
  getCriteriaPerCrop,
  postCriteriaPerCrop,
} from "../containers/CriteriaPerCrop/criteriaPerCropSaga";
import {
  CRITERIA_PER_CROP_FETCH,
  POST_CRITERIA_PER_CROP,
} from "../containers/CriteriaPerCrop/criteriaPerCropAction";

import {
  labResultFetch,
  labPlatePositionFetch,
  labResultPeriodFetch,
  determinationAssignmentsFetch,
  determinationAssignmentsDetailFetch,
  approvalDetAssignment,
  reTestDetAssignment,
  saveRemarks,
  savePatternRemarks
} from "../containers/LabResult/labResultSaga";
import {
  LAB_RESULT_FETCH,
  LAB_PLATE_POSITION_FETCH,
  LABRESULT_PEROID_FETCH,
  LAB_RESULT_DETERMINATION_ASS_FETCH,
  LAB_RESULT_DETERMINATION_ASS_DETAIL_FETCH,
  LAB_RESULT_DETAIL_APPROVE,
  LAB_RESULT_DETAIL_RETEST,
  SAVE_REMARKS,
  SAVE_PATTERN_REMARKS,
} from "../containers/LabResult/labResultAction";

import { fetchPage, exportPage } from "../containers/TotalPAC/TotalPACSaga";
import { FETCH_PAGE, EXPORT_PAGE } from "../containers/TotalPAC/TotalPACAction";

export default function* rootSaga() {
  yield all([
    yield takeEvery(YEAR_FETCH, planningYear),
    yield takeEvery(LAB_DATA_FETCH, planningCapacity),
    yield takeLatest(LAB_DATA_UPDATE, planningUpdate),

    yield takeEvery(PERIOD_FETCH, capacitySOPeriod),
    yield takeEvery(CAPACITY_DATA_FETCH, capacitySO),
    yield takeEvery(CAPACITY_DATA_UPDATE, capacitySOUpdate),

    yield takeEvery("LABPREPARATION_PERIOND_FETCH", labPreparationPeriod),
    yield takeEvery("LABPREPARATION_FOLDER_FETCH", labPreparationFolder),
    yield takeEvery("LABDECLUSTER_FETCH", labDeclusterResult),
    yield takeEvery("RESERVE_PLATES_LIMS", reservePlatestInLIMS),
    yield takeEvery("TEST_STATUS_FETCH", getMinimumTestStatus),
    yield takeLatest("PLANNING_SEND_TO_LIMS", sendToLims),
    yield takeLatest(PLANNING_PRINT_PLATE_LABEL, printPlateLabels),

    yield takeEvery("PLANNING_PERIOND_FETCH", planningSOPeriod),
    yield takeLatest(
      "PLANNING_DETERMINATION_FETCH",
      planningDeterminationAssignment
    ),
    yield takeLatest("AUTOPLAN_DETERMINATION_FETCH", planningAutoplan),
    yield takeLatest("PLANNING_CONFIRM_POST", planningDeterminationConfirmPlan),

    // Marker per vairety
    yield takeLatest(MARKER_PER_VARIETY_FETCH, markerPerVariety),
    yield takeLatest(GET_MARKER_FETCH, getMarkers),
    yield takeLatest(GET_VARIETIES_FETCH, getVarieties),
    yield takeLatest(GET_CROPS_FETCH, getCrops),
    yield takeLatest(POST_MARKERPERVARIETY, postMarkerPerVarieties),

    // Criteria Per Crop
    yield takeLatest(CRITERIA_PER_CROP_FETCH, getCriteriaPerCrop),
    yield takeLatest(POST_CRITERIA_PER_CROP, postCriteriaPerCrop),

    // Lab Result
    yield takeLatest(LAB_RESULT_FETCH, labResultFetch),
    yield takeLatest(LAB_PLATE_POSITION_FETCH, labPlatePositionFetch),
    yield takeLatest(LABRESULT_PEROID_FETCH, labResultPeriodFetch),
    yield takeLatest(
      LAB_RESULT_DETERMINATION_ASS_FETCH,
      determinationAssignmentsFetch
    ),
    yield takeLatest(
      LAB_RESULT_DETERMINATION_ASS_DETAIL_FETCH,
      determinationAssignmentsDetailFetch
    ),
    yield takeLatest(LAB_RESULT_DETAIL_APPROVE, approvalDetAssignment),
    yield takeLatest(LAB_RESULT_DETAIL_RETEST, reTestDetAssignment),
    yield takeLatest(SAVE_REMARKS, saveRemarks),
    yield takeLatest(SAVE_PATTERN_REMARKS, savePatternRemarks),

    // Total PAC
    yield takeLatest(FETCH_PAGE, fetchPage),
    yield takeLatest(EXPORT_PAGE, exportPage),
  ]);
}
