import { call, takeLatest, put } from "redux-saga/effects";
import {
  notificationSuccess,
  notificationSuccessTimer,
} from "../../saga/notificationSagas";
import {
  getTraitRelationApi,
  postTraitRelationApi,
  getTraitValuesApi,
  getCheckValidationApi,
} from "./api";
import {
  storeResult,
  storeTotal,
  showNotification,
  // storeAppend,
  storePage,
  storeTraitValues,
  storeCheckValidtion,
  ResultFilterBluk,
} from "./action";
import { show, hide } from "../../helpers/helper";

function* getResult(action) {
  try {
    yield put(show("getResult"));
    const { pageNumber, pageSize, filter } = action;
    const result = yield call(
      getTraitRelationApi,
      pageNumber,
      pageSize,
      filter
    );
    yield put(ResultFilterBluk(filter));
    yield put(storeResult(result.data.data));
    yield put(storePage(pageNumber));
    yield put(storeTotal(result.data.totalRows));
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
export function* watchGetResult() {
  yield takeLatest("GET_RESULT", getResult);
}

function* getTraitValues(action) {
  try {
    yield put(show("getTraitValues"));
    const { cropCode, traitID, cropTraitID } = action;
    const result = yield call(
      getTraitValuesApi,
      cropTraitID,
      cropCode,
      traitID
    );

    if (result.status === 200) {
      yield put(storeTraitValues(result.data));
    }

    yield put(hide("getTraitValues"));
  } catch (e) {
    yield put(hide("getTraitValues"));
    if (e.response.data) {
      const error = e.response.data;
      const { code, errorType, message } = error;
      yield put(showNotification(message, errorType, code));
    }
  }
}
export function* watchGetTraitValues() {
  yield takeLatest("FETCH_TRAITVALUES", getTraitValues);
}

function* getCheckValidation(action) {
  try {
    const { source } = action;
    const result = yield call(getCheckValidationApi, source);
    const { data } = result;
    if (data.length === 0) {
      const msg = "No result mapping missing.";
      yield put(notificationSuccess(msg));
    } else {
      yield put(storeCheckValidtion(data));
    }
  } catch (e) {
    if (e.response.data) {
      const error = e.response.data;
      const { code, errorType, message } = error;
      yield put(showNotification(message, errorType, code));
    }
  }
}
export function* watchGetCheckValidation() {
  yield takeLatest("getCheckValidation", getCheckValidation);
}

function* postResult(action) {
  try {
    yield put(show("postResult"));

    const result = yield call(postTraitRelationApi, action.data);
    yield put(hide("postResult"));
    if (result.data) {
      yield put(storeResult(result.data.data));
      yield put(storePage(action.data.pageNumber || 1));
      yield put(storeTotal(result.data.totalRows));

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
    yield put(hide("postResult"));
    if (e.response.data) {
      const error = e.response.data;
      const { code, errorType, message } = error;
      yield put(showNotification(message, errorType, code));
    }
  }
}
export function* watchPostResult() {
  yield takeLatest("POST_RESULT", postResult);
}
