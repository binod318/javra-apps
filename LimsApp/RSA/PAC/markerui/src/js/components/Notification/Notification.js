import React from "react";
import { connect } from "react-redux";
import PropTypes from "prop-types";
import "./notification.scss";

class Notification extends React.Component {
  constructor(props) {
    super(props);
    this.escFunction = this.escFunction.bind(this);
    this.timer = null;
    this.time = 1000;
  }

  componentDidMount() {
    document.addEventListener("keydown", this.escFunction, false);
  }
  componentWillReceiveProps(np) {
    if (np.messageType === 4) {
      this.timer = setTimeout(this.props.close, this.time);
    }
  }
  componentWillUnmount() {
    document.removeEventListener("keydown", this.escFunction, false);
    clearTimeout(this.timer);
  }

  escFunction(event) {
    this.props.close();
    if (event.keyCode === 27) {
    }
  }

  render() {
    const { code, messageType, status, notificationType, close } = this.props;
    let { commonMessage, message } = this.props;

    if (!status) return <span />;

    if (messageType === 1) message = commonMessage || "Contact you Admin."; // eslint-disable-line

    let icon = <i className='demo-icon icon-attention error' />;
    let title = <span>Error {code ? `: ${code}` : ""}</span>;
    if (notificationType === 1) {
      icon = <i className='demo-icon icon-info-circled info' />;
      title = <span>Info</span>;
    }
    if (notificationType === 2) {
      icon = <i className='demo-icon icon-ok-circled ok' />;
      title = <span>Success</span>;
    }
    if (notificationType === 3) {
      icon = <i className='demo-icon icon-attention-triangle warning' />;
      title = <span>Alert</span>;
    }
    let arrayMessage = "";
    if (Array.isArray(message)) {
      arrayMessage = message.map((er, i) => <li key={i}>{er}</li>); // eslint-disable-line
    } else {

      if(message.includes('<br>')) {
        const myArray = message.split('<br>');
        arrayMessage = <li>{myArray[0]}<br/>{myArray[1]}</li>;
      } else
         arrayMessage = <li>{message}</li>;
    }

    if (messageType === 3) {
      return (
        <div className='timerNotificationWrap'>
          <div className='timerNotification'>
            <div className='notificationTitle '>
              {icon}
              <span>{title}</span>
              <i
                className='demo-icon icon-cancel close'
                role='button'
                id='notification_success_close'
                style={{ float: "right " }}
                onKeyDown={() => {}}
                tabIndex='0'
                onClick={() => close()}
              />
            </div>
            <div className='notificationBody'>
              <ul style={{ paddingLeft: "20px" }}>{arrayMessage}</ul>
            </div>
          </div>
        </div>
      );
    }

    return (
      <div className='notificationWrap'>
        <div className='notificationContent '>
          <div className='notificationTitle '>
            {icon}
            <span>{title}</span>
            <i
              className='demo-icon icon-cancel close'
              role='button'
              id='notification_success_close'
              onKeyDown={() => {}}
              tabIndex='0'
              onClick={() => close()}
            />
          </div>
          <div className='notificationBody'>
            <ul style={{ paddingLeft: "20px" }}>{arrayMessage}</ul>
          </div>
        </div>
      </div>
    );
  }
}

Notification.defaultProps = {
  messageType: null,
  notificationType: null,
};
Notification.propTypes = {
  code: PropTypes.oneOfType([PropTypes.string, PropTypes.number]).isRequired,
  message: PropTypes.oneOfType([PropTypes.string, PropTypes.array]).isRequired,
  commonMessage: PropTypes.oneOfType([PropTypes.string, PropTypes.array])
    .isRequired,
  messageType: PropTypes.number,
  notificationType: PropTypes.number,
  close: PropTypes.func.isRequired,
  status: PropTypes.bool.isRequired,
};
const mapStateToProps = (state) => ({
  code: state.notification.code,
  commonMessage: state.notification.commonMessage,
  messageType: state.notification.messageType,
  message: state.notification.message,
  status: state.notification.status,
  notificationType: state.notification.notificationType,
});
const mapDispatchToProps = (dispatch) => ({
  close() {
    dispatch({
      type: "NOTIFICATION_HIDE",
    });
  },
});
export default connect(mapStateToProps, mapDispatchToProps)(Notification);
