using System;
using System.IO;

namespace TrialApp.Droid
{
    //public class FileService : IFileService
    //{
    //    public void SavePicture(string name, Stream data, string location = "temp")
    //    {
    //        var documentsPath = System.Environment.GetFolderPath(System.Environment.SpecialFolder.Personal);
    //        documentsPath = Path.Combine(documentsPath, "Orders", location);
    //        Directory.CreateDirectory(documentsPath);

    //        string filePath = Path.Combine(documentsPath, name);

    //        byte[] bArray = new byte[data.Length];
    //        using (FileStream fs = new FileStream(filePath, FileMode.OpenOrCreate))
    //        {
    //            using (data)
    //            {
    //                data.Read(bArray, 0, (int)data.Length);
    //            }
    //            int length = bArray.Length;
    //            fs.Write(bArray, 0, length);
    //        }
    //    }

    //}
}