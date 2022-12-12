namespace Enza.PAC.Entities
{
    public class AppRoles
    {
        public const string PAC_PUBLIC = PAC_HANDLE_LAB_CAPACITY + ","
            + PAC_SO_HANDLE_CROP_CAPACITY + ","
            + PAC_APPROVE_CALC_RESULTS + ","
            + PAC_MANAGE_LAB_PREPARATION + ","
            + PAC_SO_PLAN_BATCHES + ","
            + PAC_REQUEST_LIMS + ","
            + PAC_SO_VIEWER + ","
            + PAC_LAB_EMPLOYEE;

        public const string PAC_HANDLE_LAB_CAPACITY = "pac_handlelabcapacity";
        public const string PAC_SO_HANDLE_CROP_CAPACITY = "pac_so_handlecropcapacity";
        public const string PAC_APPROVE_CALC_RESULTS = "pac_approvecalcresults";
        public const string PAC_MANAGE_LAB_PREPARATION = "pac_managelabpreparation";
        public const string PAC_SO_PLAN_BATCHES = "pac_so_planbatches";
        public const string PAC_REQUEST_LIMS = "pac_requestlims";
        public const string PAC_SO_VIEWER = "pac_so_viewer";
        public const string PAC_LAB_EMPLOYEE = "pac_labemployee";
    }
}