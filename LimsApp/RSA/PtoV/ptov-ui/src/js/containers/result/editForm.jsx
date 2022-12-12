import React, { Component } from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import { getTrait, getTraitList, getScreeningList, postData } from './action';

class EditForm extends Component {
  constructor(props) {
    super(props);
    this.state = {
      cropSelected: props.record.cropCode,

      TraitScrResultID: props.record.traitScrResultID,

      traitScreeningID: props.record.traitScreeningID,

      screeningName: props.record.sfColumnLabel,

      traitListValue: props.record.traitName,

      traitListStatus: props.record.listOfValuesTrait, // eslint-disable-line
      screeningListStatus: props.record.listOfValuesScreening, // eslint-disable-line
      traitValue: props.traitList,
      screeningValue: props.screeningList,

      tvalue: props.record.traitValue,
      svalue: props.record.screeningValue,

      sameValue: props.record.sameValue,

      message: props.message
    };
  }
  componentDidMount() {
    this.fetchList(this.props.record);
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.message !== this.props.message) {
      this.setState({
        message: nextProps.message
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
  }

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
  };

  fetchList = value => {
    const {
      traitID,
      screeningFieldID,
      listOfValuesTrait,
      listOfValuesScreening
    } = value;
    if (listOfValuesTrait) {
      this.props.fetchTraitList(traitID);
    }
    if (listOfValuesScreening) {
      this.props.fetchScreeningList(screeningFieldID);
    }
  };

  saveAttribute = () => {
    const { TraitScrResultID, traitScreeningID, tvalue, svalue } = this.state;
    const obj = {
      traitScreeningScreeningValues: [
        {
          TraitScrResultID,
          traitScreeningID,
          traitValueChar: tvalue,
          screeningValue: svalue,
          prefferredValue: true,
          action: 'U',
          sameValue: true
        }
      ],
      pageNumber: this.props.page,
      pageSize: this.props.size,
      filter: this.props.filter,
      sorting: this.props.sorting
    };
    this.props.save(obj);
  };

  validation = () => {
    const { tvalue, svalue } = this.state;
    return !(tvalue !== '' && svalue !== '');
  };

  render() {
    // screeningSelected, screeningSuggestions, cropList, traitSelected, traitSuggestions,
    const {
      cropSelected,
      message,
      screeningName,
      tvalue,
      traitListValue,
      traitListStatus,
      traitValue
    } = this.state;

    const {
      screeningListStatus,
      screeningValue,
      svalue,
      sameValue
    } = this.state;

    const checkScreeningListFalseAndSameValueFalse =
      !screeningListStatus && !sameValue;
    const checkScreeningListTrueAndSameValueFalse =
      screeningListStatus && !sameValue;

    return (
      <div className="formWrap">
        <div className="formTitle">
          Update Trait Screening Value
          <button onClick={this.props.close}>
            <i className="icon icon-cancel" />
          </button>
        </div>

        <div className="formBody">
          {message !== '' && <p className="formErrorP">{message}</p>}
          <div>
            <label htmlFor="crop">
              <div>Crop</div>
              <input type="text" disabled value={cropSelected} />
            </label>
          </div>
          <div>
            <label htmlFor="trait">
              <div>Trait</div>
              <input type="text" disabled value={traitListValue} />
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
              <input
                type="checkbox"
                name="sameValue"
                defaultChecked={sameValue}
                disabled
              />
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
                  autoFocus={true} // eslint-disable-line
                />
              )}
              {traitListStatus && (
                <select
                  name="tvalue"
                  value={tvalue}
                  onChange={this.handleChange}
                  autoFocus={true} // eslint-disable-line
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
          <button disabled={this.validation()} onClick={this.saveAttribute}>
            Update
          </button>
          <button onClick={this.props.close}>Cancel</button>
        </div>
      </div>
    );
  }
}

EditForm.defaultProps = {
  traitList: [],
  screeningList: [],
  crops: [],
  filter: [],
  sorting: {},
  record: {},
  message: ''
};
EditForm.propTypes = {
  fetchTraitList: PropTypes.func.isRequired,
  fetchScreeningList: PropTypes.func.isRequired,
  save: PropTypes.func.isRequired,
  close: PropTypes.func.isRequired,

  traitList: PropTypes.array,  // eslint-disable-line
  screeningList: PropTypes.array,  // eslint-disable-line
  crops: PropTypes.array,  // eslint-disable-line
  page: PropTypes.number.isRequired,
  size: PropTypes.number.isRequired,
  filter: PropTypes.array, // eslint-disable-line
  sorting: PropTypes.object, // eslint-disable-line
  record: PropTypes.object, // eslint-disable-line
  message: PropTypes.string
};

const mapState = state => ({
  message: state.status.message,
  crops: state.user.crops,
  determination: state.relation.screening,
  traits: state.result.traits,
  traitList: state.result.traitList,
  screeningList: state.result.screeningList
});
const mapDispatch = dispatch => ({
  fetchTrait: (traitName, cropCode) => dispatch(getTrait(traitName, cropCode)),
  fetchTraitList: traitID => dispatch(getTraitList(traitID)),
  fetchScreeningList: screeningFieldID => dispatch(getScreeningList(screeningFieldID)),
  save: obj => dispatch(postData(obj))
});
export default connect(
  mapState,
  mapDispatch
)(EditForm);
