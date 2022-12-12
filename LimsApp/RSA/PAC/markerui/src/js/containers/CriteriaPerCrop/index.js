import React from "react";
import { connect } from "react-redux";

import CriteriaPerCropComponent from "./CriteriaPerCropComponent";
import {
  criteriaPerCropFetch,
  postCriteriaPerCrop,
  criteriaPerCropPage,
  criteriaPerCropPageSize,
  criteriaPerCropFilter,
  criteriaPerCropEmpty
} from "./criteriaPerCropAction";

const mapState = (state) => ({
  sideMenu: state.sidemenuReducer,
  role: state.user.role.includes("pac_approvecalcresults"),
  columns: state.criteriaPerCrop.columns,
  data: state.criteriaPerCrop.data,
  crops: state.criteriaPerCrop.crops,
  materialTypes: state.criteriaPerCrop.materialTypes,
  filter: state.criteriaPerCrop.filter,
  total: state.criteriaPerCrop.total,
  page: state.criteriaPerCrop.page,
  pageSize: state.criteriaPerCrop.size
});
const mapDispatch = (dispatch) => ({
  sidemenu: () => dispatch(sidemenuClose()),
  fetchCriteriaPerCrop: (page, size, sortBy, sortOrder, filter) => {
    dispatch(criteriaPerCropFetch(page, size, sortBy, sortOrder, filter));
  },
  empty: () => dispatch(criteriaPerCropEmpty()),
  pageChange: page => dispatch(criteriaPerCropPage(page)),
  pageSizeChange: pageSize => dispatch(criteriaPerCropPageSize(pageSize)),
  filterChange: filter => dispatch(criteriaPerCropFilter(filter)),
  postCriteriaPerCropFunc: (
    CropCode,
    MaterialTypeID,
    ThresholdA,
    ThresholdB,
    CalcExternalAppHybrid,
    CalcExternalAppParent,
    action
  ) =>
    dispatch(
      postCriteriaPerCrop(
        CropCode,
        MaterialTypeID,
        ThresholdA,
        ThresholdB,
        CalcExternalAppHybrid,
        CalcExternalAppParent,
        action
      )
    ),
});

export default connect(mapState, mapDispatch)(CriteriaPerCropComponent);
