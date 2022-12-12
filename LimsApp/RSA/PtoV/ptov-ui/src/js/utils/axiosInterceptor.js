import axios from "axios";
import { authContext } from "../config/adal";

axios.interceptors.request.use(
  function(config) {
    // Do something before request is sent
    return new Promise((resolve, reject) => {
      authContext.acquireToken(
        adalConfig.endpoints.api,
        (message, token, msg) => {
          if (!!token) {
            config.headers.Authorization = `Bearer ${token}`;
            resolve(config);
          } else {
            // Do something with error of acquiring the token
            reject(config);
          }
        }
      );
    });
  },
  function(error) {
    // Do something with request error
    return Promise.reject(error);
  }
);
