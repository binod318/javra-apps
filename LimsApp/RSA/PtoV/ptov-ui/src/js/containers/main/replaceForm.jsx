import React, { Component } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import { replaceLookup, replaceSave } from './action';

class ReplaceForm extends Component {
  constructor(props) {
    super(props);
    this.state = {
      replaceID: '',
      replaceList: props.replaceList,
      message: props.message
    };
  }

  componentDidMount() {
    this.props.fetchReplaceLOTLookup(this.props.replaceNode);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.replaceList) {
      this.setState({
        replaceList: nextProps.replaceList
      });
    }
    if (nextProps.message !== this.props.message) {
      this.setState({
        message: nextProps.message
      });
    }
  }

  handleChange = e => {
    const { target } = e;
    const { name, value } = target;
    this.setState({
      [name]: value * 1
    });
  };

  saveReplace = () => {
    const { replaceID } = this.state;
    const { replaceNode: gid } = this.props;
    this.props.saveReplace(gid, replaceID);
  };

  render() {
    const { replaceID, replaceList, message } = this.state;
    const { close } = this.props;

    return (
      <div className="formWrap">
        <div className="formTitle">
          Replace LOT
          <button onClick={close}>
            <i className="icon icon-cancel" />
          </button>
        </div>
        <div className="formBody">
          {message !== '' && <p className="formErrorP"> {message} </p>}
          <div>
            <label htmlFor="replace">
              <div>Replace with</div>
              <select
                name="replaceID"
                id="replaceID"
                onChange={this.handleChange}
              >
                <option value="">Select Lot</option>
                {replaceList.map(({ phenomeLotID: id, gid: name }) => (
                  <option value={name} key={id}>
                    {name}
                  </option>
                ))}
              </select>
            </label>
          </div>
        </div>
        <div className="formAction">
          <button disabled={replaceID === ''} onClick={this.saveReplace}>
            Replace
          </button>
          <button onClick={close}>Cancel</button>
        </div>
      </div>
    );
  }
}

ReplaceForm.defaultProps = {
  message: '',
  replaceList: []
};
ReplaceForm.propTypes = {
  close: PropTypes.func.isRequired,
  message: PropTypes.string,
  saveReplace: PropTypes.func.isRequired,
  replaceNode: PropTypes.number.isRequired,
  fetchReplaceLOTLookup: PropTypes.func.isRequired,
  replaceList: PropTypes.array // eslint-disable-line
};

const mapState = state => ({
  replaceList: state.main.replace,
  message: state.status.message
});
const mapDispatch = dispatch => ({
  fetchReplaceLOTLookup: gid => {
    dispatch(replaceLookup(gid));
  },
  saveReplace: (gid, replaceID) => {
    dispatch(replaceSave(gid, replaceID));
  }
});
export default connect(
  mapState,
  mapDispatch
)(ReplaceForm);
