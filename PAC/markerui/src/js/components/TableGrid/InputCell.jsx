import React from "react";
import PropTypes from "prop-types";
import { Cell } from "fixed-data-table-2";
import { v4 as uuidv4 } from "uuid";
import { connect } from "react-redux";

const errorStyle = {
  borderColor: "red",
};
const changeStyle = {
  borderColor: "#03a9f4",
};

class InputCell extends React.Component {
  constructor(props) {
    super(props);
    let value = "";
    const { data, rowIndex, arrayKey } = props;
    if (data[rowIndex][arrayKey] !== null) {
      const testKey = arrayKey.charAt(0) + arrayKey.slice(1);
      value = data[rowIndex][testKey];
    }

    this.state = {
      inputDisplay: !false,
      PeriodID: "",
      testKey: "",
      value,
      oldValue: value,
      focus: false,
      focusName: `nm-${rowIndex}-${arrayKey}-${props.data[rowIndex].id}`,
      changed: false,
    };
    this.myRef = React.createRef();
    this._isMounted = false;
    this.style = false;
  }
  UNSAFE_componentWillMount() {
    this._isMounted = true;
    window.addEventListener("beforeunload", this.handleWindowClose);
  }
  componentWillMount() {
    this._isMounted = false;
  }
  UNSAFE_componentWillReceiveProps(nextProps) {
    const { focusName, testKey, oldValue } = this.state;
    const { rowIndex, data, arrayKey } = nextProps;
    if (
      nextProps.focusStatus !== this.props.focusStatus &&
      focusName === nextProps.focusRef
    ) {
      const { rowIndex, data } = nextProps;
      const rowChanged = data[rowIndex];
      this.myRef.current.focus();
      this.style = true;
    }

    if (
      nextProps.status === "success" &&
      this.state.focus &&
      nextProps.focusRef == this.state.focusName
    ) {
      this.setState({ changed: false });
    }
  }

  componentWillUnmount() {
    window.removeEventListener("beforeunload", this.handleWindowClose);
  }

  change = (e) => {
    const {
      target: { type, name, value },
    } = e;
    const { rowIndex, data } = this.props;
    const { PeriodID, testKey, oldValue, changed } = this.state;
    const rowChanged = data[rowIndex];

    switch (type) {
      case "number":
        if (value > -1) {
          if (this._isMounted) {
            this.setState({
              changed: true,
              value: value > -1 ? value : 0,
            });
          }
          this.props.change(rowIndex, testKey, value, rowChanged, oldValue);
        }
        break;
      case "text":
        if (this._isMounted) this.setState({ value });
        this.props.change(rowIndex, testKey, value, rowChanged, oldValue);
        break;
      default:
    }
  };

  coverFunction = (e) => {
    const { type, name, value } = e.target;
    const { rowIndex, data } = this.props;
    const { PeriodID, testKey, oldValue } = this.state;
    const rowChanged = data[rowIndex];
    if (value === oldValue) return null;

    if (this.state.focusName !== this.props.focusRef) {
      this.props.refFunc(this.state.focusName);
    }

    switch (type) {
      case "number":
        if (value > -1) {
          if (this._isMounted) {
            this.setState({ value: value > -1 ? value : 0 });
          }
          this.props.change(rowIndex, testKey, value, rowChanged, oldValue);
          if (this.props.blur && typeof this.props.blur === "function") {
            this.testFunction(rowChanged, testKey, value);
          }
        }
        break;
      default:
    }
  };

  testFunction = (rowChanged, testKey, value) => {
    this.props.blur([
      {
        CropMethodID: rowChanged.CropMethodID,
        PeriodID: testKey,
        Value: value,
      },
    ]);
  };

  click = () => {
    if (this._isMounted) this.setState({ inputDisplay: true });
  };

  blur = (e) => {
    if (!this._isMounted) return null;
    return null;
  };
  focus = (e) => {
    e.target.select();
    if (this.props.setFocusName) {
      this.props.setFocusName(e.target.name);
    }
    const { rowIndex, arrayKey, data } = this.props;
    const { focusName } = this.state;
    const { PeriodID } = data[rowIndex];
    const testKey = arrayKey.charAt(0) + arrayKey.slice(1);
    if (this._isMounted) this.setState({ PeriodID, testKey, focus: true });
  };

  applyToAll = () => {
    const { value, testKey } = this.state;
    this.props.applyToAll(testKey, value);
  };

  handleWindowClose = (e) => {
    if (this._isMounted) this.setState({ focus: false });
    return null;
  };

  render() {
    const { rowIndex, data, arrayKey } = this.props;
    const { inputDisplay, focus, value } = this.state;

    let display = "";
    if (data[rowIndex][arrayKey] !== null) {
      const testKey = arrayKey.charAt(0).toLowerCase() + arrayKey.slice(1);
      display = data[rowIndex][arrayKey];
    }

    // rowType options are added / undefined ( added refores to last 4 row that are added)
    if (data[rowIndex].rowType !== undefined) {
      return <Cell>{display}</Cell>;
    }

    if (arrayKey === "Remarks") {
      return (
        <Cell>
          <input
            tabIndex={rowIndex}
            key='rowIndex'
            type='text'
            name='text'
            value={display}
            onClick={this.click}
            onChange={this.change}
            readOnly={!inputDisplay}
            onFocus={this.focus}
          />
        </Cell>
      );
    }

    const namename = `nm-${rowIndex}-${arrayKey}-${data[rowIndex].id}`;

    let match = false;
    this.props.errRef.map((s) => {
      if (s == this.state.focusName) match = true;
    });

    return (
      <Cell className='tableInputSampleNr' key={namename}>
        <div style={{ display: "flex" }}>
          <input
            tabIndex={rowIndex}
            key={namename}
            type='number'
            name={namename}
            onBlur={(e) => {}}
            value={display}
            onChange={this.change}
            onKeyUp={(e) => {
              const KEYPRESS = 13;
              if (e.keyCode === KEYPRESS && e.target.value !== "") {
                this.coverFunction(e);
              }
            }}
            readOnly={!inputDisplay}
            onClick={this.click}
            onFocus={this.focus}
            ref={this.myRef}
            style={match ? errorStyle : this.state.changed ? changeStyle : {}}
            onWheel={(e) => {
              e.preventDefault();
              // for new browser
              e.currentTarget.blur();
            }}
          />
          {namename === this.props.focusName && this.props.toAllFlag && (
            <button className='to-all' onClick={this.applyToAll} tabIndex='-1'>
              To all
            </button>
          )}
        </div>
      </Cell>
    );
  }
}
InputCell.defaultProps = {
  data: [],
  arrayKey: "",
  rowIndex: 0,
};
InputCell.propTypes = {
  applyToAll: PropTypes.func,
  change: PropTypes.func.isRequired,
  rowIndex: PropTypes.number,
  data: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  arrayKey: PropTypes.oneOfType([PropTypes.string, PropTypes.number]),
};

const mapState = (state) => ({
  noteStatus: state.notification.status,
  errRef: state.capacity.errList,
  status: state.capacity.status,
});
export default connect(mapState, null)(InputCell);
