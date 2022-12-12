import React, { Component } from 'react';
import { connect } from 'react-redux';

class MailForm extends Component {
  constructor(props) {
    super(props);
    this.state = {
      crops: props.crops || [],
      cropSelected: props.cropSelected || '',
      email: props.email || '',

      message: props.message
    }
  }

  componentWillReceiveProps(nextProps) {
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
      [name]: value
    });

  };

  formSubmit = () => {
    const { id, group } = this.props;
    const { cropSelected: crop, email } = this.state;
    if (this.emailValidation(email)) {
      this.props.submit(id, group, crop, email);
      this.props.close();
    } else {
      this.props.errorMsg('Invalid Email address or Email can\'t be empty.');
    }
  };

  emailValidation = recipients => {
    let validation = true;
    let re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;

    const emailList = recipients.replace(/\s/g,'').replace(';', ',').split(',');
    emailList.map(e => {
      if (!re.test(String(e).toLowerCase())) {
        validation = false;
      }
    });
    return validation;
  };

  render() {
    const { crops, group, mode } = this.props;
    const { cropSelected, email, message } = this.state;

    return (
      <div className="formWrap">
        <div className="formTitle">
          {this.props.mode === "edit" ? "Edit" : "Append"} Email
          <button onClick={this.props.close}>
            <i className="icon icon-cancel" />
          </button>
        </div>

        <div className="formBody">
          {this.props.source === 'mail' && message !== '' && <p className="formErrorP">{message}</p>}
          <div>
            <label htmlFor="crop">
              <div>Group</div>
              <input type="text" disabled defaultValue={group} />
            </label>
          </div>
          <div>
            <label htmlFor="crop">
              <div>Crop</div>
              {mode === 'edit' && (
                <input type="text" disabled defaultValue={cropSelected} />
              )}
              {mode === 'add' && (
                <select
                  name="cropSelected"
                  onChange={this.handleChange}
                  autoFocus={true} // eslint-disable-line
                  value={cropSelected}
                >
                  <option value="*">All Crops</option>
                  {crops.map(crop => (
                    <option key={crop.cropCode} value={crop.cropCode}>
                      {crop.cropCode}
                    </option>
                  ))}
                </select>
              )}
            </label>
          </div>
          <div>
            <label htmlFor="crop">
              <div>Email</div>
              <textarea name="email" defaultValue={email} onChange={this.handleChange}></textarea>
            </label>
          </div>
        </div>

        <div className="formAction">
          <button disabled={false} onClick={this.formSubmit}>
            {this.props.mode === "edit" ? "Update" : "Save"}
          </button>
          <button onClick={this.props.close}>Cancel</button>
        </div>
      </div>
    );
  }
}
const mapState = state => ({
  message: state.status.message,
  source: state.status['from'],
});
export default connect(
  mapState,
  null
) (MailForm);