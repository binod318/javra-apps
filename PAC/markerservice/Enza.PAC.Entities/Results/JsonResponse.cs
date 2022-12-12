using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Enza.PAC.Entities.Results
{
    public class JsonResponse
    {
        public JsonResponse()
        {
            Errors = new List<Error>();
        }
        public object Data { get; set; }
        public List<Error> Errors { get; set; }
        public string Message { get; set; }
        public int Total { get; set; }

        public void AddError(string error)
        {
            Errors.Add(new Error
            {
                Type = 1,
                Message = error
            });
        }        
        public void AddWarning(string warning)
        {
            Errors.Add(new Error
            {
                Type = 2,
                Message = warning
            });
        }
    }
    public class Error
    {
        /// <summary>
        /// Used to distinguish the type of message sent
        /// </summary>
        /// <remarks>
        /// type of error
        /// </remarks>
        /// <value>
        /// 1: error
        /// 2: warning
        /// 3: info
        /// </value>
        public int Type { get; set; }
        public string Message { get; set; }
    }

}
