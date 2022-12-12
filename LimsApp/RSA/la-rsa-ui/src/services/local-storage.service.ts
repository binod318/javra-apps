function get(key: string, fallback = ''): string | null {
  try {
    return window.localStorage.getItem(key);
  } catch {
    return fallback;
  }
}

function set(key: string, value: string): boolean {
  try {
    window.localStorage.setItem(key, value);
    return true;
  } catch {
    return false;
  }
}

function removeItem(key: string): boolean {
  try {
    window.localStorage.removeItem(key);
    return true;
  } catch (error) {
    return false;
  }
}

export const localStorageService = {
  get,
  set,
  removeItem,
};
