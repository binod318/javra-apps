const serverUrl = `${window.services.API_BASE_URL}/api/v1`;
const serverUrl2 = `${window.services.API_BASE_URL}/api/v2`;

export default {
  // recipcal
  recipcalRecord: `${serverUrl}/germplasm/raciprocate`,

  // Phenome
  phenomeLogin: `${serverUrl}/phenome/login`,
  phenomeAccessToken: `${serverUrl}/phenome/accessToken`,

  phenomeSSOLogin: `${serverUrl}/phenome/ssologin`,
  getResearchGroups: `${serverUrl}/phenome/getResearchGroups`,
  getFolders: `${serverUrl}/phenome/getFolders`,
  importPhenome: `${serverUrl}/phenome/import`,
  getgermplasm: `${serverUrl}/germplasm/getgermplasm`,

  getmappedgermplasm: `${serverUrl}/germplasm/getmappedgermplasm`,

  // main
  getNewCropsAndProduct: `${serverUrl}/Master/getNewCropsAndProductSegments`,
  postProductSegments: `${serverUrl}/Varieties/updateProductSegments`,
  postVarmas: `${serverUrl}/phenome/sendToVarmas`,
  postDelete: `${serverUrl}/germplasm/deletegermplasm`,
  getCountryOfOrigin: `${serverUrl}/Master/getCountryOfOrigin`,

  postReplaceLOTLookup: `${serverUrl}/Varieties/replaceLOTLookup`, // list
  postReplaceLOT: `${serverUrl2}/Varieties/replaceLOT`, // save GID, lotGID later added LotGID

  // TraitScrenning
  gettraitScreening: `${serverUrl}/traitScreening/gettraitScreening`,
  gettraitScreeningvalue: `${serverUrl}/traitScreening/gettraitScreeningvalue`,

  getRelationScreening: `${serverUrl}/traitScreening/getScreening`,
  postRelation: `${serverUrl}/traitScreening/saveTraitScreening`,

  getTraits: `${serverUrl}/traitScreening/getTraitsWithScreening`,
  getTraitList: `${serverUrl}/traitScreening/getTraitLOV`,
  getScreeningList: `${serverUrl}/traitScreening/getScreeningLOV`,
  postSaveTraitScreeningResult: `${serverUrl}/traitScreening/saveTraitScreeningResult`,

  getCrops: `${serverUrl}/Master/getCrops`,
  getUserCrops: `${serverUrl}/Master/getUserCrops`,

  // TraitOV
  getTraitResults: `${serverUrl}/traitScreening/gettraitScreeningResult`,

  postUnmapColumn: `${serverUrl}/traitScreening/removeUnmappedColumns`,

  // EMAIL CONFIG
  getEmailConfig: `${serverUrl}/EmailConfig`,
  postEmailConfig: `${serverUrl}/EmailConfig`,
  deletEmailConfig: `${serverUrl}/EmailConfig`,

  // PEDIGREE
  getPedigree: `${serverUrl}/pedigree/getPedigree`,
  undoReplace: `${serverUrl2}/Varieties/undoReplaceLOT`
};
