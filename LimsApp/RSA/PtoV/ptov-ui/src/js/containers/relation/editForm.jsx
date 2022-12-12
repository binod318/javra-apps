// @flow
import React from 'react';
import { connect } from 'react-redux';
import Autosuggest from 'react-autosuggest';

import { fetchDetermination } from './action';

type PropsType = {
  close: string,
  determination: Array<number>,
  edit: (screeningSelected: string, sameValue: boolean) => void,
  fetchDetermination: (value: string, cropCode: string) => void,
  message: string,

  record: {
    cropCode: string,

    listOfValues: boolean,
    sameValue: boolean,
    screeningFieldID: string,
    sfColumnLabel: string,
    traitName: string
  }
};
type StateType = {
  screeningSuggestions: Array<number>,
  message: string,
  sameValue: boolean,
  screeningSelected: string,
  screeningValue: string
};

class EditForm extends React.Component<PropsType, StateType> {
  constructor(props: PropsType) {
    super(props);
    this.state = {
      screeningSelected: props.record.screeningFieldID || '',
      screeningSuggestions: [],
      screeningValue: props.record.sfColumnLabel || '',
      sameValue: props.record.sameValue,

      message: props.message
    };
  }
  componentWillReceiveProps(nextProps: any) {
    if (nextProps.determination) {
      this.setState({
        screeningSuggestions: nextProps.determination
      });
    }
    if (nextProps.message !== this.props.message) {
      this.setState({ message: nextProps.message });
    }
  }

  componentWillUnmount() {
    if (this.timer) {
      clearTimeout(this.timer);
    }
  }

  onScreeningChange = (event: any, { newValue }: any) => {
   
    this.setState({
      screeningValue: newValue
    });
  };
  onScreeningBlur = () => {
  };
  timer: TimeoutID;
  screeningSuggestionValue = (value: any) => {
    this.setState({
      screeningSelected: value.screeningFieldID
    });
    return value.sfColumnLabel;
  };
  screeningSuggestion = (suggestion: any) => (
    <div>{suggestion.sfColumnLabel}</div>
  );
  screeningFetchReq = ({ value }: any) => {
    const _this = this;
    const inputValue = value.trim().toLowerCase();
    clearTimeout(this.timer);
    this.timer = setTimeout(() => {
      _this.determinationFetch(inputValue);
    }, 500);
  };
  determinationFetch = (value: any) => {
    const { record } = this.props;
    const { cropCode } = record;
    this.setState({ screeningSelected: '' });
    this.props.fetchDetermination(value, cropCode);
  };
  screeningClearReq = () => {
    this.setState({
      screeningSuggestions: []
    });
  };

  handleInputChange = (e: any) => {
    const { target } = e;
    const { type, checked, value } = target;
    const val = type === 'checkbox' ? checked : value;
    const { name } = target;

    this.setState({
      [name]: val
    });
  };

  validateAdd = () => {
    const { screeningSelected } = this.state;
    return screeningSelected === '';
  };

  render() {
    const { close, edit, record } = this.props;
    const { listOfValues } = record;
    const {
      screeningSelected,
      screeningSuggestions,
      screeningValue,
      sameValue,
      message
    } = this.state;

    const screeningInput = {
      placeholder: '...',
      value: screeningValue,
      onChange: this.onScreeningChange,
      onBlur: this.onScreeningBlur
    };

    return (
      <div className="formWrap">
        <div className="formTitle">
          Update Trait Screening
          <button onClick={this.props.close}>
            <i className="icon icon-cancel" />
          </button>
        </div>
        <div className="formBody">
          {message !== '' && <p className="formErrorP">{message}</p>}
          <div>
            <label htmlFor="crop">
              <div>Crop</div>
              <input disabled type="text" defaultValue={record.cropCode} />
            </label>
          </div>
          <div>
            <label htmlFor="traits">
              <div>Trait</div>
              <input disabled type="text" defaultValue={record.traitName} />
            </label>
          </div>
          <div>
            <label htmlFor="screemomg">
              <div>Screening Field</div>
              <Autosuggest
                suggestions={screeningSuggestions}
                onSuggestionsFetchRequested={this.screeningFetchReq}
                onSuggestionsClearRequested={this.screeningClearReq}
                getSuggestionValue={this.screeningSuggestionValue}
                renderSuggestion={this.screeningSuggestion}
                inputProps={screeningInput}
              />
            </label>
          </div>

          <div>
            <label htmlFor="traits">
              <div>Same Value</div>
              <input
                type="checkbox"
                name="sameValue"
                disabled={true || !listOfValues}
                checked={sameValue}
                onChange={this.handleInputChange}
              />
            </label>
          </div>
        </div>
        <div className="formAction">
          <button
            disabled={this.validateAdd()}
            onClick={() => {
              edit(screeningSelected, sameValue);
            }}
          >
            Update
          </button>
          <button onClick={close}>Cancel</button>
        </div>
      </div>
    );
  }
}
const mapState = (state: StateType) => ({
  message: state.status.message,
  determination: state.relation.screening
});
const mapDispatch = dispatch => ({
  fetchDetermination: (determinationName, cropCode) => {
    dispatch(fetchDetermination(determinationName, cropCode));
  }
});

export default connect(
  mapState,
  mapDispatch
)(EditForm);
