import { delay } from "redux-saga";
import { call, put, select, takeLatest } from "redux-saga/effects";
import parse from "xml-parser";
import { lensPath, set, concat } from "ramda";
import {
  reciprocalRecordApi,
  phenomeLoginSSOApi,
  phenomeLoginApi,
  getResearchGroupsApi,
  getFoldersApi,
  importPhenomeApi,
  germplasmApi,
  getNewCropsAndProductApi,
  getCountryOriginApi,
  postProductSegmentsApi,
  postVarmasApi,
  deleteApi,
  postReplaceLOTLookupApi,
  postReplaceLOTApi,
  pedigreeApi,
  fetchPhenomTokenApi,
  fetchUserCropsApi,
  undoReplaceLotApi
} from "./api";
import {
  recipocalSuccess,
  recipocalError,
  loginProcessing,
  loginSuccess,
  loginError,
  importProcessing,
  importSuccess,
  importError,
  productProcessing,
  productSuccess,
  productError,
  mainProcessing,
  mainSuccess,
  mainError,
  varmasProcessing,
  varmasSuccess,
  varmasError,
  deleteProcessing,
  deleteSuccess,
  deleteError,
  replaceProcessing,
  replaceSuccess,
  replaceError,
  phenomeLoginDone,
  getResearchGroupsDone,
  getFoldersDone,
  phenomeLogout,
  SetOpAsParentFunc,
  undoReplaceLotSucceeded
} from "./action";

/**
 * Reciprocal AND refetch table data with current pg and filter
 * success / error / loader
 */
function* reciprocalRecord(action) {
  try {
    const response = yield call(reciprocalRecordApi, action);

    if (response.status === 200) {
      const { files: fileName, filter, sort: sorting, total } = yield select(
        state => state.main
      );
      const { pageNumber, pageSize } = total;
      yield put({
        type: "FETCH_MAIN",
        fileName,
        pageNumber,
        pageSize,
        filter,
        sorting,
        loader: false
      });
    }
  } catch (e) {
    const { response } = e;
    const { data } = response;
    yield put(recipocalError(data.message));
  }
}
export function* watchReciprocalRecord() {
  yield takeLatest("RECIPROCAL_RECORD", reciprocalRecord);
}

function* phenomeLogin(action) {
  try {
    yield put(loginProcessing());

    const loginUrl = window.adalConfig.enabled
      ? phenomeLoginSSOApi
      : phenomeLoginApi;
    const response = yield call(loginUrl, action);
    const { data } = response;
    if (data.status) {
      yield put(phenomeLoginDone());
      yield put(loginSuccess());
    } else {
      const { message } = data;
      yield put(loginError(message));
    }
  } catch (err) {
    yield put(loginError("Login request failed."));
  }
}
export function* watchPhenomeLogin() {
  yield takeLatest("PHENOME_LOGIN", phenomeLogin);
}

