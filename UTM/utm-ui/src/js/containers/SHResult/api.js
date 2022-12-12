import axios from "axios";
import urlConfig from "../../urlConfig";

export const getTraitDeterminationResultSHApi = (
  pageNumber,
  pageSize,
  filter
) =>
  axios({
    method: "post",
    url: urlConfig.getTraitDeterminationResultSH,
    data: {
      pageNumber,
      pageSize,
      filter
    }
  });

export const postTraitDeterminationResultSHApi = ({
  cropCode,
  data,
  pageNumber,
  pageSize,
  filter
}) =>
  axios({
    method: "post",
    url: urlConfig.postTraitDeterminationResultSH,
    data: {
      cropCode,
      data,
      pageNumber,
      pageSize,
      filter
    }
  });
