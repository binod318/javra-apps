namespace Enza.PtoV.Entities.Results
{
    public class PhenomePermissionsResult
    {
        public PhenomePermissionsResult()
        {
            Permissions = new Permission();
        }
       public Permission Permissions { get; set; }
    }
    public class Permission
    {
        public string RGID { get; set; }
    }
}