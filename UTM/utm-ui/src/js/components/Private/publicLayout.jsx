import React from "react";
import PropTypes from "prop-types";

import Header from "../Header";

const PublicLayout = ({ children }) => (
  <div className="bodyWrap">
    <Header />
    <div>
      <div className="main">{children}</div>
    </div>
  </div>
);

PublicLayout.propTypes = {
  children: PropTypes.object.isRequired // eslint-disable-line
};

export default PublicLayout;
