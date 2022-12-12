import { ApiResponse } from './api-response.model';
import { RunDetail } from './run-details.model';

export class RunDetailApiResponse extends ApiResponse {
  public run: RunDetail;
}
