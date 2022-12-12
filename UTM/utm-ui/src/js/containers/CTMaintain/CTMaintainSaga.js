import { call, put } from "redux-saga/effects";

import { noInternet, notificationMsg } from "../../saga/notificationSagas";
import { show, hide } from "../../helpers/helper";

import {
  getCTProcessApi,
  postSaveCTProcessApi,
  getCNTLabLocationsApi,
  postCNTLabLocationsApi,
  getCNTStartMaterialApi,
  postCNTStartMaterialApi,
  getCNTTypesApi,
  postCNTTypesApi
} from "./CTMaintainApi";

export function* ctMaintainProcessFetch() {
  try {
    yield put(show("ctMaintainProcessFetch"));

    const result = yield call(getCTProcessApi);
    yield put({
      type: "CT_PROCESS_ADD",
      data: result.data
    });
    yield put(hide("ctMaintainProcessFetch"));
  } catch (e) {
    yield put(hide("ctMaintainProcessFetch"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* ctMaintainProcessPost(action) {
  try {
    yield put(show("ctMaintainProcessPost"));
    const { id: processID, name: processName, active, action: act } = action;

    const result = yield call(
      postSaveCTProcessApi,
      processID,
      processName,
      active,
      act
    );
    if (result.status === 200 && result.statusText === "OK") {
      yield put({
        type: "CT_PROCESS_FETCH"
      });
    }

    yield put(hide("ctMaintainProcessPost"));
  } catch (e) {
    yield put(hide("ctMaintainProcessPost"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* ctLabLocationsFetch() {
  try {
    yield put(show("ctLabLocationsFetch"));

    const result = yield call(getCNTLabLocationsApi);
    yield put({
      type: "CT_LOCATION_ADD",
      data: result.data
    });
    yield put(hide("ctLabLocationsFetch"));
  } catch (e) {
    yield put(hide("ctLabLocationsFetch"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* ctLabLocationsPost(action) {
  try {
    yield put(show("ctLabLocationsPost"));
    const {
      id: labLocationID,
      name: labLocationName,
      active,
      action: act
    } = action;

    const result = yield call(
      postCNTLabLocationsApi,
      labLocationID,
      labLocationName,
      active,
      act
    );
    if (result.status === 200 && result.statusText === "OK") {
      yield put({
        type: "CT_LABLOCATIONS_FETCH"
      });
    }

    yield put(hide("ctLabLocationsPost"));
  } catch (e) {
    yield put(hide("ctLabLocationsPost"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* ctStartMaterialsFetch() {
  try {
    yield put(show("ctStartMaterialsFetch"));

    const result = yield call(getCNTStartMaterialApi);
    yield put({ type: "CT_STARTMATERIAL_ADD", data: result.data });
    yield put(hide("ctStartMaterialsFetch"));
  } catch (e) {
    yield put(hide("ctStartMaterialsFetch"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* ctStartMaterialsPost(action) {
  try {
    yield put(show("ctLabLocationsPost"));
    const {
      id: startMaterialID,
      name: startMaterialName,
      active,
      action: act
    } = action;

    const result = yield call(
      postCNTStartMaterialApi,
      startMaterialID,
      startMaterialName,
      active,
      act
    );
    if (result.status === 200 && result.statusText === "OK") {
      yield put({
        type: "CT_STARTMATERIAL_FETCH"
      });
    }

    yield put(hide("ctLabLocationsPost"));
  } catch (e) {
    yield put(hide("ctLabLocationsPost"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* ctTypeFetch() {
  try {
    yield put(show("ctTypeFetch"));

    const result = yield call(getCNTTypesApi);
    yield put({ type: "CT_TYPE_ADD", data: result.data });
    yield put(hide("ctTypeFetch"));
  } catch (e) {
    yield put(hide("ctTypeFetch"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* ctTypePost(action) {
  try {
    yield put(show("ctTypePost"));
    const { id: typeID, name: typeName, active, action: act } = action;

    const result = yield call(postCNTTypesApi, typeID, typeName, active, act);
    if (result.status === 200 && result.statusText === "OK") {
      yield put({
        type: "CT_TYPE_FETCH"
      });
    }

    yield put(hide("ctTypePost"));
  } catch (e) {
    yield put(hide("ctTypePost"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
