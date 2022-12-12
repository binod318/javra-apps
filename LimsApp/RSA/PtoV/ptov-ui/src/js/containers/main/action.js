export const recipocalProcessing = () => ({ type: "RECIPOCAL_PROCESSING" });
export const recipocalSuccess = message => ({
  type: "RECIPOCAL_SUCCESS",
  message
});
export const recipocalError = message => ({ type: "RECIPOCAL_ERROR", message });

export const loginProcessing = () => ({ type: "REQUEST_LOGIN_PROCESSING" });
export const loginSuccess = () => ({ type: "REQUEST_LOGIN_SUCCESS" });
export const loginError = message => ({ type: "REQUEST_LOGIN_ERROR", message });

export const importProcessing = () => ({ type: "IMPORT_PROCESSING" });
export const importSuccess = () => ({ type: "IMPORT_SUCCESS" });
export const importError = message => ({ type: "IMPORT_ERROR", message });

export const productProcessing = () => ({ type: "PRODUCT_PROCESSING" });
export const productSuccess = () => ({ type: "PRODUCT_SUCCESS" });
export const productError = message => ({ type: "PRODUCT_ERROR", message });

export const mainProcessing = () => ({ type: "MAIN_PROCESSING" });
export const mainSuccess = () => ({ type: "MAIN_SUCCESS" });
export const mainError = message => ({ type: "MAIN_ERROR", message });

export const varmasProcessing = () => ({ type: "VARMAS_PROCESSING" });
export const varmasSuccess = message => ({ type: "VARMAS_SUCCESS", message });
export const varmasError = message => ({ type: "VARMAS_ERROR", message });

export const deleteProcessing = () => ({ type: "DELETE_PROCESSING" });
export const deleteSuccess = message => ({ type: "DELETE_SUCCESS", message });
export const deleteError = message => ({ type: "DELETE_ERROR", message });

export const replaceProcessing = () => ({ type: "REPLACE_PROCESSING" });
export const replaceSuccess = message => ({ type: "REPLACE_SUCCESS", message });
export const replaceError = message => ({ type: "REPLACE_ERROR", message });
//
export const phenomeLogin = (token = "", user = "", pwd = "") => ({
  type: "PHENOME_LOGIN",
  token,
  user,
  pwd
});
export const phenomeLoginDone = () => ({
  type: "PHENOME_LOGIN_DONE"
});
export const getResearchGroups = () => ({
  type: "GET_RESEARCH_GROUPS"
});
export const getResearchGroupsDone = data => ({
  type: "GET_RESEARCH_GROUPS_DONE",
  data
});
export const getFolders = (id, path) => ({
  type: "GET_FOLDERS",
  id,
  path
});
export const getFoldersDone = data => ({
  type: "GET_FOLDERS_DONE",
  data
});
export const phenomeLogout = () => ({
  type: "PHENOME_LOGOUT"
});
export const importPhenome = data => ({
  type: "IMPORT_PHENOME",
  data
});

export const replaceLookup = gid => ({
  type: "GET_REPLACE_LIST",
  gid
});
//GID, LotGID, PhenomeLotID, Level, Data
export const replaceSave = (GID, LotGID, PhenomeLotID, Level, Data) => ({
  type: "POST_REPLACE_SAVE",
  GID,
  LotGID,
  PhenomeLotID,
  Level,
  Data
});
// export const replaceSave = (gid, replaceID) => ({
//   type: 'POST_REPLACE_SAVE',
//   gid,
//   replaceID
// });

// helper function
export const SetOpAsParentFunc = data => {
  const selected = [];
  data.map(row => {
    if (row.opAsParent) {
      selected.push({
        varietyID: row.varietyID,
        checked: false
      });
    } else {
      selected.push({
        varietyID: row.varietyID,
        checked: false
      });
    }
    return null;
  });
  return selected;
};

export const undoReplaceLotSucceeded = gid => ({
  type: "UNDO_REPLACE_LOT_SUCCEEDED",
  gid
});
