import React, { Component } from 'react';
import moment from 'moment';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';

import TwoGB from './components/TwoGB';
import ThreeGB from './components/ThreeGB';
import S2S from './components/S2S';
import DNA from './components/DNA';
import SeedHealth from './components/SeedHealth';

import './selected-file.scss';
import LeafDisk from './components/LeafDisk';

class SelectedFileAttributes extends Component {
  constructor(props) {
    super(props);
    const selectedMaterialType = props.materialTypeList.find(
      item => item.selected
    );
    const selectedTestProtocol = props.testProtocolList.find(
      item => item.selected
    );
    const selectedMaterialState = props.materialStateList.find(
      item => item.selected
    );
    const selectedContainerType = props.containerTypeList.find(
      item => item.selected
    );

    this.state = {
      cumulate: props.cumulate,
      testEditMode: false,
      todayDate: moment(),
      plannedDate: props.plannedDate,
      expectedDate: props.expectedDate,
      isolationStatus: props.isolationStatus,
      materialTypeID: selectedMaterialType
        ? selectedMaterialType.materialTypeID
        : 0,
      testProtocolID: selectedTestProtocol
        ? selectedTestProtocol.testProtocolID
        : 0,
      materialStateID: selectedMaterialState
        ? selectedMaterialState.materialStateID
        : 0,
      containerTypeID: selectedContainerType
        ? selectedContainerType.containerTypeID
        : 0,
      siteID: props.siteID,
      sites: [],
      testTypeID: props.testTypeID,
      slotID: props.slotID,
      dateChange: false,
      siteID: props.siteID,
      sites: props.sites,
      sampleType: props.sampleType
    };
  }
  componentWillReceiveProps(nextProps) {
    if (nextProps.cumulate !== this.props.cumulate) {
      this.setState({ cumulate: nextProps.cumulate });
    }
    if (nextProps.isolationStatus !== this.props.isolationStatus) {
      this.setState({ isolationStatus: nextProps.isolationStatus });
    }
    if (nextProps.slotID !== this.props.slotID) {
      this.setState({ slotID: nextProps.slotID });
    }
    if (nextProps.plannedDate !== this.props.plannedDate) {
      this.setState({ plannedDate: nextProps.plannedDate });
    }
    if (nextProps.expectedDate !== this.props.expectedDate) {
      this.setState({ expectedDate: nextProps.expectedDate });
    }
    if (nextProps.testTypeID !== this.props.testTypeID) {
      this.setState({ testTypeID: nextProps.testTypeID });
    }
    const selectedMaterialType = nextProps.materialTypeList.find(
      item => item.selected
    );
    const selectedTestProtocol = nextProps.testProtocolList.find(
      item => item.selected
    );
    const selectedMaterialState = nextProps.materialStateList.find(
      item => item.selected
    );
    const selectedContainerType = nextProps.containerTypeList.find(
      item => item.selected
    );
    this.setState({
      materialTypeID: selectedMaterialType
        ? selectedMaterialType.materialTypeID
        : 0,
      testProtocolID: selectedTestProtocol
        ? selectedTestProtocol.testProtocolID
        : 0,
      materialStateID: selectedMaterialState
        ? selectedMaterialState.materialStateID
        : 0,
      containerTypeID: selectedContainerType
        ? selectedContainerType.containerTypeID
        : 0
    });
    if (nextProps.updateAttributesFailed) {
      this.resetAttributesToOriginalState();
      this.props.resetUpdateAttributesFailure();
    }
    if (nextProps.testID !== this.props.testID) {
      this.setState({ testEditMode: false });
    }
    if (nextProps.siteID !== this.props.siteID) {
      this.setState({ siteID: nextProps.siteID });
    }
    if (nextProps.sites.length) {
      this.setState({ sites: nextProps.sites });
    }
    if (nextProps.sampleType !== this.props.sampleType) {
      this.setState({ sampleType: nextProps.sampleType });
    }
  }

  componentDidMount() {
    //get Sites : for leafdisk and seedhealth
    if(this.props.sites.length < 1 && (this.state.testTypeID === 8 || this.state.testTypeID === 9 || this.state.testTypeID === 10)) {
      this.props.fetchGetSites();
    }
  }

