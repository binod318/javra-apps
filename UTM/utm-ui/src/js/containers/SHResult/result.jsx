import React from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import Autosuggest from "react-autosuggest";

import Wrapper from "../../components/Wrapper/wrapper";

import { fetchCrop, fetchDetermination, fetchTrait } from "../Trait/action";

class Result extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      sourceSelected: "Phenome",

      cropList: props.crop,
      cropSelected: props.editData.crop || "",

      traitSuggestions: [],
      traitValue: props.editData.trait || "",
      traitType: props.editData.listOfValues || false,

      determinationValue: props.editData.determination || "",

      traitName: props.editData.traitValue || "",
      determinationName: props.editData.value || "",

      relationID: props.editData.relationID || "",

      sampleType: props.editData.sampleType || "",
      mappingCol: props.editData.mappingCol || "Result"
    };
  }
  componentDidMount() {
    this.props.fetchCrop();
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.crop.length !== this.props.crop.length) {
      this.setState({
        cropList: nextProps.crop
      });
    }
    if (nextProps.trait !== this.props.trait) {
      this.setState({ traitSuggestions: nextProps.trait });
    }
  }
  onTraitChange = (event, { newValue }) => {
    this.setState({ traitValue: newValue });
  };
  onDeterminationChange = (event, { newValue }) => {
    this.setState({ determinationValue: newValue });
  };

  traitSuggestionValue = value => {
    const {
      traitName,
      listOfValues,
      determinatioName,
      relationID
    } = value;

    this.setState({
      traitType: listOfValues,
      traitValue: "",
      determinationValue: determinatioName,
      relationID
    });
    return traitName;
  };
  traitSuggestion = suggestion => {
    const { traitName } = suggestion;
    return <div>{traitName}</div>;
  };
  traitFetchReq = ({ value }) => {
    this.setState({ traitType: "" });
    const _this = this;
    const inputValue = value.trim().toLowerCase();
    clearTimeout(this.timer);
    this.timer = setTimeout(() => {
      _this.traitFetch(inputValue);
    }, 500);
  };
  traitFetch = value => {
    const { cropSelected, sourceSelected } = this.state;
    this.props.fetchTrait(value, cropSelected, sourceSelected);
  };
  traitClearReq = () => {
    this.setState({
      traitSuggestions: []
    });
  };

  determinationSuggestionValue = value => value.determinationName;

  determinationSuggestion = suggestion => (
    <div>{suggestion.determinationName}</div>
  );
  determinationFetchReq = ({ value }) => {
    const _this = this;
    const inputValue = value.trim().toLowerCase();
    clearTimeout(this.timer);
    this.timer = setTimeout(() => {
      _this.determinationFetch(inputValue);
    }, 500);
  };
  determinationFetch = value => {
    this.props.fetchDetermination(value, this.state.cropSelected);
  };
  determinationClearReq = () => {};

  handleChange = e => {
    const { target } = e;
    const { name, value } = target;
    
    if (name === "cropSelected") {
      this.setState({
        determinationValue: "",
        traitValue: "",
        traitType: false,
        sampleType: ""
      });
    }
    this.setState({
      [name]: value
    });
  };
  validateAdd = () => {
    const {
      relationID,
      sampleType,
      mappingCol
    } = this.state;

    const relationIDNotEmt = relationID !== "";
    const mappingColNotEmp = mappingCol !== "";
    const sampleTypeNotEmp = sampleType !== "";

    if (relationIDNotEmt && sampleTypeNotEmp && mappingColNotEmp) {
      return false;
    }

    return true;
  };
  handleAddResult = () => {
    const _this = this;
    const {
      cropSelected,

      relationID,
      sampleType,
      mappingCol
    } = this.state;

    let action = "I";
    if (this.props.mode === "edit") {
      action = "U";
    }

    let obj = {
      relationID,
      sampleType,
      mappingCol,
      action
    };

    if (this.props.mode === "edit") {
      obj = Object.assign(
        {
          id: _this.props.editData.id
        },
        obj
      );
    }

    this.props.onAppend({
      cropCode: cropSelected,
      data: [obj]
    });
    this.props.close("");
    this.setState({
      determinationValue: "",
      traitValue: "",
      sampleType: ""
    });
  };

  handleAddStay = () => {
    const _this = this;
    const {
      cropSelected,
      relationID,
      sampleType,
      mappingCol
    } = this.state;

    let action = "I";
    if (this.props.mode === "edit") {
      action = "U";
    }

    let obj = {
      relationID,
      sampleType,
      mappingCol,
      action
    };

    if (this.props.mode === "edit") {
      obj = Object.assign(
        {
          id: _this.props.editData.traitDeterminationResultID
        },
        obj
      );
    }

    this.props.onAppend({
      cropCode: cropSelected,
      data: [obj]
    });

    this.setState({
      mappingCol: "Result",
      sampleType: ""
    });
  };

  handMappingContextChange = e => {
    this.setState({ mappingCol: e.target.value });
  };

  render() {
    const {
      sourceSelected,
      cropSelected,
      traitSuggestions,
      traitValue,
      determinationValue,
      sampleType,
      mappingCol
    } = this.state;

    const showFields = cropSelected !== "" && sourceSelected !== "";
    const traitInput = {
      placeholder: "Select Trait",
      value: traitValue,
      onChange: this.onTraitChange
    };

    const buttonName = this.props.mode === "edit" ? "Edit " : "Add ";

    return (
      <Wrapper>
        <div className="modalContent">
          <div className="modalTitle">
            <i className="demo-icon icon-plus-squared info" />
            <span>Seed Health Trait Result</span>
            <i
              role="presentation"
              className="demo-icon icon-cancel close"
              onClick={() => this.props.close("")}
              title="Close"
            />
          </div>
          <div className="modelsubtitle">
            <label>Crop</label>{/*eslint-disable-line*/}

            {this.props.mode === "edit" && (
              <input type="text" value={cropSelected} disabled />
            )}

            {this.props.mode !== "edit" && (
              <select
                name="cropSelected"
                value={this.state.cropSelected}
                onChange={this.handleChange}
              >
                <option value="">Select</option>
                {this.state.cropList.map(crop => (
                  <option key={crop.cropCode} value={crop.cropCode}>
                    {crop.cropCode}
                  </option>
                ))}
              </select>
            )}
          </div>

          <div className="modelsubtitle">
            {showFields && (
              <div className="mapColradioSection">
                <label htmlFor="Result">
                  <input
                    id="Result"
                    type="radio"
                    value="Result"
                    checked={mappingCol === "Result"}
                    onChange={this.handMappingContextChange}
                  />
                  Result
                </label>
                <label htmlFor="ABSTestNumber">
                  <input
                    id="ABSTestNumber"
                    type="radio"
                    value="ABSTestNumber"
                    checked={mappingCol === "ABSTestNumber"}
                    onChange={this.handMappingContextChange}
                  />
                  ABS Test Number
                </label>
              </div>
            )}
          </div>

          <div className="modalBody">
            {showFields && (
              <div>
                <label htmlFor="trait">Traits</label> {/*eslint-disable-line*/}
                {this.props.mode === "edit" && (
                  <input type="text" value={traitValue} disabled />
                )}
                {this.props.mode !== "edit" && (
                  <Autosuggest
                    suggestions={traitSuggestions}
                    onSuggestionsFetchRequested={this.traitFetchReq}
                    onSuggestionsClearRequested={this.traitClearReq}
                    getSuggestionValue={this.traitSuggestionValue}
                    renderSuggestion={this.traitSuggestion}
                    inputProps={traitInput}
                  />
                )}
              </div>
            )}

            {showFields && (
              <div>
                <label htmlFor="determination">Determination</label>{/*eslint-disable-line*/}
                <input type="text" value={determinationValue} disabled />
              </div>
            )}
            
            {showFields && (
              <div>
                <label htmlFor="sampleType">Sample Type</label> {/*eslint-disable-line*/}
                <select
                  name="sampleType"
                  value={sampleType}
                  onChange={this.handleChange}
                >
                  <option value="">Select</option>
                  <option value="Fruit">Fruit</option>
                  <option value="Seed">Seed</option>
                </select>
              </div>
            )}
          </div>

          <div className="modalFooter">
            {this.props.mode !== "edit" && (
              <button
                disabled={this.validateAdd()}
                onClick={() => this.handleAddStay()}
              >
                {buttonName}
              </button>
            )}
            &nbsp;&nbsp;
            <button
              disabled={this.validateAdd()}
              onClick={this.handleAddResult}
            >
              {buttonName} &amp; Close
            </button>
          </div>
        </div>
      </Wrapper>
    );
  }
}

const mapState = state => ({
  crop: state.traitRelation.crop,
  trait: state.traitRelation.trait,
  determination: state.traitRelation.determination,
  relation: state.traitRelation.relation
});
const mapDispatch = dispatch => ({
  fetchCrop: () => dispatch(fetchCrop()),
  fetchTrait: (traitName, cropCode, sourceSelected) =>
    dispatch(fetchTrait(traitName, cropCode, sourceSelected)),
  fetchDetermination: (determinationName, cropCode) =>
    dispatch(fetchDetermination(determinationName, cropCode))
});

Result.defaultProps = {
  crop: [],
  trait: [],
  editData: {},
  mode: ""
};
Result.propTypes = {
  crop: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  trait: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  close: PropTypes.func.isRequired,
  onAppend: PropTypes.func.isRequired,
  fetchCrop: PropTypes.func.isRequired,
  fetchDetermination: PropTypes.func.isRequired,
  fetchTrait: PropTypes.func.isRequired,
  editData: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  mode: PropTypes.string
};

export default connect(
  mapState,
  mapDispatch
)(Result);
