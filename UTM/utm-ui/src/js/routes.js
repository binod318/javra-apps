// routes
import Home from "./containers/Home";
import PlateFilling from "./containers/PlateFilling/PlateFilling";
import PlatPlan from "./containers/PlatPlan";
import Breeder from "./containers/Breeder";
import LeafDiskCapacityPlanning from "./containers/LeafDiskCapacityPlanning";
// import BreederOverview from './containers/BreederOverview/index';
import Lab from "./containers/Lab";
import LabOverview from "./containers/LabOverview";
import LabApproval from "./containers/LabApproval";
// import PrintList from './containers/PunchList/PunchList';
import Trait from "./containers/Trait";
import TraitResult from "./containers/TraitResult";
import LabProtocol from "./containers/LabProtocol";
import Mail from "./containers/Mail/index";
// import Test from './containers/Test/Email';
import CTMaintain from "./containers/CTMaintain";
import RDTOverview from "./containers/RDTOverview";
import RDTResult from "./containers/RdtResult";
import { hiddenTesttypes } from "./helpers/helper";

import LDlabCapacity from "./containers/LDlabCapacity";
import LDLabOverview from "./containers/LDLabOverview";
import LDLabApproval from "./containers/LDLabApproval";
import LDOverview from "./containers/LDOverview";

import SHOverview from "./containers/SHOverview";
import SHResult from "./containers/SHResult";

const menuGroups = {
  utmGeneral: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12],
  rdt: [1, 13, 5, 18, 11],
  leafDisk: [1, 17, 15, 14, 15, 16, 10, 11],
  seedHealth:[1,19,20,5,11]
};
export const routeList = [
  {
    index: 1,
    name: "Assign request",
    to: "/",
    role: "utmCommonRole",
    comp: Home,
    id: "s_m_assigmMarker",
    icon: "icon-bookmark"
  },
  {
    index: 2,
    name: "Plate filling",
    to: "/platefilling",
    role: "utmCommonRole",
    comp: PlateFilling,
    id: "s_m_plateFilling",
    icon: "icon-grid"
  },
  {
    index: 3,
    name: "BTA-MM Folder Overview",
    to: "/platplan",
    role: "platePlansRole",
    comp: PlatPlan,
    id: "s_m_platePlanOverview",
    icon: "icon-th-list"
  },
  {
    index: 17,
    name: "Leaf Disk Overview",
    to: "/ldoverview",
    role: "platePlansRole",
    comp: LDOverview,
    id: "s_m_ldoverview",
    icon: "icon-sweden"
  },
  {
    index: 13,
    name: "RDT Overview",
    to: "/rdtoverview",
    role: "rdtRole",
    comp: RDTOverview,
    id: "s_m_rdtoverview",
    icon: "icon-sweden"
  },
  {
    index: 4,
    name: "Capacity Planning",
    to: "/breeder",
    role: ["requesttest", "managemasterdatautm"],
    comp: Breeder,
    id: "s_m_capacityPlanning",
    icon: "icon-wpforms"
  },
  
  //Seed Health
  {
    index: 19,
    name: "Seed Health Overview",
    to: "/shoverview",
    role: "platePlansRole",
    comp: SHOverview,
    id: "s_m_shoverview",
    icon: "icon-sweden"
  },

  {
    index: 15,
    name: "LD Capacity Planning",
    to: "/leaf-disk-capacity-planning",
    role: ["requesttest", "managemasterdatautm"],
    comp: LeafDiskCapacityPlanning,
    id: "s_m_leaf_disk_capacityPlanning",
    icon: "icon-wpforms"
  },
  {
    index: 5,
    name: "Traits Relation",
    to: "/traits",
    role: "utmCommonRole",
    comp: Trait,
    id: "s_m_traitsRelation",
    icon: "icon-ok-circled"
  },
  {
    index: 6,
    name: "Traits Result",
    to: "/result-traits",
    role: "utmCommonRole",
    comp: TraitResult,
    id: "s_m_traitsResult",
    icon: "icon-chart-1"
  },
  {
    index: 18,
    name: "RDT Traits Result",
    to: "/rdt-result",
    role: "utmCommonRole",
    comp: RDTResult,
    id: "managemasterdatautm",
    icon: "icon-chart-outline"
  },
  {
    index: 20,
    name: "Seed Health Traits Result",
    to: "/sh-result",
    role: "utmCommonRole",
    comp: SHResult,
    id: "managemasterdatautm",
    icon: "icon-chart-outline"
  },
  {
    index: 14,
    name: "LD Lab Capacity",
    to: "/ld-lab-capacity",
    role: "handlelabcapacity",
    comp: LDlabCapacity,
    id: "s_m_ldLabCapacity",
    icon: "icon-calendar-empty"
  },
  {
    index: 7,
    name: "Lab Capacity",
    to: "/lab",
    role: "handlelabcapacity",
    comp: Lab,
    id: "s_m_labCapacity",
    icon: "icon-calendar-inv"
  },
  {
    index: 15,
    name: "LD Lab Overview",
    to: "/ld-lab-overview",
    role: "handlelabcapacity",
    comp: LDLabOverview,
    id: "s_m_ldLabOverview",
    icon: "icon-eye"
  },
  {
    index: 8,
    name: "Lab Overview",
    to: "/lab-overview",
    role: "handlelabcapacity",
    comp: LabOverview,
    id: "s_m_labOverview",
    icon: "icon-eye"
  },
  {
    index: 16,
    name: "LD Lab Approval",
    to: "/ld-lab-approval",
    role: "handlelabcapacity",
    comp: LDLabApproval,
    id: "s_m_ldLabApproval",
    icon: "icon-ok-squared"
  },
  {
    index: 9,
    name: "Lab Approval",
    to: "/lab-approval",
    role: "handlelabcapacity",
    comp: LabApproval,
    id: "s_m_labApproval",
    icon: "icon-ok-squared"
  },
  {
    index: 10,
    name: "Lab Protocol",
    to: "/lab-protocal",
    role: "handlelabcapacity",
    comp: LabProtocol,
    id: "s_m_labProtocal",
    icon: "icon-spread"
  },  
  {
    index: 11,
    name: "Mail Config",
    to: "/mail",
    role: "admin",
    comp: Mail,
    id: "s_m_mailConfig",
    icon: "icon-mail"
  },
  {
    index: 12,
    name: "Maintenance C&T",
    to: "/ctmaintain",
    role: "managemasterdatautm",
    comp: CTMaintain,
    id: "s_m_ctmaintain",
    icon: "icon-cog"
  }
  // { name: 'Test', to: '/test', role: 'admin', comp: Test, id: 's_m_test'},
];

