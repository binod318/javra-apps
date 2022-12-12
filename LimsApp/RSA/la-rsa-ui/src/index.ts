import { runWithAdal } from 'react-adal';
import { authContext } from './config/adal';

const DO_NOT_LOGIN = false; //change DO_NOT_LOGIN to true to stop login on index.ts
runWithAdal(
  authContext,
  () => {
    require('./app-index.tsx');
  },
  DO_NOT_LOGIN,
);
