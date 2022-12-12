import React, { Component } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import { phenomeLogin } from './action';

class LoginForm extends Component {
  constructor(props) {
    super(props);
    this.state = {
      user: '',
      pwd: ''
    };
  }
  handleClose = () => {
    this.props.resetError();
    this.props.close();
  };
  handleSubmit = () => {
    const { user, pwd } = this.state;
    if (user && pwd) this.props.login(user, pwd);
  };
  handleReset = () => {
    this.setState({
      user: '',
      pwd: ''
    });
    this.props.resetError();
  };
  handleUserChange = e => {
    this.setState({
      user: e.target.value
    });
  };
  handlePwdChange = e => {
    this.setState({
      pwd: e.target.value
    });
  };
  handleKeyPress = event => {
    if (event.key === 'Enter') {
      this.handleSubmit();
    }
  };

  validation = () => this.state.user !== '' && this.state.pwd !== '';

  render() {
    const { isLoggedIn, message } = this.props;
    const { user, pwd } = this.state;
    if (isLoggedIn) {
      return null;
    }
    return (
      <div className="formWrap">
        <div className="formTitle">
          Login
          <button onClick={this.handleClose}>
            <i className="icon icon-cancel" />
          </button>
        </div>
        <div className="formBody">
          {message !== '' && <p className="formErrorP">{message}</p>}
          <div>
            <label htmlFor="user">
              <div>User</div>
              <input
                name="username"
                type="text"
                onChange={this.handleUserChange}
                value={user}
              />
            </label>
          </div>
          <div>
            <label htmlFor="pwd">
              <div>Password</div>
              <input
                name="password"
                type="password"
                onChange={this.handlePwdChange}
                onKeyPress={this.handleKeyPress}
                value={pwd}
              />
            </label>
          </div>
        </div>
        <div className="formAction">
          <button
            type="submit"
            disabled={!this.validation()}
            onClick={this.handleSubmit}
          >
            Login
          </button>
          <button type="reset" onClick={this.handleReset}>
            Reset
          </button>
        </div>
      </div>
    );
  }
}

LoginForm.defaultProps = {
  message: ''
};
LoginForm.propTypes = {
  message: PropTypes.string,
  resetError: PropTypes.func.isRequired,
  close: PropTypes.func.isRequired,
  login: PropTypes.func.isRequired,
  isLoggedIn: PropTypes.bool.isRequired
};

const mapState = state => ({
  isLoggedIn: state.phenome.isLoggedIn,
  message: state.status.message
});
const mapDispatch = dispatch => ({
  login: (user, pwd) => {
    dispatch(phenomeLogin('', user, pwd));
  },
  resetError: () => {
    dispatch({
      type: 'RESET_ERROR'
    });
  }
});
export default connect(
  mapState,
  mapDispatch
)(LoginForm);
