import React from 'react';
import { connect } from 'react-redux';
import PropTypes from 'prop-types';
// import Wrapper from '../../../../components/Wrapper/wrapper.jsx';

import Phenome from './Phenome';
import Breezys from './Breezys';
import External from './External';

class Import extends React.Component {
  constructor(props) {
    super(props);
    this.state = {
      sourceSelected: props.sourceSelected,
      existFile: props.existFile
    };
  }

  componentWillReceiveProps(nextProps) {
    if (this.props.sourceSelected !== nextProps.sourceSelected) {
      this.setState({ sourceSelected: nextProps.sourceSelected });
    }
  }

  render() {
    const { sourceSelected } = this.state;
    if (sourceSelected === 'Breezys') {
      return <Breezys {...this.state} {...this.props} />;
    }
    if (sourceSelected === 'Phenome') {
      return <Phenome {...this.state} {...this.props} />;
    }
    return <External {...this.state} {...this.props} />;
    // return null;
  }
}

const mapState = state => ({
  testTypeList: state.assignMarker.testType.list,
  materialTypeList: state.materialType,
  testProtocolList: state.testProtocol,
  materialStateList: state.materialState,
  containerTypeList: state.containerType,
  warningFlag: state.phenome.warningFlag,
  warningMessage: state.phenome.warningMessage
});

Import.defaultProps = {
  sourceSelected: ''
};
Import.propTypes = {
  existFile: PropTypes.bool.isRequired,
  sourceSelected: PropTypes.string
};

export default connect(
  mapState,
  null
)(Import);
