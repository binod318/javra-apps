import React, { Fragment, useState, useEffect } from "react";

import { getDim } from "../../helpers/helper";
import ActionBar from "../../components/ActionBar/ActionBar";
import TabelGrid from "../../components/TableGrid/TableGrid";
import Decluster from "./DeclusterComponent";

import { platePlanOverViewAPI } from "./labPreparationApi";

// Hook
function useWindowSize() {
  const isClient = typeof window === "object";

  function getSize() {
    return {
      width: isClient ? window.innerWidth : undefined,
      height: isClient ? window.innerHeight : undefined,
    };
  }

  const [windowSize, setWindowSize] = useState(getSize);

  useEffect(() => {
    if (!isClient) {
      return false;
    }

    function handleResize() {
      setWindowSize(getSize());
    }

    window.addEventListener("resize", handleResize);
    return () => window.removeEventListener("resize", handleResize);
  }, []); // Empty array ensures that effect is only run on mount and unmount

  return windowSize;
}

const Preparation = (props) => {
  const [showDecluster, setShowDecluster] = useState(false);

  const {
    status,
    year: pYear,
    selected: pSelected,
    period: pPeriod,
    periodSelected: pPeriodSelected,
    sideMenu: pSideMenu,
    role,
  } = props;

  const roleAccess = role.includes("pac_requestlims");
  const [statusCode, setStatusCode] = useState("");

  const [first, setFirst] = useState(0);
  const [sideMenu, setSideMenu] = useState(pSideMenu);
  useEffect(() => {
    setSideMenu(pSideMenu);
  }, [pSideMenu]);

  const { width: tblWidth, height: tblHeight } = useWindowSize();

  const [year, setYear] = useState(pYear);
  const [yearSelected, setYearSelected] = useState(pSelected);

  const [period, setPeriod] = useState(pPeriod);
  const [periodSelected, setPeriodSelected] = useState(pPeriodSelected);

  const [detAssignmentID, setDetAssignmentID] = useState();
  const timeInterval = 15000;
  let timerCall = "";
  const [callStatus, setCallStatus] = useState(false);

  useEffect(() => {
    if (pYear.length === 0) props.labPreparationYearFetch();
  }, []);

  useEffect(() => {
    setStatusCode(status);
    if (status === 200 && !callStatus) {
      timerCall = setInterval(() => {
        props.getTestStatus(periodSelected);
      }, timeInterval);
    }
    if (status === 300) {
      clearInterval(timerCall);
      setCallStatus(false);
      props.labPreparationFolderFetch(periodSelected);
    }
    if (status === 450) {
      props.labPreparationFolderFetch(periodSelected);
    }
    return () => clearInterval(timerCall);
  }, [status]);

  useEffect(() => {
    props.labPreparationPeriodBlank();
    setYear(pYear);
  }, [pYear]);
  useEffect(() => {
    setYearSelected(pSelected);
    if (pSelected !== "" && pPeriodSelected === "") {
      props.labPreparationPeriodFetch(pSelected);
    }
  }, [pSelected]);

  useEffect(() => {
    setPeriod(pPeriod);
  }, [pPeriod]);
  useEffect(() => {
    setPeriodSelected(pPeriodSelected);
    if (pYear !== "" && pPeriodSelected !== "") {
      props.labPreparationFolderFetch(pPeriodSelected);
    }
  }, [pPeriodSelected]);

  const changeYearFunc = ({ target }) => {
    const { value } = target;
    setYearSelected(value);
    setPeriodSelected("");
    props.labPreparationPeriodBlank();
    props.labPreparationPeriodFetch(value);
  };
  const changePeriodFunc = ({ target }) => {
    const { value } = target;
    setPeriodSelected(value);
    if (value !== "") {
      props.labPreparationPeriodBlank();
      props.labPreparationFolderFetch(value);
    }
  };
  function reservePlatesFunc() {
    props.reservePlates(periodSelected);
  }
  function sendToLimsFunc() {
    props.sendToLims(periodSelected);
  }

  const leftSection = () => (
    <Fragment>
      <div className='form-e'>
        <label htmlFor='year'>Year</label>
        <select
          id='year'
          name='year'
          onChange={changeYearFunc}
          value={yearSelected}
        >
          {year.map((y) => (
            <option key={y.Year} value={y.Year}>
              {y.Year}
            </option>
          ))}
        </select>
      </div>
      <div className='form-e'>
        <label htmlFor='year'>Period</label>
        <select
          id='peroid'
          name='period'
          onChange={changePeriodFunc}
          value={periodSelected}
        >
          <option value=''>--</option>
          {period.map((p) => (
            <option key={p.PeriodID} value={p.PeriodID}>
              {p.PeriodName}
            </option>
          ))}
        </select>
      </div>
    </Fragment>
  );
  const rightSection = () => {
    const status150 = roleAccess ? statusCode === 150 : roleAccess; // 150;
    const status350 = roleAccess ? statusCode === 350 : roleAccess; // 150;

    return (
      <Fragment>
        <button
          className='with-i'
          disabled={!status150}
          onClick={reservePlatesFunc}
        >
          <i className='demo-icon icon-ok-circled' />
          Reserve Plates
        </button>
        <button
          className='with-i'
          disabled={!status350}
          onClick={sendToLimsFunc}
        >
          <i className='demo-icon icon-paper-plane' />
          Send to LIMS
        </button>
        <button
          className='with-i'
          onClick={() => platePlanOverViewAPI(periodSelected)}
        >
          <i className='demo-icon icon-file-pdf' />
          Plate Plan Overview
        </button>
        <button
          className='with-i'
          onClick={() => props.postPrintPlateLabel(periodSelected, "")}
        >
          <i className='demo-icon icon-print' />
          Print Label
        </button>
      </Fragment>
    );
  };

  const getTable = () => {
    const newList = [];
    props.groups.map((g) => {
      const { open, id } = g;
      const arrangedList = [];
      newList.push(g);
      if (open) {
        props.data.map((d) => {
          const {
            TestName,
            ABSCropCode,
            MethodCode,
            PlatformName,
            TestID,
            IsLabPriority,
            IsParent,
            DetAssignmentID,
            NrOfPlates,
            NrOfMarkers,
            TraitMarkers,
            VarietyName,
            SampleNr,
          } = d;
          const arrange = IsLabPriority ? "true" : "false";
          if (id === TestID) {
            arrangedList.push({
              DetAssignmentID,
              NrOfPlates,
              NrOfMarkers,
              TraitMarkers,
              VarietyName,
              SampleNr,
              IsLabPriority,
              IsParent,
            });
          }
          return null;
        });
        const res = arrangedList
          .sort((a, b) => {
            return b.IsLabPriority - a.IsLabPriority || b.IsParent - a.IsParent;
          })
          .map((r) => {
            newList.push(r);
          });
      }
      return null;
    });

    return newList;
  };

  const customWidth = {
    DetAssignmentID: 130,
    SampleNr: 80,
    VarietyNr: 80,
    ProcessNr: 80,
    Action: 70,
    PlatformName: 160,
    VarietyName: 260,
    TestName: 130,
    TraitMarkers: 100,
  };

  return (
    <Fragment>
      <div>
        <ActionBar left={leftSection} right={rightSection} />
        <div className='container'>
          <br />
          <div>
            <TabelGrid
              customWidth={customWidth}
              tblWidth={tblWidth}
              tblHeight={tblHeight}
              isChange={false}
              changeValue={() => {}}
              sideMenu={sideMenu}
              data={getTable()}
              columns={props.columns}
              action={{
                name: "folder",
                open: (index) => props.groupToggle(index),
                view: (DetAssignmentID) => {
                  setDetAssignmentID(DetAssignmentID);
                  setShowDecluster(true);
                },
                edit: () => alert("edit"),
              }}
            />
          </div>
        </div>
      </div>

      {showDecluster && (
        <Decluster
          PeriodID={periodSelected}
          DetAssignmentID={detAssignmentID}
          closeFunc={setShowDecluster}
          detAssignMentIdFunc={setDetAssignmentID}
          getTableFunc={getTable}
          groupToggle={() => {}}
          fetch={props.labDeclusterFetch}
          data={props.ddata}
          columns={props.dcolumns}
        />
      )}
    </Fragment>
  );
};
export default Preparation;