export const couputeRoute = (role, testTypeID, menuGroup) => {
  const requestTestRole = role.includes("requesttest");
  const manageMasterDataUTMRole = role.includes("managemasterdatautm");
  const handleLabCpapacityRole = role.includes("handlelabcapacity");
  const adminRole = role.includes("admin");
  const platePlansRole = requestTestRole || handleLabCpapacityRole;
  const utmCommonRole = requestTestRole || manageMasterDataUTMRole || adminRole;

  const rdtCommonRosle = requestTestRole || handleLabCpapacityRole;

  const accessRoute = [];
  routeList
    .filter(route => {
      if (!menuGroup) return true;
      if (menuGroups[menuGroup].indexOf(route.index) > -1) {
        //TestType to Hide will be on the menu: Works only for production, when empty value comes in hiddentTesttypes function everything will be displayed
        if(hiddenTesttypes().split('|').find(o => o == menuGroup.toLowerCase()))
          return false;

        return true;
      }
      return false;
    })
    .forEach(route => {
      const { name, role: routeRoles } = route;
      if (Array.isArray(routeRoles)) {
        if (requestTestRole || manageMasterDataUTMRole) {
          accessRoute.push(route);
        }
        return null;
      }
      switch (routeRoles) {
        case "utmCommonRole": {
          if (utmCommonRole) {
            if (name === "Plate filling") {
              // TODO :: improve this code
              const conditionTestType =
                testTypeID === 7 || testTypeID === 6 || testTypeID === 8;
              if (conditionTestType) return null;

              accessRoute.push(route);
            } else {
              accessRoute.push(route);
            }
          }
          break;
        }
        case "platePlansRole":
          if (platePlansRole) accessRoute.push(route);
          break;
        case "rdtRole":
          if (rdtCommonRosle) accessRoute.push(route);
          break;
        default: {
          if (role.includes(routeRoles)) accessRoute.push(route);
        }
      }
      return null;
    });
  return accessRoute;
};
