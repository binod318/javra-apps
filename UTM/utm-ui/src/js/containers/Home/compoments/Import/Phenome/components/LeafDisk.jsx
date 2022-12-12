import React, { Fragment } from "react";
import PropTypes from "prop-types";
import DateInput from "../../../../../../components/DateInput";

function LeafDisk(props) {
  const { sites, siteID, importSource } = props;

  let testProtocolList = [];
  let ttype = props.testTypeList.filter(o => o.testTypeCode == props.testType);
  if(ttype && ttype.length > 0)
    testProtocolList = props.testProtocolList.filter(o => o.testTypeID === ttype[0].testTypeID);

  return (
    <Fragment>
      <div>
         <label htmlFor="siteID">
          Lab Location
          <select
            id="siteID"
            name="siteID"
            value={siteID}
            onChange={props.handleChange}
          >
            <option value="">Select</option>
            {sites.map(x => (
              <option key={x.siteID} value={x.siteID}>
                {x.siteName}
              </option>
            ))}
          </select>
        </label>
      </div>

      <DateInput
        label="Planned Week"
        todayDate={props.todayDate}
        selected={props.startDate}
        change={props.handlePlannedDateChange}
        id="import_planned"
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
          Method
          <select
            id="import_testProtocol"
            name="testProtocolID"
            value={props.testProtocolID}
            onChange={props.handleChange}
          >
            <option value="">Select</option>
            {testProtocolList.map(x => (
              <option key={x.testProtocolID} value={x.testProtocolID}>
                {x.testProtocolName}
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
            id="import_fileName"
            name="fileName"
            type="text"
            value={props.fileName}
            onChange={props.handleChange}
            disabled={false}
          />
        </label>
      </div>

      <div>
        <label>Import Source</label>
        <div className="radioSection">
          <label
            htmlFor="importSource"
            className={importSource === "Phenome" ? "pr-11 active" : "pr-11"}
          >
            <input
              id="phenome"
              type="radio"
              value="Phenome"
              name="importSource"
              checked={importSource === "Phenome"}
              onChange={props.handleChange}
            />
            Phenome
          </label>
          <label
            htmlFor="sampleList"
            className={importSource === "SampleList" ? "active" : ""}
          >
            <input
              id="list"
              type="radio"
              value="SampleList"
              name="importSource"
              checked={importSource === "SampleList"}
              onChange={props.handleChange}
            />
            Sample
          </label>
          {/*
           */}
        </div>
      </div>
    </Fragment>
  );
}
export default LeafDisk;

LeafDisk.defaultProps = {
  excludeControlPosition: false,
  materialTypeList: [],
  testPrositeIDtocolList: [],
  siteID: 0,
  sites: [],
  materialTypeID: null,
  testProtocolID: null,
  objectID: "",
  fileName: "",
  testType: "",
};

LeafDisk.propTypes = {
  todayDate: PropTypes.object, // eslint-disable-line
  startDate: PropTypes.object, // eslint-disable-line
  handlePlannedDateChange: PropTypes.func.isRequired,
  materialTypeID: PropTypes.any, // eslint-disable-line
  testProtocolID: PropTypes.any, // eslint-disable-line
  handleChange: PropTypes.func.isRequired,
  materialTypeList: PropTypes.array, // eslint-disable-line
  testProtocolList: PropTypes.array, // eslint-disable-line
  sites: PropTypes.array,
  siteID: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
  objectID: PropTypes.string,
  fileName: PropTypes.string,
  testType: PropTypes.string
};
