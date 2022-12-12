import { BASE_URL } from '../constants';
import {
  RunListApiResponse,
  RunDetailApiResponse,
  Score,
  LocalRunStore,
  LocalRunDetailModel,
  LocalScoreModel,
  SaveRunDetailPayload,
  SaveRunDetailApiResponse,
  SaveRunDetailApiResponseStatus,
  Plate,
  LocalRunModel,
} from '../models';
import { apiService } from './api.service';
import { dateUtils, DaysInWeek, runUtils } from '../utils';
import { runsLocalService } from './runs-local-store.service';
import { adalUserInfo } from '../config';
import { userService } from './user.service';
import { notification } from 'antd';

async function getRunList(): Promise<LocalRunStore> {
  try {
    let runList = runsLocalService.getRunsLocalStore();
    if (navigator.onLine) {
      const { site } = await userService.getUserDetail();
      const dateFrom = dateUtils.formatDate(
        dateUtils.startOfTheWeek(Date.now(), DaysInWeek.SUNDAY),
      );
      const dateTo = dateUtils.formatDate(dateUtils.endOfTheWeek(Date.now(), DaysInWeek.SUNDAY));
      const response = await apiService.get<RunListApiResponse>(`${BASE_URL}/runlist`, {
        site,
        dateFrom,
        dateTo,
        status: 'logged',
      });
      runList = runsLocalService.storeRuns(response.runs);
    }
    return runList;
  } catch {
    return runsLocalService.getRunsLocalStore();
  }
}

async function getRunDetails(
  id: string,
  stepCode: string,
  wfCode: string,
): Promise<LocalRunDetailModel | undefined> {
  const response = await apiService.get<RunDetailApiResponse>(`${BASE_URL}/rundetail`, {
    id,
    stepCode,
    wfCode,
  });
  return runsLocalService.storeRunDetails(id, stepCode, response.run);
}

function prepareSaveRunDetailPayload(
  runId: string,
  stepCode: string,
  plates: Plate[],
): SaveRunDetailPayload {
  const userInfo = adalUserInfo();
  return {
    id: runId,
    stepCode: stepCode,
    user: userInfo ? userInfo.userName : 'mock user name',
    plates,
  };
}

async function saveRunDetail(
  runId: string,
  stepCode: string,
  plates: Plate[],
): Promise<SaveRunDetailApiResponse> {
  const payload = prepareSaveRunDetailPayload(runId, stepCode, plates);
  return await apiService.post<SaveRunDetailPayload, SaveRunDetailApiResponse>(
    `${BASE_URL}/saverundetail`,
    payload,
  );
}

function getScore(localScoreModel: LocalScoreModel): Score[] | undefined {
  const run = runsLocalService.getRun(localScoreModel.runId, localScoreModel.stepCode);
  if (!run?.details) {
    return;
  }
  const foundPlate = run.details.plates.find((plate) => plate.plateID === localScoreModel.plateId);
  if (!foundPlate || !foundPlate.invs) {
    return;
  }
  const foundInventory = foundPlate.invs.find(
    (inventory) =>
      inventory.id === localScoreModel.inventoryId &&
      inventory.replicateID == localScoreModel.replicateId &&
      inventory.plateRowCol == localScoreModel.plateRowCol,
  );
  if (!foundInventory) {
    return;
  }
  return foundInventory.score;
}

function isScoreChanged(localScoreModel: LocalScoreModel): boolean {
  const currentScore = getScore(localScoreModel) || [];
  for (let i = 0; i < currentScore.length; ++i) {
    const foundScore = localScoreModel.score.find(
      (nscore) => nscore.columnName === currentScore[i].columnName,
    );
    if (currentScore[i].val !== foundScore?.val) {
      return true;
    }
  }
  return false;
}

async function saveScore(localScoreModel: LocalScoreModel): Promise<void> {
  try {
    if (!isScoreChanged(localScoreModel)) {
      return;
    }
    localScoreModel.synced = false;
    localScoreModel.error = false;
    if (navigator.onLine) {
      const plates: Plate[] = [
        {
          plateID: localScoreModel.plateId,
          invs: [
            {
              id: localScoreModel.inventoryId as string,
              replicateID: localScoreModel.replicateId,
              plateRowCol: localScoreModel.plateRowCol,
              score: localScoreModel.score,
            },
          ],
        },
      ];
      const response = await saveRunDetail(localScoreModel.runId, localScoreModel.stepCode, plates);
      localScoreModel.synced =
        response.status.toLowerCase() === SaveRunDetailApiResponseStatus.SUCCESS;
      localScoreModel.error = !localScoreModel.synced;
      // FIXME commented for now as discussed with prakash.
      // Result of discussion was to not show error message on every next click
      // if (!localScoreModel.synced) {
      //   showSyncErrorNotification([localScoreModel.runId]);
      // }
    }
    runsLocalService.storeScore(localScoreModel);
  } catch (error) {
    localScoreModel.synced = false;
    localScoreModel.error = true;
    // FIXME commented for now as discussed with prakash.
    // Result of discussion was to not show error message on every next click
    // showSyncErrorNotification();
    runsLocalService.storeScore(localScoreModel);
  }
}

