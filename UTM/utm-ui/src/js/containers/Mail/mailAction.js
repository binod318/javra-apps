/* @flow */
import {
  MAIL_CONFIG_FETCH,
  MAIL_CONFIG_APPEND,
  MAIL_CONFIG_UPDATE,
  MAIL_CONFIG_DESTORY
} from './mailConstant';
import { MailType } from './mailType';

// SAGA
export const mailConfigFetchFunc = () => ({
  type: MAIL_CONFIG_FETCH
});

export const mailConfigAppendFunc = (obj: MailType) => ({
  type: MAIL_CONFIG_APPEND,
  ...obj
});

export const mailConfigUpdateFunc = (obj: MailType) => ({
  type: MAIL_CONFIG_UPDATE,
  ...obj
});

export const mailConfigDeleteFunc = (id: Number) => ({
  type: MAIL_CONFIG_DESTORY,
  id
});

// components
export const dMailConfigFetch = (
  pageNumber: Number,
  pageSize: Number,
  usedForMenu: String
) => ({
  type: MAIL_CONFIG_FETCH,
  pageNumber,
  pageSize,
  usedForMenu
});
export const dMailConfigAppend = (
  configID: Number,
  cropCode: String,
  configGroup: String,
  recipients: String,
  brStationCode: String,
  usedForMenu: String
) => ({
  type: MAIL_CONFIG_APPEND,
  configID,
  cropCode,
  configGroup,
  recipients,
  brStationCode,
  usedForMenu
});
export const dMailCconfigDestory = (
  configID: Number,
  usedForMenu: String
) => ({
  type: MAIL_CONFIG_DESTORY,
  configID,
  usedForMenu
});
