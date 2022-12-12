import { all, takeEvery } from "redux-saga/effects";

import {
  watchGetRelation,
  watchPostRelation,
  watchGetDetermination
} from "../../js/containers/relation/saga";
import {
  watchGetResult,
  watchGetTraits,
  watchGetTraitList,
  watchGetScreeningList,
  watchPostTraitScreening,
  watchGetCrops
} from "../../js/containers/result/saga";
import {
  watchReciprocalRecord,
  watchPhenomeLogin,
  getResearchGroups,
  getFolders,
  importPhenome,
  watchPostGermplasm,
  watchGetNewCropAndProduct,
  watchGetCountryOrigin,
  watchPostProductSegments,
  watchPostVarmas,
  watchPostVarmas2,
  watchPostDelete,
  watchPostReplaceLotLookup,
  watchPostReplaceLot,
  watchGetPedigree,
  watchFilterPedigree,
  watchRemoveFilterPedigree,
  watchClearFilterPedigree,
  watchFetchPhenomToken,
  watchFetchUserCrops,
  watchUndoReplaceLot
} from "../../js/containers/main/saga";

import {
  watchCovert,
  watchUnmapColumn
} from "../../js/containers/convert/saga";

import {
  watchGetMail,
  watchpostMail,
  watchDeleteMail
} from "../../js/containers/mail/saga";

export default function* rootSaga() {
  yield all([
    watchReciprocalRecord(),
    watchPhenomeLogin(),
    yield takeEvery("GET_RESEARCH_GROUPS", getResearchGroups),
    yield takeEvery("GET_FOLDERS", getFolders),
    yield takeEvery("IMPORT_PHENOME", importPhenome),
    watchPostGermplasm(),
    watchGetNewCropAndProduct(),
    watchGetCountryOrigin(),
    watchPostProductSegments(),
    watchPostVarmas(),
    watchPostVarmas2(),
    watchPostDelete(),
    watchPostReplaceLotLookup(),
    watchPostReplaceLot(),
    watchGetPedigree(),
    watchFilterPedigree(),
    watchRemoveFilterPedigree(),
    watchClearFilterPedigree(),

    watchGetRelation(),
    watchPostRelation(),
    watchGetDetermination(),

    watchGetResult(),
    watchGetTraits(),
    watchGetTraitList(),
    watchGetScreeningList(),
    watchPostTraitScreening(),
    watchGetCrops(),

    watchCovert(),
    watchUnmapColumn(),

    watchGetMail(),
    watchpostMail(),
    watchDeleteMail(),
    watchFetchPhenomToken(),
    watchFetchUserCrops(),
    watchUndoReplaceLot()
  ]);
}
