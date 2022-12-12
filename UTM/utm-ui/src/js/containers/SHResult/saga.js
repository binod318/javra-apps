import { call, takeLatest, put } from "redux-saga/effects";
import {
  notificationSuccessTimer
} from "../../saga/notificationSagas";
import {
  getTraitDeterminationResultSHApi,
  postTraitDeterminationResultSHApi,
} from "./api";
import {
  storeSHResult,
  storeSHTotal,
  storeSHPage,
  SHResultFilterBluk,
  showNotification
} from "./action";
import { show, hide } from "../../helpers/helper";

function* getSHResult(action) {
  try {
    console.log('getSHResult',action);
    yield put(show("getSHResult"));
    const { pageNumber, pageSize, filter } = action;
    const result = yield call(
      getTraitDeterminationResultSHApi,
      pageNumber,
      pageSize,
      filter
    );
    yield put(SHResultFilterBluk(filter));
    yield put(storeSHResult(result.data.data));
    yield put(storeSHPage(pageNumber));
    yield put(storeSHTotal(result.data.totalRows));
    yield put(hide("getSHResult"));
  } catch (e) {
    yield put(hide("getSHResult"));
    if (e.response.data) {
      const error = e.response.data;
      const { code, errorType, message } = error;
      yield put(showNotification(message, errorType, code));
    }
  }
}
export function* watchGetSHResult() {
  yield takeLatest("GET_SH_RESULT", getSHResult);
}

function* postSHResult(action) {
  try {
    yield put(show("postSHResult"));
    const result = yield call(postTraitDeterminationResultSHApi, action.data);
    yield put(hide("postSHResult"));
    if (result.data) {
      yield put(storeSHResult(result.data.data));
      yield put(storeSHPage(action.data.pageNumber || 1));
      yield put(storeSHTotal(result.data.totalRows));

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
    yield put(hide("postSHResult"));
    if (e.response.data) {
      const error = e.response.data;
      const { code, errorType, message } = error;
      yield put(showNotification(message, errorType, code));
    }
  }
}
export function* watchPostSHResult() {
  yield takeLatest("POST_SH_RESULT", postSHResult);
}