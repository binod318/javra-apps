import { takeLatest, call, put, select } from "redux-saga/effects";
import { noInternet, notificationMsg } from "../../saga/notificationSagas";
import { show, hide } from "../../helpers/helper";

import {
  MAIL_CONFIG_FETCH,
  MAIL_CONFIG_APPEND,
  MAIL_CONFIG_DESTORY
} from "./mailConstant";
import {
  mailConfigFetchApi,
  mailConfigAppendApi,
  mailConfigDeleteApi
} from "./mailApi";

/**
 * Fetch Availabel Mail Config
 * Action / Act
 */
function* mailConfigFetch(action) {
  try {
    yield put(show("mailConfigFetch"));

    const { pageNumber, pageSize, usedForMenu } = action;

    const result = yield call(mailConfigFetchApi, pageNumber, pageSize, usedForMenu);
    const { data, status } = result;
    if (status === 200) {
      yield put({ type: "MAIL_BULK", data: data.data });
      yield put({ type: "MAIL_RECORDS", total: data.total });
      yield put({ type: "MAIL_PAGE", pageNumber });
    }
    yield put(hide("mailConfigFetch"));
  } catch (e) {
    yield put(hide("mailConfigFetch"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchMailConfigFetch() {
  yield takeLatest(MAIL_CONFIG_FETCH, mailConfigFetch);
}

/**
 * Append New Mail
 */
function* mailConfigAdd(action) {
  try {
    yield put(show("mailConfigAdd"));

    const {
      configID,
      cropCode,
      configGroup,
      recipients,
      brStationCode,
      usedForMenu
    } = action;

    const result = yield call(
      mailConfigAppendApi,
      configID,
      cropCode,
      configGroup,
      recipients,
      brStationCode
    );
    if (result.data) {
      const pageNumber = yield select(
        (state) => state.mailResult.total.pageNumber
      );
      const pageSize = yield select((state) => state.mailResult.total.pageSize);

      yield put({
        type: MAIL_CONFIG_FETCH,
        pageNumber,
        pageSize,
        usedForMenu
      });
    }
    yield put(hide("mailConfigAdd"));
  } catch (e) {
    yield put(hide("mailConfigAdd"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchMailConfigAdd() {
  yield takeLatest(MAIL_CONFIG_APPEND, mailConfigAdd);
}

/**
 * Update Existing Mail
 */

/**
 * Destroy Mail
 */
function* mailConfigDelete(action) {
  try {
    yield put(show("mailConfigDelete"));

    const { configID, usedForMenu } = action;

    const result = yield call(mailConfigDeleteApi, configID);

    if (result.data) {
      const pageSize = yield select((state) => state.mailResult.total.pageSize);

      yield put({ type: "MAIL_PAGE", pageNumber: 1 });
      yield put({ type: MAIL_CONFIG_FETCH, pageNumber: 1, pageSize, usedForMenu });
    }

    yield put(hide("mailConfigDelete"));
  } catch (e) {
    yield put(hide("mailConfigDelete"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchMailConfigDelete() {
  yield takeLatest(MAIL_CONFIG_DESTORY, mailConfigDelete);
}
