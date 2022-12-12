import { call, put, select } from "redux-saga/effects";
import { delay } from "redux-saga";
import { v4 as uuidv4 } from "uuid";

import {
  capacityPeriodAPI,
  capacitySOAPI,
  capacitySOUpdateAPI,
} from "./capacitySOApi";

import {
  capacityPeriodData,
  capacityPeriodSelect,
  capacitySOData,
  capacitySOColumn,
  capacitySOEmpty,
  capacityFetch,
  capacityUpdateSuccess,
  capacityUpdateError,
  capacityUpdateProcess,
  capacityError,
} from "./capacitySOAction";

import {
  noInternet,
  notificationMsg,
  notificationTimer,
} from "../../saga/notificationSagas";
import { show, hide } from "../../helpers/helper";

export function* capacitySOPeriod(action) {
  try {
    yield put(show("capacitySOPeriod"));

    const result = yield call(capacityPeriodAPI, action);

    const { Data, Errors, Message } = result.data;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      if (Data.length) {
        const tt = Data.filter((y) => y.Current);
        yield put(capacityPeriodData(Data));
        if (tt.length)
          yield put(
            capacityPeriodSelect(Data.filter((y) => y.Current)[0].PeriodID)
          );
        else {
          yield put(capacityPeriodSelect(Data[0].PeriodID));
          yield put(capacitySOEmpty());
        }
      } else {
        yield put(capacityPeriodSelect(""));
        yield put(capacityPeriodData([]));
      }
    }
    yield put(hide("capacitySOPeriod"));
  } catch (e) {
    yield put(hide("capacitySOPeriod"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const {
          errorType: ErrorType,
          code: Code,
          message: Message,
        } = e.response.data;
        if (ErrorType === 1) {
          yield put(noInternet);
          return null;
        }
        yield put(
          notificationMsg({
            ErrorType,
            Code,
            Message,
          })
        );
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* capacitySO(action) {
  try {
    yield put(show("capacitySO"));
    const result = yield call(capacitySOAPI, action);

    const { Data, Errors, Message } = result.data;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      const addRow = Data.CalculatedPlates.map((c) => {
        return Object.assign({}, c, {
          PACCropCode: null,
          ABSCropCode: null,
          MethodCode: c.Method,
          UsedFor: null,
          rowType: "added",
        });
      });
      yield put({ type: "CAL_DATA_ADD", data: addRow });
      const newData2 = Data.Data.map((d) => {
        d.id = uuidv4();
        return d;
      });
      yield put(capacitySOData(newData2));
      yield put(capacitySOColumn(Data.Columns));
    }

    yield put(hide("capacitySO"));
  } catch (e) {
    yield put(hide("capacitySO"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const {
          errorType: ErrorType,
          code: Code,
          message: Message,
        } = e.response.data;
        if (ErrorType === 1) {
          yield put(noInternet);
          return null;
        }
        yield put(
          notificationMsg({
            ErrorType,
            Code,
            Message,
          })
        );
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* capacitySOUpdate(action) {
  try {
    yield put(show("capacitySOUpdate"));
    yield put(capacityUpdateProcess());

    const result = yield call(capacitySOUpdateAPI, action);
    const { Data, Errors, Message } = result.data;

    const ref = yield select((state) => state.capacity.focus.ref);
    if (Errors.length) {
      yield put({
        type: "ERRORLIST_ADD",
        data: ref,
      });

      yield put(notificationTimer({ ...Errors[0], Type: 2 }));
      yield put(capacityError());
      yield put(capacityUpdateError());
    } else {
      const periodID = yield select((state) => state.capacity.period.selected);
      const res = yield call(capacitySOAPI, {
        periodID,
      });
      const { Data: DD } = res.data;
      const addRow = DD.CalculatedPlates.map((c) => {
        return Object.assign({}, c, {
          PACCropCode: null,
          ABSCropCode: null,
          MethodCode: c.Method,
          UsedFor: null,
          rowType: "added",
        });
      });
      yield put({ type: "CAL_DATA_ADD", data: addRow });

      yield put({
        type: "ERRORLIST_REMOVE",
        data: ref,
      });

      yield put(capacityUpdateSuccess());
    }

    yield put(hide("capacitySOUpdate"));
  } catch (e) {
    yield put(hide("capacitySOUpdate"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const {
          errorType: ErrorType,
          code: Code,
          message: Message,
        } = e.response.data;
        if (ErrorType === 1) {
          yield put(noInternet);
          return null;
        }
        yield put(notificationTimer(e.response.data));
        yield put(capacityError());
      }
    } else {
      yield put(noInternet);
    }
  }
}
