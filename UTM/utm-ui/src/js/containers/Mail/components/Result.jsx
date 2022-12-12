import * as React from 'react';
import PropTypes from 'prop-types';

import Wrapper from '../../../components/Wrapper/wrapper';

class Result extends React.Component {
  constructor(props: Object) {
    super(props);
    this.state = {
      configID: props.editData.configID || '',
      crop: props.editData.cropCode || '',
      group: props.editData.configGroup || '',
      email: props.editData.recipients || '',
      brStationCode: props.editData.brStationCode || '',
      errState: false,
      errMsg: 'Please enter valid email address.'
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
      .replace(/;/g, ',')
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
    const {
      configID,
      crop: cropCode,
      group: configGroup,
      email: recipients,
      brStationCode
    } = this.state;
    const { mode } = this.props;

    //get selected menu
    let selectedMenu = window.localStorage.getItem("selectedMenuGroup");

    //if menu is not set then set default menu(Utm general) from here
    if(!selectedMenu || selectedMenu == '') {
      selectedMenu = 'utmGeneral';
      window.localStorage.setItem("selectedMenuGroup", selectedMenu);
    }

    if (this.emailValidation(recipients)) {
      if (mode === 'add') {
        this.props.onAppend(
          configID,
          cropCode,
          configGroup,
          recipients,
          brStationCode,
          selectedMenu
        );
      }
      if (mode === 'edit') {
        this.props.onAppend(
          configID,
          cropCode,
          configGroup,
          recipients,
          brStationCode,
          selectedMenu
        );
      }
      this.setState({ errState: false });
      this.props.close('');
    } else {
      this.setState({ errState: true });
    }
    return null;
  };
  // $FlowFixMe
  handleChange = e => {
    const { target } = e;
    const { value, name } = target;

    this.setState({
      [name]: value
    });
  };

  cropUI = () => {
    const { mode } = this.props;
    if (mode !== 'edit') {
      return (
        <select
          name="crop"
          value={this.state.crop}
          onChange={this.handleChange}
          id="mail_crop_select"
        >
          <option value="*">All Crops</option>
          {this.props.crops.map(crop => (
            <option key={crop} value={crop}>
              {crop}
            </option>
          ))}
        </select>
      );
    }
    return (
      <input
        name="group"
        type="text"
        value={this.state.crop}
        onChange={() => {}}
        disabled
      />
    );
  };
  stationUI = () => {
    const { mode } = this.props;
    if (mode !== 'edit') {
      return (
        <select
          name="brStationCode"
          value={this.state.brStationCode}
          onChange={this.handleChange}
          id="mail_crop_select"
        >
          <option value="">All Breading Station</option>
          {this.props.breedingStation.map(b => (
            <option key={b.breedingStationCode} value={b.breedingStationCode}>
              {b.breedingStationCode}
            </option>
          ))}
        </select>
      );
    }
    return (
      <input
        name="group"
        type="text"
        value={this.state.brStationCode}
        onChange={() => {}}
        disabled
      />
    );
  };

  render() {
    const { mode } = this.props;
    const { errState, errMsg } = this.state;
    const title = mode === 'edit' ? 'Edit ' : 'Add ';
    const buttonName = mode === 'edit' ? 'Update ' : 'Save';

    return (
      <Wrapper>
        <div className="modalContent">
          <div className="modalTitle">
            <i className="demo-icon icon-plus-squared info" />
            <span>{title} Mail Config</span>
            <i
              role="presentation"
              className="demo-icon icon-cancel close"
              onClick={() => this.props.close('')}
              title="Close"
            />
          </div>
          {/*
          <div className="modalBody"></div>
          */}
          <div className="modelsubtitle">
            <div>
              <label htmlFor="trait">Group</label> {/*eslint-disable-line*/}
              <input
                name="group"
                type="text"
                value={this.state.group}
                onChange={() => {}}
                disabled
              />
            </div>
            <div>
              <label>Crop</label>
              {/*eslint-disable-line*/}
              {this.cropUI()}
            </div>
            <div>
              <label>Breeding Station</label>
              {/*eslint-disable-line*/}
              {this.stationUI()}
            </div>
            <div>
              <label htmlFor="determination">
                Email
                {errState && (
                  <span style={{ paddingLeft: '5px', color: 'red' }}>
                    {errMsg}
                  </span>
                )}
              </label>
              {/*eslint-disable-line*/}
              <textarea
                name="email"
                type="text"
                value={this.state.email}
                onChange={this.handleChange}
                style={{ minHeight: '100px' }}
                id="mail_text"
              />
            </div>
          </div>

          <div className="modalFooter">
            &nbsp;&nbsp;
            <button onClick={this.handleAdd} id="mail_btn">
              {buttonName}
            </button>
          </div>
        </div>
      </Wrapper>
    );
  }
}

Result.defaultProps = {
  breedingStation: [],
  mode: '',
  crops: [],
  editData: {}
};
Result.propTypes = {
  breedingStation: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  onAppend: PropTypes.func.isRequired,
  close: PropTypes.func.isRequired,
  mode: PropTypes.string,
  crops: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  editData: PropTypes.object // eslint-disable-line react/forbid-prop-types
};

export default Result;
