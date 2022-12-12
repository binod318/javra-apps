import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import DateInput from '../../../../../components/DateInput';
import Dropdown from '../../../../../components/Combobox/Combobox';

function DNA(props) {
  const {
    testEditMode,

    testTypeID,
    testTypeList,
    handleTestTypeChange,

    materialTypeList,
    materialTypeID,
    handleMaterialTypeChange,

    materialStateList,
    materialStateID,
    handleMaterialStateChange,

    containerTypeList,
    containerTypeID,
    handleContainerTypeChange,

    todayDate,
    plannedDate,
    handleDateChange,

    expectedDate,
    handleExpectedDateChange,

    isolationStatus,
    handleIsolationChange,

    cumulate,
    handleCumulate,
    excludeControlPosition
  } = props;
  return (
    <Fragment>
      <div className="trow">
        <div className="tcell">
          <Dropdown
            disabled
            label="Test type"
            options={testTypeList}
            value={testTypeID}
            change={handleTestTypeChange}
          />
        </div>
        <div className="tcell">
          <Dropdown
            disabled={!testEditMode}
            label="Material Type"
            options={materialTypeList}
            value={materialTypeID}
            change={handleMaterialTypeChange}
          />
        </div>
        <div className="tcell">
          <Dropdown
            disabled={!testEditMode}
            label="Material State"
            options={materialStateList}
            value={materialStateID}
            change={handleMaterialStateChange}
          />
        </div>
        <div className="tcell">
          <Dropdown
            disabled={!testEditMode}
            label="Container Type"
            options={containerTypeList}
            value={containerTypeID}
            change={handleContainerTypeChange}
          />
        </div>
      </div>

      <div className="trow">
        <div className="tcell">
          <DateInput
            disabled={!testEditMode}
            label="Planned Week"
            todayDate={todayDate}
            selected={moment(plannedDate, [
              moment.HTML5_FMT.DATETIME_LOCAL_SECONDS,
              'DD/MM/YYYY'
            ])}
            change={handleDateChange}
          />
        </div>
        <div className="tcell">
          <DateInput
            disabled={!testEditMode}
            label="Expected Week"
            todayDate={moment(plannedDate, [
              moment.HTML5_FMT.DATETIME_LOCAL_SECONDS,
              'DD/MM/YYYY'
            ])}
            selected={moment(expectedDate, [
              moment.HTML5_FMT.DATETIME_LOCAL_SECONDS,
              'DD/MM/YYYY'
            ])}
            change={handleExpectedDateChange}
          />
        </div>
        <div style={{ flex: 2, display: 'flex' }}>
          <div className="tcell">
            <div className="markContainer">
              <label>&nbsp;</label>  {/*eslint-disable-line*/}
              <div className={testEditMode ? 'marker' : 'marker disabled'}>
                <input
                  type="checkbox"
                  id="isolationHome"
                  disabled={!testEditMode}
                  checked={isolationStatus || false}
                  onChange={handleIsolationChange}
                />
                <label htmlFor="isolationHome">Already Isolated</label>  {/*eslint-disable-line*/}
              </div>
            </div>
          </div>
          <div className="tcell">
            <div className="markContainer">
              <label>&nbsp;</label>  {/*eslint-disable-line*/}
              <div className={testEditMode ? 'marker' : 'marker disabled'}>
                <input
                  type="checkbox"
                  id="cumulateHome"
                  disabled={!testEditMode}
                  checked={cumulate}
                  onChange={handleCumulate}
                />
                <label htmlFor="cumulateHome">Cumulate</label>  {/*eslint-disable-line*/}
              </div>
            </div>
          </div>
          <div className="tcell">
            <div className="markContainer">
              <label>&nbsp;</label>  {/*eslint-disable-line*/}
              <div className="marker disabled">
                <input
                  type="checkbox"
                  id=""
                  disabled
                  checked={excludeControlPosition}
                  onChange={() => {}}
                />
                <label htmlFor="">Control Position</label>  {/*eslint-disable-line*/}
              </div>
            </div>
          </div>
        </div>
      </div>
    </Fragment>
  );
}

DNA.defaultProps = {
  testTypeList: [],
  materialTypeList: [],
  materialStateList: [],
  containerTypeList: [],
  isolationStatus: false
};
DNA.propTypes = {
  excludeControlPosition: PropTypes.any, // eslint-disable-line

  testEditMode: PropTypes.bool.isRequired,

  todayDate: PropTypes.object, // eslint-disable-line
  plannedDate: PropTypes.string.isRequired,
  expectedDate: PropTypes.string.isRequired,

  isolationStatus: PropTypes.bool,
  cumulate: PropTypes.bool.isRequired,

  testTypeList: PropTypes.array, // eslint-disable-line
  materialTypeList: PropTypes.array, // eslint-disable-line
  materialStateList: PropTypes.array, // eslint-disable-line
  containerTypeList: PropTypes.array, // eslint-disable-line

  handleCumulate: PropTypes.func.isRequired,
  handleTestTypeChange: PropTypes.func.isRequired,
  handleMaterialTypeChange: PropTypes.func.isRequired,
  handleMaterialStateChange: PropTypes.func.isRequired,
  handleContainerTypeChange: PropTypes.func.isRequired,
  handleDateChange: PropTypes.func.isRequired,
  handleExpectedDateChange: PropTypes.func.isRequired,
  handleIsolationChange: PropTypes.func.isRequired,

  testTypeID: PropTypes.number.isRequired,
  materialTypeID: PropTypes.any, // eslint-disable-line
  materialStateID: PropTypes.any, // eslint-disable-line
  containerTypeID: PropTypes.any // eslint-disable-line
};

export default DNA;
