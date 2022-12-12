import React, { Fragment, useState, useEffect } from "react";
import { useSelector } from "react-redux";
import { dat } from "../../LabPreparation/data";

const GroupTable = (props) => {
  if (props.columns === undefined) return null;
  const {
    group,
    data,
    columns,
    customWidth,
    automaticPlan,
    NrOfPlates,
    refresh,
  } = props;
  const {
    ABSCropCode,
    MethodCode,
    UsedFor,
    NrOfResPlates,
    TotalPlates,
    SlotName,
  } = group;
  const baseWidth = 125;

  const [number, setNumber] = useState(NrOfResPlates);
  const [plates] = useState(TotalPlates);

  const [ddata, setDdata] = useState(data);

  useEffect(() => {
    setDdata(data);
  });

  const checkAction = (state, row, frm, action) => {
    const { NrOfPlates: currentPlates, flag } = row;

    if (state) {
      const nn = ddata.filter(
        (m) =>
          m.ABSCropCode === ABSCropCode &&
          m.MethodCode === MethodCode &&
          m.UsedFor.toLowerCase() === UsedFor.toLowerCase()
      );
      let tot = 0;
      nn.map((n) => {
        if (n.flag) tot = tot + n.NrOfPlates;
      });

      const sumtotal = tot + currentPlates;
      if (!flag) {
        if (sumtotal > plates) {
          props.show(
            "Capacity exceeded. Please increase capacity or no new batch can be planned."
          );
          return null;
        } else setNumber(sumtotal);
      }
    } else {
      if (frm === 1 && flag) setNumber(number - currentPlates);
    }
    action();
  };

  const testFunc = (evel, row) => {
    checkAction(evel.target.checked, row, 1, () =>
      props.gourpCheckBoxClick(row, evel.target.checked)
    );
  };

  const prioFunc = (evel, row) => {
    checkAction(evel.target.checked, row, 2, () =>
      props.groupLabPrioClick(row, evel.target.checked)
    );
  };

  const text = `${ABSCropCode} (${MethodCode}), Slot: ${SlotName}, ${UsedFor} (Capacity: ${number}/${TotalPlates})`;

  const rows = [];
  ddata.map((m) => {
    const userForCompaer = m.UsedFor.toLowerCase() === UsedFor.toLowerCase();
    if (
      m.ABSCropCode === ABSCropCode &&
      m.MethodCode === MethodCode &&
      userForCompaer
    ) {
      const row = [];

      columns.forEach((cc) => {
        const isPacCompletFlag = m["IsPacComplete"];
        const IsLabPriorityFlag = m["IsLabPriority"];
        let ccname = "";
        if (IsLabPriorityFlag) {
          ccname = ccname + "top";
        }
        if (!isPacCompletFlag) {
          ccname = ccname + " completed";
        }

        if (
          cc.ColumnID === "RepeatIndicator" ||
          cc.ColumnID === "IsPlanned" ||
          cc.ColumnID === "IsLabPriority"
        ) {
          const disabledCheck = cc.ColumnID !== "RepeatIndicator"; // || !automaticPlan;
          const ukey =
            ABSCropCode +
            m.DetAssignmentID +
            MethodCode +
            UsedFor +
            SlotName +
            cc.ColumnID;
          let disableStatus = disabledCheck;

          if (disabledCheck) {
            if (!m.CanEditPlanning) disableStatus = false;
          }

          if (cc.ColumnID === "IsLabPriority") {
            row.push(
              <td
                key={cc.ColumnID}
                width={customWidth[cc.ColumnID] || baseWidth}
                className={ccname}
              >
                <div className='tableCheck'>
                  <input
                    id={ukey}
                    type='checkbox'
                    onChange={(evel) => prioFunc(evel, m)}
                    disabled={!isPacCompletFlag ? true : !disableStatus}
                    checked={m[cc.ColumnID]}
                  />
                  <label htmlFor={ukey} />
                </div>
              </td>
            );
            return null;
          }

          if (cc.ColumnID === "RepeatIndicator") {
            row.push(
              <td
                key={cc.ColumnID}
                width={customWidth[cc.ColumnID] || baseWidth}
                className={ccname}
              >
                <div className='tableCheck'>
                  <input
                    type='checkbox'
                    disabled={!disableStatus}
                    defaultChecked={m["RepeatIndicator"]}
                  />
                  <label htmlFor={ukey} />
                </div>
              </td>
            );
            return null;
          }
          row.push(
            <td
              key={cc.ColumnID}
              width={customWidth[cc.ColumnID] || baseWidth}
              className={ccname}
            >
              <div className='tableCheck'>
                <input
                  id={ukey}
                  type='checkbox'
                  onChange={(evel) => testFunc(evel, m)}
                  disabled={!isPacCompletFlag ? true : !disableStatus}
                  checked={m["flag"]}
                />
                <label htmlFor={ukey} />
              </div>
            </td>
          );
        } else {
          if (cc.ColumnID === "Remarks") {
            row.push(
              <td
                key={cc.ColumnID}
                width={customWidth[cc.ColumnID] || baseWidth}
                className={ccname}
              >
                <p
                  style={{
                    overflow: "hidden",
                    width: customWidth[cc.ColumnID]
                      ? customWidth[cc.ColumnID] - 11
                      : baseWidth - 11,
                    boxSizing: "border-box",
                  }}
                  title={m[cc.ColumnID]}
                >
                  {m[cc.ColumnID]}
                </p>
              </td>
            );
          } else {
            row.push(
              <td
                key={cc.ColumnID}
                width={customWidth[cc.ColumnID] || baseWidth}
                className={ccname}
              >
                {m[cc.ColumnID]}
              </td>
            );
          }
        }
      });

      rows.push(row);
    }
  });
  const newDataRow = [];
  return (
    <Fragment>
      <h4 className='tbl-title'>{text}</h4>
      <div className='tbl-container'>
        <div className='tbl-wrapper'>
          <div className='tbl-table'>
            <table>
              <thead style={{ overflowY: "scroll" }}>
                <tr>
                  {columns.map((c) => {
                    return (
                      <th
                        width={customWidth[c.ColumnID] || baseWidth}
                        key={c.ColumnID}
                      >
                        {c.Label}
                      </th>
                    );
                  })}
                </tr>
              </thead>
              <tbody>
                {rows.map((r, i) => (
                  <tr key={i}>{r}</tr>
                ))}
              </tbody>
            </table>
          </div>
        </div>
      </div>
    </Fragment>
  );
};

export default GroupTable;
