import React, { Fragment, useState, useEffect } from "react";

import { getDim } from "../../helpers/helper";
import Wrapper from "../../components/Wrapper/wrapper";
import TabelGrid from "../../components/TableGrid/TableGrid";

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

// Hook
function useKeyPress(targetKey) {
  // State for keeping track of whether key is pressed
  const [keyPressed, setKeyPressed] = useState(false);

  // If pressed key is our target key then set to true
  function downHandler({ key }) {
    if (key === targetKey) {
      setKeyPressed(true);
    }
  }

  // If released key is our target key then set to false
  const upHandler = ({ key }) => {
    if (key === targetKey) {
      setKeyPressed(false);
    }
  };

  // Add event listeners
  useEffect(() => {
    window.addEventListener("keydown", downHandler);
    window.addEventListener("keyup", upHandler);
    // Remove event listeners on cleanup
    return () => {
      window.removeEventListener("keydown", downHandler);
      window.removeEventListener("keyup", upHandler);
    };
  }, []); // Empty array ensures that effect is only run on mount and unmount

  return keyPressed;
}

const Decluster = (props) => {
  const escapePress = useKeyPress("Escape");

  const {
    closeFunc,
    detAssignMentIdFunc,
    getTableFunc,
    PeriodID,
    DetAssignmentID,
    columns,
    data,
  } = props;

  if (escapePress) closeFunc();

  const { width: tblWidth, height: tblHeight } = useWindowSize();

  useEffect(() => {
    props.fetch(PeriodID, DetAssignmentID);
  }, []);

  let newWidth = tblWidth - 30;
  const customWidth = {
    VarietyNr: 80,
    VarietyName: 260,
    VarietyType: 100,
  };
  columns.map((c) => {
    if (customWidth[c.ColumnID] === undefined) {
      Object.assign(customWidth, { [c.ColumnID]: 100 });
    }
  });
  return (
    <Wrapper>
      <div className='decluster-wrapper' id={PeriodID}>
        <div className='decluster-title'>
          <span>Selected Markers</span>
          <i
            role='button'
            className='demo-icon icon-cancel close'
            title='Close'
            onClick={() => {
              closeFunc(false);
              detAssignMentIdFunc("");
            }}
          />
        </div>

        <div>
          <TabelGrid
            customWidth={customWidth}
            tblWidth={newWidth || 980}
            tblHeight={tblHeight + 25}
            isChange={false}
            changeValue={() => {}}
            sideMenu={false}
            data={data}
            columns={columns}
            action={{
              name: "decluster",
            }}
          />
        </div>
      </div>
    </Wrapper>
  );
};
export default Decluster;
