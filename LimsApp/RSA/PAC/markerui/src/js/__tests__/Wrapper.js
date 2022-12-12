import React from 'react';
import ReactDOM from 'react-dom';
// setup file
import { configure } from 'enzyme';
import { shallow, mount, render } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import toJson from 'enzyme-to-json';

// import { AsideW } from '../components/Aside';
import { myWrapper } from '../components/Wrapper/wrapper.jsx';

configure({ adapter: new Adapter(), disableLifecycleMethods: true });

it('ture', () => {
  expect(1).toEqual(1);
});
