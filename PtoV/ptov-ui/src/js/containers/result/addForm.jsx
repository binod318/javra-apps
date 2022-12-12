import React, { Component } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import Autosuggest from 'react-autosuggest';
import { getTrait, getTraitList, getScreeningList, postData } from './action';

class AddForm extends Component {
  constructor(props) {
    super(props);
    this.state = {
      cropList: props.crops,
      cropSelected: '',

      TraitScrResultID: 0,
      screeningName: '',

      traitSelected: '',
      traitSuggestions: [],
      traitListValue: '',

      traitListStatus: false,
      screeningListStatus: false,
      traitValue: props.traitList,
      screeningValue: props.screeningList,

      tvalue: '',
      svalue: '',

      sameValue: false,

      message: props.message
    };
  }
  componentDidMount() {
    this.props.fetchCrops();
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.message !== this.props.message) {
      this.setState({
        message: nextProps.message
      });
    }
    if (nextProps.traits !== this.props.traits) {
      this.setState({
        traitSuggestions: nextProps.traits
      });
    }
    if (nextProps.traitList !== this.props.traitList) {
      this.setState({
        traitValue: nextProps.traitList
      });
    }
    if (nextProps.screeningList !== this.props.screeningList) {
      this.setState({
        screeningValue: nextProps.screeningList
      });
    }
    if (nextProps.crops !== this.props.crops) {
      this.setState({
        cropList: nextProps.crops
      });
    }
  }

  onTraitChange = (event, { newValue }) => {
    this.setState({
      traitListValue: newValue
    });
  };

  onTraitBlur = () => {
    const { traitListValue } = this.state; // traitSelected
    if (traitListValue === '') {
      this.setState({
        traitScreeningID: '',
        screeningName: '',
        traitListValue: '',
        traitListStatus: false,
        screeningListStatus: false,
        traitValue: [],
        screeningValue: [],
        sameValue: false
      });
    }
  };
  handleChange = e => {
    const { target } = e;
    const { name, value } = target;
    this.setState({
      [name]: value
    });
    if (this.state.sameValue) {
      this.setState({
        svalue: value
      });
    }

    // RESET FORM IF CROP IS CHANGED
    if (name === 'cropSelected') {
      this.setState({
        screeningName: '',

        traitSelected: '',
        traitSuggestions: [],
        traitListValue: '',

        traitListStatus: false,
        screeningListStatus: false,
        traitValue: this.props.traitList,
        screeningValue: this.props.screeningList,

        tvalue: '',
        svalue: ''
      });
    }
  };
  traitSuggestionValue = value => {
    const {
      traitScreeningID,
      traitID,
      sfColumnLabel,
      traitLOV,
      screeningLOV,
      sameValue
    } = value;

    this.setState({
      traitScreeningID,
      traitSelected: traitID,
      screeningName: sfColumnLabel,
      sameValue,
      traitListStatus: traitLOV,
      screeningListStatus: screeningLOV
    });
    this.fetchList(value);
    return value.traitName;
  };
  fetchList = value => {
    const { traitID, screeningFieldID, traitLOV, screeningLOV } = value;
    if (traitLOV) {
      this.props.fetchTraitList(traitID);
    }
    if (screeningLOV) {
      this.props.fetchScreeningList(screeningFieldID);
    }
  };

  traitSuggestion = suggestion => <div>{suggestion.traitName}</div>;
  traitFetchReq = ({ value }) => {
    const _this = this;
    const inputValue = value.trim().toLowerCase();
    clearTimeout(this.timer);
    this.timer = setTimeout(() => {
      _this.traitFetch(inputValue);
    }, 500);
  };
  traitFetch = value => {
    const { cropSelected } = this.state;
    this.setState({ traitSelected: '' });
    this.props.fetchTrait(value, cropSelected);
  };
  traitClearReq = () => {
    this.setState({
      traitSuggestions: []
    });
  };

  saveAttribute = process => {
    const {
      TraitScrResultID,
      traitScreeningID,
      tvalue,
      svalue,
      sameValue
    } = this.state;
    const obj = {
      traitScreeningScreeningValues: [
        {
          TraitScrResultID,
          traitScreeningID,
          traitValueChar: tvalue,
          screeningValue: sameValue ? tvalue : svalue,
          prefferredValue: true,
          action: 'i',
          sameValue: true
        }
      ],
      pageNumber: this.props.page,
      pageSize: this.props.size,
      filter: this.props.filter,
      sorting: this.props.sorting,
      process
    };
    this.props.save(obj);
    if (process) {
      this.setState({
        tvalue: '',
        svalue: ''
      });
    }
  };

  validation = () => {
    const {
      cropSelected,
      svalue,
      tvalue,
      traitSelected,
      traitScreeningID
    } = this.state;
    return !(
      cropSelected &&
      svalue &&
      tvalue &&
      traitSelected &&
      traitScreeningID
    );
  };

  render() {
    const {
      cropList,
      message,
      screeningName,
      traitSuggestions,
      tvalue,
      traitListValue,
      traitListStatus,
      traitValue,
      sameValue,
      screeningListStatus,
      screeningValue,
      svalue
    } = this.state;
   
    const traitInput = {
      placeholder: '...',
      value: traitListValue,
      onChange: this.onTraitChange,
      onBlur: this.onTraitBlur
    };

    const checkScreeningListFalseAndSameValueFalse =
      !screeningListStatus && !sameValue;
    const checkScreeningListTrueAndSameValueFalse =
      screeningListStatus && !sameValue;

    return (
      <div className="formWrap">
        <div className="formTitle">
          Add Trait Screening Value
          <button onClick={this.props.close}>
            <i className="icon icon-cancel" />
          </button>
        </div>

        <div className="formBody">
          {this.props.source === 'result' && message !== '' && <p className="formErrorP">{message}</p>}
          <div>
            <label htmlFor="crop">
              <div>Crop</div>
              <select
                name="cropSelected"
                onChange={this.handleChange}
                autoFocus={true} // eslint-disable-line
              >
                <option value="">Select</option>
                {cropList.map(crop => (
                  <option key={crop.cropCode} value={crop.cropCode}>
                    {crop.cropCode}
                  </option>
                ))}
              </select>
            </label>
          </div>
          <div>
            <label htmlFor="trait">
              <div>Trait</div>
              <Autosuggest
                suggestions={traitSuggestions}
                onSuggestionsFetchRequested={this.traitFetchReq}
                onSuggestionsClearRequested={this.traitClearReq}
                getSuggestionValue={this.traitSuggestionValue}
                renderSuggestion={this.traitSuggestion}
                inputProps={traitInput}
              />
            </label>
          </div>
          <div>
            <label htmlFor="screening">
              <div>Screening Field</div>
              <input type="text" disabled value={screeningName} />
            </label>
          </div>
          <div>
            <label htmlFor="traits">
              <div>Same Value</div>
              {sameValue && (
                <input
                  type="checkbox"
                  name="sameValue"
                  defaultChecked={sameValue}
                  disabled
                />
              )}
              {!sameValue && (
                <input
                  type="checkbox"
                  name="sameValue"
                  defaultChecked={sameValue}
                  disabled
                />
              )}
            </label>
          </div>
          <div>
            <label htmlFor="crop">
              <div>Trait Value</div>
              {!traitListStatus && (
                <input
                  type="text"
                  name="tvalue"
                  onChange={this.handleChange}
                  value={tvalue}
                />
              )}
              {traitListStatus && (
                <select
                  name="tvalue"
                  value={tvalue}
                  onChange={this.handleChange}
                >
                  <option value="">select</option>
                  {traitValue.map(trait => {
                    const { traitValueCode } = trait;
                    return (
                      <option key={traitValueCode} value={traitValueCode}>
                        {traitValueCode}
                      </option>
                    );
                  })}
                </select>
              )}
            </label>
          </div>
          <div>
            <label htmlFor="crop">
              <div>Screening Value</div>
              {checkScreeningListFalseAndSameValueFalse && (
                <input
                  type="text"
                  name="svalue"
                  onChange={this.handleChange}
                  value={svalue}
                />
              )}
              {sameValue && (
                <input disabled type="text" name="svalue" value={tvalue} />
              )}
              {checkScreeningListTrueAndSameValueFalse && (
                <select
                  name="svalue"
                  value={svalue}
                  onChange={this.handleChange}
                >
                  <option value="">select</option>
                  {screeningValue.map(screening => {
                    const { attributeCode } = screening;
                    return (
                      <option key={attributeCode} value={attributeCode}>
                        {attributeCode}
                      </option>
                    );
                  })}
                </select>
              )}
            </label>
          </div>
        </div>

        <div className="formAction">
          <button
            disabled={this.validation()}
            onClick={() => this.saveAttribute(false)}
          >
            Save
          </button>
          <button
            disabled={this.validation()}
            onClick={() => this.saveAttribute(true)}
          >
            Save &amp; Cont.
          </button>
          <button onClick={this.props.close}>Cancel</button>
        </div>
      </div>
    );
  }
}

