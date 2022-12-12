import {
  FETCH_RDT_OVERVIEW,
  FILTER_RDT_ADD_BLUK,
  RDT_CHANGE,
  RDT_RECORS,
  RDT_PAGE,
  RDT_BLUK
} from './constant';

export const fetchRDTOverview = (pageNumber, pageSize, filter, active) => ({
  type: FETCH_RDT_OVERVIEW,
  pageNumber,
  pageSize,
  filter,
  active
});
export const rdtActiveChange = flag => ({
  type: RDT_CHANGE,
  flag
});
export const rdtTotal = total => ({
  type: RDT_RECORS,
  total
});
export const rdtPage = pageNumber => ({
  type: RDT_PAGE,
  pageNumber
});
export const rdtDataBulk = data => ({
  type: RDT_BLUK,
  data
});
export const filterRDTaddBluk = filter => ({
  type: FILTER_RDT_ADD_BLUK,
  filter
});