function showSyncErrorNotification(runIds?: string[]): void {
  setTimeout(() => {
    notification.error({
      message: `Unable to sync last run${
        runIds && runIds.length ? ` RunID/s: ${runIds.join(',')}` : ''
      }.`,
      description:
        'Your last save could not be synced. Please navigate to overview page for details.',
      duration: 5000,
      placement: 'topLeft',
      className: 'notification',
    });
  });
}

function filterOutSyncedPlates(plates: Plate[], forceSync?: boolean): Plate[] {
  return plates
    .map((plate) => {
      if (runUtils.isPlateSynced(plate)) {
        return;
      }
      const palteToUpdate = {
        ...plate,
      };
      const inventories = plate.invs.filter(
        (inventory) =>
          !runUtils.isInventorySynced(inventory) &&
          ((runUtils.inventoryHasError(inventory) && forceSync) ||
            !runUtils.inventoryHasError(inventory)),
      );
      if (!inventories.length) {
        return;
      }
      palteToUpdate.invs = inventories;
      return palteToUpdate;
    })
    .filter(Boolean) as Plate[];
}

async function syncRun(run: LocalRunModel, forceSync?: boolean): Promise<boolean | undefined> {
  if (run.isSynced || !run.details) {
    return true;
  }
  const plates = run.details.plates;
  const filteredPlates = filterOutSyncedPlates(plates, forceSync);
  if (!filteredPlates.length) {
    return true;
  }
  const response = await saveRunDetail(run.id, run.stepCode, filteredPlates);
  const synced = response.status.toLowerCase() === SaveRunDetailApiResponseStatus.SUCCESS;
  plates.forEach((plate) => {
    if (runUtils.isPlateSynced(plate)) {
      return;
    }
    plate.synced = synced;
    plate.error = !synced;
    plate.invs = plate.invs.map((inv) => {
      if (!runUtils.isInventorySynced(inv)) {
        inv.synced = synced;
        inv.error = !synced;
      }
      return inv;
    });
  });
  run.isSynced = runUtils.isRunSynced(run);
  run.error = runUtils.runHasError(run);
  return synced;
}

async function syncRuns(): Promise<void> {
  try {
    const store = runsLocalService.getRunsLocalStore();
    const runsInLocalStore = Object.values(store);
    const runIdNotSynced: string[] = [];
    const requestPromises = runsInLocalStore
      .map(async (run) => {
        const synced = await syncRun(run);
        if (!synced) {
          runIdNotSynced.push(run.id);
        }
      })
      .filter(Boolean);
    await Promise.all(requestPromises);
    if (runIdNotSynced.length) {
      showSyncErrorNotification(runIdNotSynced);
    }
    runsLocalService.setStore(store);
  } catch (error) {
    showSyncErrorNotification();
  }
}

function resetTheSelectedStates(): void {
  const currentStore = runsLocalService.getRunsLocalStore();
  const selectedRun = Object.values(currentStore).find((run) => run.selected);
  if (!selectedRun) {
    return;
  }
  selectedRun.selected = false;
  runsLocalService.setStore(currentStore);
}

function getSelectedRun(): LocalRunModel | undefined {
  const currentStore = runsLocalService.getRunsLocalStore();
  const selectedRun = Object.values(currentStore).find((run) => run.selected);
  return selectedRun;
}

export const runsService = {
  getRunList,
  getRunDetails,
  saveScore,
  syncRuns,
  syncRun,
  showSyncErrorNotification,
  getLocalStoreKey: runsLocalService.getLocalStoreKey,
  getRunsLocalStore: runsLocalService.getRunsLocalStore,
  removeRun: runsLocalService.removeRun,
  setStore: runsLocalService.setStore,
  resetTheSelectedStates,
  getSelectedRun,
};