export function* getResearchGroups() {
  try {
    const response = yield call(getResearchGroupsApi);
    const data = {};
    if (response.data) {
      const obj = parse(response.data);
      const rootItem = obj.root.children[0];
      if (rootItem.attributes.status === "0") {
        yield put(phenomeLogout());
      }
      if (rootItem.attributes.text) {
        data.name = rootItem.attributes.text;
        data.img = rootItem.attributes.im0;
        data.children = [];
        let i = 0;
        let j = 0;
        while (i < rootItem.children.length) {
          const child = rootItem.children[i];
          if (child.attributes.text) {
            data.children.push({
              name: child.attributes.text,
              img: child.attributes.im0,
              id: child.attributes.id,
              children: [],
              path: ["children", j, "children"],
              objectType: child.children.find(
                item => item.attributes.name === "ObjectType"
              ).content
            });
            j += 1;
          }
          i += 1;
        }
      }
    }
    yield put(getResearchGroupsDone(data));
  } catch (err) {
    console.log(err);
  }
}
export function* getFolders({ id, path }) {
  try {
    const response = yield call(getFoldersApi, id);
    const data = [];
    if (response.data) {
      const obj = parse(response.data);
      const rootItem = obj.root;
      if (rootItem.children.length > 0) {
        if (rootItem.children[0].attributes.status === "0") {
          yield put(phenomeLogout());
        }
      }
      if (rootItem.attributes.id) {
        let i = 0;
        let j = 0;
        while (i < rootItem.children.length) {
          const child = rootItem.children[i];
          if (child.attributes.text) {
            data.push({
              name: child.attributes.text,
              img: child.attributes.im0,
              id: child.attributes.id,
              children: child.attributes.child ? [] : null,
              path: concat(path, [j, "children"]),
              objectType: child.children.find(
                item => item.attributes.name === "ObjectType"
              ).content,
              researchGroupID: child.children.find(
                item => item.attributes.name === "rg_id"
              ).content
            });
            j += 1;
          }
          i += 1;
        }
      }
    }
    const currentTreeData = yield select(state => state.phenome.treeData);
    const newTreeData = set(lensPath(path), data, currentTreeData);
    yield put(getFoldersDone(newTreeData));
  } catch (err) {
    console.log(err);
  }
}
export function* importPhenome(action) {
  try {
    const {
      cropID,
      objectID,
      objectType,
      pageSize,
      tree,
      folderObjectType,
      researchGroupObjectType,
      withoutHierarchy
    } = action;

    yield put(importProcessing());

    const result = yield call(
      importPhenomeApi,
      cropID,
      objectID,
      objectType,
      pageSize,
      tree,
      folderObjectType,
      researchGroupObjectType,
      withoutHierarchy
    );
    const { data } = result;
    if (data.success) {
      yield put({
        type: "MAIN_BULK",
        data: data.data.data
      });
      yield put({
        type: "COLUMN_BULK_ADD",
        data: data.data.columns
      });
      yield put({
        type: "MAIN_RECORDS",
        total: data.total
      });
      yield put({
        type: "MAIN_SIZE",
        pageSize
      });
      yield put({
        type: "MAIN_PAGE",
        pageNumber: 1
      });
      yield put({
        type: "FILE_SELECT",
        cropSelected: data.fileName
      });

      yield put({ type: "FILTER_WITHOUT_FALSE" });

      yield put({
        type: "FILE_STATUS",
        status: 100
      });
      yield put({
        type: "SELECT_BLANK"
      });

      const opasparent = SetOpAsParentFunc(data.data.data);

      yield put({
        type: "OP_SET",
        opasparent
      });
      yield put({ type: "IMPORT_VIEW_FLAG", flag: false });
      yield put(importSuccess());
    } else {
      const { errors } = data;
      // ONLY ONE ARR ERROR MESSAGE DISCUSSED WITH .NET TEAM
      yield put(importError(errors[0]));
    }
  } catch (e) {
    const { response } = e;
    const { data } = response;
    yield put(importError(data.message));
  }
}

function* postGermplasm(action) {
  const loading = action.loader === undefined ? true : action.loader;
  try {
    const fileStatus = yield select(state => state.main.fileStatus);
    const isHybrid = yield select(state => state.main.filterWithout);
    const {
      fileName,
      pageNumber,
      pageSize,
      filter,
      sorting,
      opAsParentFlag
    } = action;

    // request to place actual flag for isHybird
    // before if there was no filter wi always send false
    // const computedIsHybrid = filter.length === 0 ? false : isHybrid;
    const computedIsHybrid = isHybrid;

    if (loading) yield put(mainProcessing());

    let newFilter = [];
    switch (fileStatus) {
      case 0: // all
        newFilter = [...filter];
        break;
      case 200:
        newFilter = [
          ...filter,
          {
            display: "status",
            name: "statusCode",
            value: 200,
            expression: "contains",
            operator: "or"
          },
          {
            display: "status",
            name: "statusCode",
            value: 250,
            expression: "contains",
            operator: "or"
          }
        ];
        break;
      default:
        // 100 & 300
        newFilter = [
          ...filter,
          {
            display: "status",
            name: "statusCode",
            value: fileStatus,
            expression: "contains",
            operator: "and"
          }
        ];
    }

    const response = yield call(
      germplasmApi,
      fileName,
      pageNumber,
      pageSize,
      newFilter,
      sorting,
      computedIsHybrid
    );

    const { success, errors, data, total } = response.data;
    if (!success) {
      yield put({ type: "OP_RESET" });
      yield put({ type: "MAIN_BULK", data: [] });
      yield put({ type: "COLUMN_BULK_ADD", data: [] });
      yield put({ type: "MAIN_RECORDS", total: 0 });
      if (loading) yield put(mainError(errors));
    } else {
      //  response sends null if there's not data.
      //  not empty array / it Null
      const stateOPasParent = yield select(state => state.main.opasparent);

      if (opAsParentFlag || stateOPasParent.length === 0) {
        if (data.data !== null) {
          const opasparent = SetOpAsParentFunc(data.data);
          yield put({ type: "OP_SET", opasparent });
        }
      }

      yield put({ type: "MAIN_BULK", data: data.data || [] });
      yield put({ type: "COLUMN_BULK_ADD", data: data.columns || [] });
      yield put({ type: "MAIN_RECORDS", total });
      yield put({ type: "MAIN_SIZE", pageSize: action.pageSize });
      yield put({ type: "MAIN_PAGE", pageNumber: action.pageNumber });
      yield put({
        type: "MAIN_SORT",
        name: sorting.name,
        direction: sorting.direction
      });

      if (loading) yield put(mainSuccess());
    }
  } catch (e) {
    const { response } = e;
    const { data } = response;
    yield put({
      type: "MAIN_BULK",
      data: []
    });
    yield put({
      type: "COLUMN_BULK_ADD",
      data: []
    });
    yield put({
      type: "MAIN_RECORDS",
      total: 0
    });
    if (loading) yield put(mainError(data.message));
  }
}
export function* watchPostGermplasm() {
  yield takeLatest("FETCH_MAIN", postGermplasm);
}

