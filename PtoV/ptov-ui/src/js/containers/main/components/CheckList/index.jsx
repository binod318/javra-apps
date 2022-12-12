import React, { useState } from 'react';
import { connect } from 'react-redux';
import shortid from 'shortid';
import PropTypes from 'prop-types';
import Wrapper from '../../../../components/Wrapper';
import './checklist.scss';

const List = ({ optionList, message, obj, mainGID, skipGID, sendToVarmas2Func, close }) => {

  const [sel, setSel] = useState(0);

  const handleChange = e => {
    const { name, value } = e.target;
    setSel(value);
  };

  const createNew = () => {
    sendToVarmas2Func([{ ...obj, newGID: mainGID, mainGID, skipGID, forcedBit: true }]);
  };

  const existing = () => {
    const { gid: newGID } = optionList[sel];
    sendToVarmas2Func([{ ...obj, newGID, mainGID, skipGID, forcedBit: true }]);
  };

  return (
    <Wrapper display="add">
      <div className="formWrap" style={{ width: '600px' }}>
        <div className="formTitle">
          {message}
        </div>
        <div className="modalBody">
          <table className={optionList.length < 2 ? 'noScroller' : 'scroller'}>
            <thead>
              <tr>
                <th>&nbsp;</th>
                <th>eNumber</th>
                <th>GID</th>
                <th>VarietyNr</th>
              </tr>
            </thead>
            <tbody>
              {optionList.map((d, i) => (
                <tr key={d.varietyID}>
                  <td>
                    <input
                      type="radio"
                      name="newGID"
                      value={i}
                      defaultChecked={sel === i}
                      onChange={handleChange}
                    />
                  </td>
                  <td>{d.eNumber}</td>
                  <td>{d.gid}</td>
                  <td>{d.varietyNr}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="formAction">
          <button onClick={close}>Cancel</button>
          <button onClick={existing}>Use existing parentline</button>
          <button onClick={createNew}>Create new parentline</button>
        </div>
      </div>
    </Wrapper>
  );
};

const mapState = state => ({
  message: state.main.sendToVarmasConfirm.msg,
  mainGID: state.main.sendToVarmasConfirm.mainGID,
  optionList: state.main.sendToVarmasConfirm.data || [],
  obj: state.main.sendToVarmasConfirm.obj || {},
  skipGID: state.main.sendToVarmasConfirm.skipGID || []
});
const mapDispatch = dispatch => ({
  sendToVarmas2Func: row => {
    dispatch({
      type: 'POST_VARMAS_2',
      row
    });
  }
});
export default connect(
  mapState,
  mapDispatch
)(List);
