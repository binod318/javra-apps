import jwtDecode from 'jwt-decode';
import { AuthenticationContext, withAdalLogin, UserInfo, AdalConfig } from 'react-adal';
import { appInsights } from './app-insights.service';

if (process.env.NODE_ENV !== 'production') {
  // test enza env
  // var CLIENTID = "f8483aa1-1ee7-4cea-87ed-9f77b2caeccc";
  // var TENANT = "enzazaden.nl";

  // var CLIENTID = "8f95a311-437c-4faf-8a49-da4f73880aee";
  // var TENANT = "enzazaden.nl";

  // var CLIENTID = "35877890-895a-46ad-b842-848b7fc73061";
  // var TENANT = "872e34c0-01f1-4641-9cf1-e623ef3c49b0";
  window.serviceEndpoint = '/';
  // javra test app cliend id for lims
  window.CLIENTID = '8afc547a-42e1-4853-8468-5189866817b3';
  window.TENANT = 'javra.com';
  // local lims app url
  window.HOME_URL = 'http://localhost:8085';
  window.REDIRECT_URI = 'http://localhost:3000';
  window.AI_CONNECTION_STRING =
    'InstrumentationKey=a6d81d31-e233-4e49-94c0-9514aa25fa8e;IngestionEndpoint=https://centralindia-0.in.applicationinsights.azure.com/';
}

export interface TokenInfo {
  roles?: string[];
}

export const adalConfig: AdalConfig = {
  tenant: window.TENANT,
  clientId: window.CLIENTID,
  endpoints: {
    api: window.CLIENTID,
  },
  cacheLocation: 'localStorage',
  redirectUri: window.REDIRECT_URI,
};

export const authContext = new AuthenticationContext(adalConfig);

export const withAdalLoginApi = withAdalLogin(
  authContext,
  adalConfig.endpoints ? adalConfig.endpoints['api'] : '',
);

export const adalUserInfo = (): UserInfo => authContext.getCachedUser();

export async function getToken(): Promise<string> {
  return new Promise((resolve) => {
    authContext.acquireToken(window.CLIENTID, (_message, token): void => {
      if (token) resolve(token);
      else resolve('Mock token');
    });
  });
}

export const logout = (): void => {
  window.localStorage.clear();
  appInsights.clearAuthenticatedUserContext();
  return authContext.logOut();
};

export async function getTokenInfo(): Promise<TokenInfo | undefined> {
  const token: string = await getToken();
  if (!token || token === 'Mock token') {
    return;
  }

  //set user context for applicaiton insights
  const user = adalUserInfo();
  if (user.userName) Authenticated(user.userName);

  return jwtDecode(token);
}

// Called when my app has identified the user.
function Authenticated(signInId: string) {
  const validatedId = signInId.replace(/[,;=| ]+/g, '_');
  appInsights.setAuthenticatedUserContext(validatedId, '', true);
}

export const logOutUrl = `https://login.windows.net/${adalConfig.tenant}/oauth2/logout?post_logout_redirect_uri=http://localhost:8085`;
