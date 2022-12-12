using System;
using System.Collections.Generic;
using System.Text;

namespace TrialApp
{
    public interface IMessage
    {
        void LongTime(string message);
        void ShortTime(string message);
    }
    //public interface IFileService
    //{
    //    void SavePicture(string name, Stream data, string location = "temp");
    //}
}
