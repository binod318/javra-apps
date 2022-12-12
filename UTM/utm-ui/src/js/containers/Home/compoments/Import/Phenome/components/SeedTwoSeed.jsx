import React, { Fragment } from 'react';
import PropTypes from 'prop-types';
// import DateInput from '../../../../../../components/DateInput';

function SeedTwoSeed(props) {
  const { importLevel, capacitySlotList, capacityList } = props;
  // const yearData = [2016, 2017, 2018, 2019];

  const locationList =
    [...new Set(capacitySlotList.map(c => c.dH0Location))] || [];

  return (
    <Fragment>
      <div>
        <label htmlFor="cropSelected">
          Crops
          <select name="cropSelected" onChange={props.handleChange}>
            <option value="">Select</option>
            {props.crops.map(c => (
              <option value={c} key={c}>
                {c}
              </option>
            ))}
          </select>
        </label>
      </div>
      <div />
      {false && (
        <div>
          <label htmlFor="breedingStationSelected">
            Br.Station
            <select
              name="breedingStationSelected"
              onChange={props.handleChange}
            >
              <option value="">Select</option>
              {props.breedingStation.map((b, i) => {
                const bs = b.breedingStationCode;
                return (
                  <option value={bs} key={bs+i}> {/* eslint-disable-line */}
                    {bs}
                  </option>
                );
              })}
            </select>
          </label>
        </div>
      )}

      <div>
        <label>Import Level</label>
        <div className="radioSection">
          <label
            htmlFor="plant"
            className={importLevel === 'PLT' ? 'active' : ''}
          >
            <input
              id="plant"
              type="radio"
              value="PLT"
              name="importLevel"
              checked={importLevel === 'PLT'}
              onChange={props.handleChange}
            />
            Plant
          </label>
          <label
            htmlFor="list"
            className={importLevel === 'LIST' ? 'active' : ''}
          >
            <input
              id="list"
              type="radio"
              value="LIST"
              name="importLevel"
              checked={importLevel === 'LIST'}
              onChange={props.handleChange}
            />
            List
          </label>
        </div>
      </div>

      <div>
        <label htmlFor="breedingStationSelected">
          Capacity Slot
          <select
            name="capacitySlot"
            onChange={props.handleChange}
            value={props.capacitySlot}
          >
            <option value="0">Select</option>
            {capacityList.map(b => (
              <option value={b.capacitySlotID} key={b.capacitySlotID}>
                {b.sowingCode}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div>
        <label htmlFor="breedingStationSelected">
          Lab Location
          <select
            name="location"
            onChange={props.handleChange}
            value={props.location}
          >
            <option value="">Select</option>
            {locationList.map(b => (
              <option value={b} key={b}>
                {b}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div>
        <label htmlFor="objectID">
          Selected Object ID
          <input
            name="objectID"
            type="text"
            value={props.objectID}
            readOnly
            disabled
          />
        </label>
      </div>

      <div>
        <label htmlFor="fileName">
          File Name
          <input
            name="fileName"
            type="text"
            value={props.fileName}
            onChange={props.handleChange}
            disabled={false}
          />
        </label>
      </div>
    </Fragment>
  );
}

SeedTwoSeed.defaultProps = {
  capacitySlotList: [],
  capacityList: [],
  crops: [],
  breedingStation: [],
  capacitySlot: 0,
  location: '',
  fileName: ''
};
SeedTwoSeed.propTypes = {
  importLevel: PropTypes.string.isRequired,
  capacitySlotList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  capacityList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  crops: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  breedingStation: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  handleChange: PropTypes.func.isRequired,
  capacitySlot: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  location: PropTypes.string,
  objectID: PropTypes.string.isRequired,
  fileName: PropTypes.string
};
export default SeedTwoSeed;
