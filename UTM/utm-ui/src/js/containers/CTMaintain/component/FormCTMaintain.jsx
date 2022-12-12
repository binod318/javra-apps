import * as React from 'react';
// import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import Wrapper from '../../../components/Wrapper/wrapper';

class FormCT extends React.Component {
  constructor(props) {
    super(props);
    let act = true;
    if (props.editNode && props.editNode.statusName) {
      act = props.editNode.statusName === 'Active';
    }
    this.state = {
      id: props.editNode.id || 0,
      name: props.editNode.name || '',
      active: act,
      action: props.mode === 'edit' ? 'u' : 'i'
    };
  }

  /*
   * Email validation
   * receives array list which is tested with regex for validation
   * @return boolen
   */
  emailValidation = (recipients: string) => {
    let validation = true;
    const re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/; // eslint-disable-line

    const emailList = recipients
      .replace(/\s/g, '')
      .replace(';', ',')
      .split(',');
    emailList.map(e => {
      if (!re.test(String(e).toLowerCase())) {
        validation = false;
      }
      return null;
    });
    return validation;
  };

  handleAdd = () => {
    // save
    this.props.save(this.state);
    return null;
  };
  // $FlowFixMe
  handleChange = e => {
    const { target } = e;
    const { name } = target;
    const value = target.type === 'checkbox' ? target.checked : target.value;

    this.setState({
      [name]: value
    });
  };

  checkError = () => {
    if (this.state.id !== 0) {
      const status = this.props.editNode.statusName === 'Active';
      if (
        this.state.name === this.props.editNode.name &&
        this.state.active === status
      ) {
        return true;
      }
    }
    if (this.state.name === '') return true;
    return false;
  };

  render() {
    const { mode } = this.props;
    const { name, active } = this.state;
    const title = mode === 'edit' ? 'Edit ' : 'Add ';
    const buttonName = mode === 'edit' ? 'Update ' : 'Save';

    return (
      <Wrapper>
        <div className="modalContent">
          <div className="modalTitle">
            <i className="demo-icon icon-plus-squared info" />
            <span>
              {title} {this.props.title}
            </span>
            <i
              role="presentation"
              className="demo-icon icon-cancel close"
              onClick={() => this.props.close()}
              title="Close"
            />
          </div>
          <div className="modalBody" />
          <div className="modelsubtitle">
            <div>
              <label htmlFor="trait">{this.props.title} Name</label> {/*eslint-disable-line*/}
              <br />
              <input
                name="name"
                type="text"
                value={name}
                onChange={this.handleChange}
                disabled={false}
              />
            </div>
            <div style={{ display: 'flex', marginTop: '10px' }}>
              <div className="tableCheck" style={{ marginTop: '10px' }}>
                <input
                  id="ll"
                  name="active"
                  type="checkbox"
                  checked={active}
                  onChange={this.handleChange}
                  disabled={mode !== 'edit'}
                />
                <label htmlFor="ll" />
              </div>
              <label htmlFor="trait" style={{width:'100px'}}>Status Active</label> {/*eslint-disable-line*/}
            </div>
          </div>

          <div className="modalFooter">
            &nbsp;&nbsp;
            <button
              onClick={this.handleAdd}
              id="mail_btn"
              disabled={this.checkError()}
            >
              {buttonName}
            </button>
          </div>
        </div>
      </Wrapper>
    );
  }
}
FormCT.defaultProps = {
  editNode: {},
  title: ''
};
FormCT.propTypes = {
  editNode: PropTypes.object, // eslint-disable-line
  mode: PropTypes.string.isRequired,
  save: PropTypes.func.isRequired,
  title: PropTypes.string,
  close: PropTypes.func.isRequired
};
export default FormCT;
