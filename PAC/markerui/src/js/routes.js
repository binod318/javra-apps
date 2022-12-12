// routes
import Lab from "./containers/LabCapacity";
import Capacity from "./containers/CapacitySO";
import LabPreparation from "./containers/LabPreparation/";
import PlanningOverview from "./containers/PlanningBatchesSO/";
import MarkerPerVariety from "./containers/MarkerPerVariety";
import CriteriaPerCrop from "./containers/CriteriaPerCrop";
import LabResult from "./containers/LabResult";
import LabResultDetail from "./containers/LabResult/LabResultDetailComponent";

import TotalPAC from "./containers/TotalPAC/";

export const couputeRoute = (role, v) => {
  const LabCapacityRole = role.includes("pac_handlelabcapacity");
  const CapacityPlannngSORole = role.includes("pac_so_handlecropcapacity");
  const PlanningBatchesSORole = role.includes("pac_so_planbatches");
  const LabPreparationRole = role.includes("pac_managelabpreparation");
  const MarkerPerVarietyRole = role.includes("pac_handlelabcapacity");
  const TraitMarkerPerVarietyRole = role.includes("pac_handlelabcapacity");

  const LabResultRole = role.includes("pac_approvecalcresults") || role.includes("pac_labemployee");
  const LabResultDetailRole = role.includes("pac_approvecalcresults") || role.includes("pac_labemployee") || role.includes("pac_so_viewer");
  const CriteriaPerCropRole = role.includes("pac_approvecalcresults");
  const TotalPACRole = role.includes("pac_so_viewer");
  const RequestLIMSRole = role.includes("pac_requestlims");

  const anyMenu =
    LabCapacityRole ||
    CapacityPlannngSORole ||
    PlanningBatchesSORole ||
    LabPreparationRole ||
    MarkerPerVarietyRole ||
    LabResultRole ||
    TotalPACRole ||
    RequestLIMSRole;

  const accessRoute = [];
  if (!anyMenu) return [];

  if (LabCapacityRole) {
    accessRoute.push({
      index: 1,
      name: "Lab Capacity",
      to: "/",
      role: LabCapacityRole,
      comp: Lab,
      id: "s_m_labCapacity",
      show: true,
      icon: "icon-server",
    });
  }
  if (CapacityPlannngSORole) {
    accessRoute.push({
      index: 2,
      name: "Capacity Planning SO",
      to: "/planning",
      role: CapacityPlannngSORole,
      comp: Capacity,
      id: "s_m_mailConfig",
      show: true,
      icon: "icon-table",
    });
  }

  if (PlanningBatchesSORole || CapacityPlannngSORole) {
    accessRoute.push({
      index: 4,
      name: "Planning Batches SO",
      to: "/overview",
      role: PlanningBatchesSORole,
      comp: PlanningOverview,
      id: "s_m_planning_overview",
      show: true,
      icon: "icon-clipboard",
    });
  }
  if (LabPreparationRole) {
    accessRoute.push({
      index: 3,
      name: "Lab Preparation",
      to: "/preparation",
      role: LabPreparationRole,
      comp: LabPreparation,
      id: "s_m_planning_overview",
      show: true,
      icon: "icon-folder-open",
    });
  }

  if (LabResultRole) {
    accessRoute.push({
      index: 5,
      name: "Lab Results",
      to: "/lab_result",
      role: LabResultRole, // show to all but edit possible toLabCapacityRole
      comp: LabResult,
      id: "s_m_lab_result",
      show: true,
      icon: "icon-chart-1",
    });
  }

  if (LabResultDetailRole) {
    accessRoute.push({
      index: 7,
      name: "Lab Results",
      to: "/lab_result/:id",
      role: LabResultDetailRole, // show to all but edit possible to pac_handlelabcapacity
      comp: LabResultDetail,
      id: "s_m_lab_result_detail",
      show: false,
      icon: "icon-chart-1",
    });
  }

  if (TraitMarkerPerVarietyRole) {
    accessRoute.push({
      index: 6,
      name: "Trait Marker Per Variety",
      to: "/markerpervariety",
      role: LabCapacityRole, // show to all but edit possible to pac_handlelabcapacity
      comp: MarkerPerVariety,
      id: "s_m_marker_per_variety",
      show: true,
      icon: "icon-ok-circled",
    });
  }
  if (TotalPACRole) {
    accessRoute.push({
      index: 7,
      name: "Total PAC",
      to: "/total_pac",
      role: TotalPACRole, // pac_so_viewer
      comp: TotalPAC,
      id: "s_m_marker_per_variety",
      show: true,
      icon: "icon-buffer",
    });
  }
  if (CriteriaPerCropRole) {
    accessRoute.push({
      index: 8,
      name: "Criteria Per Crop",
      to: "/criteriapercrop",
      role: CriteriaPerCropRole,
      comp: CriteriaPerCrop,
      id: "s_m_criteria_per_crop",
      show: true,
      icon: "icon-ok-squared",
    });
  }

  return accessRoute;
};
