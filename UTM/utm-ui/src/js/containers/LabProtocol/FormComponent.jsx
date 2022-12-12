import React from "react";
import PropTypes from "prop-types";
import { connect } from "react-redux";
import Wrapper from "../../components/Wrapper/wrapper";

class FormComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      cropsList: props.crops,
      materialList: props.materialType,
      testTypeList: props.testType,
      protocolList: props.protocol,

      crops: props.editData.cropCode || "",
      materialType: props.editData.materialTypeID || "",
      testType: props.editData.testTypeID || "",
      testProtocol: props.editData.testProtocolID || ""
    };
  }
  componentDidMount() {
    if (this.props.crops.length === 0) {
      this.props.fetchCrops();
    }
    if (this.props.materialType.length === 0) {
      this.props.fetchMaterialType();
    }
    if (this.props.testType.length === 0) {
      this.props.fetchTestType();
    }
    if (this.props.protocol.length === 0) {
      this.props.fetchProtocol();
    }
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.crops.length !== this.props.crops.length) {
      this.setState({
        cropsList: nextProps.crops
      });
    }
    if (nextProps.materialType.length !== this.props.materialType.length) {
      this.setState({
        materialList: nextProps.materialType
      });
    }
    if (nextProps.testType.length !== this.props.testType.length) {
      this.setState({
        testTypeList: nextProps.testType
      });
    }
    if (nextProps.protocol.length !== this.props.protocol.length) {
      this.setState({
        protocolList: nextProps.protocol
      });
    }
  }

  handleChange = e => {
    const { target } = e;
    const { name, value } = target;

    if (name === "testType") {
      this.setState({
        testProtocol: ""
      });
    }
    this.setState({
      [name]: value
    });
  };

  addProtocol = flag => {
    const {
      crops: cropCode,
      materialType: materialTypeID,
      testProtocol: testProtocolID
    } = this.state;
    const { editData, mode } = this.props;

    const obj = {
      oldCropCode: "",
      oldMaterialTypeID: 0,
      oldTestProtocolID: 0,
      cropCode,
      materialTypeID,
      testProtocolID
    };

    if (mode === "edit") {
      const {
        cropCode: oldCropCode,
        materialTypeID: oldMaterialTypeID,
        testProtocolID: oldTestProtocolID
      } = editData;
      if (
        cropCode == oldCropCode &&
        materialTypeID == oldMaterialTypeID &&
        testProtocolID == oldTestProtocolID
      ) {
        // eslint-disable-line
        this.props.close(false);
        return null;
      }
      this.props.postData({
        ...obj,
        oldCropCode,
        oldMaterialTypeID,
        oldTestProtocolID
      });
    } else {
      this.props.postData(obj);
    }

    if (flag) {
      this.setState({
        crops: "",
        materialType: "",
        testType: "",
        testProtocol: ""
      });
      return null;
    }
    this.props.close(false);
    return null;
  };

  formValidation = () => {
    const {
      crops: cropCode,
      materialType: materialTypeID,
      testProtocol: testProtocolID,
      testType
    } = this.state;
    const { editData, mode } = this.props;

    if (mode === "edit") {
      const {
        cropCode: oldCropCode,
        materialTypeID: oldMaterialTypeID,
        testProtocolID: oldTestProtocolID
      } = editData;
      if (
        cropCode == oldCropCode &&
        materialTypeID == oldMaterialTypeID &&
        testProtocolID == oldTestProtocolID
      ) {
        // eslint-disable-line
        return true;
      }
    }
    if (
      cropCode == "" ||
      materialTypeID == "" ||
      testType == "" ||
      testProtocolID == ""
    )
      return true; // eslint-disable-line
    return false;
  };

  render() {
    const { mode } = this.props;
    const {
      cropsList,
      materialList,
      testTypeList,
      protocolList,
      crops,
      materialType,
      testType,
      testProtocol
    } = this.state;
    const buttonName = mode === "edit" ? "Edit " : "Add ";
    const filteredProtocolList = protocolList.filter(
      x => x.testTypeID == testType
    ); // eslint-disable-line

    return (
      <Wrapper>
        <div className="modalContent">
          <div className="modalTitle">
            <i className="demo-icon icon-plus-squared info" />
            <span>Lab Protocol</span>
            <i
              role="presentation"
              className="demo-icon icon-cancel close"
              onClick={() => this.props.close(false)}
              title="Close"
            />
          </div>
          <div className="modalBody">
            <div>
              <label>Crops</label>
              <select name="crops" value={crops} onChange={this.handleChange}>
                <option value="">Select</option>
                {cropsList.map(x => (
                  <option key={x.cropCode} value={x.cropCode}>
                    {x.cropCode}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label>Material Type</label>
              <select
                name="materialType"
                value={materialType}
                onChange={this.handleChange}
              >
                <option value="">Select</option>
                {materialList.map(x => (
                  <option key={x.materialTypeID} value={x.materialTypeID}>
                    {x.materialTypeCode} - {x.materialTypeDescription}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label>Test Type</label>
              <select
                name="testType"
                value={testType}
                onChange={this.handleChange}
              >
                <option value="">Select</option>
                {testTypeList.map(x => (
                  <option key={x.testTypeID} value={x.testTypeID}>
                    {x.testTypeName}
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label>Test Protocol</label>
              <select
                name="testProtocol"
                value={testProtocol}
                onChange={this.handleChange}
                disabled={testType === ""}
              >
                <option value="">Select</option>
                {filteredProtocolList.map(x => (
                  <option key={x.testProtocolID} value={x.testProtocolID}>
                    {x.testProtocolName}
                  </option>
                ))}
              </select>
            </div>
          </div>
          <div className="modalFooter">
            {mode !== "edit" && (
              <button
                disabled={this.formValidation()}
                onClick={() => this.addProtocol(true)}
              >
                {buttonName}
              </button>
            )}
            &nbsp;&nbsp;
            <button
              disabled={this.formValidation()}
              onClick={() => this.addProtocol(false)}
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
  crops: state.traitRelation.crop,
  materialType: state.materialType,
  testType: state.assignMarker.testType.list,
  protocol: state.labProtocol.protocolList
});

const mapDispatch = dispatch => ({
  fetchCrops: () => dispatch({ type: "FETCH_CROP" }),
  fetchMaterialType: () => dispatch({ type: "FETCH_MATERIAL_TYPE" }),
  fetchProtocol: () => dispatch({ type: "GET_PROTOCOL" }),
  fetchTestType: () => dispatch({ type: "FETCH_TESTTYPE" }),
  postData: obj => dispatch({ type: "POST_PROTOCOL", obj })
});

FormComponent.defaultProps = {
  crops: [],
  materialType: [],
  testType: [],
  protocol: []
};
FormComponent.propTypes = {
  fetchCrops: PropTypes.func.isRequired,
  fetchMaterialType: PropTypes.func.isRequired,
  fetchTestType: PropTypes.func.isRequired,
  fetchProtocol: PropTypes.func.isRequired,
  close: PropTypes.func.isRequired,
  postData: PropTypes.func.isRequired,

  mode: PropTypes.string.isRequired,

  editData: PropTypes.object, // eslint-disable-line
  crops: PropTypes.array, // eslint-disable-line
  materialType: PropTypes.array, // eslint-disable-line
  testType: PropTypes.array, // eslint-disable-line
  protocol: PropTypes.array // eslint-disable-line
};

export default connect(
  mapState,
  mapDispatch
)(FormComponent);
