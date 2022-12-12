import React from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";

class ImportFile extends React.Component {
  onSubmit = e => {
    e.preventDefault();
  };
  onChange = e => {
    this.fileValidation(e.target.files[0]);
  };
  fileValidation = xlsxFile => {
    const { pageSize, testType, testTypeList } = this.props;
    const fileName = xlsxFile.name;

    //get selected menu
    let selectedMenu = window.localStorage.getItem("selectedMenuGroup");

    if (fileName) {
      let ext = fileName.slice(fileName.lastIndexOf(".") + 1);
      if (ext) {
        ext = ext.toLowerCase();
        if (ext !== "xlsx") {
          this.props.showError({
            type: "NOTIFICATION_SHOW",
            status: true,
            message: ["Please select ( *.XLSX ) file for import."],
            messageType: 2,
            notificationType: 0,
            code: ""
          });
          this.myFormRef.reset();
        } else {
          const result = testTypeList.find(
            req => req.testTypeCode === testType
          );
          const { testTypeID, determinationRequired } = result;
          const {
            materialTypeID,
            testProtocolID,
            materialStateID,
            containerTypeID,
            isolationStatus,
            startDate,
            expectedDate,
            source,
            cropSelected: cropCode,
            breedingStationSelected: brStationCode,
            excludeControlPosition,
            btrControl,
            researcherName
          } = this.props;
          const obj = {
            pageSize,
            pageNumber: 1,
            file: xlsxFile,
            testTypeID,
            determinationRequired,
            materialTypeID,
            testProtocolID,
            materialStateID,
            containerTypeID,
            isolated: isolationStatus,
            date: startDate.format(userContext.dateFormat), // eslint-disable-line
            expected: expectedDate.format(userContext.dateFormat), // eslint-disable-line
            slotID: null,
            source,
            cropCode,
            brStationCode,
            excludeControlPosition,
            btr: btrControl,
            researcherName,
            testTypeMenu: selectedMenu
          };
          this.props.fileUpload(obj);
          this.props.changeTabIndex(0);
        }
      }
    }
  };
  handleFileSelect = () => {
    const {
      materialTypeID,
      materialStateID,
      containerTypeID,
      testProtocolID,
      startDate,
      expectedDate,
      btrControl,
      researcherName,
      testType
    } = this.props;

    let isValid = true;
    const messageList = [];

    if(testType === "LDISK") {
      if (
        materialTypeID === 0 ||
        testProtocolID === 0
      ) {
        isValid = false;
        messageList.push(
          "Please select Material Type and Method."
        );
      }
    }
    else {
      if (
        materialTypeID === 0 ||
        materialStateID === 0 ||
        containerTypeID === 0
      ) {
        isValid = false;
        messageList.push(
          "Please select Material Type, Material State and Container Type."
        );
      }
    }

    if (btrControl && researcherName.trim() === "") {
      isValid = false;
      messageList.push("Please provide Researcher name when BTR is selected.");
    }
    if (!isValid) {
      this.props.showError({
        type: "NOTIFICATION_SHOW",
        status: true,
        message: messageList,
        messageType: 2,
        notificationType: 0,
        code: ""
      });
      return;
    }
    const diffDate = expectedDate.diff(startDate, "days");
    if (diffDate < 14 && testType !== 'LDISK') {
      if (
        /* eslint-disable */
        !confirm(
          "Normal test time is 14 days, please confirm with the lab before proceeding or update expected date. Continue ?"
        )
        /* eslint enable */
      ) {
        return null;
      }
    }
    this.uploadFileInput.click();
    return null;
  };
  render() {
    return (
      <div className="importFileWrap">
        <form
          onSubmit={this.onSubmit}
          ref={el => {
            this.myFormRef = el;
          }}
        >
          <input
            ref={el => {
              this.uploadFileInput = el;
            }}
            id="fileN"
            type="file"
            className="xlsFile"
            onChange={this.onChange}
          />
          <button
            type="button"
            title="Import"
            className="btnImportFile"
            onClick={this.handleFileSelect}
          >
            Select a new file to import
          </button>
        </form>
      </div>
    );
  }
}

ImportFile.defaultProps = {
  testTypeList: [],
  startDate: {},
  expectedDate: {},
  source: ""
};
ImportFile.propTypes = {
  excludeControlPosition: PropTypes.bool,
  cropSelected: PropTypes.string.isRequired,
  breedingStationSelected: PropTypes.string.isRequired,
  testType: PropTypes.string.isRequired,
  showError: PropTypes.func.isRequired,
  fileUpload: PropTypes.func.isRequired,
  changeTabIndex: PropTypes.func.isRequired,
  pageSize: PropTypes.number.isRequired,
  testTypeList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  materialTypeID: PropTypes.number.isRequired,
  materialStateID: PropTypes.number.isRequired,
  containerTypeID: PropTypes.number.isRequired,
  isolationStatus: PropTypes.bool.isRequired,
  startDate: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  expectedDate: PropTypes.object, // eslint-disable-line react/forbid-prop-types
  source: PropTypes.string,
  btrControl: PropTypes.bool.isRequired,
  researcherName: PropTypes.string.isRequired
};

const mapState = state => ({
  pageSize: state.assignMarker.total.pageSize,
  testTypeList: state.assignMarker.testType.list
});
const mapDispatch = dispatch => ({
  fileUpload: obj => {
    dispatch({ ...obj, type: "UPLOAD_ACTION" });
    dispatch({ type: "FILTER_CLEAR" });
    dispatch({ type: "FILTER_PLATE_CLEAR" });
  },
  showError: obj => dispatch(obj)
});
export default connect(
  mapState,
  mapDispatch
)(ImportFile);
