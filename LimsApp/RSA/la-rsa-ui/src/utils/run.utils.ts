import { Inventory, LocalRunDetailModel, LocalRunModel, Plate, RunProgress } from '../models';

// FIXME the way we have to check the property is very tedious we nees to use model class for it
// so that these houskeeping is done at one place which inturn gives easier access

function isInventorySynced(inventory: Inventory): boolean | undefined {
  return (
    !inventory.hasOwnProperty('synced') || (inventory.hasOwnProperty('synced') && inventory.synced)
  );
}

function inventoryHasError(inventory: Inventory): boolean | undefined {
  return inventory.hasOwnProperty('error') && inventory.error;
}

function isPlateSynced(plate: Plate): boolean | undefined {
  return !plate.hasOwnProperty('synced') || (plate.hasOwnProperty('synced') && plate.synced);
}

function palteHasError(plate: Plate): boolean | undefined {
  return plate.hasOwnProperty('error') && plate.error;
}

function isRunSynced(run: LocalRunModel | undefined): boolean | undefined {
  return run && run.details && !run.details.plates.some((plate) => !isPlateSynced(plate));
}

function runHasError(run: LocalRunModel | undefined): boolean | undefined {
  return run && run.details && run.details.plates.some((plate) => palteHasError(plate));
}

function calculateRunProgress(details: LocalRunDetailModel): void {
  const columnLength: number = details.columns.length || 0;
  const progress: RunProgress = {
    scored: 0,
    total: 0,
  };
  details.plates.forEach((plate) => {
    progress.total += plate.invs.length;
    plate.invs.forEach((inventory) => {
      const score = inventory.score;
      if (details.class === '3a') {
        const hasScoredAny = score.find((invScore) => invScore.val !== '');
        if (hasScoredAny) {
          progress.scored++;
        }
      } else {
        let scoredSum = 0;
        score.forEach((item) => {
          if (item.val !== '') {
            scoredSum++;
          }
        });
        if (scoredSum === columnLength) {
          progress.scored++;
        }
      }
    });
  });
  details.progress = progress;
}

export const runUtils = {
  inventoryHasError,
  isInventorySynced,
  isPlateSynced,
  palteHasError,
  isRunSynced,
  runHasError,
  calculateRunProgress,
};
