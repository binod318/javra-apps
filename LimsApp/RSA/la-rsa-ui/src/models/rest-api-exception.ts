import { ApiResponse } from './api-response.model';

export class RestApiException {
  constructor(protected exception: ApiResponse) {}
}
