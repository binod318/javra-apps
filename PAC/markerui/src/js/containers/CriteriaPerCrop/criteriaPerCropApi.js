import axios from "axios";
import urlConfig from "../../urlConfig";

export const getCriteriaPerCropAPI = (
  PageNr,
  PageSize,
  SortBy,
  SortOrder,
  Filters
) =>
  axios({
    method: "post",
    url: urlConfig.getCriteriaPerCrop,
    data: {
      PageNr,
      PageSize,
      SortBy,
      SortOrder,
      Filters
    }
  });

export const postCriteriaPerCropAPI = (
  CropCode,
  MaterialTypeID,
  ThresholdA,
  ThresholdB,
  CalcExternalAppHybrid,
  CalcExternalAppParent,
  Action
) => {
  const obj =
    {
      CropCode,
      MaterialTypeID,
      ThresholdA,
      ThresholdB,
      CalcExternalAppHybrid,
      CalcExternalAppParent,
      Action
    };
  return axios({
    method: "post",
    url: urlConfig.postCriteriaPerCrop,
    data: obj,
  });
};
