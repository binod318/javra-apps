/*!
 *
 * UNAUTHORIZED AND NOT MATCHING ROUTE
 * ------------------------------
 */
import React from 'react';
import { withRouter } from 'react-router-dom';
import PropTypes from 'prop-types';

const NoMatch = ({ location }) => (
  <div className="nomatch">
    <h3>
      No match for <code>{location.pathname}</code>
    </h3>
  </div>
);

NoMatch.propTypes = {
  location: PropTypes.object.isRequired
};
export default withRouter(NoMatch);