AddForm.defaultProps = {
  crops: [],
  traitList: [],
  screeningList: [],
  message: '',
  traits: [],
  filter: [],
  sorting: {}
};
AddForm.propTypes = {
  crops: PropTypes.array, // eslint-disable-line
  traitList: PropTypes.array, // eslint-disable-line
  screeningList: PropTypes.array, // eslint-disable-line
  message: PropTypes.string,
  fetchCrops: PropTypes.func.isRequired,
  fetchTraitList: PropTypes.func.isRequired,
  fetchScreeningList: PropTypes.func.isRequired,
  fetchTrait: PropTypes.func.isRequired,
  save: PropTypes.func.isRequired,
  close: PropTypes.func.isRequired,
  traits: PropTypes.array, // eslint-disable-line
  page: PropTypes.number.isRequired,
  size: PropTypes.number.isRequired,
  filter: PropTypes.array, // eslint-disable-line
  sorting: PropTypes.object, // eslint-disable-line
};

const mapState = state => ({
  message: state.status.message,
  source: state.status['from'],
  crops: state.result.crops,
  determination: state.relation.screening,
  traits: state.result.traits,
  traitList: state.result.traitList,
  screeningList: state.result.screeningList
});
const mapDispatch = dispatch => ({
  fetchCrops: () => dispatch({ type: 'FETCH_CROPS' }),
  fetchTrait: (traitName, cropCode) => dispatch(getTrait(traitName, cropCode)),
  fetchTraitList: traitID => dispatch(getTraitList(traitID)),
  fetchScreeningList: screeningFieldID => dispatch(getScreeningList(screeningFieldID)),
  save: obj => dispatch(postData(obj))
});
export default connect(
  mapState,
  mapDispatch
)(AddForm);
