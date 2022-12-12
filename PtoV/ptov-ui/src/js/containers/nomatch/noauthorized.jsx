import React from 'react';

class NoAuthorized extends React.Component {
  reload = () => {
    window.location.reload();
  };

  render() {
    return (
      <div className="nomatch">
        <div>
          <h3>Sorry! You are not Authorized.</h3>
          <p>Please contact administrator</p>
          <button onClick={this.reload}>Refresh Page</button>
        </div>
      </div>
    );
  }
}
export default NoAuthorized;
