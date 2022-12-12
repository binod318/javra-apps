import axios from "axios";
import urlConfig from "../../../urlConfig";

export const getSlotListApi = (testID) =>
  axios({
    method: "get",
    url: urlConfig.getSlot,
    params: { testID }
  });

export const postLinkSlotTestApi = ({ testID, slotID }) =>
  axios({
    method: "post",
    url: urlConfig.getLinkSlotTest,
    data: {
      testID,
      slotID,
    },
  });
