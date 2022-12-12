/*!
 *
 * MAIN SCREEN
 * ------------------------------
 *
 */

import { connect } from "react-redux";

import MainComponent from "./main";
import { phenomeLogin } from "./action";
import { any } from "ramda";

const mapState = state => ({
  withoutHierarchy: state.main.filterWithout,
  renderChangeMain: state.main.renderChangeMain,
  flag: state.main.flag,
  status: state.status,
  files: state.user.crops,
  fileSelected: state.main.files,
  fileStatus: state.main.fileStatus,
  plant: state.main.plant,
  column: state.main.column,
  opasparent: state.main.opasparent,
  selected: state.main.selectedMap,
  total: state.main.total.total,
  pageNumber: state.main.total.pageNumber,
  pageSize: state.main.total.pageSize,
  filterList: state.main.filter,
  sort: state.main.sort,

  isLoggedIn: state.phenome.isLoggedIn,
  importView: state.phenome.importView,
  productsegment: state.main.productsegment,

  pedigreeView: state.pedigree.pedigreeNode.pedigreeView,
  replaceNode: state.pedigree.pedigreeNode.replaceNode,
  stem: state.pedigree.pedigreeNode.stem,
  stemKey: state.pedigree.pedigreeNode.stemKey,
  selectedList: state.main.selectedMap,
  sendToVarmasFlag: state.main.sendToVarmasFlag,
  sendToVarmasStage: state.main.sendToVarmasStage,
  sendToVarmasConfirm: state.main.sendToVarmasConfirm
});
const mapDispatch = dispatch => ({
  withoutHierarchyChange: value => dispatch({ type: "TOGGLE_WITHOUT", value }),
  fileSelect: cropSelected => dispatch({ type: "FILE_SELECT", cropSelected }),
  fetchFileStatus: status => dispatch({ type: "FILE_STATUS", status }),
  fetchNewCrop: cropSelected =>
    dispatch({ type: "FETCH_NEW_CROP", cropSelected }),
  fetchCountryOrigin: () => dispatch({ type: "FETCH_COUNTRY_ORIGIN" }),
  saveData: data => dispatch({ type: "POST_PRODUCT", data }),
  fetchMain: (
    fileName,
    pageNumber,
    pageSize,
    filter,
    sorting,
    opAsParentFlag = true
  ) => {
    dispatch({
      type: "FETCH_MAIN",
      fileName,
      pageNumber,
      pageSize,
      filter,
      sorting,
      opAsParentFlag
    });
  },
  fetchData: (
    objectType,
    objectID,
    researchGroupID,
    pageSize,
    tree,
    folderObjectType,
    researchGroupObjectType,
    withoutHierarchy
  ) => {
    dispatch({
      type: "IMPORT_PHENOME",
      objectType,
      objectID,
      cropID: researchGroupID,
      pageSize,
      tree,
      folderObjectType,
      researchGroupObjectType,
      withoutHierarchy
    });
  },

  filterAdd: obj => dispatch({ type: "FILTER_MAIN_ADD", ...obj }),
  filterRemove: name => dispatch({ type: "FILTER_MAIN_REMOVE", name }),
  filterClear: () => dispatch({ type: "FILTER_MAIN_CLEAR" }),

  select: (index, data, shift, ctrl, ctrlIndex) => {
    dispatch({
      type: "SELECT_ADD",
      index,
      data,
      shift,
      ctrl,
      ctrlIndex
    });
  },
  selectAll: (data, selected) => {
    dispatch({
      type: "SELECT_ALL",
      data,
      selected
    });
  },
  selectReset: () => dispatch({ type: "SELECT_BLANK" }),
  toVarmas: () => {
    dispatch({ type: "POST_VARMAS" });
  },
  resetError: () => {
    dispatch({ type: "RESET_ERROR" });
    dispatch({ type: "REPLACE_LIST_EMPTY" });
    dispatch({ type: "CHANGE_SENDTO_STAGE", stage: "end" });
  },
  stopSendToVarmas: () => dispatch({ type: "CHANGE_SENDTO_STAGE", stage: "i" }),
  deleteRow: (varietyID, fileName, pageNumber, pageSize, filter, sorting) => {
    dispatch({
      type: "POST_DELETE",
      varietyID,
      fileName,
      pageNumber,
      pageSize,
      filter,
      sorting
    });
  },
  cropUpdate: crop => dispatch({ type: "MAIN_CROP_UPDATE", ...crop }),
  testLogin: tok => dispatch(phenomeLogin(tok)),
  recipocal: varietyID => dispatch({ type: "RECIPROCAL_RECORD", varietyID }),
  opAsParentChange: varietyID => dispatch({ type: "OP_TOGGLE", varietyID }),
  filterPedigreeAdd: obj => dispatch({ type: "FILTER_PEDIGREE_ADD", ...obj }),
  importViewFunc: flag => dispatch({ type: "IMPORT_VIEW_FLAG", flag }),
  pedigreeViewFunc: flag => dispatch({ type: "PEIGREE_VIEW_FLAG", flag }),
  pedigreeReplaceNodeFunc: replaceNode =>
    dispatch({ type: "PEDIGREE_REPLACENODE", replaceNode }),
  pedigreeReplaceNodeResetFunc: () => {
    dispatch({ type: "SELECT_BLANK" });
    dispatch({ type: "PEDIGREE_REPLACENODE_RESET" });
  },
  stemSet: stem => dispatch({ type: "PEDIGREE_VIEW_STEM", stem }),
  stemKeySet: stemKey => dispatch({ type: "PEDIGREE_VIEW_STEMKEY", stemKey }),

  sendtoVarmasFlagFunc: () => dispatch({ type: "SEND_TRUE" }),
  sendtoVarmasStageFunc: stage =>
    dispatch({ type: "CHANGE_SENDTO_STAGE", stage }),
  toVarmasSolo: data => {
    dispatch({
      type: "POST_VARMAS",
      data
    });
  },
  fetchPhenomToken: callback =>
    dispatch({ type: "FETCH_PHENOM_TOKEN", callback }),
  undoReplaceLot: payload => dispatch({ type: "UNDO_REPLACE_LOT", payload })
});
export default connect(
  mapState,
  mapDispatch
)(MainComponent);
