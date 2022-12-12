import {
  FETCH_SH_OVERVIEW,
  FILTER_SH_ADD_BLUK,
  SH_CHANGE,
  SH_RECORS,
  SH_PAGE,
  SH_BLUK,
  SH_COLUMN_BULK
} from './constant';

export const fetchSHOverview = (pageNumber, pageSize, filter, active) => ({
  type: FETCH_SH_OVERVIEW,
  pageNumber,
  pageSize,
  filter,
  active
});
export const shActiveChange = flag => ({
  type: SH_CHANGE,
  flag
});
export const shTotal = total => ({
  type: SH_RECORS,
  total
});
export const shPage = pageNumber => ({
  type: SH_PAGE,
  pageNumber
});
export const shDataBulk = data => ({
  type: SH_BLUK,
  data
});
export const shColumnBulk = columns => ({
  type: SH_COLUMN_BULK,
  columns
});
export const filterSHaddBluk = filter => ({
  type: FILTER_SH_ADD_BLUK,
  filter
});
