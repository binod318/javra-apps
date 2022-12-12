import { adalUserInfo } from '../config';
import {
  Run,
  LocalRunStore,
  LocalRunModel,
  LocalRunDetailModel,
  RunDetail,
  LocalScoreModel,
  UserRunStoreMap,
} from '../models';
import { runUtils } from '../utils';
import { localStorageService } from './local-storage.service';

const RUN_STORE_LOCAL_STORE_KEY = 'localRunStore';

function storeRuns(runs: Run[]): LocalRunStore {
  const localRunStore = getRunsLocalStore();
  removeFromStoreThatDoesNotExist(runs, localRunStore);
  const newStore = prepareFreshStore(runs, localRunStore);
  setStore(newStore);
  return getRunsLocalStore();
}

function setStore(store: LocalRunStore): void {
  const runsStoreInStorage: UserRunStoreMap = getUserRunMap();
  const userInfo = adalUserInfo();
  if (!userInfo || !userInfo.userName) {
    return;
  }
  runsStoreInStorage[userInfo.userName] = store;
  localStorageService.set(RUN_STORE_LOCAL_STORE_KEY, JSON.stringify(runsStoreInStorage));
}

function getUserRunMap(): UserRunStoreMap {
  if (!localStorageService.get(RUN_STORE_LOCAL_STORE_KEY)) {
    return {};
  }
  return JSON.parse(localStorageService.get(RUN_STORE_LOCAL_STORE_KEY) as string);
}

function getRunsLocalStore(): LocalRunStore {
  const runsStoreInStorage: UserRunStoreMap = getUserRunMap();
  const userInfo = adalUserInfo();
  if (!userInfo || !userInfo.userName) {
    return {};
  }
  return runsStoreInStorage[userInfo.userName] || {};
}

function removeFromStoreThatDoesNotExist(runs: Run[], runsStore: LocalRunStore): void {
  const runIdsInStore: string[] = Object.keys(runsStore);
  runIdsInStore.forEach((key) => {
    const foundRun = runs.find((run) => {
      const runIdAndStepCode = key.split('__');
      return run.id == runIdAndStepCode[0] && run.stepCode == runIdAndStepCode[1];
    });
    if (!foundRun) {
      delete runsStore[key];
    }
  });
}

function prepareFreshStore(runs: Run[], runsStore: LocalRunStore): LocalRunStore {
  runs.forEach((run) => {
    const storeKey = getLocalStoreKey(run.id, run.stepCode);
    const runInStore = runsStore[storeKey];
    if (runInStore) {
      return;
    }
    runsStore[storeKey] = { ...run, isSynced: true, error: false };
  });
  return runsStore;
}

export function getRuns(): LocalRunModel[] {
  const localStore = getRunsLocalStore();
  return Object.values(localStore ? localStore : {});
}

function getRun(runId: string, stepCode: string): LocalRunModel | undefined {
  const locaStore = getRunsLocalStore();
  return locaStore[getLocalStoreKey(runId, stepCode)];
}

function storeRunDetails(
  runId: string,
  stepCode: string,
  details: RunDetail,
): LocalRunDetailModel | undefined {
  const localRunStore = getRunsLocalStore();
  if (!localRunStore) {
    return;
  }
  const storeKey = getLocalStoreKey(runId, stepCode);
  localRunStore[storeKey]['details'] = details;
  runUtils.calculateRunProgress(localRunStore[storeKey]['details'] as LocalRunDetailModel);
  setStore(localRunStore);
  return details;
}

function storeScore(localScoreModel: LocalScoreModel): void {
  const run = getRun(localScoreModel.runId, localScoreModel.stepCode);
  if (!run) {
    throw new Error(`No run found! runId: ${localScoreModel.runId}`);
  }
  if (!run?.details) {
    throw new Error(`No details found! runId: ${localScoreModel.runId}`);
  }
  const foundPlate = run.details.plates.find((plate) => plate.plateID === localScoreModel.plateId);
  if (!foundPlate || !foundPlate.invs) {
    throw new Error(`No plates or inventory found! runId: ${localScoreModel.runId}`);
  }
  const foundInventory = foundPlate.invs.find(
    (inventory) =>
      inventory.id === localScoreModel.inventoryId &&
      inventory.replicateID == localScoreModel.replicateId &&
      inventory.plateRowCol == localScoreModel.plateRowCol,
  );
  if (!foundInventory) {
    throw new Error(`No inventory found! runId:  ${localScoreModel.runId}`);
  }
  foundInventory.synced = localScoreModel.synced;
  foundInventory.error = localScoreModel.error;
  foundInventory.score = localScoreModel.score;
  foundPlate.synced = !foundPlate.invs.some((inventory) => !runUtils.isInventorySynced(inventory));
  foundPlate.error = foundPlate.invs.some((inventory) => runUtils.inventoryHasError(inventory));
  run.isSynced = runUtils.isRunSynced(run);
  run.error = runUtils.runHasError(run);
  runUtils.calculateRunProgress(run.details);
  const localRunStore = getRunsLocalStore();
  localRunStore[getLocalStoreKey(run.id, run.stepCode)] = run;
  setStore(localRunStore);
}

function getLocalStoreKey(runId: string, stepCode: string): string {
  return `${runId}__${stepCode}`;
}

function removeRun(runId: string, stepCode: string): LocalRunStore {
  const localRunStore = getRunsLocalStore();
  delete localRunStore[getLocalStoreKey(runId, stepCode)];
  setStore(localRunStore);
  return getRunsLocalStore();
}

// IMPORTANT DO NOT EXPOSE THIS SERVICE
export const runsLocalService = {
  storeRuns,
  getRuns,
  getRun,
  storeRunDetails,
  storeScore,
  getRunsLocalStore,
  getLocalStoreKey,
  setStore,
  removeRun,
};
