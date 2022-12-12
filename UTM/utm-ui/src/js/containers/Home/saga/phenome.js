/**
 * Created by sushanta on 4/12/18.
 */
import { call, put, select } from "redux-saga/effects";
import parse from "xml-parser";
import { lensPath, set, concat } from "ramda";
import {
  phenomeLoginApi,
  phenomeLoginSSOApi,
  getResearchGroupsApi,
  getFoldersApi,
  importPhenomeApi,
  importPhenomeLeafDiskApi,
  importPhenomeLeafDiskConfigApi,
  getThreeGBavailableProjectsApi,
  importPhenomeThreegbApi,
  sendToThreeGBCockPitApi,
  getS2SCapacityApi,
  postS2SImportApi,
  importPhenomeCNTApi,
  importPhenomeSeedHealthApi,
  postRDTImportApi,
  fetchPhenomTokenApi
} from "../api/phenome";
import {
  phenomeLoginDone,
  getResearchGroupsDone,
  getFoldersDone,
  phenomeLogout
} from "../actions/phenome";

import {
  noInternet,
  notificationMsg,
  // notificationSuccess,
  notificationSuccessTimer
} from "../../../saga/notificationSagas";

import { show, hide } from "../../../helpers/helper";

export function* phenomeLogin(action) {
  try {
    yield put(show("phenomeLogin"));
    const loginUrl = window.adalConfig.enabled
      ? phenomeLoginSSOApi
      : phenomeLoginApi;
    const response = yield call(loginUrl, action);
    if (response.data.status) {
      yield put(phenomeLoginDone());
    } else {
      const obj = {};
      obj.message = response.data.message;
      yield put(notificationMsg(obj));
    }
    yield put(hide("phenomeLogin"));
  } catch (err) {
    yield put(hide("phenomeLogin"));
    console.log(err);
  }
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
        return null;
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
    yield put(hide("getResearchGroups"));
  } catch (err) {
    yield put(hide("getResearchGroups"));
  }
}
export function* getFolders({ id, path }) {
  try {
    yield put(show("getFolders"));
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
    yield put(hide("getFolders"));
  } catch (err) {
    yield put(hide("getFolders"));
  }
}
export function* importPhenome(action) {
  try {
    yield put(show("importPhenome"));
    let result = [];
    const { testTypeID, sourceID, testTypeMenu } = action.data;
    const leafDiskMaterialMap = {};

    const isTestThreeGB = testTypeID === 4 || testTypeID === 5;
    const istTestS2S = testTypeID === 6;
    const istTestCNT = testTypeID === 7;
    const istTestRDT = testTypeID === 8;
    const istTestSeedHealth = testTypeID === 10;
    const isLeafDisk = testTypeID === 9;
    const isLeafDiskConfig = testTypeID === 9 && sourceID && sourceID > 0;

    if (isTestThreeGB) {
      result = yield call(importPhenomeThreegbApi, action.data);
    } else if (istTestRDT) {
      const { data } = action;
      const newData = {
        ...data,
        ...{
          BreedingStationCode: data.brStationCode
        }
      };
      result = yield call(postRDTImportApi, newData);
    } else if (istTestS2S) {
      const { data } = action;

      // ## Parameter name change in service so we are doing this
      const newData = {
        ...data,
        ...{
          BreedingStationCode: data.brStationCode
        }
      };
      // delete newData.brStationCode;
      result = yield call(postS2SImportApi, newData);
    } else if (istTestCNT) {
      result = yield call(importPhenomeCNTApi, action.data);
    } else if (istTestSeedHealth) {
      result = yield call(importPhenomeSeedHealthApi, action.data);
    } else if (isLeafDiskConfig) {
      result = yield call(importPhenomeLeafDiskConfigApi, action.data);
    } else if (isLeafDisk) {
      result = yield call(importPhenomeLeafDiskApi, action.data);
    } else {
      result = yield call(importPhenomeApi, action.data);
    }
    const { data } = result;

    if (data && data.success) {
      yield put({ type: "RESET_ASSIGN" });

      // Clear confirm box
      yield put({ type: "PHENOME_WARNING_FALSE" });

      if (data.dataResult) {
        yield put({ type: "DATA_BULK_ADD", data: data.dataResult.data });
        yield put({ type: "COLUMN_BULK_ADD", data: data.dataResult.columns });
        yield put({ type: "TOTAL_RECORD", total: data.total });
        yield put({
          type: "FILTERED_TOTAL_RECORD",
          grandTotal: data.totalCount
        });

        yield put({ type: "PAGE_RECORD", pageNumber: 1 });
      }
      // REFETCH FILE LIST
      const { breedingStationCode, cropCode } = data.file;

      // selction of breeding station
      yield put({
        type: "BREEDING_STATION_SELECTED",
        selected: breedingStationCode
      });
      // selection of crop
      yield put({ type: "ADD_SELECTED_CROP", crop: cropCode });

      // expectedDate
      yield put({
        type: "FILELIST_FETCH",
        breeding: breedingStationCode,
        crop: cropCode,
        testTypeMenu
      });
      yield put({ type: "FILTER_CLEAR" });
      yield put({ type: "FILTER_PLATE_CLEAR" });

      // todo make params correction
      const tobj = {
        testTypeID: data.file.testTypeID,
        cropCode: data.file.cropCode,
        fileID: data.file.fileID,
        fileTitle: data.file.fileTitle,
        testID: data.file.testID,
        importDateTime: data.file.importDateTime,
        plannedDate: data.file.plannedDate,
        userID: data.file.userID,
        remark: data.file.remark, // init blank
        remarkRequired: data.file.remarkRequired,
        statusCode: data.file.statusCode,
        slotID: null,
        expectedDate: data.file.expectedDate,
        importLevel: action.data.importLevel,
        breedingStationCode: data.file.breedingStationCode,
        excludeControlPosition: data.file.excludeControlPosition || false,
        siteID: data.file.siteID,
        sampleType: data.file.sampleType
      };
      yield put({ type: "FILELIST_ADD_NEW", file: tobj });
      // marker fetch :: works good

      //Do not fetch marker for Leafdisk and Seedhealth on first tab
      if (action.data.determinationRequired && data.file.testTypeID < 9) {
        yield put({
          type: "FETCH_MARKERLIST",
          testID: data.file.testID,
          cropCode: data.file.cropCode,
          testTypeID: action.data.testTypeID
        });
      }
      // setting rootTestID
      yield put({
        type: "ROOT_SET_ALL",
        testID: data.file.testID,
        testTypeID: data.file.testTypeID,
        remark: data.file.remark || "",
        statusCode: data.file.statusCode,
        remarkRequired: data.file.remarkRequired,
        slotID: null
      });

      yield put({ type: "FETCH_TESTLOOKUP", breedingStationCode, cropCode, testTypeMenu });
      // setting Filling page to 1 if new file selected
      // home
      yield put({ type: "PAGE_RECORD", pageNumber: 1 });
      // plate
      yield put({ type: "PAGE_PLATE_RECORD", pageNumber: 1 });
      // update test file attributes
      yield put({
        type: "SELECT_MATERIAL_TYPE",
        id: data.file.materialTypeID
      });
      yield put({
        type: "SELECT_TEST_PROTOCOL",
        id: data.file.testProtocolID
      });
      yield put({
        type: "SELECT_MATERIAL_STATE",
        id: data.file.materialstateID
      });
      yield put({
        type: "SELECT_CONTAINER_TYPE",
        id: data.file.containerTypeID
      });
      yield put({
        type: "CHANGE_ISOLATION_STATUS",
        isolationStatus: data.file.isolated
      });
      yield put({
        type: "CHANGE_CUMULATE_STATUS",
        cumulate: data.file.cumulate
      });
      yield put({
        type: "TESTTYPE_SELECTED",
        id: data.file.testTypeID
      });
      yield put({
        type: "ROOT_TESTTYPEID",
        testTypeID: data.file.testTypeID
      });
      yield put({
        type: "CHANGE_PLANNED_DATE",
        plannedDate: data.file.plannedDate
      });

      //LeafDisk : for #plants
      const refresh = yield select(
        state => !state.assignMarker.materials.refresh
      );

      data.dataResult.data.forEach(row => {
        leafDiskMaterialMap[`${row.materialID}-#plants`] = {
          '#plants': row['#plants'] || "",
          changed: false,
          newState: row['#plants'] || ""
        };
      });
      yield put({ type: "ADD_LDMATERIAL_MAP", leafDiskMaterialMap, refresh });

      yield put(hide("importPhenome"));
    } else {
      const { errors, warnings: warningMessage } = data;
      const obj = {};
      if (warningMessage.length > 0) {
        // ///////////
        // WARNING //
        // ///////////
        yield put({ type: "PHENOME_WARNING", warningMessage });
      } else {
        // ERROR
        obj.message = errors;
        yield put(notificationMsg(obj));
      }
    }

    yield put(hide("importPhenome"));
    // END copy
  } catch (e) {
    yield put(hide("importPhenome"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* getBGAvailableProjects(action) {
  try {
    yield put(show("getBGAvailableProjects"));
    const result = yield call(
      getThreeGBavailableProjectsApi,
      action.crop,
      action.breeding,
      action.testTypeCode
    );
    yield put({ type: "THREEGB_DATA_BULK_ADD", data: result.data });
    yield put(hide("getBGAvailableProjects"));
  } catch (e) {
    yield put(hide("getBGAvailableProjects"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

export function* sendToThreeGBCockpit(action) {
  try {
    yield put(show("sendToThreeGBCockpit"));

    const result = yield call(
      sendToThreeGBCockPitApi,
      action.testID,
      action.filter
    );
    if (result.data) {
      yield put({ type: "RESETALL" });
      // filelistreducer reset
      yield put({ type: "RESET_ALL" });
      // testslookup rest
      yield put({ type: "TESTSLOOKUP_RESET_ALL" });

      yield put({
        type: "REMOVE_FILE_AFTER_SENDTO_3GB",
        testID: action.testID
      });
      yield put(notificationSuccessTimer("Successfully sent to 3GB cockpit."));
    }

    yield put(hide("sendToThreeGBCockpit"));
  } catch (e) {
    yield put(hide("sendToThreeGBCockpit"));
    if (e.response !== undefined) {
      if (e.response.data) {
        yield put(notificationMsg(e.response.data));
      }
    } else {
      yield put(noInternet);
    }
  }
}

// S2S
export function* getS2SCapacity(action) {
  try {
    yield put(show("getS2SCapacity"));

    const result = yield call(getS2SCapacityApi, action);
    if (result.data) {
      yield put({
        type: "STORE_S2S_CAPACITY",
        data: result.data
      });
    }

    yield put(hide("getS2SCapacity"));
  } catch (e) {
    yield put(hide("getS2SCapacity"));
    console.log(e);
  }
}

export function* fetchPhenomToken(action) {
  try {
    yield put(show("phenomeLogin"));
    const response = yield call(fetchPhenomTokenApi);
    yield put(hide("phenomeLogin"));
    if (response && response.data && response.data.accessToken) {
      action.callback(response.data.accessToken);
    }
  } catch (e) {
    yield put(hide("phenomeLogin"));
    console.log(e);
  }
}