function* getNewCropAndProduct(action) {
  try {
    const resultCrops = yield call(
      getNewCropsAndProductApi,
      action.cropSelected
    );
    const { data } = resultCrops;
    const { newCrops, prodSegments } = data;
    yield put({
      type: "NEW_CROP_BULK",
      data: newCrops
    });
    yield put({
      type: "PRODUCT_SEGMENT_BULK",
      data: prodSegments
    });
  } catch (e) {
    const { message } = e;
    yield put(mainError(message));
  }
}
export function* watchGetNewCropAndProduct() {
  yield takeLatest("FETCH_NEW_CROP", getNewCropAndProduct);
}

function* getCountryOfOrigin() {
  try {
    const countryOrigin = yield call(getCountryOriginApi);
    const { data } = countryOrigin;
    yield put({
      type: "COUNTRY_ORIGIN_BULK",
      data
    });
  } catch (e) {
    console.log(e);
  }
}
export function* watchGetCountryOrigin() {
  yield takeLatest("FETCH_COUNTRY_ORIGIN", getCountryOfOrigin);
}

function* postProductSegments(action) {
  try {
    yield put(productProcessing());
    const response = yield call(postProductSegmentsApi, action.data);
    const { data } = response;

    if (data) {
      yield put(productSuccess());
    } else {
      yield put(productError("Something went wrong."));
    }
  } catch (e) {
    yield put(productError("Something went wrong."));
  }
}
export function* watchPostProductSegments() {
  yield takeLatest("POST_PRODUCT", postProductSegments);
}

function* postVarmas(action) {
  try {
    const plant = yield select(state => state.main.plant);
    const selected = yield select(state => state.main.selectedMap);
    const opAsParentList = yield select(state => state.main.opasparent);

    const varietyArray = [];
    for (let i = 0; i < selected.length; i += 1) {
      const number = selected[i];
      const { varietyID, statusCode, replacedLot, transferType } = plant[
        number
      ]; // eNumber
      /**
       * if transferType is CMS or Hyb only when
       * selected row will be considered for Send to Varmas.
       */
      const typetype = true; // transferType === 'CMS' || transferType === 'Hyb';

      if ((statusCode === 100 || replacedLot) && typetype) {
        const opas = opAsParentList.find(row => row.varietyID === varietyID);
        varietyArray.push({
          varietyID,
          opAsParent: opas.checked,
          newGID: 0,
          mainGID: 0,
          forcedBit: false
        });
      }
    }

    if (varietyArray.length > 0) {
      const processObj = varietyArray[varietyArray.length - 1];
      const response = yield call(postVarmasApi, [processObj]);
      const { status, data } = response;
      if (status === 200) {
        const { results, errors, warning } = data;

        if (errors.length > 0) {
          yield put({ type: "CHANGE_SENDTO_STAGE", stage: "err" });
          yield put(varmasError(errors));
        } else if (warning !== null) {
          yield put({ type: "CHANGE_SENDTO_STAGE", stage: "c" });
          yield put({
            type: "SEND_TO_VARMAS_CONFIRM",
            msg: warning.message,
            mainGID: warning.gid,
            data: results,
            obj: processObj,
            skipGID: warning.skipGID
          });
          yield put({ type: "SELECT_POP_LAST" });
        } else {
          if (varietyArray.length === 1) {
            yield put({ type: "CHANGE_SENDTO_STAGE", stage: "succ" });
            const msg = "Selected record(s) successfully sent to Varmas.";
            yield put(varmasSuccess(msg));
          } else {
            yield put({
              type: "CHANGE_SENDTO_STAGE",
              stage: varietyArray.length > 0 ? "n" : "end"
            });
          }
          yield put({ type: "SELECT_POP_LAST" });
        }
      }
    }
  } catch (e) {
    const { response } = e;
    const { data } = response;

    yield put(varmasError(data.message));
  }
}

