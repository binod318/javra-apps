import React from 'react';
import PropTypes from 'prop-types';
import { Route, withRouter } from 'react-router-dom';
import { connect } from 'react-redux';
import PublicLayout from './publicLayout';

const PrivateRoute = ({ component: Test, ...rest }) => (
  <Route
    {...rest}
    render={props => (
      <div>
        <PublicLayout>
          <Test {...props} />
        </PublicLayout>
      </div>
    )}
  />
);
PrivateRoute.propTypes = {
  component: PropTypes.any, // eslint-disable-line 
};
const mapState = state => ({ auth: state.authenticated });
export default withRouter(
  connect(
    mapState,
    null
  )(PrivateRoute)
);
