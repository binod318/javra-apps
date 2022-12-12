import { combineReducers } from 'redux';
import user from './user';

import status from './status';

import { main, phenome, pedigree } from '../../js/containers/main/reducer';
import convert from '../../js/containers/convert/reducer';
import relation from '../../js/containers/relation/reducer';
import result from '../../js/containers/result/reducer';
import mail from '../../js/containers/mail/reducer';

const SIDE_SHOW = 'SIDE_SHOW';
const SIDE_HIDE = 'SIDE_HIDE';
const initSide = false;
const side = (state = initSide, action) => {
  switch (action.type) {
    case SIDE_SHOW:
      return true;
    case SIDE_HIDE:
      return false;
    case 'SIDE_TOGGLE':
      console.log(state);
      return !state;
    default:
      return state;
  }
};

const rootReducer = combineReducers({
  user,
  side,
  status,
  main,
  phenome,
  convert,
  pedigree,
  relation,
  result,
  mail
});
export default rootReducer;
