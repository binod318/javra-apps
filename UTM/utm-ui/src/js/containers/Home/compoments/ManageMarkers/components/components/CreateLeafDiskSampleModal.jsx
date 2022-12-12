import PropTypes from "prop-types";
import React, { useState } from "react";
import Modal from "react-modal";
import "./Modal.css";
import "./CreateLeafDiskSampleModal.css";

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

const CreateLeafSampleModal = ({ toggle, testID, sampleID, save }) => {
  const [sampleName, setSampleName] = useState("");
  const [nrOfSamples, setNrOfSampels] = useState(1);
  const [error, setErrors] = useState({
    sampleName: false,
    nrOfSamples: false
  });
  const formChangeHandler = e => {
    e.preventDefault();
    switch (e.target.name) {
      case "sampleName": {
        setSampleName(e.target.value);
        setErrors({ ...error, sampleName: false });
        break;
      }
      case "nrOfSamples": {
        setNrOfSampels(e.target.value);
        setErrors({ ...error, nrOfSamples: false });
        break;
      }
      default: {
        break;
      }
    }
  };
  const saveSample = () => {
    if (sampleName === "") {
      error.sampleName = true;
    }

    if (nrOfSamples < 1) {
      error.nrOfSamples = true;
    }
    setErrors({ ...error });

    if (error.sampleName || error.nrOfSamples) return;

    const payload = {
      testID,
      sampleName,
      nrOfSamples
    };
    if (sampleID !== 0) {
      payload.sampleID = sampleID;
    }
    save(payload);
  };
  return (
    <Modal
      isOpen
      onRequestClose={toggle}
      contentLabel="Create Sample"
      style={customStyles}
      overlayClassName="modal-overlay"
    >
      <div className="create-leaf-disk-sample">
        <h2 className="modal--title">Create Sample</h2>
        <div>
          <div>
            <label>Sample Name</label>
            <input
              type="text"
              name="sampleName"
              placeholder="Sample Name"
              value={sampleName}
              onChange={formChangeHandler}
              className={error.sampleName ? "form-error--input" : ""}
            />
            {error.sampleName && (
              <span className="form-error--label">This is required field.</span>
            )}
          </div>
          <div>
            <label>No. of Samples</label>
            <input
              type="number"
              name="nrOfSamples"
              placeholder="Number of Samples"
              value={nrOfSamples}
              min={1}
              onChange={formChangeHandler}
              className={error.nrOfSamples ? "form-error--input" : ""}
            />
            {error.nrOfSamples && (
              <span className="form-error--label">Invalid value.</span>
            )}
          </div>
          <div>
            <button className="form-button" onClick={saveSample}>
              Save
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

CreateLeafSampleModal.propTypes = {
  testID: PropTypes.number.isRequired,
  sampleID: PropTypes.number.isRequired,
  save: PropTypes.func.isRequired,
  toggle: PropTypes.func.isRequired
};

export default CreateLeafSampleModal;