  resetAttributesToOriginalState() {
    this.setState({
      plannedDate: this.props.plannedDate,
      expectedDate: this.props.expectedDate,
      isolationStatus: this.props.isolationStatus,
      materialTypeID: this.props.materialTypeID,
      testProtocolID: this.props.testProtocolID,
      materialStateID: null,
      containerTypeID: null,
      testTypeID: this.props.testTypeID,
      slotID: this.props.slotID,
      siteID: this.props.siteID,
      sampleType: this.props.sampleType
    });
  }

  handleEditOrCancelButton = () => {
    if (this.state.testEditMode) {
      this.resetAttributesToOriginalState();
    } else {
      
      var materialType = this.props.materialTypeList.find( item => item.selected );
      var testProtocol = this.props.testProtocolList.find( item => item.selected );
      var materialState = this.props.materialStateList.find( item => item.selected );
      var containerType = this.props.containerTypeList.find( item => item.selected );
      //var site = this.props.sites.find( item => item.selected );

      this.setState({
        materialTypeID: materialType ? materialType.materialTypeID : null,
        testProtocolID: testProtocol ? testProtocol.testProtocolID : null,
        materialStateID: materialState ? materialState.materialStateID : null,
        containerTypeID: containerType ? containerType.containerTypeID : null
      });

    }
    this.setState({
      testEditMode: !this.state.testEditMode
    });
  };

  resetSelectedTestAttributes = () => {
    var materialType = this.props.materialTypeList.find( item => item.selected );
    var testProtocol = this.props.testProtocolList.find( item => item.selected );
    var materialState = this.props.materialStateList.find( item => item.selected );
    var containerType = this.props.containerTypeList.find( item => item.selected );

    this.setState({
      plannedDate: this.props.plannedDate,
      expectedDate: this.props.expectedDate,
      isolationStatus: this.props.isolationStatus,
      materialTypeID: materialType ? materialType.materialTypeID : null,
      testProtocolID: testProtocol ? testProtocol.testProtocolID : null,
      materialStateID: materialState ? materialState.materialStateID : null,
      containerTypeID: containerType ? containerType.containerTypeID : null,
      testTypeID: this.props.testTypeID,
      cumulate: this.props.cumulate,
      siteID: this.props.siteID,
      sampleType: this.props.sampleType
    });
  };

