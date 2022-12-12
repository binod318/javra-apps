import { call, put, takeLatest, select } from "redux-saga/effects";

import { getMailApi, postMailApi, deleteMailApi } from "./api";
import {
  mailProcessing,
  mailSuccess,
  mailError,
  mailBulk,
  mailRecords,
  mailRefresh,
  fetchMailData
} from "./action";

function* getMail(action) {
  try {
    yield put(mailProcessing());
    const { pageNumber, pageSize } = action;

    const result = yield call(getMailApi, pageNumber, pageSize);
    const { data } = result;

    yield put(mailBulk(data.data));
    yield put(mailRecords(data.total));
    yield put(mailRefresh());

    yield put(mailSuccess());
  } catch (e) {
    const { message } = e;
    yield put(mailError(message));
  }
}
export function* watchGetMail() {
  yield takeLatest("GET_MAIL", getMail);
}

function* postMail(action) {
  try {
    const { configID, configGroup, cropCode, recipients } = action;
    yield put(mailProcessing());

    const result = yield call(
      postMailApi,
      configID,
      configGroup,
      cropCode,
      recipients
    );

    if (result.data) {
      const pageNumber = yield select(state => state.mail.total.pageNumber);
      const pageSize = yield select(state => state.mail.total.pageSize);

      yield put(fetchMailData(pageNumber, pageSize));
    }
  } catch (e) {
    const { response } = e;
    const { message } = response.data;
    yield put(mailError(message));
  }
}
export function* watchpostMail() {
  yield takeLatest("POST_MAIL", postMail);
}

function* deleteMail(action) {
  try {
    yield put(mailProcessing());
    const result = yield call(deleteMailApi, action.configID);

    if (result.data) {
      const pageSize = yield select(state => state.mail.total.pageSize);

      yield put(fetchMailData(1, pageSize));
    }
    yield put(mailSuccess());
  } catch (e) {
    const { message } = e;
    const { data } = e.response;
    yield put(mailError(data.message));
  }
}
export function* watchDeleteMail() {
  yield takeLatest("DELETE_MAIL", deleteMail);
}
