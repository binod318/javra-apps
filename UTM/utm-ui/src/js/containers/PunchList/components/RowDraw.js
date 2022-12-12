/**
 * Created by sushanta on 3/13/18.
 */
import React from "react";
import PropTypes from "prop-types";

const RowDraw = ({ rows, cols }) => {
  const rowDraw = [];
  for (let i = -1; i < cols; i += 1) {
    if (i < 0) {
      rowDraw.push(<div>{rows.rowID}</div>);
    } else {
      const style = {
        background: rows.cells[i].bgColor,
        color: rows.cells[i].fgColor,
        position: "relative"
      };
      // const mockData = parseInt(Math.random() * 10);
      const data = rows.cells[i].materialKey;
      const lastIndexOfDash = data ? data.lastIndexOf("-") : -1;
      let plantName = data;
      let plantNumber = "";
      // if (data && data.length > 11) {
      if (lastIndexOfDash > -1) {
        plantName = data.substring(0, lastIndexOfDash);
        plantNumber =
          lastIndexOfDash > -1
            ? data.substring(lastIndexOfDash, data.length)
            : "";
      }
      // }
      let fontPxClass = "";
      if (plantName)
        switch (true) {
          case plantName.length < 10: {
            fontPxClass = "font12px";
            break;
          }
          case plantName.length >= 10 && plantName.length <= 12: {
            fontPxClass = "font9px";
            break;
          }
          case plantName.length > 12: {
            fontPxClass = "font8px";
            break;
          }
          default: {
            break;
          }
        }

      rowDraw.push(
        <div style={style}>
          <span>
            <span className={`plant-name ${fontPxClass}`}>{plantName}</span>
            {plantNumber !== "" && (
              <span className="plant-number"> {plantNumber}</span>
            )}
          </span>
          {rows.cells[i].broken && (
            <span className="brokenItemIcon">
              <i className="icon icon-info-circled" />
            </span>
          )}
        </div>
      );
    }
  }
  return (
    <div className="plateRow">
      {rowDraw.map((d, i) => (
        <div key={i}>{d}</div>
      ))}
    </div>
  );
};

RowDraw.propTypes = {
  rows: PropTypes.object.isRequired, // eslint-disable-line react/forbid-prop-types
  cols: PropTypes.number.isRequired
};

export default RowDraw;
