import { call, put } from "redux-saga/effects";
import { v4 } from "uuid";

import {
  labPreparationPeriodAPI,
  labPreparationFolderAPI,
  labDeclusterResultAPI,
  reservePlatestInLIMSAPI,
  getMinimumTestStatusAPI,
  sendToLimsAPI,
  printPlateLabelsAPI,
} from "./labPreparationApi";

import {
  labPreparationGroupAdd,
  labPreparationDataAdd,
  labPreparationColumnAdd,
  labDeclusterDataAdd,
  labDeclusterColumnAdd,
  labTestSetStatus,
  labTestSetDAStatus,
  labSetFillRateTotalUsed,
  labSetFillRateTotalReserved
} from "./labPreparationAction";

import {
  noInternet,
  notificationMsg,
  notificationSuccess,
} from "../../saga/notificationSagas";
import { show, hide } from "../../helpers/helper";

export function* labPreparationPeriod(action) {
  try {
    yield put(show("labPreparationPeriod"));

    const result = yield call(labPreparationPeriodAPI, action.year);

    const { Data, Errors, Message } = result.data;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      yield put({
        type: "LABPREPARATION_YEAR_SELECT",
        selected: action.year,
      });
      yield put({
        type: "LABPREPARATION_PERIOD_ADD",
        data: Data,
      });
      const periodDate = Data.find((y) => y.Current) || Data[0];
      yield put({
        type: "LABPREPARATION_PERIOD_SELECT",
        selected: periodDate.PeriodID,
      });
    }

    yield put(hide("labPreparationPeriod"));
  } catch (e) {
    yield put(hide("labPreparationPeriod"));
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

export function* labPreparationFolder({ periodID }) {
  try {
    yield put(show("labPreparationFolder"));

    const result = yield call(labPreparationFolderAPI, periodID);

    const { Data, Errors, Message } = result.data;
    if (Errors.length) {
      yield put(noInternet);
    } else {
      const { Details, Groups, TestStatusCode, DAStatusCode, TotalUsed, TotalReserved } = Data;

      yield put({
        type: "LABPREPARATION_PERIOD_SELECT",
        selected: periodID,
      });

      if (Groups.length === 0) {
        yield put(hide("labPreparationFolder"));
        yield put(labPreparationGroupAdd([]));
        yield put(labPreparationDataAdd([]));
        yield put(labTestSetStatus(TestStatusCode));
        yield put(labTestSetDAStatus(DAStatusCode));
        yield put(labSetFillRateTotalUsed(TotalUsed));
        yield put(labSetFillRateTotalReserved(TotalReserved));
        return null;
      }
      const columns = [];
      const emptyObj = {};

      const mg = Groups.length
        ? Groups.map((g) => {
            const {
              TestName,
              ABSCropCode,
              MethodCode,
              PlatformName,
              TestID,
            } = g;
            return { ...g, open: false, id: TestID };
          })
        : [];

      yield put(labPreparationGroupAdd(mg));
      yield put(labPreparationDataAdd(Details));

      const keyValue = {
        TestID: "TestID",
        DetAssignmentID: "Determination Ass.",
        TestName: "Folder",
        ABSCropCode: "Crop",
        MethodCode: "Method",
        PlatformName: "Platform",
        NrOfPlates: "#plates",
        NrOfMarkers: "#markers",
        TraitMarkers: "Trait Markers",
        VarietyName: "Variety Name",
        SampleNr: "Sample#",
        PlateNames: "Plate Names",
      };
      const dataKeys = Object.keys({
        TestID: "",
        TestName: "",
        CropCode: "",
        MethodCode: "",
        PlatformName: "",
        DetAssignmentID: "",
        NrOfPlates: "",
        NrOfMarkers: "",
        VarietyName: "",
        SampleNr: "",
        IsParent: "",
        IsLabPriority: "",
        TraitMarkers: "",
        PlateNames: "",
      });
      dataKeys.forEach((c) => {
        emptyObj[c] = "";
        const editable = c == "TraitMarkers" || c == "RepeatIndicator";
        const visibility = c !== "IsLabPriority";
        if (c == "TestID" || c == "DetAssignmentID" || c == "IsParent") {
        } else {
          if (columns.length === 0) {
            columns.push({
              ColumnID: "Action",
              Editable: editable, // ? true : false,
              IsVisible: visibility,
              Label: "Action",
              order: columns.length,
            });
          }
          columns.push({
            ColumnID: c,
            Editable: editable, // ? true : false,
            IsVisible: visibility,
            Label: keyValue[c],
            order: columns.length,
          });
        }
      });
      yield put(labPreparationColumnAdd(columns));
      yield put(labTestSetStatus(TestStatusCode));
      yield put(labTestSetDAStatus(DAStatusCode));
      yield put(labSetFillRateTotalUsed(TotalUsed));
      yield put(labSetFillRateTotalReserved(TotalReserved));
    }

    yield put(hide("labPreparationFolder"));
  } catch (e) {
    yield put(hide("labPreparationFolder"));
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

export function* labDeclusterResult({ periodID, detAssignmentID }) {
  try {
    yield put(show("labDeclusterResult"));

    const result = yield call(labDeclusterResultAPI, periodID, detAssignmentID);

    const { Data, Errors, Message } = result.data;

    if (Errors.length) {
      yield put(noInternet);
    } else {
      const columns = [];
      Data.Columns.map((column) => {
        columns.push({
          ColumnID: column.ColumnID,
          Editable: false, // ? true : false,
          IsVisible: true,
          Label: column.ColumnLabel,
          order: column.length,
          isExtraTraitMarker: column.IsExtraTraitMarker === 1,
        });
      });
      yield put(labDeclusterColumnAdd(columns));
      yield put(labDeclusterDataAdd(Data.Data));
    }

    yield put(hide("labDeclusterResult"));
  } catch (e) {
    yield put(hide("labDeclusterResult"));
    if (e.response !== undefined) {
      if (e.response.data) {
        const {
          errorType: ErrorType,
          code: Code,
          message: Message,
        } = e.response.data;
        yield put(
          notificationMsg({
            ErrorType,
            Code,
            Message,
          })
        );
      }
    } else {
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
}

export function* reservePlatestInLIMS({ periodID }) {
  try {
    yield put(show("labDeclusterResult"));
    const result = yield call(reservePlatestInLIMSAPI, periodID);
    const { data, status } = result;
    const { Data, Errors, Message } = data;

    if (result.data && status === 200) {
      yield put(labTestSetStatus(status));
      yield put(notificationSuccess("Successfully reserve plates requested."));
    }
    yield put(hide("labDeclusterResult"));
  } catch (e) {
    yield put(hide("labDeclusterResult"));
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

export function* getMinimumTestStatus({ periodID }) {
  try {
    yield put(show("getMinimumTestStatus"));

    const result = yield call(getMinimumTestStatusAPI, periodID);

    const { data, status } = result;
    if (status === 200) {
      yield put(labTestSetStatus(data));
    }

    yield put(hide("getMinimumTestStatus"));
  } catch (e) {
    yield put(hide("getMinimumTestStatus"));
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

export function* sendToLims(action) {
  try {
    const { obj, periodID, startEndDate } = action;
    yield put(show("sendToLims"));

    const result = yield call(sendToLimsAPI, periodID);

    // FORMAT of receiving response was changed form BE.
    if (result.data) {
      yield put(notificationSuccess("Successfully send to LIMS."));
      yield put(labTestSetStatus(450));
    } else {
      yield put(notificationSuccess("Error while sending to LIMS."));
    }

    yield put(hide("sendToLims"));
  } catch (e) {
    yield put(hide("sendToLims"));
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

export function* printPlateLabels(action) {
  try {
    // printPlateLabelsAPI
    yield put(show("printPlateLabesl"));

    const result = yield call(printPlateLabelsAPI, action);
    const { data } = result;
    const { Success, Error: err, PrinterName } = data;

    if (!Success) {
      yield put(
        notificationMsg({
          ErrorType: 2,
          Code: 101,
          Message: err,
        })
      );
    }

    yield put(hide("printPlateLabesl"));
  } catch (e) {
    yield put(hide("printPlateLabesl"));
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
