import axios from "axios";
import urlConfig from "../../../urlConfig";

export const saveConfigNameApi = (action) => {
  const { testID, name } = action
  axios({
    method: "post",
    url: urlConfig.saveConfigurationName,
    data: {
      testID,
      sampleConfigName: name
    },
  });
}
  
