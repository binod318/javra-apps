using System.IO;
using Newtonsoft.Json;

namespace Enza.Services.Core.Serialization
{
    public class NullJsonWriter : JsonTextWriter
    {
        public NullJsonWriter(TextWriter writer) : base(writer)
        {
        }

        public override void WriteNull()
        {
            WriteValue(string.Empty);
        }
    }
}