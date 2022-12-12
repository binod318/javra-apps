import { authContext } from "../config/adal";

export function checkStatus(status, type = "") {
  switch (type) {
    case "CREATED":
      return status === 100;
    case "REQUESTED":
      return status === 200;
    case "RESERVED":
      return status === 300;
    case "CONFIRM":
      return status === 400;
    case "INLIMS":
      return status === 500;
    case "RECEIVED":
      return status === 600;
    case "COMPLETED":
      return status === 700;
    default:
      return false;
  }
}
export function getDim() {
  const width = window.document.body.offsetWidth;
  const height = window.document.body.offsetHeight;
  return {
    width,
    height,
  };
}
export function getStatusName(status, array) {
  if (array) {
    const match = array.find((d) => d.statusCode === status);
    if (match) return `- ${match.statusName}`;
  }
  return "";
}

const flag = !true;
export const show = (func) =>
  flag ? { type: "AAAA" } : { type: "LOADER_SHOW", func };
export const hide = (func) =>
  flag ? { type: "AAAA" } : { type: "LOADER_HIDE", func };

export const dateValidRe = /^(0?[1-9]|[12][0-9]|3[01])[\/\-](0?[1-9]|1[012])[\/\-]\d{4}$/;
export const dateValidRe2 = /^\d{1,2}:\d{2}([ap]m)?$/;

export const errorStyle = {
  borderColor: "red",
};
export const changeStyle = {
  borderColor: "#03a9f4",
};

function getToken() {
  return new Promise((resolve, reject) => {
    authContext.acquireToken(
      adalConfig.endpoints.api,
      (message, token, msg) => {
        if (token) resolve(token);
      }
    );
  });
}
