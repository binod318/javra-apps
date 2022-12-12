import { RunDetail } from './run-details.model';

export type SaveRunDetailPayload = Partial<RunDetail> & {
  user: string;
};
