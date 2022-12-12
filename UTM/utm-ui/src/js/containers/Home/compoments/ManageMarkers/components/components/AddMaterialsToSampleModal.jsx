import PropTypes from "prop-types";
import React, { useState, useEffect } from "react";
import Modal from "react-modal";
import "./Modal.css";
import "./AddMaterialsToSampleModal.css";

Modal.setAppElement("#root");
const customStyles = {
  content: {
    zIndex: 10,
    top: "50%",
    left: "50%",
    right: "auto",
    bottom: "auto",
    marginRight: "-50%",
    transform: "translate(-50%, -50%)",
    backgroundColor: "#fefefe",
    border: "1px solid #888",
    width: 350,
    borderRadius: 4
  }
};

const AddMaterialsToSampleModal = ({
  toggle,
  addMaterialsToSample,
  fetchSamples,
  samples,
  testID
}) => {
  const [sampleID, setSampleID] = useState();
  const [error, setError] = useState({
    sampleID: false
  });

  useEffect(() => {
    if (samples.length > 0) setSampleID(samples[0].sampleID);
  }, [samples]);

  // fetch samples if not already done
  useEffect(() => {
    fetchSamples(testID);
  }, [testID]);

  // form change handler, handle validation error
  const formChangeHandler = e => {
    e.preventDefault();
    switch (e.target.name) {
      case "sampleID": {
        setSampleID(e.target.value);
        setError({ ...error, sampleID: false });
        break;
      }
      default: {
        break;
      }
    }
  };
  //
  const addToSample = () => {
    if (!sampleID) {
      error.sampleID = true;
      setError(error);
      return;
    }
    addMaterialsToSample(sampleID);
  };
  return (
    <Modal
      isOpen
      onRequestClose={toggle}
      contentLabel="Add Materials to Sample"
      style={customStyles}
      overlayClassName="modal-overlay"
    >
      <div className="add-materials-to-sample">
        <h2 className="modal--title">Add Materials to Sample</h2>
        <div>
          <div>
            <label>Sample Name</label>
            <select
              name="sampleID"
              placeholder="Sample ID"
              value={sampleID}
              onChange={formChangeHandler}
              className={error.sampleName ? "form-error--input" : ""}
            >
              {samples.map(sample => {
                return (
                  <option key={sample.sampleID} value={sample.sampleID}>
                    {sample.sampleName}
                  </option>
                );
              })}
            </select>
            {error.sampleID && (
              <span className="form-error--label">This is required field.</span>
            )}
          </div>
          <div>
            <button className="form-button" onClick={addToSample}>
              Add
            </button>
          </div>
        </div>
        <button onClick={toggle} className="modal--close">
          &times;
        </button>
      </div>
    </Modal>
  );
};

AddMaterialsToSampleModal.propTypes = {
  fetchSamples: PropTypes.func.isRequired,
  addMaterialsToSample: PropTypes.func.isRequired,
  toggle: PropTypes.func.isRequired,
  samples: PropTypes.arrayOf(
    PropTypes.shape({
      sampleID: PropTypes.number,
      sampleName: PropTypes.string
    })
  ).isRequired,
  testID: PropTypes.number.isRequired
};

export default AddMaterialsToSampleModal;
