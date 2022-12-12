export const CRITERIA_PER_CROP_FETCH = 'CRITERIA_PER_CROP_FETCH';
export const criteriaPerCropFetch = (page, size, sortBy, sortOrder, filter) => ({ 
  type: CRITERIA_PER_CROP_FETCH,
  page, 
  size,
  sortBy, 
  sortOrder,
  filter
});

export const CRITERIA_PER_CROP_COLUMN_ADD = 'CRITERIA_PER_CROP_COLUMN_ADD';
export const criteriaPerCropColumnAdd = data => ({
  type: CRITERIA_PER_CROP_COLUMN_ADD,
  data
});

export const CRITERIA_PER_CROP_DATA_ADD = 'CRITERIA_PER_CROP_DATA_ADD';
export const criteriaPerCropDataAdd = data => ({
  type: CRITERIA_PER_CROP_DATA_ADD,
  data
});

export const CRITERIA_PER_CROP_CROPS_ADD = 'CRITERIA_PER_CROP_CROPS_ADD';
export const criteriaPerCropCropsAdd = data => ({
  type: CRITERIA_PER_CROP_CROPS_ADD,
  data
});

export const CRITERIA_PER_CROP_MATERIALTYPES_ADD = 'CRITERIA_PER_CROP_MATERIALTYPES_ADD';
export const criteriaPerCropMaterialTypesAdd = data => ({
  type: CRITERIA_PER_CROP_MATERIALTYPES_ADD,
  data
});


export const POST_CRITERIA_PER_CROP = 'POST_CRITERIA_PER_CROP';
export const postCriteriaPerCrop = (
  CropCode,
  MaterialTypeID,
  ThresholdA,
  ThresholdB,
  CalcExternalAppHybrid,
  CalcExternalAppParent, 
  action) => 
  ({
    type: POST_CRITERIA_PER_CROP,
      CropCode,
      MaterialTypeID,
      ThresholdA,
      ThresholdB,
      CalcExternalAppHybrid,
      CalcExternalAppParent,
      action
});

export const CRITERIA_PER_CROP_EMPTY = 'CRITERIA_PER_CROP_EMPTY';
export const criteriaPerCropEmpty = () => ({
  type: CRITERIA_PER_CROP_EMPTY
});

export const CRITERIA_PER_CROP_TOTAL = 'CRITERIA_PER_CROP_TOTAL';
export const criteriaPerCropTotal = total => ({
  type: CRITERIA_PER_CROP_TOTAL,
  total
});

export const CRITERIA_PER_CROP_PAGE = 'CRITERIA_PER_CROP_PAGE';
export const criteriaPerCropPage = page => ({
  type: CRITERIA_PER_CROP_PAGE,
  page
});

export const CRITERIA_PER_CROP_PAGESIZE = 'CRITERIA_PER_CROP_PAGESIZE';
export const criteriaPerCropPageSize = pageSize => ({
  type: CRITERIA_PER_CROP_PAGESIZE,
  pageSize
});

export const CRITERIA_PER_CROP_FILTER_ADD = 'CRITERIA_PER_CROP_FILTER_ADD';
export const criteriaPerCropFilter = obj => ({
  type: CRITERIA_PER_CROP_FILTER_ADD,
  data: obj
});