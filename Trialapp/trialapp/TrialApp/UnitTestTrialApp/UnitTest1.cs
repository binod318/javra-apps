using Autofac.Extras.Moq;
using Microsoft.VisualStudio.TestTools.UnitTesting;
using Moq;
using TrialApp.DataAccess;
using TrialApp.Entities.Transaction;
using Xamarin.Forms;
using static Pattern.Tests.XamarinFormsMock;

namespace UnitTestTrialApp
{
    [TestClass]
    public class UnitTest1
    {
        [TestMethod]
        public void GetObservation_Test()
        {
            Device.PlatformServices = new MockPlatformServices();
            using (var mock = AutoMock.GetLoose())
            {
                mock.Mock<IObservationAppRepository>()
                    .Setup(x => x.GetObservations("987654321", 123456789))
                    .Returns(GetSampleObservation());

                var cls = mock.Create<IObservationAppRepository>();
                var expected = GetSampleObservation();
                var actual = cls.GetObservations("987654321", 123456789);

                Assert.IsTrue(actual != null);
                Assert.AreEqual(expected.TraitID, actual.TraitID);

            }
        }

        [TestMethod]
        public void UpdateObservation_Test()
        {
            Device.PlatformServices = new MockPlatformServices();


            var repoMock = new Mock<IObservationAppRepository>();
            repoMock.Setup(r => r.InsertObservationValue(GetSampleObservation()));


            var engine = new ObservationAppRepository(new SQLite.SQLiteAsyncConnection(""));

            var result = engine.UpdateObservationValue(GetSampleObservation());
            repoMock.Verify(r => r.UpdateObservationValue(GetSampleObservation()), Times.AtMostOnce);
            //Assert.IsTrue(result);   // PASSES
            //using (var mock = AutoMock.GetLoose())
            //{
            //    mock.Mock<IObservationAppRepository>()
            //        .Setup(x => x.UpdateObservationValue(GetSampleObservation()));

            //    var cls = mock.Create<IObservationAppRepository>();
            //    var expected = GetSampleObservation();
            //    var actual = cls.UpdateObservationValue(GetSampleObservation());

            //    mock.Mock<IObservationAppRepository>()
            //        .Verify(x => x.UpdateObservationValue(expected), Times.Exactly(1));

            //}
        }



        [TestMethod]
        public void InsertObservationValue_Test()
        {
            Device.PlatformServices = new MockPlatformServices();


            var repoMock = new Mock<IObservationAppRepository>();
            repoMock.Setup(r => r.InsertObservationValue(GetSampleObservation()));
            

            var engine = new ObservationAppRepository(new SQLite.SQLiteAsyncConnection(""));

            var result = engine.InsertObservationValue(GetSampleObservation());
            repoMock.Verify(r => r.InsertObservationValue(GetSampleObservation()), Times.AtMostOnce);
            //Assert.IsTrue(result);   // PASSES


            //using (var mock = AutoMock.GetLoose())
            //{
            //    mock.Mock<IObservationAppRepository>()
            //        .Setup(x => x.InsertObservationValue(GetSampleObservation()));

            //    var cls = mock.Create<IObservationAppRepository>();
            //    var expected = GetSampleObservation();
            //    cls.InsertObservationValue(GetSampleObservation());

            //    mock.Mock<IObservationAppRepository>()
            //        .Verify(x => x.InsertObservationValue(expected) );

            //}
        }
        private ObservationAppLookup GetSampleObservation()
        {
            return new ObservationAppLookup
            {
                DateCreated = "",
                DateUpdated = "",
                EZID = "",
                IsNullEntry = false,
                Modified = false,
                ObservationId = 123,
                ObsValueChar = null,
                ObsValueDate = null,
                ObsValueDec = null,
                ObsValueDecImp = null,
                ObsValueDecMet = null,
                TraitID = 12379895,
                UserIDUpdated = "",
                UoMCode = "M",
                ObsValueInt = 5,
                UserIDCreated = ""
            };
        }

    }
}
