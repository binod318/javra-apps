import React from 'react';
import { Route } from 'react-router-dom';

const RouteWithSubRoutes = route => {
  const { routes } = route;

  return (
    <Route
      path={route.path}
      exact={route.exact}
      render={props => (
        // pass the sub-routes down to keep nesting
        <route.component {...props} routes={routes} />
      )}
    />
  );
};
export default RouteWithSubRoutes;
