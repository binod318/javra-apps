export enum SaveRunDetailApiResponseStatus {
  SUCCESS = 'success',
  FALIURE = 'faliure',
}
export interface SaveRunDetailApiResponse {
  status: SaveRunDetailApiResponseStatus;
  reasonForFaliure: string;
}
