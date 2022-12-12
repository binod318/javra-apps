import { call, put } from "redux-saga/effects";
import { v4 as uuidv4 } from "uuid";
import {
  planningYearAPI,
  planningCapacityAPI,
  planningUpdateAPI,
} from "./labApi";
import {
  labYearData,
  labYearSelect,
  labCapacityData,
  labCapacityColumn,
  labUpdateSuccess,
  labUpdateError,
} from "./labAction";
import { capacityYearSelect } from "../CapacitySO/capacitySOAction";
import { planningYearSelected } from "../PlanningBatchesSO/planningBatchesSOAction";
import { labPreparationYearSelected } from "../LabPreparation/labPreparationAction";

import { noInternet, notificationMsg } from "../../saga/notificationSagas";
import { show, hide } from "../../helpers/helper";

export function* planningYear() {
  try {
    yield put(show("planningYear"));
    const result = yield call(planningYearAPI);

    const { Data, Errors, Message } = result.data; // Errors, Message
    if (Errors.length) {
      yield put(noInternet);
    } else {
      yield put(labYearData(Data));
      const res = Data.filter((y) => y.Current)[0].Year;
      yield put(labYearSelect(res));
      yield put(capacityYearSelect(res));
      yield put(planningYearSelected(res));
      yield put(labPreparationYearSelected(res));
      yield put({
        type: "LAB_RESULT_YEAR_SELECT",
        selected: res,
      });
    }
    yield put(hide("planningYear"));
  } catch (e) {
    yield put(hide("planningYear"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* planningCapacity(action) {
  try {
    yield put(show("planningCapacity"));

    const result = yield call(planningCapacityAPI, action);

    const { Data, Errors, Message } = result.data; // Errors, Message

    if (Errors.length) {
      yield put(noInternet);
    } else {
      const newData2 = Data.Data.map((d) => {
        d.id = uuidv4();
        return d;
      });
      yield put(labCapacityData(newData2));
      yield put(labCapacityColumn(Data.Columns));
      yield put(labYearSelect(action.year));
    }
    yield put(hide("planningCapacity"));
  } catch (e) {
    yield put(hide("planningCapacity"));
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
        yield put(notificationMsg({ ErrorType, Code, Message }));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* planningUpdate(action) {
  try {
    yield put(show("planningUpdate"));

    const result = yield call(planningUpdateAPI, action);
    const { Data, Errors, Message } = result.data;

    if (Errors.length) {
      yield put(notificationMsg(Errors[0]));
      yield put(labUpdateError());
    } else {
      yield put(labUpdateSuccess());
      planningCapacity(action);
    }

    yield put(hide("planningUpdate"));
  } catch (e) {
    yield put(hide("planningUpdate"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const { errorType: ErrorType } = e.response.data;
        if (ErrorType === 1) {
          yield put(noInternet);
          return null;
        }
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}
