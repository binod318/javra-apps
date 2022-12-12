import "babel-polyfill";
import "es6-promise";
import React from "react";
import ReactDOM from "react-dom";
import { Provider } from "react-redux";
import "react-tabs/style/react-tabs.scss";
import { AppContainer } from "react-hot-loader";
import store from "./config/store";

import "../styles/normalize.css";
import "../styles/index.scss";
import App from "./containers/App";
import "./helpers/axiosInterceptor";

import { authContext, adalConfig } from "../js/config/adal";

authContext.handleWindowCallback();

const render = MyApp => {
  ReactDOM.render(
    <AppContainer>
      <Provider store={store}>
        <MyApp />
      </Provider>
    </AppContainer>,
    document.getElementById("root")
  );
};

// Extra callback logic, only in the actual application, not in iframes in the app
if (
  window === window.parent &&
  window === window.top &&
  !authContext.isCallback(window.location.hash)
) {
  // Having both of these checks is to prevent having a token in localstorage, but no user.
  if (
    !authContext.getCachedToken(adalConfig.clientId) ||
    !authContext.getCachedUser()
  ) {
    authContext.login();
    // or render something that everyone can see
    // ReactDOM.render(<PublicPartOfApp />, document.getElementById('root'))
  } else {
    authContext.acquireToken(
      adalConfig.endpoints.api,
      (message, token, msg) => {
        if (token) {
          render(App);
        } else {
          render(<div>Authorization failed.</div>);
        }
      }
    );
  }
}

if (module.hot) {
  module.hot.accept();
}
