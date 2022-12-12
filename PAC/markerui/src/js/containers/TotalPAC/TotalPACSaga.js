import { call, put } from "redux-saga/effects";
import { v4 } from "uuid";

import { labResultfetchAPI, fetchGetExportAPI } from "./TotalPACApi";

// ACTION
import {
  totalPACColumnAdd,
  totalPACEmpty,
  totalPACDataAdd,
  totalPACTotal,
} from "./TotalPACAction";

import {
  noInternet,
  notificationMsg,
  notificationSuccess,
} from "../../saga/notificationSagas";
import { show, hide } from "../../helpers/helper";

export function* fetchPage(action) {
  try {
    yield put(show("fetchPage"));
    const { page, size, sortBy, sortOrder, filter } = action;

    const result = yield call(
      labResultfetchAPI,
      page,
      size,
      sortBy,
      sortOrder,
      filter
    );

    const {
      Data: { Data, Columns },
      Total,
    } = result.data;

    const columns = [];

    const keyValue = {
      MarkerPerVarID: "Marker Per VarID",
      MarkerID: "Marker ID",
      VarietyNr: "Variety Number",
      MarkerName: "Marker Name",
      VarietyName: "Variety Name",
      StatusName: "Status",
      Action: "Action",
    };

    Columns.map((c) => {
      const { ColumnID, ColumnName: Label, IsVisible } = c;
      const editable = false;
      const obj = {
        ColumnID,
        Editable: editable, // ? true : false,
        IsVisible,
        Label,
        order: columns.length,
        sort: false,
        filter: false,
        filtered: true,
        filteredValue: () => {},
      };
      columns.push(obj);
    });
    columns.push({
      ColumnID: "Action",
      Editable: false, // ? true : false,
      IsVisible: true,
      Label: "Action",
      order: columns.length,
      sort: false,
      filter: false,
    });

    // Condition if data is empty
    if (Data.length === 0) {
      yield put(totalPACDataAdd([]));
      yield put(totalPACColumnAdd(columns));
      yield put(hide("markerPerVariety"));
      yield put(totalPACTotal(1));
      return null;
    }

    yield put(totalPACColumnAdd(columns));
    yield put(totalPACDataAdd(Data));
    yield put(totalPACTotal(Total));

    yield put(hide("fetchPage"));
  } catch (e) {
    yield put(hide("fetchPage"));
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

export function* exportPage(action) {
  try {
    yield put(show("exportExternalTest"));
    const { filter } = action;
    const response = yield call(fetchGetExportAPI, filter);
    if (response.status === 200) {
      const url = window.URL.createObjectURL(new Blob([response.data]));
      const link = document.createElement("a");
      link.href = url;
      const fn = "BatchOverView";
      link.setAttribute("download", `${fn}.xlsx`);
      document.body.appendChild(link);
      link.click();
    }

    yield put(hide("exportExternalTest"));
  } catch (e) {
    yield put(hide("exportExternalTest"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const decodedString = String.fromCharCode.apply(null, new Uint8Array(e.response.data));
        const obj = JSON.parse(decodedString);
        const {
          errorType: ErrorType,
          code: Code,
          message: Message,
        } = obj;
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
