import React, { useEffect, useState } from 'react';
import { Route } from 'react-router-dom';
import { getTokenInfo } from '../config';
import Fallback from '../components/Fallback';

interface AuthRouteProps {
  exact?: boolean;
  path: string;
  // NOTE this type any is neccessary as we can get any type of component
  // eslint-disable-next-line  @typescript-eslint/no-explicit-any
  component: React.ComponentType<any>;
}

const SCORE_APP_REQUIRED_ROLE = 'rsauser';

const AuthRoute: React.FC<AuthRouteProps> = ({
  component: Component,
  ...rest
}: AuthRouteProps): JSX.Element => {
  const [isAuthenticated, setIsAuthenticated] = useState<boolean>();
  const [isLoading, setIsLoading] = useState<boolean>(true);

  useEffect(() => {
    const fetchTokenInfo = async () => {
      try {
        const tokenInfo = await getTokenInfo();
        const hasRole =
          tokenInfo && tokenInfo.roles && tokenInfo.roles.indexOf(SCORE_APP_REQUIRED_ROLE) > -1;
        setIsAuthenticated(hasRole);
        setIsLoading(false);
      } catch {
        setIsAuthenticated(false);
        setIsLoading(false);
      }
    };
    fetchTokenInfo();
  }, []);

  return (
    <Route
      {...rest}
      render={(props) => {
        if (isAuthenticated) {
          return <Component {...props} />;
        }
        if (isLoading) {
          return <Fallback />;
        }
        window.location.href = window.HOME_URL;
        return <Fallback />;
      }}
    />
  );
};

export default AuthRoute;
