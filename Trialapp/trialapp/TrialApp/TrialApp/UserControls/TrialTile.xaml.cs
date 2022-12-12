using System;

using Xamarin.Forms;

namespace TrialApp.UserControls
{
    [ContentProperty("ContainerContent")]
    public partial class TrialTile : ContentView
    {
        private Label LblStatus;
        private Label LabelName;
        private Label LblInfo;
        public TrialTile()
        {
            InitializeComponent();
            loadControls();
        }

        private void loadControls()
        {
            var grid = new Grid
            {

                HorizontalOptions = LayoutOptions.StartAndExpand,
                RowDefinitions = {
                    new RowDefinition { Height = new GridLength(0.5, GridUnitType.Star)},
                    new RowDefinition { Height = new GridLength(0.8, GridUnitType.Star)},
                    new RowDefinition { Height = new GridLength(0.3, GridUnitType.Star)}
                },
                ColumnDefinitions =
            {
                new ColumnDefinition { Width = new GridLength(1, GridUnitType.Star) }

            }
            };
            LblStatus = new Label
            {
                FontAttributes = FontAttributes.Bold,
                Margin = new Thickness(0,5,5,0),
                TextColor = Color.White,
                HorizontalTextAlignment = TextAlignment.End
                
            };
            grid.Children.Add(LblStatus, 0, 0);
            LabelName = new Label
            {
                FontAttributes = FontAttributes.Bold,
                TextColor = Color.White,
                VerticalOptions = LayoutOptions.CenterAndExpand,
                HorizontalOptions = LayoutOptions.CenterAndExpand
            };
            grid.Children.Add(LabelName, 0, 1);


            LblInfo = new Label
            {
                Margin = new Thickness(5, 0, 5, 5),
                TextColor = Color.White,
            };
            grid.Children.Add(LblInfo, 0, 2);
            Content = grid;
        }
        

        public string Status
        {
            get { return LblStatus.Text; }
            set { LblStatus.Text = value; }
        }

        public double btnNameFontSize
        {
            get { return LabelName.FontSize; }
            set { LabelName.FontSize = value; }
        }
       

        public Color labelBG
        {
            get { return LblStatus.BackgroundColor; }
            set { LblStatus.BackgroundColor = value; }
        }

        public string Name
        {
            get { return LabelName.Text; }
            set { LabelName.Text = value; }
        }

        public string Info
        {
            get { return LblInfo.Text; }
            set { LblInfo.Text = value; }
        }

    }
}
