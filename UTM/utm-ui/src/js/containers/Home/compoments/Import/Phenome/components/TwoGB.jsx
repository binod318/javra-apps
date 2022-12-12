import React, { Fragment } from "react";
import PropTypes from "prop-types";
import DateInput from "../../../../../../components/DateInput";

function TwoGB(props) {
  const { importLevel, testType } = props;

  //testType === 'MT' ||
  const excludeCondition = testType === "DI";

  return (
    <Fragment>
      <DateInput
        label="Planned Week"
        todayDate={props.todayDate}
        selected={props.startDate}
        change={props.handlePlannedDateChange}
        id="import_planned"
      />
      <DateInput
        label="Expected Week"
        todayDate={props.startDate}
        selected={props.expectedDate}
        change={props.handleExpectedDateChange}
        id="import_expected"
      />

      <div>
        <label htmlFor="cropSelected">
          Material Type
          <select
            id="import_materialType"
            name="materialTypeID"
            value={props.materialTypeID}
            onChange={props.handleChange}
          >
            <option value="">Select</option>
            {props.materialTypeList.map(x => (
              <option key={x.materialTypeCode} value={x.materialTypeID}>
                {x.materialTypeCode} - {x.materialTypeDescription}
              </option>
            ))}
          </select>
        </label>
      </div>
      <div>
        <label htmlFor="cropSelected">
          Material State
          <select
            id="import_materialState"
            name="materialStateID"
            value={props.materialStateID}
            onChange={props.handleChange}
          >
            <option value="">Select</option>
            {props.materialStateList.map(x => (
              <option key={x.materialStateCode} value={x.materialStateID}>
                ({x.materialStateCode}) {x.materialStateDescription}
              </option>
            ))}
          </select>
        </label>
      </div>
      <div>
        <label htmlFor="cropSelected">
          Container Type
          <select
            id="import_containerType"
            name="containerTypeID"
            value={props.containerTypeID}
            onChange={props.handleChange}
          >
            <option value="">Select</option>
            {props.containerTypeList.map(x => (
              <option key={x.containerTypeCode} value={x.containerTypeID}>
                {x.containerTypeCode} - {x.containerTypeName}
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
        <label>Import Level</label>
        <div className="radioSection">
          <label
            htmlFor="plant"
            className={importLevel === "PLT" ? "active" : ""}
          >
            <input
              id="plant"
              type="radio"
              value="PLT"
              name="importLevel"
              checked={importLevel === "PLT"}
              onChange={props.handleChange}
            />
            Plant
          </label>
          <label
            htmlFor="list"
            className={importLevel === "LIST" ? "active" : ""}
          >
            <input
              id="list"
              type="radio"
              value="LIST"
              name="importLevel"
              checked={importLevel === "LIST"}
              onChange={props.handleChange}
            />
            List
          </label>
          {/*
           */}
        </div>
      </div>

      <div>
        <label htmlFor="fileName">
          File Name
          <input
            id="import_fileName"
            name="fileName"
            type="text"
            value={props.fileName}
            onChange={props.handleChange}
            disabled={false}
          />
        </label>
      </div>

      <div className="markContainer">
        <div className="marker">
          <input
            type="checkbox"
            id="isolationModalPhenome"
            name="isolationStatus"
            checked={props.isolationStatus}
            onChange={props.handleChange}
          />
          <label htmlFor="isolationModalPhenome">Already Isolated</label>{" "}
          {/*eslint-disable-line*/}
        </div>
      </div>

      <div className="markContainer">
        <div className="marker">
          <input
            type="checkbox"
            id="cumulateStatus"
            name="cumulateStatus"
            checked={props.cumulateStatus}
            onChange={props.handleChange}
          />
          <label htmlFor="cumulateStatus">Cumulate</label>{" "}
          {/*eslint-disable-line*/}
        </div>
      </div>
      {excludeCondition && (
        <div className="markContainer">
          <div className="marker">
            <input
              type="checkbox"
              id="excludeControlPosition"
              name="excludeControlPosition"
              // checked={props.excludeControlPosition}
              defaultChecked={props.excludeControlPosition}
              onChange={props.handleChange}
            />
            <label htmlFor="excludeControlPosition">Control Position</label>{" "}
            {/*eslint-disable-line*/}
          </div>
        </div>
      )}
      <div className="markContainer">
        <div className="marker">
          <input
            type="checkbox"
            id="btrControl"
            name="btrControl"
            // checked={props.excludeControlPosition}
            checked={props.btrControl}
            onChange={props.handleChange}
          />
          <label htmlFor="btrControl">BTR</label> {/*eslint-disable-line*/}
          {props.btrControl && (
            <input
              id="researcherName"
              name="researcherName"
              type="text"
              value={props.researcherName}
              onChange={props.handleChange}
              placeholder="Researcher name"
            />
          )}
        </div>
      </div>
    </Fragment>
  );
}
export default TwoGB;

TwoGB.defaultProps = {
  btrControl: false,
  isolationStatus: false,
  cumulateStatus: false,
  excludeControlPosition: false,
  materialTypeList: [],
  materialStateList: [],
  containerTypeList: [],
  materialTypeID: null,
  materialStateID: null,
  objectID: "",
  fileName: "",
  containerTypeID: null,
  researcherName: "",
  testType: "",
  importLevel: ""
};

TwoGB.propTypes = {
  todayDate: PropTypes.object, // eslint-disable-line
  startDate: PropTypes.object, // eslint-disable-line
  expectedDate: PropTypes.object, // eslint-disable-line
  handlePlannedDateChange: PropTypes.func.isRequired,
  handleExpectedDateChange: PropTypes.func.isRequired,
  materialTypeID: PropTypes.any, // eslint-disable-line
  handleChange: PropTypes.func.isRequired,
  materialTypeList: PropTypes.array, // eslint-disable-line
  materialStateID: PropTypes.any, // eslint-disable-line
  materialStateList: PropTypes.array, // eslint-disable-line
  containerTypeID: PropTypes.any, // eslint-disable-line
  containerTypeList: PropTypes.array, // eslint-disable-line
  objectID: PropTypes.string,
  fileName: PropTypes.string,
  isolationStatus: PropTypes.bool,
  cumulateStatus: PropTypes.bool,
  excludeControlPosition: PropTypes.bool,
  btrControl: PropTypes.bool,
  researcherName: PropTypes.string,
  testType: PropTypes.string,
  importLevel: PropTypes.string
};
