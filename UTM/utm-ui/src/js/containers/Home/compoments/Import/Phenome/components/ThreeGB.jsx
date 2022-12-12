import React, { Fragment } from 'react';

function ThreeGB(props) {
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

      <div>
        <label htmlFor="breedingStationSelected">
          Br.Station
          <select
            name="breedingStationSelected"
            onChange={props.handleChange}
          >
            <option value="">Select</option>
            {props.breedingStation.map(b => (
              <option value={b.breedingStationCode} key={b.breedingStationCode}>
                {b.breedingStationCode}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div>
        <label htmlFor="threeGBTaskID">
          Project List
          <select
            name="threeGBTaskID"
            onChange={props.handleChange}
            disabled={
              props.cropSelected === '' ||
              props.breedingStationSelected === ''
            }
            value={props.threeGBTaskID}
          >
            <option value="">Select</option>
            {props.threegbList.map(b => (
              <option value={b.threeGBTaskID} key={b.threeGBTaskID}>
                {b.week} - {b.threeGBProjectcode}
              </option>
            ))}
          </select>
        </label>
      </div>

      <div>
        <label htmlFor="fileName">
          File Name
          <input
            name="fileName"
            type="text"
            value={props.fileName}
            disabled
          />
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
    </Fragment>
  );
}
export default ThreeGB;
