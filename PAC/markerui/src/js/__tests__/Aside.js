import React from "react";
import ReactDOM from "react-dom";
// setup file
import { configure } from "enzyme";
import { shallow, mount, render } from "enzyme";
import Adapter from "enzyme-adapter-react-16";
import toJson from "enzyme-to-json";

// import { AsideW } from '../components/Aside';

configure({ adapter: new Adapter(), disableLifecycleMethods: true });

it("ture", () => {
  expect(1).toEqual(1);
});

// describe('<AsideW />', () => {
//   it('render', () => {
//     const props = { role: ['admin', 'crop specialist', 'handlelabcapacity', 'managemasterdatautm', 'pac_handlelabcapacity', 'pac_managelabpreparation', 'pac_so_handlecropcapacity', 'ptov-user', 'requesttest'] };
//     const wrapper = shallow(<AsideW {...props} />);
//     except(wrapper.find('h3').length).toBe(1);
//   });
// });
