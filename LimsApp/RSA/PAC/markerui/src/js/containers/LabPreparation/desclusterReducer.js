import { combineReducers } from 'redux';
import {
    LABDECLUSTER_DATA_ADD,
    LABDECLUSTER_COLUMN_ADD
} from './labPreparationAction';

const isFetching = (state = false, action) => {
    // switch(action.type) {
        
    // }
    return state;
};

const column = (state = [], { type, payload }) => {
    switch(type) {
        case LABDECLUSTER_COLUMN_ADD:
            return payload;
        default:
            return state;
    }
};

const data = (state = [], { type, payload }) => {
    switch (type) {
        case LABDECLUSTER_DATA_ADD:
            return payload;
        default:
            return state;
    }
};


const labDescluster = combineReducers({
    isFetching,
    column,
    data
});
export default labDescluster;
