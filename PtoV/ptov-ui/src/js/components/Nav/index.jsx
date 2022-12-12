import React from "react";
import { NavLink, withRouter } from "react-router-dom";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import { adalUserInfo } from "../../config/adal";

import { couputeRoute } from "../../routes";

const Nav = ({ isLoggedIn }) => {
  const userInfo = adalUserInfo();
  const roles = userInfo.profile.roles;

  return (
    <nav>
      <ul>
        <li className="brand">PtoV</li>
        {couputeRoute(roles, true).map((x, i) => (
          <li key={i}>
            <NavLink exact={x.exact} to={x.path} label={x.name} id={x.id}>
              {x.name}
            </NavLink>
          </li>
        ))}

        {isLoggedIn && (
          <li className="user">
            <i className="icon icon-user-circle" />
          </li>
        )}
      </ul>
    </nav>
  );
};

Nav.propTypes = {
  isLoggedIn: PropTypes.bool.isRequired
};

const mapState = state => ({
  isLoggedIn: state.phenome.isLoggedIn
});
const mapDispatch = dispatch => ({
  toggleSide: () => {
    dispatch({
      type: "SIDE_TOGGLE"
    });
  }
});
export default withRouter(
  connect(
    mapState,
    mapDispatch
  )(Nav)
);
