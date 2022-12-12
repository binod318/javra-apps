using Enza.UTM.BusinessAccess.Interfaces;
using Enza.UTM.BusinessAccess.Services;
using Enza.UTM.Common;
using Enza.UTM.Common.Exceptions;
using Enza.UTM.Common.Extensions;
using Enza.UTM.Entities.Args;
using Enza.UTM.Services.EmailTemplates;
using Quartz;
using System;
using System.Configuration;
using System.Data;
using System.Linq;
using System.Threading.Tasks;

namespace Enza.UTM.Web.Services.Scheduling.Jobs
{
    [DisallowConcurrentExecution]
    public class LeafDiskSummaryCalculationJob : IJob
    {
        private readonly UELService uelService = new UELService();
        private readonly ILeafDiskService _leafDiskService;
        private readonly ITestService _testService;
        private readonly IEmailConfigService _emailConfigService;
        private readonly IEmailService _emailService;

        public LeafDiskSummaryCalculationJob(ILeafDiskService leafDiskService, ITestService testService, IEmailConfigService emailConfigService, IEmailService emailService)
        {
            _leafDiskService = leafDiskService;
            _testService = testService;
            _emailConfigService = emailConfigService;
            _emailService = emailService;
        }

        public async Task Execute(IJobExecutionContext context)
        {
            try
            {
                var ds = await _leafDiskService.ProcessSummaryCalcuationAsync();

                //Log if there is exception for certain test/determinationid
                foreach (DataRow row in ds.Tables[0].Rows)
                {
                    var id = row["TestID"].ToString();
                    var msg = row["ErrorMessage"].ToString();

                    var exception = new BusinessException("TestID : " + id + " - " + msg);

                    uelService.LogError(exception, out _);
                }

                foreach (DataRow row in ds.Tables[1].Rows)
                {
                    var id = row["TestID"].ToInt32();
                    var name = row["TestName"].ToString();
                    var result = row["LDResultSummary"].ToString();
                    var siteName = row["SiteName"].ToString();
                    var cropCode = row["CropCode"].ToString();
                    var brStationCode = row["BreedingStationCode"].ToString();

                    var emailNotificationType = result.Contains("negative") ? EmailConfigGroups.TEST_COMPLETE_NEGATIVE : EmailConfigGroups.TEST_COMPLETE_POSITIVE;

                    //email config for email group per site
                    var config = await _emailConfigService.GetEmailConfigAsync(emailNotificationType, cropCode, brStationCode);
                    var recipients = config?.Recipients;
                    if (string.IsNullOrWhiteSpace(recipients))
                    {
                        //get default email
                        config = await _emailConfigService.GetEmailConfigAsync(emailNotificationType, cropCode);
                        recipients = config?.Recipients;
                        if (string.IsNullOrWhiteSpace(recipients))
                        {
                            //get default email
                            config = await _emailConfigService.GetEmailConfigAsync(emailNotificationType, "*");
                            recipients = config?.Recipients;
                            if (string.IsNullOrWhiteSpace(recipients))
                            {
                                //get default email
                                config = await _emailConfigService.GetEmailConfigAsync(EmailConfigGroups.DEFAULT_EMAIL_GROUP, "*");
                                recipients = config?.Recipients;
                            }
                        }

                    }

                    if (string.IsNullOrWhiteSpace(recipients))
                        return;

                    var emailList = recipients.Split(new[] { ',', ';' }, StringSplitOptions.RemoveEmptyEntries)
                        .Where(o => !string.IsNullOrWhiteSpace(o))
                        .Select(o => o.Trim());

                    //get sender
                    var from = "lab1@enzazaden.nl";
                    var configemails = ConfigurationManager.AppSettings["SH:EmailSender"];
                    var email = configemails.Split(';');
                    foreach (var _email in email)
                    {
                        var emailPerSite = _email.Split('|');
                        if (emailPerSite.Length == 2)
                        {
                            var site = emailPerSite[0];
                            if (siteName.EqualsIgnoreCase(site))
                            {
                                from = emailPerSite[1];
                                break;
                            }

                        }
                    }
                    string body;
                    if (result.ToLower().Contains("negative"))
                    {
                        var subject = $"{name} completed";
                        //get test result email body template
                        var testResultBody = EmailTemplate.GetLeafDiskTestResultEmailTemplate("negative");
                        body = Template.Render(testResultBody, new
                        {
                            TestName = name
                        });

                        await _emailService.SendEmailAsync(from, emailList, subject.AddEnv(), body);

                        //Update test status to 700(Completed)
                        await _testService.UpdateTestStatusAsync(new UpdateTestStatusRequestArgs
                        {
                            TestId = id,
                            StatusCode = 700
                        });
                    }
                    else if (result.EqualsIgnoreCase("positive"))
                    {
                        var subject = $"{name} completed with positive result";
                        var testResultBody = EmailTemplate.GetLeafDiskTestResultEmailTemplate("positive");
                        body = Template.Render(testResultBody, new
                        {
                            TestName = name
                        });

                        await _emailService.SendEmailAsync(from, emailList, subject.AddEnv(), body, "high");

                        //Update test status to 700(Completed)
                        await _testService.UpdateTestStatusAsync(new UpdateTestStatusRequestArgs
                        {
                            TestId = id,
                            StatusCode = 700
                        });
                    }
                }
            }
            catch (Exception ex)
            {
                uelService.LogError(ex, out _);
            }
        }
    }
}