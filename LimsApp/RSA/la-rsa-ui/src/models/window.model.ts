// eslint-disable-next-line prettier/prettier
export { };
declare global {
  interface Window {
    TENANT: string;
    CLIENTID: string;
    serviceEndpoint: string;
    HOME_URL: string;
    REDIRECT_URI: string;
    STEP_NAMES: string;
    AI_CONNECTION_STRING: string;
  }
}
