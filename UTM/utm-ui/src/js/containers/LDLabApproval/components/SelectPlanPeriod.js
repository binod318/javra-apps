import React from 'react';
import PropTypes from 'prop-types';

const SelectPlanPeriod = ({ onChange, planPeriods, selectedPeriodID, siteLocation, location, changeLocation }) => (
  <section className="page-action">
    <div className="left">
      <div className="form-e">
        <label>Plan period</label>
        <select onChange={onChange} className="w-300" value={selectedPeriodID}>
          <option value="0">Choose Plan Period</option>
          {planPeriods.map(period => (
            <option key={period.periodID} value={period.periodID}>
              {period.periodName}
            </option>
          ))}
        </select>
      </div>
      <div className="form-e">
        <label htmlFor="location">Lab Location</label>{" "}
        {/* eslint-disable-line */}
        <select
          id="location"
          name="location"
          onChange={changeLocation}
          value={siteLocation}
          className="w-200"
        >
          {location.map(location => {
            const {
              siteID,
              siteName
            } = location;
            return (
              <option
                key={`${siteID}`}
                value={siteID}
              >
                {siteName}
              </option>
            );
          })}
        </select>
      </div>
    </div>
  </section>
);
SelectPlanPeriod.propTypes = {
  onChange: PropTypes.func.isRequired,
  planPeriods: PropTypes.array.isRequired, // eslint-disable-line react/forbid-prop-types
  selectedPeriodID: PropTypes.number.isRequired,
  siteLocation: PropTypes.number.isRequired,
  location: PropTypes.array.isRequired,
  changeLocation: PropTypes.func.isRequired
};
export default SelectPlanPeriod;
