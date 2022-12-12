import React, { Fragment } from "react";
import { NavLink, withRouter } from "react-router-dom";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import "./aside.scss";

import { couputeRoute } from "../../routes";

function CustomLink({ to, label, id, show, icon }) {
  if (!show) {
    return (
      <li style={{ opacity: 0, position: "absolute", zIndex: -1 }}>
        <NavLink exact to={to} activeClassName='active' id={id}>
          <span>
            <i className='icon icon-right-1' />
            {label}
          </span>
          <div>
            <i className='icon icon-right-1' />
          </div>
        </NavLink>
      </li>
    );
  }
  return (
    <li>
      <NavLink exact to={to} activeClassName='active' id={id} title={label}>
        <span>
          <i className={`icon ${icon}`} />
          {label}
        </span>
        <div>
          <i className={`icon ${icon}`} />
        </div>
      </NavLink>
    </li>
  );
}
CustomLink.defaultProps = {
  id: "",
};
CustomLink.propTypes = {
  id: PropTypes.string,
  to: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
};

export const myAside = ({ role, onclick, sideStatus }) => (
  <aside>
    {/* <h3>Menu</h3> */}
    <ul>
      <li style={{ borderBottom: "1px #d0cbcb solid", marginBottom: "10px" }}>
        <button onClick={onclick} id={!sideStatus ? "h" : "h_c"}>
          <i className='icon icon-menu' />
          <i className='icon icon-down' />
        </button>
      </li>
      {couputeRoute(role).map((x, i) => (
        <CustomLink
          key={i}
          to={i === 0 ? "/" : x.to}
          label={x.name}
          id={x.id}
          show={x.show}
          icon={x.icon || ""}
        />
      ))}
    </ul>
  </aside>
);

const mapStateToProps = (state) => ({
  role: state.user.role,
});

myAside.defaultProps = {
  role: [],
};
myAside.propTypes = {
  role: PropTypes.array, // eslint-disable-line
};
const Aside = withRouter(connect(mapStateToProps, null)(myAside));
export default Aside;
