import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
import moment from 'moment';
import DateInput from '../../../../../components/DateInput';
import Dropdown from '../../../../../components/Combobox/Combobox';

function LeafDisk(props) {
  const {
    testEditMode,

    testTypeID,
    testTypeList,
    handleTestTypeChange,

    materialTypeList,
    materialTypeID,
    handleMaterialTypeChange,

    testProtocolID,
    handleTestProtocolChange,

    siteID,
    sites,
    handleLabLocationChange,

    todayDate,
    plannedDate,
    handleDateChange,

  } = props;

  //filter testprotocol based on testtype
  let testProtocolList = props.testProtocolList.filter(o => o.testTypeID === testTypeID);

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
            label="Lab Location"
            options={sites}
            value={siteID}
            change={handleLabLocationChange}
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
            label="Method"
            options={testProtocolList}
            value={testProtocolID}
            change={handleTestProtocolChange}
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
      </div>
    </Fragment>
  );
}

LeafDisk.defaultProps = {
  testTypeList: [],
  sites: [],
  materialTypeList: [],
  testProtocolList: []
};
LeafDisk.propTypes = {
  testEditMode: PropTypes.bool.isRequired,

  todayDate: PropTypes.object, // eslint-disable-line
  plannedDate: PropTypes.string.isRequired,

  testTypeList: PropTypes.array, // eslint-disable-line
  materialTypeList: PropTypes.array, // eslint-disable-line
  sites: PropTypes.array,

  handleTestTypeChange: PropTypes.func.isRequired,
  handleMaterialTypeChange: PropTypes.func.isRequired,
  handleLabLocationChange: PropTypes.func.isRequired,
  handleDateChange: PropTypes.func.isRequired,

  testTypeID: PropTypes.number.isRequired,
  materialTypeID: PropTypes.any, // eslint-disable-line
  testProtocolID: PropTypes.any, // eslint-disable-line
  siteID: PropTypes.any
};

export default LeafDisk;
