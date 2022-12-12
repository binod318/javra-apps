import { call, put, takeLatest } from "redux-saga/effects";
import axios from "axios";
import urlConfig from "../../../urlConfig";

import { noInternet, notificationMsg } from "../../../saga/notificationSagas";
import { labCapacityData, labCapacityColumn } from "../action";
import { show, hide } from "../../../helpers/helper";

function planningCapacityApi(action) {
  return axios({
    method: "get",
    url: urlConfig.planingCapacity,

    params: {
      year: action.year
    }
  });
}
function* planningCapacity(action) {
  try {
    yield put(show("planningCapacity"));

    const result = yield call(planningCapacityApi, action);

    const { data, columns } = result.data;
    yield put(labCapacityData(data));
    yield put(labCapacityColumn(columns));
    yield put(hide("planningCapacity"));
  } catch (e) {
    yield put(hide("planningCapacity"));
  }
}
export function* watchPlanningCapacity() {
  yield takeLatest("LAB_DATA_FETCH", planningCapacity);
}

function planningUpdateApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postPlaningCapacity,

    data: {
      capacityList: action.data
    }
  });
}
function* planningUpdate(action) {
  try {
    yield put(show("planningUpdate"));

    yield call(planningUpdateApi, action);
    planningCapacity(action);

    yield put(hide("planningUpdate"));
  } catch (e) {
    yield put(hide("planningUpdate"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchPlanningUpdate() {
  yield takeLatest("LAB_DATA_UPDATE", planningUpdate);
}
