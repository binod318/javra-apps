import { call, put, takeLatest } from "redux-saga/effects";
import {
  getRelationApi,
  getRelationDeterminationApi,
  postRelationApi
} from "./api";
import {
  relationProcessing,
  relationSuccess,
  relationError,
  updateProcessing,
  updateSuccess,
  storeSort,
  storeDetermination,
  storeRelation,
  storeTotal,
  storePage
} from "./action";

function* getRelation(action) {
  try {
    const { pageNumber, pageSize, filter, sorting } = action;
    yield put(relationProcessing());
    const result = yield call(
      getRelationApi,
      pageNumber,
      pageSize,
      filter,
      sorting
    );

    yield put(storeRelation(result.data.data));
    yield put(storePage(pageNumber));
    yield put(storeTotal(result.data.totalRows));
    yield put(storeSort(sorting.name, sorting.direction));

    yield put(relationSuccess());
  } catch (e) {
    const { message } = e;
    yield put(relationError("relaton", message));
  }
}
export function* watchGetRelation() {
  yield takeLatest("GET_RELATION", getRelation);
}

function* getDetermination(action) {
  try {
    const { determinationName, cropCode } = action;

    const result = yield call(
      getRelationDeterminationApi,
      determinationName,
      cropCode
    );
    yield put(storeDetermination(result.data));
  } catch (e) {
    console.log(e);
  }
}
export function* watchGetDetermination() {
  yield takeLatest("FETCH_DETERMINATION", getDetermination);
}

function* postRelation(action) {
  try {
    yield put(updateProcessing());
    const result = yield call(postRelationApi, action.data);
    yield put(storeRelation(result.data));

    yield put(updateSuccess());
  } catch (e) {
    const { data } = e.response;
    yield put(relationError("relation", data.message));
  }
}
export function* watchPostRelation() {
  yield takeLatest("POST_RELATION", postRelation);
}
