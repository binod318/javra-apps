using Syncfusion.SfDataGrid.XForms;
using Xamarin.Forms;

namespace TrialApp
{
    public class CustomGridStyle : DataGridStyle
    {
        public CustomGridStyle()
        {
                
        }

        public override Color GetAlternatingRowBackgroundColor()
        {
            return Color.LightGray;
        }

        public override Color GetCurrentCellBorderColor()
        {
            return Color.Pink;
        }

        public override float GetBorderWidth()
        {
            return 2;
        }

        public override Color GetHeaderBorderColor()
        {
            return Color.LightGray;
        }

        public override float GetHeaderBorderWidth()
        {
            return 2;
        }

        public override GridLinesVisibility GetGridLinesVisibility()
        {
            return GridLinesVisibility.Both;
        }

        public override Color GetSelectionBackgroundColor()
        {
            return base.GetSelectionBackgroundColor();
        }
        
    }
}
