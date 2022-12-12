import React from "react";
import { NavLink, withRouter } from "react-router-dom";
import PropTypes from "prop-types";
import "./aside.scss";

function CustomLink({ to, label, id, icon }) {
  return (
    <li>
      <NavLink exact to={to} activeClassName="active" id={id} title={label}>
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
  id: ""
};

CustomLink.propTypes = {
  id: PropTypes.string,
  to: PropTypes.string.isRequired,
  label: PropTypes.string.isRequired,
  icon: PropTypes.string.isRequired
};

export default withRouter(CustomLink);
