// CONSTANTS
const TOGGLE_MATERIAL_MARKER = 'TOGGLE_MATERIAL_MARKER';
// 2GB -> CONSTANTS
const SAVE_MATERIAL_MARKER = 'SAVE_MATERIAL_MARKER';
// 3GB -> CONSTANTS
const SAVE_3GB_MATERIAL_MARKER = 'SAVE_3GB_MATERIAL_MARKER';
// S2S -> CONSTANTS
const FETCH_S2S = 'FETCH_S2S';
const SAVE_S2S_MATERIAL_MARKER = 'SAVE_S2S_MATERIAL_MARKER';

const SAVE_CNT_MATERIAL_MARKER = 'SAVE_CNT_MATERIAL_MARKER';

const SAVE_RDT_MATERIAL_MARKER = 'SAVE_RDT_MATERIAL_MARKER';

// ###########################################
// ACTIONS
export const toggleMaterialMarker = markerMaterialList => ({
  type: TOGGLE_MATERIAL_MARKER,
  markerMaterialList
});
// 2GB -> ACTIONS
export const saveMarkerMaterial = materialsMarkers => ({
  type: SAVE_MATERIAL_MARKER,
  materialsMarkers
});
// 3GB -> ACTIONS
export const save3GBMarkerMaterial = materialsMarkers => ({
  type: SAVE_3GB_MATERIAL_MARKER,
  materialsMarkers
});
// S2S -> ACTIONS
export const fetchS2S = ({ testID, pageNumber, pageSize, filter }) => ({
  type: FETCH_S2S,
  testID,
  pageNumber,
  pageSize,
  filter
});
export const saveS2SMarkerMaterial = materialsMarkers => ({
  type: SAVE_S2S_MATERIAL_MARKER,
  materialsMarkers
});
export const saveCNTMarkerMaterial = materialsMarkers => ({
  type: SAVE_CNT_MATERIAL_MARKER,
  materialsMarkers
});

export const saveRDTMarkerMaterial = materialsMarkers => ({
  type: SAVE_RDT_MATERIAL_MARKER,
  materialsMarkers
});
