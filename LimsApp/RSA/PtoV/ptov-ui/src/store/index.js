import { applyMiddleware, compose, createStore } from "redux";
import createSagaMiddleware from "redux-saga";

import rootReducer from "./reducer/index";
import rootSaga from "./saga/index";
import { loadState } from "./local";

const presistedState = loadState();

const sagaMiddleware = createSagaMiddleware();

const configStore = () => {
  const composeEnhancers =
    typeof window === "object" && window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__
      ? window.__REDUX_DEVTOOLS_EXTENSION_COMPOSE__({
          // Specify extension’s options like name, actionsBlacklist, actionsCreators, serialize...
        })
      : compose;

  const enhancer = composeEnhancers(applyMiddleware(sagaMiddleware));

  const store = createStore(rootReducer, presistedState, enhancer);
  sagaMiddleware.run(rootSaga);

  return store;
};

export default configStore;
