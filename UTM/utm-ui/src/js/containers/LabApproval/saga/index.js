/**
 * Created by sushanta on 3/14/18.
 */
import { call, takeLatest, takeEvery, put } from "redux-saga/effects";
import {
  getApprovalListApi,
  getPlanPeriodsApi,
  approveSlotApi,
  denySlotApi,
  updateSlotPeriodApi
} from "../api";
import { getApprovalListDone, getPlanPeriodsDone } from "../actions";
import {
  noInternet,
  notificationMsg,
  notificationSuccess,
  notificationSuccessTimer
} from "../../../saga/notificationSagas";
import { show, hide } from "../../../helpers/helper";

function* getApprovalList({ periodID }) {
  try {
    yield put(show("getApprovalList"));
    const result = yield call(getApprovalListApi, periodID);
    yield put(getApprovalListDone(result.data));
    yield put(hide("getApprovalList"));
  } catch (e) {
    yield put(hide("getApprovalList"));
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
export function* watchGetApprovalList() {
  yield takeEvery("GET_APPROVAL_LIST", getApprovalList);
}

function* getPlanPeriods() {
  try {
    yield put(show("getPlanPeriods"));

    const result = yield call(getPlanPeriodsApi);
    yield put(getPlanPeriodsDone(result.data));
    yield put(hide("getPlanPeriods"));
  } catch (e) {
    yield put(hide("getPlanPeriods"));
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
export function* watchGetPlanPeriods() {
  yield takeLatest("GET_PLAN_PERIODS", getPlanPeriods);
}

function* approveSlot({ slotID, selectedPeriodID, forced }) {
  try {
    yield put(show("approveSlot"));

    const result = yield call(approveSlotApi, slotID, forced);

    const { success, message } = result.data;
    if (success) {
      yield put(notificationSuccessTimer(message));
      const approvalList = yield call(getApprovalListApi, selectedPeriodID);
      yield put(getApprovalListDone(approvalList.data));
    }
    yield put(hide("approveSlot"));
  } catch (e) {
    yield put(hide("approveSlot"));
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
export function* watchSlotApproval() {
  yield takeLatest("APPROVE_SLOT", approveSlot);
}

function* denySlot({ slotID, selectedPeriodID }) {
  try {
    yield put(show("denySlot"));

    const result = yield call(denySlotApi, slotID);
    const { success, message } = result.data;
    if (success) {
      yield put(notificationSuccess(message));
      const approvalList = yield call(getApprovalListApi, selectedPeriodID);
      yield put(getApprovalListDone(approvalList.data));
    }
    yield put(hide("denySlot"));
  } catch (e) {
    yield put(hide("denySlot"));
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
export function* watchSlotDenial() {
  yield takeLatest("DENY_SLOT", denySlot);
}

function* updateSlotPeriod({ slotID, periodID, plannedDate, expectedDate }) {
  try {
    yield put(show("updateSlotPeriod"));

    const result = yield call(
      updateSlotPeriodApi,
      slotID,
      plannedDate,
      expectedDate
    );
    const { success, message } = result.data;
    if (success) {
      yield put(notificationSuccess(message));
      const approvalList = yield call(getApprovalListApi, periodID);
      yield put(getApprovalListDone(approvalList.data));
    }
    yield put(hide("updateSlotPeriod"));
  } catch (e) {
    yield put(hide("updateSlotPeriod"));
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
export function* watchUpdateSlotPeriod() {
  yield takeLatest("UPDATE_SLOT_PERIOD", updateSlotPeriod);
}
