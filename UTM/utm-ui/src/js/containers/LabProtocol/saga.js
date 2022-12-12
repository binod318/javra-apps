import { call, takeLatest, put, select } from "redux-saga/effects";
import { show, hide } from "../../helpers/helper";
import { noInternet, notificationMsg } from "../../saga/notificationSagas";
import { getProtocolApi, postProtocolApi, postSaveProtocolApi } from "./api";

function* getProtocol() {
  try {
    yield put(show("getProtocol"));

    const result = yield call(getProtocolApi);
    if (result.status === 200) {
      yield put({
        type: "PROTOCOL_BULK",
        data: result.data
      });
    }

    yield put(hide("getProtocol"));
  } catch (e) {
    yield put(hide("getProtocol"));
  }
}
export function* watchGetProtocol() {
  yield takeLatest("GET_PROTOCOL", getProtocol);
}

function* postSaveProtocol(action) {
  try {
    yield put(show("postProtocol"));

    const result = yield call(postSaveProtocolApi, action.obj);

    if (result.status === 200) {
      const getLabPara = state => state.labProtocol;
      const labPara = yield select(getLabPara);

      yield put({
        type: "POST_PROTOCOL_LIST",
        filter: labPara.filter,
        pageNumber: labPara.total.pageNumber,
        pageSize: labPara.total.pageSize
      });
    }

    yield put(hide("postProtocol"));
  } catch (e) {
    yield put(hide("postProtocol"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchPostSaveProtocol() {
  yield takeLatest("POST_PROTOCOL", postSaveProtocol);
}

function* postProtocolList(action) {
  try {
    yield put(show("postProtocolList"));

    const result = yield call(postProtocolApi, action);

    if (result.status === 200) {
      const { data, total } = result.data;
      const { pageNumber, filter } = action;
      yield put({ type: "FILTER_PROTOCOL_ADD_BLUK", filter });
      yield put({ type: "MAINTAIN_RECORDS", total });
      yield put({ type: "MAINTAIN_PAGE", pageNumber });
      yield put({ type: "MANITAIN_LIST_BULK", data });
      yield put({ type: "MAINTAIN_REFRESH_TOGGLE" });
    }

    yield put(hide("postProtocolList"));
  } catch (e) {
    yield put(hide("postProtocolList"));
  }
}
export function* watchPostProtocolList() {
  yield takeLatest("POST_PROTOCOL_LIST", postProtocolList);
}