  updateSelectedTestAttributes = () => {
    if(this.state.testTypeID === 9 ) // LeafDisk
    {
      if (
        this.state.materialTypeID === 0 ||
        this.state.testProtocolID === 0 ||
        this.state.materialTypeID === null ||
        this.state.testProtocolID === null ||
        this.state.siteID === 0 ||
        this.state.siteID === null 
      ) {
        this.props.showError({
          type: 'NOTIFICATION_SHOW',
          status: true,
          message: [
            'Please select Material Type and Method.'
          ],
          messageType: 2,
          notificationType: 0,
          code: ''
        });
      } else {
        const currentTestType = this.props.testTypeList.find(
          testType => testType.testTypeID === this.state.testTypeID
        );
        const attributes = {
          testID: this.props.testID,
          plannedDate: this.state.plannedDate,
          materialTypeID: this.state.materialTypeID,
          testProtocolID: this.state.testProtocolID,
          siteID: this.state.siteID,
          testTypeID: this.state.testTypeID,
          cropCode: this.props.cropCode,
          breeding: this.props.breeding,
          determinationRequired: currentTestType.determinationRequired,
          slotID: this.state.slotID
        };
        this.props.updateTestAttributes(attributes);
        this.setState({
          testEditMode: false,
          dateChange: false
        });
      }
    } else if(this.state.testTypeID === 10 ) // SeedHealth
    {
      if (
        this.state.sampleType === '' ||
        this.state.sampleType === null ||
        this.state.siteID === 0 ||
        this.state.siteID === null 
      ) {
        this.props.showError({
          type: 'NOTIFICATION_SHOW',
          status: true,
          message: [
            'Please select Sample Type and Site Location.'
          ],
          messageType: 2,
          notificationType: 0,
          code: ''
        });
      } else {
        const currentTestType = this.props.testTypeList.find(
          testType => testType.testTypeID === this.state.testTypeID
        );
        const attributes = {
          testID: this.props.testID,
          siteID: this.state.siteID,
          testTypeID: this.state.testTypeID,
          sampleType: this.state.sampleType,
          cropCode: this.props.cropCode,
          breeding: this.props.breeding,
          determinationRequired: currentTestType.determinationRequired
        };
        this.props.updateTestAttributes(attributes);
        this.setState({
          testEditMode: false
        });
      }
    }
    else
    {
      if (
        this.state.materialTypeID === 0 ||
        this.state.materialStateID === 0 ||
        this.state.containerTypeID === 0 ||
        this.state.materialTypeID === null ||
        this.state.materialStateID === null ||
        this.state.containerTypeID === null
      ) {
        this.props.showError({
          type: 'NOTIFICATION_SHOW',
          status: true,
          message: [
            'Please select Material Type, Material State and Container Type.'
          ],
          messageType: 2,
          notificationType: 0,
          code: ''
        });
      } else {
        const currentTestType = this.props.testTypeList.find(
          testType => testType.testTypeID === this.state.testTypeID
        );
        const attributes = {
          testID: this.props.testID,
          plannedDate: this.state.plannedDate,
          expectedDate: this.state.expectedDate,
          materialTypeID: this.state.materialTypeID,
          containerTypeID: this.state.containerTypeID * 1,
          isolated: this.state.isolationStatus,
          testTypeID: this.state.testTypeID,
          materialStateID: this.state.materialStateID * 1,
          cropCode: this.props.cropCode,
          breeding: this.props.breeding,
          determinationRequired: currentTestType.determinationRequired,
          slotID: this.state.slotID,
          cumulate: this.state.cumulate
        };
        const planDate = moment(this.state.plannedDate, userContext.dateFormat); /* eslint-disable-line */
        const expDate = moment(this.state.expectedDate, userContext.dateFormat); /* eslint-disable-line */
        const diffDate = expDate.diff(planDate, 'days');
        if (this.state.dateChange && diffDate < 14) {
          if (
            /* eslint-disable */
            !confirm(
              'Normal test time is 14 days, please confirm with the lab before proceeding or update expected date. Continue ?'
            )
            /* eslint-enable */
          ) {
            return null;
          }
        }
        this.props.updateTestAttributes(attributes);
        this.setState({
          testEditMode: false,
          dateChange: false
        });
      }
    }
    return null;
  };

  handleDateChange = date => {
    const expDate = moment(date, userContext.dateFormat).add(14, 'days'); // eslint-disable-line
    this.setState({
      dateChange: true,
      plannedDate: date.format(userContext.dateFormat),  // eslint-disable-line
      expectedDate: expDate.format(userContext.dateFormat)  // eslint-disable-line
    });
  };

  handleExpectedDateChange = date => {
    this.setState({
      dateChange: true,
      expectedDate: date.format(userContext.dateFormat) /* eslint-disable-line */
    }); // eslint-disable-line
  };

  handleIsolationChange = () => {
    this.setState({ isolationStatus: !this.state.isolationStatus });
  };
  handleCumulate = () => {
    this.setState({ cumulate: !this.state.cumulate });
  };

  handleContainerTypeChange = e => {
    this.setState({ containerTypeID: e.target.value * 1 });
  };

  handleMaterialStateChange = e => {
    this.setState({ materialStateID: e.target.value * 1 });
    // this.fetchSlot(this.props.testID, e.target.value, this.state.materialTypeID);
  };

  handleMaterialTypeChange = e => {
    this.setState({ materialTypeID: e.target.value * 1 });
    // this.fetchSlot(this.props.testID, this.state.materialStateID, e.target.value, this.state.isolationStatus, this.state.date);
  };

  handleLabLocationChange = e => {
    this.setState({ siteID: e.target.value * 1 });
  };

  handleSampleTypeChange = e => {
    this.setState({ sampleType: e.target.value });
  };

  handleTestProtocolChange = e => {
    this.setState({ testProtocolID: e.target.value * 1 });
  };

  handleTestTypeChange = () => {
    // const {
    //   target: { name, value }
    // } = e;
    // this.setState({ testTypeID: e.target.value * 1 });
  };

