using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

using Xamarin.Forms;

namespace TrialApp.UserControls
{
    [ContentProperty("ContainerContent")]
    public partial class SharedTile : ContentView
    {
        public EventHandler OnClick;
        public SharedTile()
        {
            InitializeComponent();
            
            OnClick += OnTileClick(null,null);
        }

        private void BtnName_Clicked(object sender, EventArgs e)
        {
            OnClick(sender, e);
        }

        private EventHandler OnTileClick(object sender, EventArgs args)
        {
            
            return null;   
        }

        public string Status
        {
            get { return LblStatus.Text; }
            set { LblStatus.Text = value; }
        }

        public string Name
        {
            get { return BtnName.Text; }
            set { BtnName.Text = value; }
        }

        public string Info
        {
            get { return LblInfo.Text; }
            set { LblInfo.Text = value; }
        }
        
    }
}
