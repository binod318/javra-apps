import { call, put, takeLatest } from "redux-saga/effects";
import {
  getResultsApi,
  getTraitsApi,
  getTraitListApi,
  getScreeningListApi,
  postTraitScreenResultApi,
  getCropsApi
} from "./api";
import {
  processing,
  success,
  error,
  storeResult,
  storeTotal,
  storePage,
  storeSort,
  traitsAdd,
  traitListAdd,
  screeningListAdd,
  resultError,
  cropBulk
} from "./action";

function* getResult(action) {
  try {
    const { pageNumber, pageSize, filter, sorting } = action;
    yield put(processing());
    const result = yield call(
      getResultsApi,
      pageNumber,
      pageSize,
      filter,
      sorting
    );
    const { totalRows, data } = result.data;
    yield put(storeResult(data));
    yield put(storePage(pageNumber));
    yield put(storeTotal(totalRows));
    yield put(storeSort(sorting.name, sorting.direction));
    yield put(success());
  } catch (e) {
    const { message } = e;
    yield put(error("result", message));
  }
}
export function* watchGetResult() {
  yield takeLatest("GET_RESULT", getResult);
}

function* getTraits(action) {
  try {
    const { traitName, cropCode } = action;
    const result = yield call(getTraitsApi, traitName, cropCode);
    yield put(traitsAdd(result.data));
  } catch (e) {
    console.log(e);
  }
}
export function* watchGetTraits() {
  yield takeLatest("TRAITS_GET", getTraits);
}

function* getTraitList(action) {
  try {
    const result = yield call(getTraitListApi, action.traitID);
    yield put(traitListAdd(result.data));
  } catch (e) {
    console.log(e);
  }
}
export function* watchGetTraitList() {
  yield takeLatest("TRAITLIST_GET", getTraitList);
}

function* getScreeningList(action) {
  try {
    const result = yield call(getScreeningListApi, action.screeningFieldID);
    yield put(screeningListAdd(result.data));
  } catch (e) {
    console.log(e);
  }
}
export function* watchGetScreeningList() {
  yield takeLatest("SCREENINGLIST_GET", getScreeningList);
}

function* postTraitScreening(action) {
  try {
    yield put({
      type: "RESULT_ADD_PROCESSING"
    });

    const result = yield call(postTraitScreenResultApi, action.data);

    const { totalRows, data } = result.data;
    yield put(storeResult(data));
    yield put(storePage(action.data.pageNumber));
    yield put(storeTotal(totalRows));

    let message = "";
    const messageType = action.data.traitScreeningScreeningValues[0].action;
    switch (messageType) {
      case "U":
        message = "Trait screening value succesfully updated.";
        break;
      case "D":
        message = "Trait screening value succesfully deleted.";
        break;
      default:
        message = "Trait screening value succesfully created.";
    }
    if (messageType === "i" && action.data.process) {
      yield put({
        type: "RESULT_ADD_PROCESSING_CONTINUE"
      });
      return null;
    }
    yield put({
      type: "RESULT_ADD_SUCCESS"
    });
  } catch (e) {
    const { data } = e.response;
    const { message } = data; // errorType,
   
    yield put(resultError(message));
  }
}
export function* watchPostTraitScreening() {
  yield takeLatest("ATTRIBUTE_SAVE", postTraitScreening);
}

function* getCrops() {
  try {
    const result = yield call(getCropsApi);
    yield put(cropBulk(result.data));
  } catch (e) {
    console.log(e);
  }
}
export function* watchGetCrops() {
  yield takeLatest("FETCH_CROPS", getCrops);
}
