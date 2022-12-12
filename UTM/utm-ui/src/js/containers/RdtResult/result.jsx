import React from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import Autosuggest from "react-autosuggest";

import Wrapper from "../../components/Wrapper/wrapper";

import { fetchCrop, fetchDetermination, fetchTrait } from "../Trait/action";
// import { getTraitValues, traitValuesReset } from '../../action';
export const traitValuesReset = () => ({
  type: "TRAITVALUE_RESET"
});
export const getTraitValues = cropTraitID => ({
  type: "FETCH_TRAITVALUES",
  cropTraitID
});

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

      traitValuesList: props.traitValues,

      relationID: props.editData.relationID || "",

      materialStatusList: [],
      materialStatus: props.editData.materialStatus || "",
      mappingColList: [],
      mappingCol: props.editData.mappingCol || "",
      maxPercent: props.editData.percentTo || "",
      minPercent: props.editData.percentFrom || "",
      mappingColumnContext: "none"
    };
  }
  componentDidMount() {
    this.props.fetchCrop();
    this.props.fetchMaterialStatus();
    this.props.fetchMappingColumns();
    const { editData, mode } = this.props;
    if (mode === "edit") {
      const { cropTraitID, listOfValues } = editData;
      if (listOfValues) {
        this.props.fetchTraitValues(cropTraitID);
      }
    }
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
    if (nextProps.traitValues !== this.props.traitValues) {
      this.setState({ traitValuesList: nextProps.traitValues });
    }

    if (nextProps.rdtMaterialStatus !== this.props.rdtMaterialStatus) {
      this.setState({ materialStatusList: nextProps.rdtMaterialStatus });
    }
    if (nextProps.rdtMappingColumns !== this.props.rdtMappingColumns) {
      this.setState({ mappingColList: nextProps.rdtMappingColumns });
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
      // traitID,
      traitName,
      listOfValues,
      cropTraitID,
      // determinationID,
      determinatioName,
      relationID
    } = value;

    if (listOfValues) {
      this.props.fetchTraitValues(cropTraitID);
    }

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
    const { maxPercent, minPercent, traitName } = this.state;

    if (name === "traitName" && maxPercent !== "" && minPercent !== "") {
      this.setState({ determinationName: "" });
    }
    if (name === "maxPercent" && traitName !== "" && minPercent !== "") {
      this.setState({ determinationName: "" });
    }
    if (name === "minPercent" && maxPercent !== "" && traitName !== "") {
      this.setState({ determinationName: "" });
    }

    if (name === "mappingCol") {
      this.setState({
        materialStatus: "",
        maxPercent: "",
        minPercent: "",
        traitName: "",
        determinationName: ""
      });
    }
    if (name === "materialStatus") {
      this.setState({
        mappingCol: ""
      });
    }

    if (name === "cropSelected") {
      this.props.resetTraitValues();
      this.setState({
        determinationValue: "",
        traitValue: "",
        traitType: false
      });
    }
    this.setState({
      [name]: value
    });
  };
  validateAdd = () => {
    const {
      traitName,
      determinationName,
      relationID,
      mappingCol,
      maxPercent,
      minPercent,
      mappingColumnContext
    } = this.state;

    const relationIDNotEmt = relationID !== "";
    const traitNameNotEmt = traitName !== "";
    const mappingCOlNotEmt = mappingCol !== "" && relationIDNotEmt;

    if (mappingColumnContext === "Resistantper") {
      return traitNameNotEmt;
    }

    if (
      traitNameNotEmt &&
      !determinationName &&
      !mappingCOlNotEmt &&
      maxPercent !== "" &&
      minPercent !== ""
    ) {
      return false;
    }
    if (traitNameNotEmt && determinationName && !mappingCOlNotEmt) {
      return false;
    }
    if (mappingCOlNotEmt) {
      return false;
    }
    return true;
  };
  handleAddResult = () => {
    const _this = this;
    const {
      cropSelected,
      traitName,
      traitValue,
      determinationName,

      relationID,
      materialStatus,
      maxPercent,
      minPercent,
      mappingColumnContext
    } = this.state;

    let { mappingCol } = this.state;

    if (mappingColumnContext !== "none") {
      mappingCol = mappingColumnContext;
    }

    let action = "I";
    if (this.props.mode === "edit") {
      action = "U";
    }

    let obj = {
      relationID,
      traitValue: traitName.trim(),
      trait: traitValue,
      determinationValue: determinationName.trim(),
      materialStatus,
      mappingCol,
      maxPercent,
      minPercent,
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
      traitName: "",
      determinationName: "",
      materialStatus: "",
      mappingCol: "",
      maxPercent: "",
      minPercent: ""
    });
  };

  handleAddStay = () => {
    const _this = this;
    const {
      cropSelected,
      traitName,
      traitValue,
      determinationName,

      relationID,
      materialStatus,
      maxPercent,
      minPercent,

      mappingColumnContext
    } = this.state;

    let { mappingCol } = this.state;

    if (mappingColumnContext !== "none") {
      mappingCol = mappingColumnContext;
    }

    let action = "I";
    if (this.props.mode === "edit") {
      action = "U";
    }

    let obj = {
      relationID,
      traitValue: traitName.trim(),
      trait: traitValue,
      determinationValue: determinationName.trim(),
      materialStatus,
      mappingCol,
      maxPercent,
      minPercent,
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
      traitName: "",
      determinationName: "",
      materialStatus: "",
      mappingCol: "",
      maxPercent: "",
      minPercent: ""
    });
  };

  showFieldsTraitTypeNotTrueUI = () => {
    const { sourceSelected, cropSelected, traitType, traitName } = this.state;
    const showFields = cropSelected !== "" && sourceSelected !== "";
    if (showFields && !traitType === true) {
      return (
        <div>
          <label htmlFor="determination">Trait Value</label>
          <input
            name="traitName"
            type="text"
            value={traitName}
            onChange={this.handleChange}
          />
        </div>
      );
    }
    return null;
  };

  handMappingColumnContextChange = e => {
    const currentColumnContext = e.target.value;
    this.setState({ mappingColumnContext: e.target.value });

    if (currentColumnContext === "Resistantper") {
      this.setState({
        materialStatus: "",
        maxPercent: "",
        minPercent: "",
        traitName: "",
        determinationName: "",
        mappingCol: ""
      });
    }

    if (currentColumnContext === "SusceptibilityPer") {
      this.setState({
        mappingCol: ""
      });
    }
  };

  render() {
    const {
      sourceSelected,
      cropSelected,
      traitSuggestions,
      traitValue,
      traitType,
      determinationValue,

      traitName,
      determinationName,
      traitValuesList,

      materialStatus,
      mappingCol,
      maxPercent,
      minPercent,

      mappingColumnContext
    } = this.state;

    const showFields = cropSelected !== "" && sourceSelected !== "";
    const traitInput = {
      placeholder: "Select Trait",
      value: traitValue,
      onChange: this.onTraitChange
    };

    const buttonName = this.props.mode === "edit" ? "Edit " : "Add ";

    const materialStatusNotEmpty = materialStatus !== "";
    const mappingColumnNotEmpty = mappingCol !== "";

    const traitValueCheckTrue = showFields && !traitType === true;
    const traitValueCheck = showFields && traitType;

    const disableDeterminationValue =
      traitName !== "" && maxPercent !== "" && minPercent !== "";

    const isResistant = mappingColumnContext === "Resistantper";
    const isSusceptible = mappingColumnContext === "SusceptibilityPer";

    return (
      <Wrapper>
        <div className="modalContent">
          <div className="modalTitle">
            <i className="demo-icon icon-plus-squared info" />
            <span>RDT Trait Result</span>
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
                <label htmlFor="none">
                  <input
                    id="none"
                    type="radio"
                    value="none"
                    checked={mappingColumnContext === "none"}
                    onChange={this.handMappingColumnContextChange}
                  />
                  None
                </label>
                <label htmlFor="resistant">
                  <input
                    id="resistant"
                    type="radio"
                    value="Resistantper"
                    checked={mappingColumnContext === "Resistantper"}
                    onChange={this.handMappingColumnContextChange}
                  />
                  Resistant
                </label>
                <label htmlFor="susceptible">
                  <input
                    id="susceptible"
                    type="radio"
                    value="SusceptibilityPer"
                    checked={mappingColumnContext === "SusceptibilityPer"}
                    onChange={this.handMappingColumnContextChange}
                  />
                  Susceptible
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

            {traitValueCheckTrue && (
              <div>
                <label htmlFor="determination">Trait Value</label>{/*eslint-disable-line*/}
                <input
                  name="traitName"
                  type="text"
                  value={traitName}
                  onChange={this.handleChange}
                  disabled={isResistant || mappingColumnNotEmpty}
                />
              </div>
            )}

            {traitValueCheck && (
              <div>
                <label htmlFor="determination">Trait Value List</label>{/*eslint-disable-line*/}
                <select
                  name="traitName"
                  value={traitName}
                  onChange={this.handleChange}
                  disabled={isResistant || mappingColumnNotEmpty}
                >
                  <option value="">Select</option>
                  {traitValuesList.map(val => {
                    const { traitValueCode } = val;
                    return (
                      <option key={traitValueCode} value={traitValueCode}>
                        {traitValueCode}
                      </option>
                    );
                  })}
                </select>
              </div>
            )}

            {showFields && (
              <div>
                <label htmlFor="determination">Determination Value</label>{/*eslint-disable-line*/}
                <input
                  name="determinationName"
                  type="text"
                  value={determinationName}
                  onChange={this.handleChange}
                  disabled={
                    isResistant ||
                    mappingColumnNotEmpty ||
                    disableDeterminationValue
                  }
                />
              </div>
            )}

            {showFields && (
              <div>
                <label htmlFor="materialStatus">Material Status</label> {/*eslint-disable-line*/}
                <select
                  name="materialStatus"
                  value={materialStatus}
                  onChange={this.handleChange}
                  disabled={isResistant || mappingColumnNotEmpty}
                >
                  <option value="">Select</option>
                  {this.state.materialStatusList.map(({ code, name }) => (
                    <option key={code} value={code}>
                      {name}
                    </option>
                  ))}
                </select>
              </div>
            )}

            {showFields && (
              <div>
                <label htmlFor="mappingCol">Mapping Columns</label> {/*eslint-disable-line*/}
                <select
                  name="mappingCol"
                  value={mappingCol}
                  onChange={this.handleChange}
                  disabled={
                    isSusceptible || isResistant || materialStatusNotEmpty
                  }
                >
                  <option value="">Select</option>
                  {this.state.mappingColList.map(mp => (
                    <option key={mp} value={mp}>
                      {mp}
                    </option>
                  ))}
                </select>
              </div>
            )}
            {showFields && (
              <div>
                <label htmlFor="minPercent">Min Percent</label>{/*eslint-disable-line*/}
                <input
                  name="minPercent"
                  type="text"
                  value={minPercent}
                  onChange={this.handleChange}
                  disabled={isResistant || mappingColumnNotEmpty}
                />
              </div>
            )}
            {showFields && (
              <div>
                <label htmlFor="maxpercent">Max Percent</label>{/*eslint-disable-line*/}
                <input
                  name="maxPercent"
                  type="text"
                  value={maxPercent}
                  onChange={this.handleChange}
                  disabled={isResistant || mappingColumnNotEmpty}
                />
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
  relation: state.traitRelation.relation,
  traitValues: state.traitResult.traitValues,
  rdtMaterialStatus: state.rdtResult.rdtMaterialStatus,
  rdtMappingColumns: state.rdtResult.rdtMappingColumns
});
const mapDispatch = dispatch => ({
  fetchMaterialStatus: () => dispatch({ type: "GET_RDT_MATERIAL_STATUS" }),
  fetchMappingColumns: () => dispatch({ type: "GET_RDT_MAPPING_COLUMNS" }),
  fetchCrop: () => dispatch(fetchCrop()),
  fetchTrait: (traitName, cropCode, sourceSelected) =>
    dispatch(fetchTrait(traitName, cropCode, sourceSelected)),
  fetchTraitValues: cropTraitID => dispatch(getTraitValues(cropTraitID)),
  resetTraitValues: () => dispatch(traitValuesReset()),
  fetchDetermination: (determinationName, cropCode) =>
    dispatch(fetchDetermination(determinationName, cropCode))
});

Result.defaultProps = {
  rdtMaterialStatus: [],
  rdtMappingColumns: [],
  crop: [],
  trait: [],
  traitValues: [],
  editData: {},
  mode: ""
};
Result.propTypes = {
  rdtMaterialStatus: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  rdtMappingColumns: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  crop: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  trait: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  traitValues: PropTypes.array, // eslint-disable-line react/forbid-prop-types

  fetchMaterialStatus: PropTypes.func.isRequired,
  fetchMappingColumns: PropTypes.func.isRequired,
  close: PropTypes.func.isRequired,
  onAppend: PropTypes.func.isRequired,
  fetchCrop: PropTypes.func.isRequired,
  fetchDetermination: PropTypes.func.isRequired,
  fetchTrait: PropTypes.func.isRequired,
  fetchTraitValues: PropTypes.func.isRequired,
  resetTraitValues: PropTypes.func.isRequired,
  editData: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  mode: PropTypes.string
};

export default connect(
  mapState,
  mapDispatch
)(Result);
