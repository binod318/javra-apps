import { call, takeLatest, put } from "redux-saga/effects";
import {
  // notificationSuccess,
  notificationSuccessTimer
} from "../../saga/notificationSagas";
import {
  getTraitDeterminationResultRDTApi,
  postTraitDeterminationResultRDTApi,
  getMappingColumnsApi,
  getMaterialStatusApi
} from "./api";
import {
  storeRDTResult,
  storeRDTTotal,
  storeRDTPage,
  RDTResultFilterBluk,
  showNotification
} from "./action";
import { show, hide } from "../../helpers/helper";

function* getRDTResult(action) {
  try {
    yield put(show("getResult"));
    const { pageNumber, pageSize, filter } = action;
    const result = yield call(
      getTraitDeterminationResultRDTApi,
      pageNumber,
      pageSize,
      filter
    );
    yield put(RDTResultFilterBluk(filter));
    yield put(storeRDTResult(result.data.data));
    yield put(storeRDTPage(pageNumber));
    yield put(storeRDTTotal(result.data.totalRows));
    yield put(hide("getResult"));
  } catch (e) {
    yield put(hide("getResult"));
    if (e.response.data) {
      const error = e.response.data;
      const { code, errorType, message } = error;
      yield put(showNotification(message, errorType, code));
    }
  }
}
export function* watchGetRDTResult() {
  yield takeLatest("GET_RDT_RESULT", getRDTResult);
}

function* postRDTResult(action) {
  try {
    yield put(show("postRDTResult"));
    const result = yield call(postTraitDeterminationResultRDTApi, action.data);
    yield put(hide("postRDTResult"));
    if (result.data) {
      yield put(storeRDTResult(result.data.data));
      yield put(storeRDTPage(action.data.pageNumber || 1));
      yield put(storeRDTTotal(result.data.totalRows));

      const mode = action.data.data[0].action || "";
      let msg = "";
      switch (mode) {
        case "D":
          msg = "Result was removed successfully";
          break;
        case "U":
          msg = "Result was updated successfully";
          break;
        default:
          msg = "Result was created successfully.";
      }
      yield put(notificationSuccessTimer(msg));
    }
  } catch (e) {
    yield put(hide("postRDTResult"));
    if (e.response.data) {
      const error = e.response.data;
      const { code, errorType, message } = error;
      yield put(showNotification(message, errorType, code));
    }
  }
}
export function* watchPostRDTResult() {
  yield takeLatest("POST_RDT_RESULT", postRDTResult);
}

function* getMaterialStatus() {
  try {
    const result = yield call(getMaterialStatusApi);
    if (result.status === 200) {
      yield put({
        type: "RDT_MATERIAL_STATUS_BLUK",
        data: result.data
      });
    }
  } catch (e) {
    if (e.response.data) {
      const error = e.response.data;
      const { code, errorType, message } = error;
      yield put(showNotification(message, errorType, code));
    }
  }
}
export function* watchGetMaterialStatus() {
  yield takeLatest("GET_RDT_MATERIAL_STATUS", getMaterialStatus);
}
function* getMappingColumns() {
  try {
    const result = yield call(getMappingColumnsApi);
    if (result.status === 200) {
      yield put({
        type: "RDT_MAPPINT_COLUMNS_BLUK",
        data: result.data
      });
    }
  } catch (e) {
    if (e.response.data) {
      const error = e.response.data;
      const { code, errorType, message } = error;
      yield put(showNotification(message, errorType, code));
    }
  }
}
export function* watchGetMappingColumns() {
  yield takeLatest("GET_RDT_MAPPING_COLUMNS", getMappingColumns);
}
