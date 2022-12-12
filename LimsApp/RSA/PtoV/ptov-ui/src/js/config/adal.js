import AuthenticationContext from "adal-angular";

const { tenant, clientId, cacheLocation, redirectUri } = window.adalConfig;

export const adalConfig = {
  tenant,
  clientId,
  cacheLocation,
  redirectUri,
  endpoints: {
    api: clientId
  }
};
export const authContext = new AuthenticationContext(adalConfig);
export const adalUserInfo = () => authContext.getCachedUser();

export const getToken = () => authContext.getCachedToken(adalConfig.clientId);

export const logOutUrl = `https://login.windows.net/${
  adalConfig.tenant
}/oauth2/logout?post_logout_redirect_uri=${adalConfig.redirectUri}`;
