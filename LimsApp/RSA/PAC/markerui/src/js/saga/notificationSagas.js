// TODO: need to add these action creator to action in respective modules/container's actions
export const noInternet = {
  type: "NOTIFICATION_SHOW",
  status: true,
  message: [],
  messageType: 1,
  notificationType: 0,
  code: "",
};
// TODO: need to add these action creator to action in respective modules/container's actions
export function notificationSuccess(message) {
  return {
    type: "NOTIFICATION_SHOW",
    status: true,
    message,
    messageType: 2,
    notificationType: 2,
    code: "",
  };
}
export function notificationSuccessTimer(message) {
  return {
    type: "NOTIFICATION_SHOW",
    status: true,
    message,
    messageType: 4,
    notificationType: 2,
    code: "",
  };
}
// TODO: need to add these action creator to action in respective modules/container's actions
export function notificationGeneric() {
  return {
    type: "NOTIFICATION_SHOW",
    status: true,
    message: "",
    messageType: 1,
    notificationType: 0,
    code: "",
  };
}
// TODO: need to add these action creator to action in respective modules/container's actions
export function notificationMsg(data) {
  return {
    type: "NOTIFICATION_SHOW",
    status: true,
    message: data.Message || data.message || "",
    messageType: data.Type || data.type || 2,
    notificationType: 0,
    code: data.code || "",
  };
}

export function notificationAlert(data) {
  return {
    type: "NOTIFICATION_SHOW",
    status: true,
    message: data.Message || data.message || "",
    messageType: 4,
    notificationType: 3,
    code: data.code || "",
  };
}

export function notificationTimer(data) {
  return {
    type: "NOTIFICATION_SHOW",
    status: true,
    message: data.Message || data.message || "",
    messageType: 3,
    notificationType: 0,
    code: data.code || "",
  };
}