import React, { Fragment } from "react";
import { connect } from "react-redux";
import { withRouter } from "react-router-dom";
import { Input, Button } from "antd";
import { SaveOutlined, RollbackOutlined } from "@ant-design/icons";

import { getDim } from "../../helpers/helper";
import ActionBar from "../../components/ActionBar/ActionBar";
import TabelGrid from "../../components/TableGrid/TableGrid";
import { withAITracking } from '@microsoft/applicationinsights-react-js';
import { reactPlugin, appInsights } from '../../config/app-insights-service';

import {
  labResutDeterminationAss,
  labPlatePositionFetchAction,
  labResutDeterminationAssDetail,
  labResultDetailApprove,
  labResultDetailReTest,
  saveRemarks,
  patternRemarkChange,
  savePatternRemarks,
  resetApproveRetest
} from "./labResultAction";

import "./labResult.scss";

const { TextArea } = Input;
class LabResultDetailComponent extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      date: "",
      username: "",

      data: props.data,
      columns: props.columns,
      tblWidth: 900,
      tblHeight: 600,

      more: true,
      activeID: "",
      remarks: (this.props.detInfo && this.props.detInfo.Remarks) || "",
      changed: [],

      sortBy: "",
      sortOrder: "",
      activeSorting: false,
      collapsedRows: new Set()
    };
  }

  componentDidMount() {
    appInsights.trackPageView({ name: 'LabResultDetail' });
    window.addEventListener("beforeunload", this.handleWindowClose);
    window.addEventListener("resize", this.updateDimensions);
    if (this.props.match.params.id) {
      this.setState({
        activeID: this.props.match.params.id,
      });
      this.props.fetch(this.props.match.params.id);
      this.props.fetch2(this.props.match.params.id, "", "");
    }
    this.updateDimensions();
    this.props.resetApproveRetestFlag();
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.data) {
      this.setState({ data: nextProps.data });
    }
    if (nextProps.columns.length) {
      this.setState({ columns: nextProps.columns });
    }
    if(nextProps.saveSuccess === true) {
      this.setState({ changed: [] });
      this.props.resetSaveSuccess();
    }
    if(nextProps.approveRetestSuccess === true) {
      //wait 1sec and go back
      setTimeout(() => {
        this.props.history.goBack();
      }, 1100);

      this.props.resetApproveRetestFlag();
    }

    this.updateDimensions();
  }

  componentDidUpdate(prevProps) {
    if (
      Object.keys(prevProps.detInfo).length !==
      Object.keys(this.props.detInfo).length
    ) {
      this.setState({ remarks: this.props.detInfo.Remarks });
    }
  }

  componentWillUnmount() {
    this.props.empty2();
    window.removeEventListener("beforeunload", this.handleWindowClose);
    window.removeEventListener("resize", this.updateDimensions);
    if (!this.props.history.location.pathname.includes('lab_result')) {
      this.props.empty();
    }
  }

  updateDimensions = () => {
    const { width: tblWidth, height: tblHeight } = getDim();
    this.setState({ tblWidth: tblWidth });
  };
  handleWindowClose = (e) => {
    if (this.props.isChange) {
      e.returnValue = "blocked";
    }
  };

  leftSection = () => {
    const { year, selected, period, periodSelected } = this.state;
    const {
      validationInfo: { Date, UserName },
    } = this.props;
    return (
      <Fragment>
        <button
          onClick={() => {
            this.props.history.goBack();
          }}
        >
          <i className='demo-icon icon-left-open' />
          Back
        </button>
        <div className='form- e' style={{ paddingLeft: "15px" }}>
          <label>Date: {this.props.validationInfo.Date}</label>
        </div>
        <div className='form- e' style={{ paddingLeft: "15px" }}>
          <label>Username: {this.props.validationInfo.UserName}</label>
          {/* <label>Username</label> {this.state.username} <br /> */}
        </div>
      </Fragment>
    );
  };
  rightSection = () => {
    const {
      detInfo: { StatusCode },
      user,
    } = this.props;
    const isApproveRole = user.includes("pac_approvecalcresults");
    const isRetestRole = user.includes("pac_approvecalcresults") || user.includes("pac_labemployee");
    const isCodeNot600 = StatusCode !== 600;
    const isApproveAccess = isCodeNot600 || !isApproveRole;
    const isRetestAccess = isCodeNot600 || !isRetestRole;

    return (
      <Fragment>
        <div className='right'>
          <button
            className='with-i'
            disabled={isApproveAccess}
            onClick={this.approveFunc}
          >
            <i className='demo-icon icon-ok-circled' />
            Approve
          </button>
          <button
            className=''
            disabled={isRetestAccess}
            onClick={this.reTestFunc}
          >
            Retest
          </button>
        </div>
      </Fragment>
    );
  };
  moreFunc = () => {
    const { more, sortBy, sortOrder } = this.state;
    if (this.props.match.params.id && this.props.data3.length === 0) {
      this.props.fetch2(this.props.match.params.id, sortBy, sortOrder);
    }
    this.updateDimensions();
    this.setState({ more: !more });
  };

  approveFunc = () => {
    if(this.state.data[0]) {
      const varName = this.state.data[0].VarietyName;

      if (confirm('Are you sure you want approve ' + varName + '??')) {
        const {
          detInfo: { StatusCode },
        } = this.props;
        const isCodeNot600 = StatusCode !== 600;
        if (!isCodeNot600) {
          this.props.approve(this.state.activeID);
        }
      }
    }
  };
  reTestFunc = () => {
    if(this.state.data[0]) {
      const varName = this.state.data[0].VarietyName;

      if (confirm('Are you sure you want re-test ' + varName + '??')) {
        const {
          detInfo: { StatusCode },
        } = this.props;
        const isCodeNot600 = StatusCode !== 600;
        if (!isCodeNot600) {
          this.props.retest(this.state.activeID);
        }
      }
    }
  };

  saveRemarks = () => {
    const payload = {
      DetAssignmentID: this.props.detInfo.DetAssignmentID,
      Remarks: this.state.remarks,
    };
    this.props.saveRemarks(payload);
  };

  resetRemarks = () => {
    this.setState({ remarks: this.props.detInfo.Remarks });
  };
  three = (
    compWidth,
    QualityClass,
    QualityThreshold,
    ReasonForRejection,
    OffTypes,
    Inbred,
    PossibleInbred,
    TestResultQuality,
    FolderName,
    Plates,
    LastExport,
    SampleNr,
    BatchNr,
    StatusName,
    DetAssignmentID,
    Reciprocal,
    Remarks,
    Rejected,
    TotalSamples,
    ValidSamples,
    RejectedPercentage,
    OfftypesPercentage,
    InbredPercentage,
    PossibleInbredPercentage
  ) => (
    <div>
      <div className='textCol'>
        <div style={{ width: `${compWidth}px` }}>
          <h4>Result Info</h4>
          <div>
            <dl className='table-display'>
              <dt>Quality class</dt>
              <dd className='min-width'>{QualityClass}</dd>

              <dt>Offtypes (deviation)</dt>
              <dd className='min-width'>{OffTypes}/{ValidSamples}</dd>
              <dl>{OfftypesPercentage}%</dl>

              <dt>Inbred</dt>
              <dd className='min-width'>{Inbred}/{ValidSamples}</dd>
              <dl>{InbredPercentage}%</dl>

              <dt>Possible inbred</dt>
              <dd className='min-width'>{PossibleInbred}/{ValidSamples}</dd>
              <dl>{PossibleInbredPercentage}%</dl>

              <dt>Rejected</dt>
              <dd className='min-width'>{Rejected}/{TotalSamples}</dd>
              <dl>{RejectedPercentage}%</dl>

              <dt>Test result quality</dt>
              <dd className='min-width'><p> </p></dd>
              <dl style={QualityClass === 4 && (TestResultQuality < QualityThreshold) ? {color: 'Red'} : {}}>{TestResultQuality}%</dl>

              {QualityClass === 4 && ReasonForRejection !== '' && (<dl style={{color: 'Red', fontStyle: 'italic', fontSize: '14px'}}>({ReasonForRejection})</dl>)}
            </dl>
          </div>
        </div>
        <div style={{ width: `${compWidth}px` }}>
          <h4>Test Info</h4>
          <div>
            <dl className='table-display'>
              <dt>Folder</dt>
              <dd>{FolderName}</dd>
              <dt>Plate(s)</dt>
              <dd>{Plates}</dd>

              <dt>Last calculation</dt>
              <dd>{LastExport}</dd>
            </dl>
          </div>
        </div>

        <div style={{ width: `${compWidth}px` }}>
          <h4>Det. Assignment Info</h4>
          <div>
            <dl className='table-display'>
              <dt>Sample nr</dt>
              <dd>{SampleNr}</dd>

              <dt>Batch nr</dt>
              <dd>{BatchNr}</dd>

              <dt>Det. Ass</dt>
              <dd>{DetAssignmentID}</dd>

              <dt>Reciprocal</dt>
              <dd>{Reciprocal}</dd>

              <dt>Status</dt>
              <dd>{StatusName}</dd>

              <dt>Remarks</dt>
              <dt className='whole'>
                <TextArea
                  value={this.state.remarks}
                  className={
                    this.props.detInfo &&
                    this.props.detInfo.Remarks !== this.state.remarks
                      ? "editing"
                      : ""
                  }
                  onChange={this.handleRemarkChange}
                  disabled={
                    this.props.detInfo.StatusCode &&
                    this.props.detInfo.StatusCode >= 700
                  }
                />
                <div>
                  {this.props.detInfo &&
                    this.props.detInfo.Remarks !== this.state.remarks && (
                      <Button
                        icon={<RollbackOutlined />}
                        onClick={this.resetRemarks}
                        className='reset'
                      >
                        reset
                      </Button>
                    )}
                  {this.props.detInfo.StatusCode &&
                    this.props.detInfo.StatusCode < 700 && (
                      <Button
                        type='primary'
                        icon={<SaveOutlined />}
                        onClick={this.saveRemarks}
                        className='save'
                      >
                        Save
                      </Button>
                    )}
                </div>
              </dt>
            </dl>
          </div>
        </div>
      </div>
    </div>
  );
  handleRemarkChange = (e) => {
    this.setState({ remarks: e.target.value });
  };
  saveRemark = (e) => {
    this.props.saveRemark(this.state.remarks);
  };

  addToChange = (p, k, v, i) => {
    const { changed } = this.state;
    const obj = [];

    if (changed.length <= 0) {
      obj.push({
        patternID: p,
        remarks: v,
      });
      this.setState({ isChange: true, changed: obj });
    } else {
      const check = changed.filter(
        (d) => d.patternID === p
      );
      if (check.length) {
        const newObj = changed.map((d) => {
          if (d.patternID === p) {
            return { patternID: p, remarks: v };
          }
          return d;
        });
        this.setState({ isChange: true, changed: newObj });
      } else {
        obj.push.apply(changed, [
          {
            patternID: p,
            remarks: v,
          },
        ]);
      }
    }
  };

  changeValue = (i, k, v, p) => {
    console.log(p, p.PatternID,k,v,i);
    this.props.patternRemarkChange(i, k, v);
    this.addToChange(p.PatternID, k, v, i);
  };

  savePatternRemarks = () => {
    const {changed} = this.state;
    this.props.savePatternRemarks(changed);
  }

  _handleExpandClick = (patternID) => {
    this.props.fetchLabPlatePositions(patternID);
  }

  sortFunction = (key) => {
    const { sortOrder } = this.state;
    let sortB = key;
    let sortD = "";
    let active = false;

    if (key != '') {
      if(sortOrder == '') {
        sortD = 'asc';
        active = true;
      }
      else if (sortOrder == 'asc') {
        sortD = 'desc';
        active = true;
      }
      //reset sort
      else {
        sortB = '';
        sortD = '';
        active = false;
      }

      this.setState({ sortBy: sortB, sortOrder: sortD, activeSorting: active, collapsedRows: new Set()})

      //reload data
      this.props.fetch2(this.props.match.params.id, sortB, sortD);
    }
  };

  render() {
    const customWidth = {
      DetAssignmentID: 90,
      SampleNr: 80,
      BatchNr: 80,
      Article: 350,
      Status: 100,

      "Exp Ready": 100,
      Folder: 120,
      "Folder#": 180,
      "Quality Class": 100,
      VarietyName: 340,
      VarietyType: 100,
      "Matching Varieties": 250,

      "": 30,
      "Pat#": 60,
      Sample: 70,
      "Sam%": 60,
      "Type": 130,
      "Remarks": 400
    };
    const { tblWidth, tblHeight, columns, data, more, changed } = this.state;

    const compWidth = tblWidth / 3;
    const disableSavePatternRemarks = changed.length <= 0;

    columns.map((c) => {
      if (customWidth[c.ColumnID] === undefined) {
        Object.assign(customWidth, { [c.ColumnID]: 100 });
      }
    });

    const { columns3, data3 } = this.props;

    //dynamic height of detail grid
    let rows = data3.length < 1 ? 1 : data3.length;
    let detailHeight = 200;
    detailHeight += rows * 40;

    //Detail grid
    const newCol = [];

    newCol.push({
      ColumnID: '',
      Editable: false, // ? true : false,
      IsVisible: true,
      order: 0,
      fixed: "left"
    });

    columns3.map((c) => {

      if (customWidth[c.ColumnID] === undefined) {
        Object.assign(customWidth, { [c.ColumnID]: 100 });
      }

      //Fix Remarks column to right
      if (c.ColumnID === "Remarks") {
        newCol.push({
          ColumnID: c.ColumnID,
          Editable: c.Editable, // ? true : false,
          IsVisible: c.IsVisible,
          Label: c.Label, // keyValue[c] ||
          order: c.order,
          sort: c.sort,
          fixed: "right"
        });

        return null;
      }
      newCol.push(c);
      return null;
    });

    const {
      validationInfo: { Date, UserName },
      resultInfo: {
        Inbred,
        OffTypes,
        PossibleInbred,
        QualityClass,
        QualityThreshold,
        ReasonForRejection,
        TestResultQuality,
        Rejected,
        TotalSamples,
        ValidSamples = (TotalSamples != undefined) ? TotalSamples - Rejected : '',
        RejectedPercentage = (Rejected != undefined) ? ( Rejected == 0 ? 0 : (Rejected * 100 / TotalSamples).toFixed(1)) : '',
        OfftypesPercentage = (OffTypes != undefined) ? ( OffTypes == 0 ? 0 : (OffTypes * 100 / (TotalSamples - Rejected)).toFixed(1)) : '',
        InbredPercentage = (Inbred != undefined) ? ( Inbred == 0 ? 0 : (Inbred * 100 / (TotalSamples - Rejected)).toFixed(1)) : '',
        PossibleInbredPercentage = (PossibleInbred != undefined) ? ( PossibleInbred == 0 ? 0 : (PossibleInbred * 100 / (TotalSamples - Rejected)).toFixed(1)): '',
      },
      testInfo: { FolderName, Plates, LastExport },
      detInfo: { SampleNr, BatchNr, DetAssignmentID, Reciprocal, Remarks, StatusName },
    } = this.props;

    return (
      <div>
        <ActionBar left={this.leftSection} right={this.rightSection} />
        <div className='container'>
          <br />
          {this.three(
            compWidth,
            QualityClass,
            QualityThreshold,
            ReasonForRejection,
            OffTypes,
            Inbred,
            PossibleInbred,
            TestResultQuality,
            FolderName,
            Plates,
            LastExport,
            SampleNr,
            BatchNr,
            StatusName,
            DetAssignmentID,
            Reciprocal,
            Remarks,
            Rejected,
            TotalSamples,
            ValidSamples,
            RejectedPercentage,
            OfftypesPercentage,
            InbredPercentage,
            PossibleInbredPercentage
          )}
          <br />
          <TabelGrid
            customWidth={customWidth}
            tblWidth={more ? tblWidth - 17 : tblWidth}
            tblHeight={300}
            isChange={false}
            changeValue={() => {}}
            sideMenu={this.props.sideMenu}
            data={data}
            columns={columns}
            action={{
              name: "labResult",
            }}
          />

          {more && (
            <Fragment>
              <br />

              <Button
                type='primary'
                icon={<SaveOutlined />}
                onClick={this.savePatternRemarks}
                className='savepatternremarks'
                disabled={disableSavePatternRemarks}
              >
                Save
              </Button>

              <TabelGrid
                customWidth={customWidth}
                tblWidth={more ? tblWidth - 17 : tblWidth}
                tblHeight={detailHeight}
                isChange={false}
                changeValue={this.changeValue}
                sideMenu={this.props.sideMenu}
                data={data3}
                columns={newCol}
                platePosition={this.props.platePosition}
                _handleExpandClick={this._handleExpandClick}
                sortFunc={this.sortFunction}
                activeSorting={this.state.activeSorting}
                collapsedRows={this.state.collapsedRows}
                action={{
                  name: "labResult",
                }}
              />
              <br />
              <br />
            </Fragment>
          )}
        </div>
      </div>
    );
  }
}
const mapState = (state) => ({
  sideMenu: state.sidemenuReducer,

  user: state.user.role,

  validationInfo: state.labResults.validationInfo,
  testInfo: state.labResults.testInfo,
  resultInfo: state.labResults.resultInfo,
  detInfo: state.labResults.detAssignmentInfo,

  data: state.labResults.data2,
  columns: state.labResults.column2,

  data3: state.labResults.data3,
  columns3: state.labResults.column3,

  saveSuccess: state.labResults.saveSuccess,
  platePosition: state.labResults.platePosition,
  approveRetestSuccess: state.labResults.approveRetestSuccess
});
const mapDispatch = (dispatch) => ({
  fetch: (id) => dispatch(labResutDeterminationAss(id)),
  fetch2: (id, sortBy, sortOrder) => dispatch(labResutDeterminationAssDetail(id, sortBy, sortOrder)),
  empty2: () => dispatch({ type: "LAB_RESULT_THREE_EMPTY" }),
  empty: () => dispatch({ type: "LAB_RESULT_EMPTY" }),
  approve: (id) => dispatch(labResultDetailApprove(id)),
  retest: (id) => dispatch(labResultDetailReTest(id)),
  saveRemarks: (payload) => dispatch(saveRemarks(payload)),
  savePatternRemarks: (payload) => dispatch(savePatternRemarks(payload)),
  patternRemarkChange: (index, key, value) => dispatch(patternRemarkChange(index, key, value)),
  resetSaveSuccess: () => dispatch({ type: "RESET_SAVE_SUCCESS" }),
  fetchLabPlatePositions: (patternID) => dispatch(labPlatePositionFetchAction(patternID)),
  resetApproveRetestFlag: () => dispatch(resetApproveRetest())
});

export default withAITracking(reactPlugin, withRouter(
  connect(mapState, mapDispatch)(LabResultDetailComponent)
));

// export default withRouter(
//   connect(mapState, mapDispatch)(LabResultDetailComponent)
// );
