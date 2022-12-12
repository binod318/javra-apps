import { RunDetail, Score } from './run-details.model';
import { Run } from './run.model';

export interface LocalScoreModel {
  runId: string;
  stepCode: string;
  plateId: string;
  inventoryId?: string;
  score: Score[];
  replicateId: number;
  plateRowCol?: string;
  synced?: boolean;
  error?: boolean;
}
export interface RunProgress {
  scored: number;
  total: number;
}

export type LocalRunDetailModel = RunDetail & {
  progress?: RunProgress;
};

export type LocalRunModel = Run & {
  details?: LocalRunDetailModel;
  isSynced?: boolean;
  error?: boolean;
  downloading?: boolean;
  lovTypable?: boolean;
  selected?: boolean;
};

export interface UserRunStoreMap {
  [user: string]: LocalRunStore;
}

export interface LocalRunStore {
  [runId_stepCode: string]: LocalRunModel;
}
