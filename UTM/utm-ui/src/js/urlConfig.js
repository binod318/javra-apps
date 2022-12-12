const serverUrl = `${window.services.API_BASE_URL}/api/v1/`;
const planningUrl = `${window.services.API_BASE_PLANNING_URL}/api/v1/`;

const urlConfig = {
  // source
  getImportSource: `${serverUrl}Master/getImportSources`,

  // Planning
  planingCapacity: `${planningUrl}Capacity`,
  postPlaningCapacity: `${planningUrl}Capacity/saveCapacity`,
  getApprovalListForLab: `${planningUrl}Capacity/getApprovalListForLab`,
  getPlanPeriods: `${planningUrl}Planning/Master/PlanPeriods`,
  approveSlot: `${planningUrl}Slot/approveSlot`,
  denySlot: `${planningUrl}Slot/denySlot`,
  updateSlotPeriod: `${planningUrl}Slot/UpdateSlotPeriod`,

  // new call 2018/08/15
  getBreedingNew: `${serverUrl}Master/getbreedingstation`,

  // Breed
  getBreeder: `${planningUrl}Planning/Master/ReserveCapacityLookup`,
  postBreeder: `${planningUrl}Capacity/reserveCapacity`,
  getPeriod: `${planningUrl}Planning/Master/DisplayPeriod`,
  getPlatestTest: `${planningUrl}Slot/AvailablePlatesTests`,
  getMaterialType: `${planningUrl}Planning/Master/MaterialTypePerCropLookup`,
  postSlotEdit: `${planningUrl}slot/editSlot`,

  // OVERVIEW
  getLabOverview: `${planningUrl}Slot/plannedOverview`,
  postLabOverviewExcel: `${planningUrl}Slot/ExportLabOverviewToExcel`,

  // slot
  getSlotBreedingOverview: `${planningUrl}Slot/breedingOverview`,
  deleteSlotBreedingOverview: `${planningUrl}Slot/breedingOverview`,
  updateSlotBreedingOverview: `${planningUrl}Slot/breedingOverview`,
  getApprovedSlots: `${planningUrl}Slot/GetApprovedSlots`,

  // determination :: Marker
  postMarkers: `${serverUrl}determination/assignDeterminations`,
  getDetermination: `${serverUrl}determination/getDataWithDeterminations`, // plateFilling GRID call
  getMaterials: `${serverUrl}determination/getMaterialsWithDeterminations`, // plateFilling GRID call
  getMarkers: `${serverUrl}Determination`,
  getExternalDeterminations: `${serverUrl}determination/getExternalDeterminations`,

  getMaterialsWithDeterminationsForExternalTest: `${serverUrl}determination/getMaterialsWithDeterminationsForExternalTest`,

  // ExcelData
  postExternalFile: `${serverUrl}externaltests/import`,
  postFile: `${serverUrl}exceldata/import`,
  getFileData: `${serverUrl}exceldata/getdata`,
  getExternalTests: `${serverUrl}externaltests/getExternalTests`,
  getExport: `${serverUrl}externaltests/export`,

  // getFileList
  getFileList: `${serverUrl}File`,

  // slot
  getSlot: `${serverUrl}test/getslotpertest`,
  getLinkSlotTest: `${serverUrl}test/linkslotntest`,

  deleteSlot: `${planningUrl}Capacity/deleteSlot`,
  moveSlot: `${planningUrl}Capacity/MoveSlot`,
  moveSlotPeriod: `${planningUrl}Slot/UpdateSlotPeriod`,

  // Materials
  getPlant: `${serverUrl}Materials`,
  // delMaterials: `${serverUrl}materials/Delete`, changed
  delMaterials: `${serverUrl}materials/markdead`,
  deleteDeadMaterials: `${serverUrl}materials/DeleteDeadMaterial`,
  saveDeterminations: `${serverUrl}determination/assigndeterminations`,

  delMaterialsUndo: `${serverUrl}materials/UndoDead`,
  delDeleteReplicate: `${serverUrl}materials/DeleteReplicate`,

  getmaterialState: `${serverUrl}materials/getMaterialstate`,
  getmaterialType: `${serverUrl}materials/getMaterialtype`,
  replicateMaterials: `${serverUrl}materials/replicate`,
  getContainerTypes: `${serverUrl}test/getContainerTypes`,

  // LeafDisk planning
  ldPlaningCapacity: `${planningUrl}leafdisk/Capacity/get`,
  postLDplaningCapacity: `${planningUrl}leafdisk/Capacity/save`,
  getLDreserveCapacityLookup: `${planningUrl}leafdisk/Slot/ReserveCapacityLookup`,
  getLeafDiskSlotBreedingOverview: `${planningUrl}leafdisk/Slot/breedingOverview`,
  postLDReserve: `${planningUrl}leafdisk/Slot/ReserveCapacity`,
  exportCapacityPlanningLeafDisk: `${planningUrl}leafdisk/Slot/ExportCapacityPlanningToExcel`,
  postSlotEditLeafDisk: `${planningUrl}leafdisk/slot/editSlot`,
  getApprovedSlotsLeafDisk: `${planningUrl}leafdisk/Slot/GetApprovedSlots`,
  getAvailSamples: `${planningUrl}leafdisk/Slot/AvailableSample`,
  updateSlotPeriodLeafDisk: `${planningUrl}leafdisk/Slot/UpdateSlotPeriod`,
  getLDApprovalListForLab: `${planningUrl}leafdisk/Capacity/getApprovalListForLab`,

  // Leafdisk-OVERVIEW
  getLabOverviewLeafDisk: `${planningUrl}leafdisk/Slot/plannedOverview`,
  postLabOverviewExcelLeafDisk: `${planningUrl}leafdisk/Slot/ExportLabOverviewToExcel`,

  //LeafDisk
  getConfigurationList: `${serverUrl}leafdisk/getconfiglist`,
  saveConfigurationName: `${serverUrl}leafdisk/saveconfigname`,
  importLeafDisk: `${serverUrl}leafdisk/import`,
  importfromconfigurationLeafDisk: `${serverUrl}leafdisk/importfromconfiguration`,
  getTestProtocols: `${serverUrl}Master/getTestProtocols`,
  getLeafDiskFileData: `${serverUrl}leafdisk/getdata`,
  saveLeafDiskMaterial: `${serverUrl}leafdisk/updatematerial`,
  getLeafDiskSampleData: `${serverUrl}leafdisk/getsamplematerial`,
  saveleafDiskSample: `${serverUrl}leafdisk/savesample`,
  getLeafDiskSamples: `${serverUrl}leafdisk/getsample`,
  saveLeafDiskSampleMaterial: `${serverUrl}leafdisk/savesamplematerial`,
  materialDeterminations: `${serverUrl}leafdisk/getDataWithDeterminations`,
  getLeafDiskDeterminations: `${serverUrl}determination/getLeafDiskDetermination`,
  manageInfo: `${serverUrl}leafdisk/manageInfo`,
  leafDiskRequestSampleTest: `${serverUrl}leafdisk/requestsampletest`,
  getLeafDiskOverview: `${serverUrl}leafdisk/getleafdiskoverview`,
  getLeafDiskOverviewExcelApi: `${serverUrl}leafdisk/leafdiskoverviewtoExcel`,
  getLDPunchList: `${serverUrl}leafdisk/getPunchList`,
  getLDPrintlabels: `${serverUrl}leafdisk/printLabels`,

  getWellType: `${serverUrl}well/getwelltypes`,

  // Test
  getTestsLookup: `${serverUrl}test/gettestslookup`,
  updateTestAttributes: `${serverUrl}test/updateTest`,
  postSaveNrOfSamples: `${serverUrl}test/saveNrOfSamples`,
  postDeleteTest: `${serverUrl}test/deleteTest`,

  // TestType
  getTestType: `${serverUrl}TestType`,

  // Well
  getWellPosition: `${serverUrl}well/getwellpositions`,
  postAssignFixedPosition: `${serverUrl}well/assignfixedposition`,
  postUndoFixedPosition: `${serverUrl}well/undofixedposition`,

  // Reorder Save to DB
  postWellSaveDB: `${serverUrl}well/save`,

  // PunchList
  getPunchList: `${serverUrl}punchlist/getPunchlist`,

  // PlateLabel
  postPlateLabel: `${serverUrl}test/printPlateLabels`,

  // Reserve Plate
  postReservePlate: `${serverUrl}test/reserveplatesinlims`,

  // Plate in LIMS
  postPlateInLims: `${serverUrl}test/fillPlatesInLims`,

  // Get test detail
  getTestDetail: `${serverUrl}test/gettestdetail`,

  // Remarks
  putTestSaveRemark: `${serverUrl}test/saveremark`,

  // complete request
  putTestUpdateStatus: `${serverUrl}test/updateteststatus`,
  // mixed with above call ( Binod above and krishna below )
  putCompleteTestRequest: `${serverUrl}test/completeTestRequest`,

  // getStatus
  getStatusList: `${serverUrl}/status/getstatuslist/test`,

  // Phenome url
  // https://onprem.unity.phenome-networks.com/login_do
  phenomeLogin: `${serverUrl}phenome/login`,
  phenomeSSOLogin: `${serverUrl}phenome/ssologin`,
  getResearchGroups: `${serverUrl}phenome/getResearchGroups`,
  getFolders: `${serverUrl}phenome/getFolders`,
  importPhenome: `${serverUrl}phenome/import`,

  // Traits
  getRelationTrait: `${serverUrl}traitDetermination/getTraitsAndDetermination`,
  getRelationDetermination: `${serverUrl}traitDetermination/getDeterminations`,
  getRelation: `${serverUrl}traitDetermination/getRelationTraitDetermination`,
  postRelation: `${serverUrl}traitdetermination/saveRelationTraitDetermination`,

  getCropTraits: `${serverUrl}traitdetermination/getCrops`,

  // Traits Results
  getTraitResults: `${serverUrl}traitdetermination/getTraitDeterminationResult`,
  postTraitResults: `${serverUrl}traitdetermination/saveTraitDeterminationResult`,
  // getTraitValues: `${serverUrl}Master/getTraitValues`, // ?cropCode=TO&traitID=230
  getTraitValues: `${serverUrl}traitdetermination/getTraitLOV`, // ?cropCode=TO&traitID=230
  checkValidation: `${serverUrl}validateData/ValidateTraitDeterminationResult`,

  // 3gb
  getThreeGBavailableProjects: `${serverUrl}threeGB/getAvailableProjects`,
  postThreeGBimport: `${serverUrl}threeGB/import`,
  postSendToThreeGBCockpit: `${serverUrl}threeGB/sendTo3GBCockpit`,

  postGetThreeGBmaterial: `${serverUrl}materials/getSelectedMaterial`, // get3GBMaterial`, // getSelectedMaterial
  postAddToThreeGB: `${serverUrl}materials/AddMaterial`, // AddTo3GB // AddMaterial

  // EMAIL CONFIG
  getEmailConfig: `${serverUrl}emailConfig/GetEmailConfig`,
  postEmailConfig: `${serverUrl}EmailConfig`,
  deletEmailConfig: `${serverUrl}EmailConfig`,

  getPlatPlan: `${serverUrl}test/getPlatePlanOverview`,

  // PLAT PLAN
  postPlatPlanExcel: `${serverUrl}test/PlatePlanResultToExcel`,

  // Plate Filling
  postPlateFillingExcel: `${serverUrl}test/TestToExcel`,

  // S2S
  getS2SCapacity: `${serverUrl}s2s/getS2SCapacity`,
  getS2SData: `${serverUrl}s2s/getData`,
  postS2SImport: `${serverUrl}s2s/import`,
  getS2SMaterial: `${serverUrl}s2s/MarkerWithMaterialS2S`,
  postS2SAssign: `${serverUrl}s2s/assignDeterminationsForS2S`,
  getS2SFillRate: `${serverUrl}s2s/getFillRate`,
  postUploadS2S: `${serverUrl}s2s/UploadS2SDonor`,
  projectS2S: `${serverUrl}s2s/getProjects`,
  postS2SmanageMarker: `${serverUrl}s2s/manageMarkers`,

  // RDT
  postRDTImport: `${serverUrl}rdt/import`,
  getRDTData: `${serverUrl}rdt/getData`,
  getRDTMaterial: `${serverUrl}rdt/getmaterialwithtests`,
  postRDTAssignTests: `${serverUrl}rdt/assignTests`,
  getRDTMaterialState: `${serverUrl}rdt/getmaterialStatus`,

  getRDTtestOverview: `${serverUrl}rdt/getRDTtestOverview`,
  postRDTsampleTestCB: `${serverUrl}rdt/RequestSampleTestCallBack`,
  postRDTrequestSampleTest: `${serverUrl}rdt/requestSampleTest`,
  postRdtUpdateRequestSampleTest: `${serverUrl}rdt/RDTUpdatesampletestinfo`,
  postRDTprint: `${serverUrl}rdt/print`,

  getMasterGetSites: `${serverUrl}Master/getSites`,

  getMaterialStatus: `${serverUrl}rdt/getmaterialstatus`,
  getMappingColumns: `${serverUrl}rdt/getmappingcolumns`,

  getTraitDeterminationResultRDT: `${serverUrl}traitdetermination/getTraitDeterminationResultRDT`,
  postTraitDeterminationResultRDT: `${serverUrl}traitdetermination/saveTraitDeterminationResultRDT`,

  getRDTOverviewExcelApi: `${serverUrl}rdt/RDTResultToExcel`,

  // protocol
  getTestProtocols: `${serverUrl}Master/getTestProtocols`,
  getCrop: `${serverUrl}Master/getCrops`,
  postMaterialTypeTestProtocols: `${serverUrl}MaterialTypeTestProtocols`,
  postSaveProtocolData: `${serverUrl}MaterialTypeTestProtocols/saveData`,

  // C & T MANAGE
  getCTProcess: `${serverUrl}Master/getCNTProcesses`,
  postSaveCTProcess: `${serverUrl}Master/saveCNTProcesses`,

  getCNTLabLocations: `${serverUrl}Master/getCNTLabLocations`,
  postCNTLabLocations: `${serverUrl}Master/saveCNTLabLocations`,

  getCNTStartMaterials: `${serverUrl}Master/getCNTStartMaterials`,
  postCNTStartMaterials: `${serverUrl}Master/saveCNTStartMaterials`,

  getCNTTypes: `${serverUrl}Master/getCNTTypes`,
  postCNTTTypes: `${serverUrl}Master/saveCNTTypes`,

  // C & T SCREEN
  postImportCNT: `${serverUrl}cnt/import`,
  getCNTData: `${serverUrl}cnt/getData`,
  postCNTAssignMarkers: `${serverUrl}cnt/assignMarkers`,
  getCNTgetDataWithMarkers: `${serverUrl}cnt/getDataWithMarkers`,
  postCNTManageMarkers: `${serverUrl}cnt/manageMarkers`,
  postCNTManageInfo: `${serverUrl}cnt/manageInfo`,
  getCNTExport: `${serverUrl}cnt/exportToExcel`,

  // Seed health
  postImportSeedHealth: `${serverUrl}seedhealth/import`,
  getSeedHealthData: `${serverUrl}seedhealth/getdata`,
  getSeedHealthSamples: `${serverUrl}seedhealth/getsample`,
  saveSeedHealthSample: `${serverUrl}seedhealth/savesample`,
  saveSeedHealthSampleMaterial: `${serverUrl}seedhealth/savesamplematerial`,
  getSeedHealthSampleData: `${serverUrl}seedhealth/getsamplematerial`,
  getSeedHealthmaterialDeterminations: `${serverUrl}seedhealth/getDataWithDeterminations`,
  getSeedHealthDeterminations: `${serverUrl}determination/getSeedHealthDetermination`,
  seedHealthManageInfo: `${serverUrl}seedhealth/manageInfo`,
  seedHealthExportToExcel: `${serverUrl}seedhealth/ExcelForABS`,
  seedHealthSendToABS: `${serverUrl}seedhealth/SendToABS`,
  seedHealthPrintlabels: `${serverUrl}seedhealth/printSticker`,
  getSeedHealthOverview: `${serverUrl}seedhealth/getSHoverview`,
  getSeedHealthOverviewExcelApi: `${serverUrl}seedhealth/SHoverviewtoExcel`,
  getTraitDeterminationResultSH: `${serverUrl}traitdetermination/getTraitDeterminationResultSeedHealth`,
  postTraitDeterminationResultSH: `${serverUrl}traitdetermination/saveTraitDeterminationResultSeedHealth`,

  // PLATEFILLING
  getPlateFillingTotalMarkers: `${serverUrl}test/GetTotalMarkers`,

  // User crops url
  getUserCrops: `${serverUrl}Master/getUserCrops`,
  // Phenom access token api url
  phenomeAccessToken: `${serverUrl}phenome/accessToken`,
  exportCapacityPlanning: `${planningUrl}Slot/ExportCapacityPlanningToExcel`
};
export default urlConfig;
