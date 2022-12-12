import { call, takeLatest, put } from "redux-saga/effects";
import { saveConfigNameApi } from "../api/index";
import { notificationSuccessTimer } from "../../../saga/notificationSagas";

function* saveConfigName(action) {
  try {
    yield call(saveConfigNameApi, action);
    yield put({
      type: "FILELIST_SET_CONFIGNAME",
      testID: action.testID,
      name: action.name
    });
    yield put(notificationSuccessTimer("Configuration name successfully saved."));
  } catch (err) {
    console.log(err);
  }
  return null;
}
export function* watchsaveConfigName() {
  yield takeLatest("SAVE_CONFIGNAME", saveConfigName);
}
