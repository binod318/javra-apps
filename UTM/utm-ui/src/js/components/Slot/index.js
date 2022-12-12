import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import { slotFetch, slotTestLink } from './actions/index';
import './slot.scss';

class Slot extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      testID: props.testID,
      slotID: props.slotID,
      slotList: props.slotList
    };
  }

  componentDidMount() {
    this.props.fetchSlot(this.props.testID);
  }

  componentWillReceiveProps(nextProps) {
    if (nextProps.slotList) {
      this.setState({ slotList: nextProps.slotList });
    }
  }

  slotSelect = e => {
    const { target } = e;
    const { value } = target;
    if (value !== '') {
      this.setState({
        slotID: value
      });
    }
  };

  saveLink = () => {
    const { testID, slotID } = this.state;
    this.props.toggleVisibility();
    this.props.saveSlotTestLink(testID, slotID);
  };
  unassignSlot = () => {
    const { testID } = this.state;
    this.props.toggleVisibility();
    this.props.saveSlotTestLink(testID, '');
  };

  render() {
    const { toggleVisibility, slotID: propsSlotID } = this.props;
    const { slotID, slotList } = this.state;

    const assignButton = propsSlotID == slotID || slotID === ''; // eslint-disable-line
    const selectedValue = this.state.slotID || '';

    return (
      <div className="slot-file-modal">
        <div className="slot-file-modal-content">
          <div className="slot-file-modal-title">
            <span
              id="slot_close_btn"
              onKeyDown={() => {}}
              className="slot-file-modal-close"
              onClick={toggleVisibility}
              tabIndex="0"
              role="button"
            >
              &times;
            </span>
            <span>Assign Slot to Test</span>
          </div>
          <div className="slot-file-modal-body">
            <select
              id="slot_select"
              value={selectedValue}
              onChange={this.slotSelect}
            >
              <option value="">Select</option>
              {slotList.map(item => (
                <option value={item.slotID} key={item.slotID}>
                  {item.slotName}
                </option>
              ))}
            </select>
          </div>
          <div className="slot-file-modal-footer">
            <button
              id="slot_unassign_btn"
              onClick={this.unassignSlot}
              disabled={!propsSlotID}
            >
              Unassign
            </button>
            <button
              id="slot_assign_btn"
              onClick={this.saveLink}
              disabled={assignButton}
            >
              Assign
            </button>
          </div>
        </div>
      </div>
    );
  }
}

Slot.defaultProps = {
  slotID: 0,
  slotList: []
};
Slot.propTypes = {
  slotID: PropTypes.number,
  testID: PropTypes.number.isRequired,
  toggleVisibility: PropTypes.func.isRequired,
  slotList: PropTypes.array, // eslint-disable-line react/forbid-prop-types
  fetchSlot: PropTypes.func.isRequired,
  saveSlotTestLink: PropTypes.func.isRequired
};
const mapState = state => ({
  slotID: state.rootTestID.slotID,
  slotList: state.slot
});
const mapDispatch = dispatch => ({
  fetchSlot: id => dispatch(slotFetch(id)),
  saveSlotTestLink: (testID, slotID) => dispatch(slotTestLink(testID, slotID))
});
export default connect(
  mapState,
  mapDispatch
)(Slot);
