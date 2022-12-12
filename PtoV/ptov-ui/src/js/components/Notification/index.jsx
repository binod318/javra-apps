import React from "react";
import { connect } from "react-redux";
import shortid from "shortid";
import PropTypes from "prop-types";

const Notification = ({ status, close, where }) => {
  const { message } = status;
  if (message === "") {
    return null;
  }

  const source = status.from;
  const type = status[source];
  const Red = "#fd8484";
  const Green = "#8fde39";


  if (where !== source) {
    return null;
  }


  if (source === "result" && type === "error") {
    return null;
  }

  /*
   * If source of notification is login / import
   * PopUp notification will not appear
   * I will appear in Form itself.
   */
  if (source === "login" || source === "import") {
    return null;
  }

  let style = {};
  switch (type) {
    case "error":
      style = Object.assign(
        {},
        {
          borderColor: Red
        }
      );
      break;
    case "success":
      style = Object.assign(
        {},
        {
          borderColor: Green
        }
      );
      break;
    default:
  }

  const msgIsArray = Array.isArray(message);
  let listMsg = "";
  if (msgIsArray) {
    listMsg = message.map(m => (
      <li key={shortid.generate().substr(1, 3)}>{m}</li>
    ));
  }

  return (
    <div className="nWrapper">
      <div className="nBody" style={style}>
        <div className="message">
          {msgIsArray ? <ul> {listMsg} </ul> : message}
        </div>
        <div className="nAct">
          <i
            role="button"
            tabIndex={0}
            onKeyPress={() => {}}
            className="icon icon-cancel"
            onClick={() => close()}
          />
        </div>
      </div>
    </div>
  );
};

Notification.defaultProps = {
  where: ""
};
Notification.propTypes = {
  status: PropTypes.object.isRequired, // eslint-disable-line
  close: PropTypes.func.isRequired,
  where: PropTypes.string
};

const mapState = state => ({
  status: state.status
});
export default connect(
  mapState,
  null
)(Notification);
