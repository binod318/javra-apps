const initStatus = {
  initial: null,
  main: null,
  convert: null,
  unmapcolumn: null,
  update: null,
  login: null,
  relation: null,
  result: null,
  import: null,
  product: null,
  varmas: null,
  delete: null,
  replace: null,
  recipocal: null,
  mail: null,
  pedigree: null,
  from: '',
  message: ''
};
const status = (state = initStatus, action) => {
  switch (action.type) {
    case 'MAIN_PROCESSING':
      return Object.assign({}, state, {
        main: 'procesing',
        from: '',
        message: ''
      });
    case 'MAIN_SUCCESS':
      return Object.assign({}, state, {
        main: 'success',
        from: '',
        message: ''
      });
    case 'MAIN_ERROR':
      return Object.assign({}, state, {
        main: 'error',
        from: 'main',
        message: action.message
      });

    case 'VARMAS_PROCESSING':
      return Object.assign({}, state, {
        varmas: 'procesing',
        from: '',
        message: ''
      });
    case 'VARMAS_SUCCESS':
      return Object.assign({}, state, {
        main: 'success',
        varmas: 'success',
        from: 'main',
        message: action.message || ''
      });
    case 'VARMAS_ERROR':
      return Object.assign({}, state, {
        main: 'error',
        varmas: 'error',
        from: 'main',
        message: action.message || ''
      });

    case 'DELETE_PROCESSING':
      return Object.assign({}, state, {
        delete: 'procesing',
        from: '',
        message: ''
      });
    case 'DELETE_SUCCESS':
      return Object.assign({}, state, {
        main: 'success',
        delete: 'success',
        from: 'main',
        message: action.message || ''
      });
    case 'DELETE_RESET':
      return Object.assign({}, state, {
        delete: null,
        from: '',
        message: ''
      });
    case 'DELETE_ERROR':
      return Object.assign({}, state, {
        main: 'error',
        delete: 'error',
        from: 'main',
        message: action.message || ''
      });

    case 'CONVERT_PROCESSING':
      return Object.assign({}, state, {
        convert: 'procesing',
        from: '',
        message: ''
      });
    case 'CONVERT_SUCCESS':
      return Object.assign({}, state, {
        convert: 'success',
        from: '',
        message: ''
      });
    case 'CONVERT_ERROR':
      return Object.assign({}, state, {
        convert: 'error',
        from: 'convert',
        message: action.message
      });

    case 'UNMAP_PROCESSING':
      return Object.assign({}, state, {
        unmapcolumn: 'procesing',
        from: '',
        message: ''
      });
    case 'UNMAP_SUCCESS':
      return Object.assign({}, state, {
        unmapcolumn: 'success',
        from: 'unmapcolumn',
        message: action.message
      });
    case 'UNMAP_ERROR':
      return Object.assign({}, state, {
        unmapcolumn: 'error',
        from: 'unmapcolumn',
        message: action.message
      });

    case 'FETCHING_RELATION_PROCESSING':
      return { ...state, relation: 'procesing' };
    case 'FETCHING_RELATION_SUCCESS':
      return { ...state, relation: 'success' };
    case 'FETCHING_RELATION_ERROR':
      return Object.assign({}, state, {
        update: 'error',
        relation: 'error',
        from: 'relation',
        message: action.message
      });

    case 'FETCHING_RELATION_UPDATE_PROCESSING':
      return Object.assign({}, state, {
        update: 'procesing',
        from: '',
        message: ''
      });
    case 'FETCHING_RELATION_UPDATE_SUCCESS':
      return Object.assign({}, state, {
        update: 'success'
      });
    case 'FETCHING_RELATION_UPDATE_ERROR':
      return Object.assign({}, state, {
        update: 'error',
        from: 'update',
        message: action.message
      });

    case 'REQUEST_LOGIN_PROCESSING':
      return Object.assign({}, state, {
        login: 'procesing',
        from: '',
        message: ''
      });
    case 'REQUEST_LOGIN_SUCCESS':
      return Object.assign({}, state, {
        login: 'success',
        from: '',
        message: ''
      });
    case 'REQUEST_LOGIN_ERROR':
      return Object.assign({}, state, {
        login: 'error',
        from: 'login',
        message: action.message
      });

    case 'RESULT_ADD_PROCESSING':
      return Object.assign({}, state, {
        result: 'procesing',
        from: '',
        message: ''
      });
    case 'RESULT_ADD_PROCESSING_CONTINUE':
      return Object.assign({}, state, {
        result: '',
        from: '',
        message: ''
      });
    case 'RESULT_ADD_SUCCESS':
      return Object.assign({}, state, {
        result: 'success',
        message: action.message
      });
    case 'RESULT_ADD_ERROR':
      return Object.assign({}, state, {
        result: 'error',
        from: 'result',
        message: action.message
      });

    case 'IMPORT_PROCESSING':
      return Object.assign({}, state, {
        import: 'procesing',
        from: '',
        message: ''
      });
    case 'IMPORT_SUCCESS':
      return Object.assign({}, state, {
        import: 'success',
        from: '',
        message: ''
      });
    case 'IMPORT_ERROR':
      return Object.assign({}, state, {
        import: 'error',
        from: 'import',
        message: action.message
      });

    case 'PRODUCT_PROCESSING':
      return Object.assign({}, state, {
        product: 'procesing',
        from: '',
        message: ''
      });
    case 'PRODUCT_SUCCESS':
      return Object.assign({}, state, {
        product: 'success',
        from: '',
        message: ''
      });
    case 'PRODUCT_ERROR':
      return Object.assign({}, state, {
        product: 'error',
        from: 'product',
        message: action.message
      });

    case 'REPLACE_PROCESSING':
      return Object.assign({}, state, {
        replace: 'procesing',
        from: '',
        message: ''
      });
    case 'REPLACE_SUCCESS':
      return Object.assign({}, state, {
        replace: 'success',
        from: 'replace',
        message: action.message
      });
    case 'REPLACE_ERROR':
      return Object.assign({}, state, {
        replace: 'error',
        from: 'replace',
        message: action.message
      });

    case 'RECIPOCAL_PROCESSING':
      return Object.assign({}, state, {
        main: 'procesing',
        from: '',
        message: ''
      });
    case 'RECIPOCAL_SUCCESS':
      return Object.assign({}, state, {
        main: 'success',
        from: 'main',
        message: action.message
      });
    case 'RECIPOCAL_ERROR':
      return Object.assign({}, state, {
        main: 'error',
        from: 'main',
        message: action.message
      });

    case 'MAIL_PROCESSING':
      return Object.assign({}, state, {
        mail: 'procesing',
        from: '',
        message: ''
      });
    case 'MAIL_SUCCESS':
      return Object.assign({}, state, {
        mail: 'success',
        from: 'mail',
        message: action.message || ''
      });
    case 'MAIL_ERROR':
      return Object.assign({}, state, {
        mail: 'error',
        from: 'mail',
        message: action.message
      });

    case 'PEDIGREE_PROCESSING':
      return Object.assign({}, state, {
        pedigree: 'procesing',
        from: 'main',
        message: ''
      });
    case 'PEDIGREE_SUCCESS':
      return Object.assign({}, state, {
        pedigree: 'success',
        from: 'main',
        message: action.message || ''
      });
    case 'PEDIGREE_ERROR':
      return Object.assign({}, state, {
        pedigree: 'error',
        main: 'error',
        from: 'main',
        message: action.message
      });
    case 'RESET_ERROR':
      return initStatus;

    default:
      return state;
  }
};
export default status;
