import React from "react";
import { Cell } from "fixed-data-table-2";

class CollapseCell extends React.Component {
    constructor(props) {
        super(props);
    }

    render() {
        const {
            rowIndex,
            columnKey,
            collapsedRows,
            callback,
            ...props
        } = this.props;
        return (
            <Cell {...props}>
                <a onClick={() => callback(rowIndex)} style={{ fontSize: 'larger' }}>
                    {collapsedRows.has(rowIndex) ? '\u2212' : '\u002B'}
                </a>
            </Cell>
        );
    }
}
export default CollapseCell;
