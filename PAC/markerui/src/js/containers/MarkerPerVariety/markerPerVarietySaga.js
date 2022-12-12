import { call, put, select } from "redux-saga/effects";

import {
  markerPerVarietyAPI,
  getMarkersAPI,
  getVarietiesAPI,
  getCropsAPI,
  postMarkerPerVarietiesAPI,
} from "./markerPerVarietyApi";

import {
  markerPerVarietyFetch,
  getMarkersFetch,
  MARKER_DATA,
  getVarietiesFetch,
  VARIETIES_DATA,
  CROPS_DATA,
  markerPerVarietyColumnAdd,
  markerPerVarietyEmpty,
  markerPerVarietyDataAdd,
  markerPerVarietyTotal,
} from "./markerPerVarietyAction";

import {
  noInternet,
  notificationMsg,
  notificationTimer,
} from "../../saga/notificationSagas";
import { show, hide } from "../../helpers/helper";

export function* markerPerVariety(action) {
  try {
    yield put(show("markerPerVariety"));
    const { page, size, sortBy, sortOrder, filter } = action;

    const result = yield call(
      markerPerVarietyAPI,
      page,
      size,
      sortBy,
      sortOrder,
      filter
    );
    const { Data: D, Errors, Message, Total } = result.data;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      const cols = [];
      const emptyObj = {};

      const { Data, Columns } = D;
      const keyValue = {
        MarkerPerVarID: "Marker Per VarID",
        MarkerID: "Marker ID",
        VarietyNr: "Variety Number",
        MarkerName: "Marker Name",
        VarietyName: "Variety Name",
        StatusName: "Status",
        Action: "Action",
      };

      Columns.map((c, i) => {
        const { ColumnID, ColumnLabel: Label, IsVisible } = c;
        const editable = false;

        cols.push({
          ColumnID,
          Editable: editable, // ? true : false,
          IsVisible,
          Label,
          order: cols.length,
          sort: false,
          filter: false,
          filtered: true,
          filteredValue: () => {},
        });
        if (i === Columns.length - 1) {
          cols.push({
            ColumnID: "Action",
            Editable: editable, // ? true : false,
            IsVisible: true,
            Label: "Action",
            order: 100,
          });
        }
      });

      // yield put({
      //   type: "MARKERPERVARIETY_COLUMN_ADD",
      //   data: cols,
      // });
      // yield put({
      //   type: "MARKERPERVARIETY_DATA_ADD",
      //   data: Data,
      // });

      // Condition if data is empty
      if (Data.length === 0) {
        yield put(markerPerVarietyDataAdd([]));
        yield put(markerPerVarietyColumnAdd(cols));
        yield put(hide("markerPerVariety"));
        yield put(markerPerVarietyTotal(1));
        return null;
      }

      yield put(markerPerVarietyColumnAdd(cols));
      yield put(markerPerVarietyDataAdd(Data));
      yield put(markerPerVarietyTotal(Total));

    }
    yield put(hide("markerPerVariety"));
  } catch (e) {
    yield put(hide("markerPerVariety"));
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

export function* getMarkers(action) {
  try {
    const result = yield call(getMarkersAPI, action);
    const { Data, Errors, Message } = result.data;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      yield put({
        type: MARKER_DATA,
        data: Data.map((d) => ({ id: d.MarkerID, label: d.MarkerName })),
      });
    }
  } catch (e) {
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

export function* getVarieties(action) {
  try {
    const result = yield call(getVarietiesAPI, action);
    const { Data, Errors, Message } = result.data;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      yield put({
        type: VARIETIES_DATA,
        data: Data.map((d) => ({ id: d.VarietyNr, label: d.VarietyName })),
      });
    }
  } catch (e) {
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

export function* getCrops() {
  try {
    const result = yield call(getCropsAPI);
    const { Data, Errors, Message } = result.data;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      yield put({
        type: CROPS_DATA,
        data: Data.map((d) => ({ id: d.CropCode, label: d.CropCode + ' - ' + d.CropName })),
      });
    }
  } catch (e) {
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

export function* postMarkerPerVarieties(payload) {
  try {
    const {
      MarkerPerVarID,
      MarkerID,
      VarietyNr,
      Remarks,
      ExpectedResult,
      action,
    } = payload;

    const result = yield call(
      postMarkerPerVarietiesAPI,
      MarkerPerVarID,
      MarkerID,
      VarietyNr,
      Remarks,
      ExpectedResult,
      action
    );

    const { Data, Errors, Message } = result.data;

    const state = yield select();
    const { page, pageSize, sorter, filter } = state.markerPerVariety;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      yield put(markerPerVarietyFetch(page, pageSize, sorter.sortBy, sorter.sortOrder, filter));
      // yield put({
      //   //markerPerVarietyFetch(page, size, sortBy, sortOrder, filter)
      //   //type: "MARKER_PER_VARIETY_FETCH",
      // });
    }
  } catch (e) {
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
