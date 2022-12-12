function get(key ) {
    // try {
         return window.localStorage.getItem(key);
    // } catch {
    //     return fallback;
    // }
}
  
function set(key, value) {
    // try {
         window.localStorage.setItem(key, value);
    //     return true;
    // } catch {
    //     return false;
    // }
}
  
function removeItem(key) {
    // try {
       window.localStorage.removeItem(key);
    //   return true;
    // } catch (error) {
    //   return false;
    // }
}
  
export const localStorageService = {
    get,
    set,
    removeItem
};
  