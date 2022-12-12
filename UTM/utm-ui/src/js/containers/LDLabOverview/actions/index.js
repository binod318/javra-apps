export const pageTitle = () => ({
  type: 'SET_PAGETITLE',
  title: 'LD Lab Overview'
});

export const fetchYearPeriod = (year, periodID, siteID, filter) => ({
  type: 'LEAF_DISK_LAB_OVERVIEW_DATA_FETCH',
  year,
  periodID,
  siteID,
  filter
});

export const fetchYearPeriodUpdate = (data, year) => ({
  type: 'LEAF_DISK_LAB_OVERVIEW_DATA_UPDATE',
  data,
  year
});
