import "babel-polyfill";
import "es6-promise";
import React from "react";
import ReactDOM from "react-dom";
import { Provider } from "react-redux";
import "react-tabs/style/react-tabs.scss";
import { createStore, applyMiddleware, compose } from "redux";
import createSagaMiddleware from "redux-saga";
import { AppContainer } from "react-hot-loader";

import { authContext, adalConfig } from "./config/adal";
authContext.handleWindowCallback();

import reducer from "./reducers";
import "../styles/normalize.css";
import "../styles/index.scss";
import rootSaga from "./saga/saga";
import App from "./containers/App";
import { appInsights } from './config/app-insights-service';

const sagaMiddleware = createSagaMiddleware();

const loadState = () => {
  try {
    const serializedState = localStorage.getItem("state");
    if (serializedState === null) {
      return undefined;
    }
    return JSON.parse(serializedState);
  } catch (e) {
    return undefined;
  }
};
const saveState = (state) => {
  try {
    const serializedState = JSON.stringify(state);
    localStorage.setItem("state", serializedState);
  } catch (e) {
    console.log("Not able to save locally.");
  }
};

const composeEnhancers =
  typeof window === "object" && window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__
    ? window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__({})
    : compose;
const enhancer = composeEnhancers(applyMiddleware(sagaMiddleware));

const store = createStore(reducer, loadState(), enhancer);

store.subscribe(() =>
  saveState({
    sidemenuReducer: store.getState().sidemenuReducer,
  })
);

sagaMiddleware.run(rootSaga);

const render = (MyApp) => {
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

    //set user context for applicaiton insights
    var user = authContext.getCachedUser();
    if (user.userName) Authenticated(user.userName);

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

// Called when my app has identified the user.
function Authenticated(signInId) {
  const validatedId = signInId.replace(/[,;=| ]+/g, '_');
  appInsights.setAuthenticatedUserContext(validatedId, '', true);
}

if (module.hot) {
  module.hot.accept("./containers/App", () => {
    render(App);
  });
}
