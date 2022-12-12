import axios from "axios";
import { authContext } from "../config/adal";

axios.interceptors.request.use(
  config =>
    // Do something before request is sent
    new Promise((resolve, reject) => {
      authContext.acquireToken(
        window.adalConfig.endpoints.api,
        (message, token) => {
          if (token) {
            config.headers.Authorization = `Bearer ${token}`;
            resolve(config);
          } else {
            // Do something with error of acquiring the token
            reject(config);
          }
        }
      );
    }),
  error => {
    // Do something with request error
    return Promise.reject(error);
  }
);
