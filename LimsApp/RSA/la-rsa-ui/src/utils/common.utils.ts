import { Viewport } from '../models';

export const getViewport = (): Viewport => {
  if (!('innerWidth' in window)) {
    const element = document.documentElement || document.body;
    return {
      width: element['clientWidth'],
      height: element['clientHeight'],
    };
  } else {
    return {
      width: window[`innerWidth`],
      height: window[`innerHeight`],
    };
  }
};
