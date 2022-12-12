using TrialApp.Common;

namespace TrialApp.Entities
{
    [System.Xml.Serialization.XmlTypeAttribute(AnonymousType = true, Namespace = "http://schemas.cordys.com/TrialPrepWsApp")]
    public  class GetTrialTokenBack
    {
        private string _password;
        public string userName { get; set; }

        public string password
        {
            get { return _password; }
            set { _password = AESEncryption.EncryptAesTest(value, "Enz@o123");
            }
        }

        public string cropCode { get; set; }

    }
    
}
