import axios from "axios";

import URLS from "../../urls";

export const getmappedgermplasmApi = (
  fileName,
  pageNumber,
  pageSize,
  filter,
  sorting
) =>
  axios({
    method: "post",
    url: URLS.getmappedgermplasm,
    data: {
      fileName,
      pageNumber,
      pageSize,
      filter,
      sorting
    }
  });

export const postUnmapColumns = (cropCode, columns) =>
  axios({
    method: "post",
    url: URLS.postUnmapColumn,
    data: {
      cropCode,
      columns
    }
  });
