import { call, put, takeLatest } from "redux-saga/effects";
import axios from "axios";
import urlConfig from "../../../urlConfig";

import { noInternet, notificationMsg } from "../../../saga/notificationSagas";
import { labCapacityData, labCapacityColumn, locationAdd } from "../action";
import { show, hide } from "../../../helpers/helper";

function planningCapacityApi(action) {
  return axios({
    method: "get",
    url: urlConfig.ldPlaningCapacity,

    params: {
      year: action.year,
      siteLocation: action.siteLocation
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

export function* watchLDplanningCapacity() {
  yield takeLatest("LD_LAB_DATA_FETCH", planningCapacity);
}



function planningUpdateApi(action) {
  return axios({
    method: "post",
    url: urlConfig.postLDplaningCapacity,

    data: {
      siteID: action.siteLocation,
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

export function* watchLDplanningUpdate() {
  yield takeLatest("LD_LAB_DATA_UPDATE", planningUpdate);
}
