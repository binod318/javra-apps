import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
import './savedialogue.scss';
import { saveConfigName } from './actions'

class SaveDialogue extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      testID: props.testID,
      title: props.title,
      text: props.value
    };
  }

  change = e => {
    this.setState({ text: e.target.value });
  };

  save = () => {
    const { testID, text } = this.state;
    this.props.toggleVisibility();
    this.props.saveConfigName(testID, text);
  };

  render() {
    const { toggleVisibility } = this.props;
    const { title } = this.state;

    return (
      <div className="saveDialogueWrap">
        <div className="saveDialogueContent">
          <div className="saveDialogueTitle">
            <span>{title}</span>
            <i
              role="presentation"
              className="demo-icon icon-cancel close"
              onClick={toggleVisibility}
              title="Close"
            />
          </div>
          <div className="saveDialogueBody">
            <input
              value={this.state.text}
              ref={input => {
                this.remarksInput = input;
                return null;
              }}
              onChange={this.change}
            />
          </div>
          <div className="saveDialogueFooter">
              <button onClick={this.save} title="Save" disabled={this.state.text === ""}>
                Save
              </button>
          </div>
        </div>
      </div>
    );
  }
}

SaveDialogue.propTypes = {
  testID: PropTypes.number.isRequired,
  toggleVisibility: PropTypes.func.isRequired
};

const mapState = state => ({
  testID: state.rootTestID.testID,
});

const mapDispatch = dispatch => ({
  saveConfigName: (testID, name) => dispatch(saveConfigName(testID, name))
});
export default connect(
  mapState,
  mapDispatch
)(SaveDialogue);