export function* watchPostVarmas() {
  yield takeLatest("POST_VARMAS", postVarmas);
}

function* postVarmas2(action) {
  try {
    const selected = yield select(state => state.main.selectedMap);
    const response = yield call(postVarmasApi, action.row);
    const { status, data } = response;
    if (status === 200) {
      const { results, errors, warning } = data;

      // if there is any error
      // this action will terminate
      if (errors.length > 0) {
        yield put({ type: "CHANGE_SENDTO_STAGE", stage: "err" });
        yield put(varmasError(errors));
        return null;
      }

      // If warining exists, we will show selection box
      // where use can Use existing or new parentlin or event cancel this action
      if (warning !== null) {
        yield put({ type: "CHANGE_SENDTO_STAGE", stage: "c" });
        yield put({
          type: "SEND_TO_VARMAS_CONFIRM",
          msg: warning.message,
          mainGID: warning.gid,
          data: results,
          obj: {
            varietyID: action.row[0].varietyID,
            opAsParent: action.row[0].opAsParent
          },
          skipGID: warning.skipGID
        });
        return null;
      }

      // if selected row is zero, indicates that the action is completed
      // here we will display success message
      if (selected.length === 0) {
        yield put(
          varmasSuccess("Selected record(s) successfully sent to Varmas.")
        );
        yield put({ type: "CHANGE_SENDTO_STAGE", stage: "succ" });
      } else {
        // if selected row is greater than 0
        // this indicates that there is more send to varmas action required
        yield put({ type: "CHANGE_SENDTO_STAGE", stage: "n" });
      }
    }
  } catch (e) {
    const { response } = e;
    const { data } = response;
    yield put({ type: "CHANGE_SENDTO_STAGE", stage: "n" });
    yield put(varmasError(data.message));
  }
}
export function* watchPostVarmas2() {
  yield takeLatest("POST_VARMAS_2", postVarmas2);
}

function* postDelete(action) {
  try {
    yield put(deleteProcessing());

    const {
      varietyID,
      fileName,
      pageNumber,
      pageSize,
      filter,
      sorting
    } = action;

    const delRes = yield call(deleteApi, varietyID);
    if (delRes.data) {
      yield put({ type: "SELECT_BLANK" });
      yield put(deleteSuccess("All selected record(s) successfully deleted."));
      // refetching done here :: loking for better process
      // FETCH_MAIN
      yield put({
        type: "FETCH_MAIN",
        fileName,
        pageNumber,
        pageSize,
        filter,
        sorting
      });
    }
  } catch (e) {
    const { data } = e.response;
    yield put(deleteError(data.message));
  }
}
export function* watchPostDelete() {
  yield takeLatest("POST_DELETE", postDelete);
}

function* postReplaceLOTLookup(action) {
  try {
    const { gid } = action;
    const result = yield call(postReplaceLOTLookupApi, gid);

    yield put({
      type: "REPLACE_BULK",
      data: result.data
    });
  } catch (e) {
    const { response } = e;
    const { data } = response;
    yield put(replaceError(data.message));
  }
}
export function* watchPostReplaceLotLookup() {
  yield takeLatest("GET_REPLACE_LIST", postReplaceLOTLookup);
}

function* postReplaceLOT(action) {
  try {
    yield put(replaceProcessing());
    yield call(postReplaceLOTApi, action);
    yield put({ type: "FLAG_TOGGLE" });
    yield put(replaceSuccess("Succesfully Lot replaced."));
  } catch (e) {
    const { data } = e.response;
    if (e.response && data) {
      const { errorType, message } = data;
      const msg =
        errorType === 2
          ? message
          : "Request failed, please contact you administrator";
      yield put(replaceError(msg));
    }
  }
}
export function* watchPostReplaceLot() {
  yield takeLatest("POST_REPLACE_SAVE", postReplaceLOT);
}

/**
 * Fetch list of pedigree records related to selected record.
 * S 110
 * watch and fetch function
 */
