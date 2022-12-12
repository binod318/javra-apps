using System;

namespace TrialApp.Entities.ServiceResponse
{
    public class GetTrialTokenBackResponse
    {

        public tuple tuple { get; set; }

    }

    public class tuple
    {

        public old old { get; set; }
    }
    public class old
    {
        public TokenInformation TokenInformation { get; set; }
    }
    public class TokenInformation
    {
        public string Token { get; set; }
        public DateTime IssueDate { get; set; }
        public DateTime ExpiryDate { get; set; }
    }
}