  render() {
    const {
      visibility,
      materialTypeList,
      testProtocolList,
      materialStateList,
      containerTypeList,
      testTypeList,
      testTypeID,
      cropCode
    } = this.props;

    const threeGBstatus = testTypeID === 4 || testTypeID === 5;
    const s2sType = testTypeID === 6;
    const cntType = testTypeID === 7;
    const isDNA = testTypeID === 2;
    const isLeafDisk = testTypeID === 9;
    const isSeedHealth = testTypeID === 10;
    const twoGBStatus = testTypeID === 1 || testTypeID === 8;
    const lastCondition =
      this.props.statusCode < 400 &&
      testTypeID !== 6 &&
      testTypeID !== 7 &&
      (this.state.slotID === null ||
        this.state.slotID === 0 ||
        !this.state.slotID);

    return (
      <div
        className="imported-files-attributes"
        style={{
          display: `${visibility ? 'block' : 'none'}`
        }}
      >
        {twoGBStatus && (
          <TwoGB
            testEditMode={this.state.testEditMode}
            testTypeID={testTypeID}
            testTypeList={testTypeList}
            handleTestTypeChange={this.handleTestTypeChange}
            materialTypeList={materialTypeList}
            materialTypeID={this.state.materialTypeID}
            handleMaterialTypeChange={this.handleMaterialTypeChange}
            materialStateList={materialStateList}
            materialStateID={this.state.materialStateID}
            handleMaterialStateChange={this.handleMaterialStateChange}
            containerTypeList={containerTypeList}
            containerTypeID={this.state.containerTypeID}
            handleContainerTypeChange={this.handleContainerTypeChange}
            todayDate={this.state.todayDate}
            plannedDate={this.state.plannedDate}
            handleDateChange={this.handleDateChange}
            expectedDate={this.state.expectedDate}
            handleExpectedDateChange={this.handleExpectedDateChange}
            isolationStatus={this.state.isolationStatus}
            handleIsolationChange={this.handleIsolationChange}
            cumulate={this.state.cumulate}
            handleCumulate={this.handleCumulate}
            excludeControlPosition={this.props.excludeControlPosition}
          />
        )}
        {testTypeID === 4 && (
          <ThreeGB
            testEditMode={this.state.testEditMode}
            testTypeID={testTypeID}
            testTypeList={testTypeList}
            handleTestTypeChange={this.handleTestTypeChange}
            testID={this.props.testID}
            fileList={this.props.fileList}
            containerTypeList={containerTypeList}
            containerTypeID={this.state.containerTypeID}
            handleContainerTypeChange={this.handleContainerTypeChange}
          />
        )}

        {(s2sType || cntType) && (
          <S2S
            testEditMode={this.state.testEditMode}
            testTypeID={testTypeID}
            testTypeList={testTypeList}
            handleTestTypeChange={this.handleTestTypeChange}
            cropCode={cropCode}
          />
        )}

        {isDNA && (
          <DNA
            testEditMode={this.state.testEditMode}
            testTypeID={testTypeID}
            testTypeList={testTypeList}
            handleTestTypeChange={this.handleTestTypeChange}
            materialTypeList={materialTypeList}
            materialTypeID={this.state.materialTypeID}
            handleMaterialTypeChange={this.handleMaterialTypeChange}
            materialStateList={materialStateList}
            materialStateID={this.state.materialStateID}
            handleMaterialStateChange={this.handleMaterialStateChange}
            containerTypeList={containerTypeList}
            containerTypeID={this.state.containerTypeID}
            handleContainerTypeChange={this.handleContainerTypeChange}
            todayDate={this.state.todayDate}
            plannedDate={this.state.plannedDate}
            handleDateChange={this.handleDateChange}
            expectedDate={this.state.expectedDate}
            handleExpectedDateChange={this.handleExpectedDateChange}
            isolationStatus={this.state.isolationStatus}
            handleIsolationChange={this.handleIsolationChange}
            cumulate={this.state.cumulate}
            handleCumulate={this.handleCumulate}
            excludeControlPosition={this.props.excludeControlPosition}
          />
        )}

        
        {isLeafDisk && (
          <LeafDisk
            testEditMode={this.state.testEditMode}
            testTypeID={testTypeID}
            testTypeList={testTypeList}
            handleTestTypeChange={this.handleTestTypeChange}
            materialTypeList={materialTypeList}
            materialTypeID={this.state.materialTypeID}
            handleMaterialTypeChange={this.handleMaterialTypeChange}
            testProtocolList={testProtocolList}
            testProtocolID={this.state.testProtocolID}
            handleTestProtocolChange={this.handleTestProtocolChange}
            siteID={this.state.siteID}
            sites={this.state.sites}
            handleLabLocationChange={this.handleLabLocationChange}
            todayDate={this.state.todayDate}
            plannedDate={this.state.plannedDate}
            handleDateChange={this.handleDateChange}
          />
        )}

        {isSeedHealth && (
          <SeedHealth
            testEditMode={this.state.testEditMode}
            testTypeID={testTypeID}
            testTypeList={testTypeList}
            handleTestTypeChange={this.handleTestTypeChange}
            siteID={this.state.siteID}
            sites={this.state.sites}
            handleLabLocationChange={this.handleLabLocationChange}
            sampleType={this.state.sampleType}
            handleSampleTypeChange={this.handleSampleTypeChange}
          />
        )}

        {lastCondition && (
          <div className="imported-files-actions">
            {!threeGBstatus && (
              <button
                onClick={this.handleEditOrCancelButton}
                className="imported-files-actions-button"
                title={this.state.testEditMode ? 'Cancel' : 'Edit'}
              >
                {this.state.testEditMode ? (
                  <i className="icon icon-cancel" />
                ) : (
                  <i className="icon icon-pencil" />
                )}
                {this.state.testEditMode ? 'Cancel' : 'Edit'}
              </button>
            )}
            {this.state.testEditMode && (
              <button
                onClick={this.resetSelectedTestAttributes}
                disabled={!this.state.testEditMode}
                className="imported-files-actions-button"
                title="Reset form"
              >
                <i className="icon icon-ccw" />
                Reset
              </button>
            )}
            {this.state.testEditMode && (
              <button
                onClick={this.updateSelectedTestAttributes}
                disabled={!this.state.testEditMode}
                className="imported-files-actions-button"
                title="Save"
              >
                <i className="icon icon-floppy" />
                Save
              </button>
            )}
          </div>
        )}
      </div>
    );
  }
}
const mapStateToProps = state => ({
  updateAttributesFailed:
    state.assignMarker.file.selected.updateAttributesFailed,
  excludeControlPosition:
    state.assignMarker.file.selected.excludeControlPosition,
  sites: state.assignMarker.getSites
});

