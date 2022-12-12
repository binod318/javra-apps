import 'babel-polyfill';
import 'es6-promise';
import React from 'react';
import { render } from 'react-dom';
import { Provider } from 'react-redux';

import Store from './store';
import App from './js/App';
import { saveState } from './store/local';

const store = Store();
store.subscribe(() => saveState({main: {files: store.getState().main.files } }));

render(
  <Provider store={store}>
    <App />
  </Provider>,
  document.getElementById('root')
);
