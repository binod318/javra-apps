import { call, put, takeLatest, select } from "redux-saga/effects";
import {
  breederApi,
  cropChangeApi,
  breederReserveApi,
  periodApi,
  plantsTestsApi,
  slotDeleteApi,
} from "../api";

import {
  periodAdd,
  displayPeriodAdd,
  displayPeriodExpected,
  breedingFomrData,
  breedingMessage,
  breedingSubmit,
  breedingForced,
  breedingReset,
  breedingMaterialType,
} from "../action";
import {
  noInternet,
  notificationMsg,
  notificationSuccess,
} from "../../../saga/notificationSagas";
import { show, hide } from "../../../helpers/helper";

function getBreederPageSize(store) {
  return store.slotBreeder.total.pageSize || 200;
}

function* breeder() {
  try {
    yield put(show("breeder"));

    const result = yield call(breederApi);

    yield put(breedingFomrData(result.data));
    yield put(hide("breeder"));
  } catch (e) {
    yield put(hide("breeder"));
  }
}
export function* watchBreeder() {
  yield takeLatest("BREEDER_FIELD_FETCH", breeder);
}

function* cropChange(action) {
  try {
    yield put(show("cropChange"));

    const result = yield call(cropChangeApi, action);
    if (result.status === 200) yield put(breedingMaterialType(result.data));
    yield put(hide("cropChange"));
  } catch (e) {
    yield put(hide("cropChange"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const { data } = e.response;
        yield put(notificationMsg(data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchCropChange() {
  yield takeLatest("BREEDER_FETCH_MATERIALTYPE", cropChange);
}

function* breederReserve(action) {
  try {
    yield put(show("breederReserve"));

    // breedingStationCode, cropCode
    const result = yield call(breederReserveApi, action);
    const { success, message } = result.data;

    if (success) {
      const state = yield select();
      const pageSize = getBreederPageSize(state);
      // Refetch table data after success
      const { breedingStationCode: brStationCode, cropCode } = action;
      yield put({
        type: "FETCH_BREEDER_SLOT",
        cropCode,
        brStationCode,
        pageNumber: 1,
        pageSize,
        filter: [],
      });

      yield put(notificationSuccess(message));
      yield put(breedingMessage(""));
      yield put(breedingSubmit(true));
      yield put(breedingForced(false));
      yield put(breedingReset());
    } else {
      yield put(breedingMessage(message));
      yield put(breedingSubmit(false));
      yield put(breedingForced(true));
    }
    yield put(hide("breederReserve"));
  } catch (e) {
    yield put(hide("breederReserve"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const { data } = e.response;
        yield put(notificationMsg(data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchBreederReserve() {
  // yield takeEvery('BREEDER_RESERVE', breederReserve);
  yield takeLatest("BREEDER_RESERVE", breederReserve);
}

function* period(action) {
  try {
    const result = yield call(periodApi, action);
    const { displayPeriod } = result.data;
    if (action.period === 1) {
      yield put(displayPeriodAdd(displayPeriod));
    } else {
      yield put(displayPeriodExpected(displayPeriod));
    }
  } catch (e) {
    console.log(e);
  }
}
export function* watchPeriod() {
  yield takeLatest("PERIOD_FETCH", period);
}

function* plantsTests(action) {
  try {
    const result = yield call(plantsTestsApi, action);
    if (result.status === 200) {
      const {
        availPlates,
        availTests,
        displayExpectedWeek,
        displayPlannedWeek,
        expectedDate,
      } = result.data;

      const obj = {
        planned: displayPlannedWeek,
        expected: displayExpectedWeek,
        availPlates,
        availTests,
        expectedDate,
      };

      yield put(periodAdd(obj));
    }
  } catch (e) {}
}
export function* watchPlantsTests() {
  // yield takeEvery('PLATES_TESTS_FETCH', plantsTests);
  yield takeLatest("PLATES_TESTS_FETCH", plantsTests);
}

function* slotDelete(action) {
  try {
    yield put(show("slotDelete"));

    const { slotID, cropCode, brStationCode, slotName } = action;

    const result = yield call(slotDeleteApi, slotID);
    if (result.data) {
      // delete success fetch again and reirect to page 1
      const state = yield select();
      const pageSize = getBreederPageSize(state);
      yield put({
        type: "FETCH_BREEDER_SLOT",
        cropCode,
        brStationCode,
        pageNumber: 1,
        pageSize,
        filter: [],
      });

      yield put(notificationSuccess(`Slot ${slotName} deleted successfully.`));
    }

    yield put(hide("slotDelete"));
  } catch (e) {
    yield put(hide("slotDelete"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const { data } = e.response;
        yield put(notificationMsg(data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
export function* watchSlotDelete() {
  yield takeLatest("SLOT_DELETE", slotDelete);
}