const mapDispatchToProps = dispatch => ({
  fetchGetSites: () => dispatch({ type: "FETCH_GETSITES" }),
  resetUpdateAttributesFailure: () => dispatch({ type: 'RESET_UPDATE_ATTRIBUTES_FAILURE' })
});

SelectedFileAttributes.defaultProps = {
  fileList: [],
  materialTypeList: [],
  testProtocolList: [],
  materialStateList: [],
  containerTypeList: [],
  testTypeList: [],
  sites: [],
  // slotList: [],
  updateAttributesFailed: null,
  testTypeID: null,
  isolationStatus: false,
  cropCode: null,
  slotID: null,
  siteID: null,
  breeding: '',
  expectedDate: '',
  siteID: null,
  sampleType: ''
};
SelectedFileAttributes.propTypes = {
  excludeControlPosition: PropTypes.any, // eslint-disable-line
  cumulate: PropTypes.bool.isRequired,
  breeding: PropTypes.string,
  fileList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  materialTypeList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  testProtocolList: PropTypes.array,
  materialStateList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  containerTypeList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  testTypeList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  // slotList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  plannedDate: PropTypes.string,
  expectedDate: PropTypes.string,
  cropCode: PropTypes.string,
  isolationStatus: PropTypes.bool,
  visibility: PropTypes.bool.isRequired,
  updateAttributesFailed: PropTypes.bool,
  testTypeID: PropTypes.number,
  statusCode: PropTypes.number.isRequired,
  testID: PropTypes.number.isRequired,

  slotID: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  showError: PropTypes.func.isRequired,
  updateTestAttributes: PropTypes.func.isRequired,

  siteID: PropTypes.number,
  sites: PropTypes.array,
  sampleType: PropTypes.string,
  fetchGetSites: PropTypes.func,
  resetUpdateAttributesFailure: PropTypes.func
};
export default connect(
  mapStateToProps,
  mapDispatchToProps
)(SelectedFileAttributes);
