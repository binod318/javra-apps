/**
 * Created by sushanta on 4/12/18.
 */
import React from 'react';
import { decorators } from 'react-treebeard';
// import PropTypes from 'prop-types';

const modifiedDecorators = {
  ...decorators,
  Header: obj => {
    const imgBaseUrl = `${services.PHENOME_BASE_URL}/static/images/icons/`; // eslint-disable-line
    // services.PHENOME_BASE_URL + '/static/images/icons/';
    const { node, style } = obj;
    const listObj = '26,27,28';
   
    return (
      <div
        style={{
          ...style.base,
          marginLeft: node.children === null ? '19px' : 0
        }}
      >
        <div style={style.title}>
          <span>
            <img
              alt="img icon"
              style={{ margin: '0 3px -3px 0' }}
              src={`${imgBaseUrl}${node.img}`}
            />
          </span>
          <span style={{backgroundColor: ((listObj.split(',').indexOf(node.objectType) > -1 ) && node.active) ? '#ceefff' : ''}}>{node.name}</span>
        </div>
      </div>
    );
  }
};

export default modifiedDecorators;
