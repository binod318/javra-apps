import React from 'react';
import ReactDOM from 'react-dom';
// setup file
import { configure } from 'enzyme';
import { shallow, mount, render } from 'enzyme';
import Adapter from 'enzyme-adapter-react-16';
import toJson from 'enzyme-to-json';

import { LoaderW } from '../components/Loader/Loader';
configure({ adapter: new Adapter() });
// test file

describe('<LoaderW />', () => {
  const props = { status: 0 };
  const wrapper = shallow(<LoaderW {...props} />);

  it('LoaderW draw', () => {
    expect(wrapper.find('span').length).toBe(1);

    wrapper.setProps({ status: 1 });
    expect(wrapper.find('.loader').length).toBe(1);
  });

  it('match a loader shap', () => {
    const tree = shallow(<wrapper />);
    expect(toJson(tree)).toMatchSnapshot();
  });
});
