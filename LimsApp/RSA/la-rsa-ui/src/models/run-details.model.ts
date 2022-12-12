export enum RunColumnDataTypes {
  LOV = 'lov',
  INTEGER = 'int',
  CHAR = 'char',
  DECIMAL = 'dec',
}

export interface RunColumn {
  columnName: string;
  caption: string;
  dataType: RunColumnDataTypes;
  LOVs?: string[];
}

export interface Score {
  columnName: string;
  val: string;
  qc?: string;
}

export interface Inventory {
  id: string;
  score: Score[];
  synced?: boolean;
  error?: boolean;
  replicateID: number;
  plateRowCol?: string;
}

export interface Plate {
  plateID: string;
  invs: Inventory[];
  synced?: boolean;
  error?: boolean;
}

export interface RunDetail {
  id: string;
  workflowCode: string;
  stepCode: string;
  class: string;
  caption: string;
  columns: RunColumn[];
  plates: Plate[];
}
