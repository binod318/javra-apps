import AuthenticationContext from "adal-angular";
import { appInsights } from './app-insights-service';

const { tenant, clientId, cacheLocation, redirectUri } = window.adalConfig;
export const adalConfig = {
  tenant,
  clientId,
  cacheLocation,
  redirectUri,
  endpoints: {
    api: clientId,
  },
};

export const authContext = new AuthenticationContext(adalConfig);
export const adalUserInfo = () => authContext.getCachedUser();
export const logout = () => {
  window.localStorage.clear();
  appInsights.clearAuthenticatedUserContext();
  return authContext.logOut();
};
