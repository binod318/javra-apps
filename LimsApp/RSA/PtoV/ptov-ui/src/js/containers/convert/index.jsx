/*!
 *
 * CONVERT SCREEN
 * ------------------------------
 * This item is about showing what the data looks like, ifthe data looks like if the data has been translated / converted from trait to screening values. So far we see the following features:
 * 1. Change view from Trait attribute to Screening fields attribute on choose of button
 * 2. Show different color on non transformable Columns (No Result mapping between Trait and Screening fields)
 * 3. Show diffrerent color on non translatable cells
 * 4. Show delete button to remove column if there is no relation
 *
 */
import { connect } from 'react-redux';
import ConvertComponent from './convert';
import { convertProcessing, convertFetch, convertImportPhenome, convertFilterAdd, convertFilterRemove, convertFilterClear, convertColumnRemove } from './action';

const mapState = state => ({
  status: state.status,
  files: state.user.crops,
  fileSelected: state.main.files,
  fileStatus: state.main.fileStatus,

  plant: state.convert.plant,
  column: state.convert.column,
  total: state.convert.total.total,
  pageNumber: state.convert.total.pageNumber,
  pageSize: state.convert.total.pageSize,

  filterList: state.convert.filter,
  sort: state.convert.sort
});
const mapDispatch = dispatch => ({
  selectReset: () => dispatch({ type: "SELECT_BLANK" }),
  fileSelect: cropSelected => dispatch({ type: "FILE_SELECT", cropSelected }),
  fetchFileStatus: status => dispatch({ type: "FILE_STATUS", status }),
  fetchMain: (fileName, pageNumber, pageSize, filter, sorting) => {
    convertProcessing();
    dispatch(convertFetch(fileName, pageNumber, pageSize, filter, sorting));
  },
  fetchData: (objectType, objectID, researchGroupID, pageSize) => dispatch(convertImportPhenome(objectType, objectID, researchGroupID, pageSize)),
  filterAdd: obj => dispatch(convertFilterAdd(obj)),
  filterRemove: name => dispatch(convertFilterRemove(name)),
  filterClear: () => dispatch(convertFilterClear()),
  resetError: () => {
    dispatch({
      type: 'RESET_ERROR'
    });
  },
  deleteColumn: (cropCode, columns) => {
    dispatch({
      type: 'UNMAP_COLUMN',
      cropCode, columns
    });
  }
});
export default connect(
  mapState,
  mapDispatch
)(ConvertComponent);
