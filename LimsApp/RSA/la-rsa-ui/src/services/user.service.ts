import { BASE_URL } from '../constants';
import { UserDetailApiResponse } from '../models';
import { RestApiException } from '../models/rest-api-exception';
import { apiService } from './api.service';

export class UserNotFoundException extends RestApiException {}

async function getUserDetail(): Promise<UserDetailApiResponse> {
  try {
    const response = await apiService.get<UserDetailApiResponse>(`${BASE_URL}/userdetail`);
    if (response.error) {
      throw new UserNotFoundException(response);
    }
    return response;
  } catch {
    throw new UserNotFoundException({});
  }
}

export const userService = {
  getUserDetail,
};
