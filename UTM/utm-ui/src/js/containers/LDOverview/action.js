import {
  FETCH_LD_OVERVIEW,
  FILTER_LD_ADD_BLUK,
  LD_CHANGE,
  LD_RECORS,
  LD_PAGE,
  LD_BLUK,
  LD_COLUMN_BULK
} from './constant';

export const fetchLDOverview = (pageNumber, pageSize, filter, active) => ({
  type: FETCH_LD_OVERVIEW,
  pageNumber,
  pageSize,
  filter,
  active
});
export const ldActiveChange = flag => ({
  type: LD_CHANGE,
  flag
});
export const ldTotal = total => ({
  type: LD_RECORS,
  total
});
export const ldPage = pageNumber => ({
  type: LD_PAGE,
  pageNumber
});
export const ldDataBulk = data => ({
  type: LD_BLUK,
  data
});
export const ldColumnBulk = columns => ({
  type: LD_COLUMN_BULK,
  columns
});
export const filterLDaddBluk = filter => ({
  type: FILTER_LD_ADD_BLUK,
  filter
});