function* getPedigree(action) {
  try {
    yield put(mainProcessing());
    const currentList = yield select(state => state.pedigree.pedigree);

    const { includeChildFrom, parentNode, parentLevel } = action;
    const response = yield call(pedigreeApi, action);

    let { message = "" } = response.data;
    const { data, status } = response.data;
    if (status.code === "1" && data.rows.length > 0) {
      let gridRow = [];
      const { columns, rows } = data;
      rows.forEach(row => {
        if (parentLevel !== null && parentNode !== 0 && row.lvl === "0") {
          return;
        }
        if (row["Lot~ids"] !== null) {
          row["Lot~ids"].forEach(id => {
            gridRow.push({
              ...row,
              parentNode:
                includeChildFrom === null && row.lvl > 0 ? null : parentNode,
              parentLevel,
              lotID: id
            });
          });
        }
      });

      if (includeChildFrom !== null) {
        const firstSlice = currentList.slice(0, includeChildFrom + 1);
        const lastSlice = currentList.slice(
          includeChildFrom + 1,
          currentList.length
        );
        gridRow = [...firstSlice, ...gridRow, ...lastSlice];
      }
      const total = gridRow.length;
      yield put({ type: "PEDIGREE_SIZE", pageSize: total });
      yield put({ type: "PEDIGREE_BULK", pedigree: gridRow });
      yield put({ type: "PEDIGREE_COLUMN_BULK", columns });
      yield put({ type: "PEDIGREE_RECORDS", total });
      yield put({ type: "PEDIGREE_REFRESH" });
      yield put(mainSuccess());
    } else {
      message = status.message || message;
      // for temporary purpose
      if (message === "User is not logged in") {
        sessionStorage.removeItem("isLoggedIn");
      }
      yield put(mainError(message));
    }
  } catch (e) {
    const { message } = e;
    yield put(mainError(message));
  }
}
export function* watchGetPedigree() {
  yield takeLatest("GET_PEDIGREE", getPedigree);
}

function* filterPedigree() {
  yield put({ type: "PEDIGREE_FILTER_CHANGE" });
}
export function* watchFilterPedigree() {
  yield takeLatest("FILTER_PEDIGREE_ADD", filterPedigree);
}

function* removeFilterPedigree() {
  yield put({ type: "PEDIGREE_FILTER_CHANGE" });
}
export function* watchRemoveFilterPedigree() {
  yield takeLatest("FILTER_PEDIGREE_REMOVE", removeFilterPedigree);
}

function* clearFilterPedigree() {
  yield put({ type: "PEDIGREE_FILTER_CHANGE" });
}
export function* watchClearFilterPedigree() {
  yield takeLatest("FILTER_PEDIGREE_CLEAR", clearFilterPedigree);
}

function* fetchPhenomToken(action) {
  try {
    yield put(mainProcessing());
    const response = yield call(fetchPhenomTokenApi);
    if (response && response.data && response.data.accessToken) {
      action.callback(response.data.accessToken);
      yield put(mainSuccess());
    } else {
      yield put(mainError("Failed to fetch token."));
    }
  } catch (e) {
    const { message } = e;
    yield put(mainError(message));
  }
}
export function* watchFetchPhenomToken() {
  yield takeLatest("FETCH_PHENOM_TOKEN", fetchPhenomToken);
}

function* fetchUserCrops(action) {
  try {
    yield put(mainProcessing());
    const response = yield call(fetchUserCropsApi);
    if (response && response.data) {
      yield put({
        type: "FETCH_USER_CROPS_SUCCEEDED",
        crops: response.data.map(crop => crop.cropCode)
      });
      yield put(mainSuccess());
    } else {
      yield put(mainError("Failed to fetch token."));
    }
  } catch (e) {
    const { message } = e;
    yield put(mainError(message));
  }
}
export function* watchFetchUserCrops() {
  yield takeLatest("FETCH_USER_CROPS", fetchUserCrops);
}

function* undoReplaceLot({ payload }) {
  try {
    yield put(mainProcessing());
    const response = yield call(undoReplaceLotApi, payload);
    if (response) {
      yield put(undoReplaceLotSucceeded(payload.gid));
      yield put(mainSuccess());
    } else {
      yield put(mainError("Failed to undo replace."));
    }
  } catch (e) {
    const { message } = e;
    yield put(mainError(message));
  }
}
export function* watchUndoReplaceLot() {
  yield takeLatest("UNDO_REPLACE_LOT", undoReplaceLot);
}
