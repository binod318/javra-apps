import { HttpRequestError, StringMap } from '../models';
import { getToken } from '../config/adal';

async function http<T>(path: string, config: RequestInit = {}): Promise<T> {
  const token = await getToken();
  const headers = {
    ...config.headers,
    Authorization: `Bearer ${token}`,
  };

  const configuration = { ...config, headers };
  const request = new Request(path, configuration);
  const response = await fetch(request);
  if (!response.ok) {
    throw new HttpRequestError(response.status, response.statusText);
  }
  return response.json().catch((err) => {
    console.log(err);
  });
}

async function get<T>(path: string, searchParams?: StringMap, config?: RequestInit): Promise<T> {
  const url = new URL(path);
  if (searchParams != null) {
    Object.keys(searchParams).forEach((key) => url.searchParams.append(key, searchParams[key]));
  }
  const init = { method: 'get', ...config };
  return await http<T>(url.toString(), init);
}

async function post<T, U>(path: string, body: T, config?: RequestInit): Promise<U> {
  if (!config) {
    config = {
      headers: {
        'Content-Type': 'application/json',
      },
    };
  }
  const init = { method: 'post', body: JSON.stringify(body), ...config };
  return await http<U>(path, init);
}

async function put<T, U>(path: string, body: T, config?: RequestInit): Promise<U> {
  const init = { method: 'put', body: JSON.stringify(body), ...config };
  return await http<U>(path, init);
}

export const apiService = {
  get,
  post,
  put,
};
