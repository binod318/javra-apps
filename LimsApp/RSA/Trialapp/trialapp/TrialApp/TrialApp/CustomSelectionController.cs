using Syncfusion.SfDataGrid.XForms;
using System.Threading.Tasks;
using TrialApp.ViewModels;

namespace TrialApp
{
    public class CustomSelectionController : GridSelectionController
    {
        private SfDataGrid dataGrid;
        public CustomSelectionController(SfDataGrid dataGrid) : base(dataGrid)
        {
            this.dataGrid = dataGrid;
            this.SelectedRows = new GridSelectedRowsCollection();
        }


        protected override async void ProcessKeyDown(string keyCode, bool isCtrlKeyPressed, bool isShiftKeyPressed)
        {
            var keyCodeList = "Left,Right,Up,Down,Tab";

            if (keyCodeList.Contains(keyCode))
            {
                var row = DataGrid.CurrentCellManager.RowColumnIndex.RowIndex;
                var col = DataGrid.CurrentCellManager.RowColumnIndex.ColumnIndex;

                switch (keyCode)
                {
                    case "Left":
                        col--;
                        break;
                    case "Right":
                        col++;
                        break;
                    case "Up":
                        row--;
                        break;
                    case "Down":
                        row++;
                        break;
                    case "Tab":
                        {
                            var bindingContext = dataGrid.BindingContext as VarietyPageTabletViewModel;
                            if (bindingContext.UpdateModeText == "Horizontal")
                            {
                                //reverse navigation with shift press
                                if (isShiftKeyPressed)
                                    col--;
                                else
                                    col++;
                            }
                            else
                            {
                                //reverse navigation with shift press
                                if (isShiftKeyPressed)
                                    row--;
                                else
                                    row++;
                            }
                        }
                        break;
                    default:
                        break;
                }

                var totalRows = dataGrid.View.Records.Count;
                var totalCols = dataGrid.Columns.Count;

                if (row > 0 && row <= totalRows && col > 0 && col <= totalCols)
                {
                    var selectedCol = dataGrid.Columns[col];
                    if (selectedCol.AllowEditing)
                    {
                        dataGrid.EndEdit();

                        await Task.Delay(200);
                        dataGrid.BeginEdit(row, col);
                    }
                }
            }
            else
            {
                // default key action
                base.ProcessKeyDown(keyCode, isCtrlKeyPressed, isShiftKeyPressed);
            }
        }
    }
}
