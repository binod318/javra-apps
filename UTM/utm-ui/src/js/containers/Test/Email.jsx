import React, { useState, useEffect } from 'react';
import { connect } from 'react-redux';
import axios from 'axios';

import {
  d_mailConfigFetch,
  d_mailConfigAppend,
  d_mailCconfigDestory
} from '../Mail/mailAction';

class Emails extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      tblWidth: 0,
      tblHeight: 0,
      data: props.email,
      total: props.total,
      pagesize: props.pagesize,
      pagenumber: props.pagenumber,
      refresh: props.refresh, // eslint-disable-line
      mode: '',
      editNode: {},
      filter: []
    };
  }

  componentDidMount() {
    this.props.fetchMail(this.props.pagenumber, this.props.pagesize, this.state.filter);
  }

  render() {
    console.log(this.props.email);

    return (
      <div className="traitContainer">
        <section className="page-action">
          <div className="right" />
        </section>
        <div className="container">
          <div className="phtable">
            <ul>
              {this.props.email.map(m => (
                <li key={m.configID}>{m.configGroup}</li>
              ))}
            </ul>
          </div>
        </div>
      </div>
    );
  }
}

const mapState = state => ({
  sideMenu: state.sidemenuReducer,
  email: state.mailResult.data,
  total: state.mailResult.total.total,
  pagenumber: state.mailResult.total.pageNumber,
  pagesize: state.mailResult.total.pageSize,
  refresh: state.mailResult.total.refresh
});
const mapDispatch = dispatch => ({
  fetchMail: (pageNumber, pageSize) =>
    dispatch(d_mailConfigFetch(pageNumber, pageSize)),
  addMailFunc: (configID, cropCode, configGroup, recipients) =>
    dispatch(d_mailConfigAppend(configID, cropCode, configGroup, recipients)),
  editMailFunc: (configID, cropCode, configGroup, recipients) =>
    dispatch(d_mailConfigAppend(configID, cropCode, configGroup, recipients)),
  deleteMailFunction: configID => dispatch(d_mailCconfigDestory(configID))
});
export default connect(
  mapState,
  mapDispatch
)(Emails);
// export default Emails;
