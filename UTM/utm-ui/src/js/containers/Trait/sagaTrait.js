import { call, takeLatest, put } from "redux-saga/effects";
import {
  noInternet,
  // notificationSuccess,
  notificationMsg,
  notificationSuccessTimer
} from "../../saga/notificationSagas";
import {
  storeCrops,
  storeTrait,
  storeDetermination,
  storeRelation,
  storeTotal,
  storePage,
  showNotification,
  filterPlatPlanAddBluk
} from "./action";

import {
  getCropApi,
  getRelationApi,
  getRelationDeterminationApi,
  getRelationTraitApi,
  postRelationApi
} from "./api";
import { show, hide } from "../../helpers/helper";

function* getCrop() {
  try {
    const result = yield call(getCropApi);
    yield put(storeCrops(result.data));
  } catch (e) {
    console.log(e);
  }
}
export function* watchGetCrop() {
  yield takeLatest("FETCH_CROP", getCrop);
}

function* getTrait(action) {
  try {
    yield put(show("getTrait"));
    const { traitName, cropCode, sourceSelected } = action;

    const result = yield call(
      getRelationTraitApi,
      traitName,
      cropCode,
      sourceSelected
    );
    yield put(storeTrait(result.data));
    yield put(hide("getTrait"));
  } catch (e) {
    yield put(hide("getTrait"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchGetTrait() {
  yield takeLatest("FETCH_TRAIT", getTrait);
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
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchGetDetermination() {
  yield takeLatest("FETCH_DETERMINATION", getDetermination);
}

function* getRelation(action) {
  try {
    yield put(show("getRelation"));
    const { pageNumber, pageSize, filter } = action;

    const result = yield call(getRelationApi, pageNumber, pageSize, filter);
    yield put(filterPlatPlanAddBluk(filter));
    yield put(storeRelation(result.data.data));
    yield put(storePage(pageNumber));
    yield put(storeTotal(result.data.totalRows));
    yield put(hide("getRelation"));
  } catch (e) {
    yield put(hide("getRelation"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchGetRelation() {
  yield takeLatest("GET_RELATION", getRelation);
}

function* postRelation(action) {
  try {
    yield put(show("postRelation"));

    const result = yield call(postRelationApi, action.data);
    yield put(storeRelation(result.data.data));
    yield put(storePage(action.data.pageNumber));
    yield put(storeTotal(result.data.totalRows));

    yield put(hide("postRelation"));
    const mode = action.data.relationTraitDetermination[0].action || "";
    let msg = "";
    switch (mode) {
      case "D":
        msg = "Relation was blocked successfully";
        break;
      case "U":
        msg = "Relation was updated successfully";
        break;
      default:
        msg = "Relation was created successfully.";
    }

    yield put(notificationSuccessTimer(msg));
  } catch (e) {
    if (e.response.data) {
      yield put(hide("postRelation"));
      const error = e.response.data;
      const { message, errorType, code } = error;
      yield put(showNotification(message, errorType, code));
    }
  }
}
export function* watchPostRelation() {
  yield takeLatest("POST_RELATION", postRelation);
}
