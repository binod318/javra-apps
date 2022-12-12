using System;
using System.Collections.Generic;
using System.Dynamic;
using System.Globalization;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Enza.DataAccess;
using Microsoft.Data.Sqlite;
using TrialApp.Common;
using TrialApp.Common.Extensions;
using TrialApp.Entities.Transaction;

namespace TrialApp.DataAccess
{
    public class ObservationAppRepository1 : Repository1<ObservationAppLookup>
    {
        //static string connectionString = $"Data Source={DbPath.GetTransactionDbPath()}";
        public ObservationAppRepository1() : base($"Data Source={DbPath.GetTransactionDbPath()}")
        {
        }

        //public ObservationAppRepository1(SqliteConnection connection) : base(connection)
        //{
        //}

        public async Task GetObsevationdataAsync(List<Entities.Master.Trait> traits, List<dynamic> itemSource, string historyVal,int ezID, Dictionary<string,int> indexedEzIDs)
        {
            if(traits.Any())
            {
                if (DbContextAsync().State != System.Data.ConnectionState.Open)
                    await DbContextAsync().OpenAsync();
                //var UoMQuery =  App.UoM == "Metric" ? "v1.ObsValueMet " : "v1.ObsValueImp ";
                string observationQuery = "";
                if (historyVal != "")
                {
                    if (historyVal != "Latest_Obs")
                        observationQuery = " (SELECT * from [ObservationApp] AS [data] where datecreated = '" + historyVal.Split('|')[0] + "' and useridcreated = '" + historyVal.Split('|')[1] + "'  ) as v1 ";
                    else
                        observationQuery = "( SELECT * from [ObservationApp] AS [data] where "
                + " case when (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and modified = 1 )  is not null "
                + " then DateCreated = (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and modified = 1 )  and modified = 1 "
                + " else case when (select DateCreated from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and observationid is null) is not null "
                + " then  DateCreated = (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and observationid is null) "
                + " else case when  ( select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID) is not null "
                + " then DateCreated= ( select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID)  end end end " +
                    ") as v1  ";

                }
                else
                    observationQuery = "( SELECT * from [ObservationApp] AS [data] where "
                + " case when (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and modified = 1 )  is not null "
                + " then DateCreated = (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and modified = 1 )  and modified = 1 "
                + " else case when (select DateCreated from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and observationid is null) is not null "
                + " then  DateCreated = (select max (DateCreated) from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and observationid is null) "
                + " else case when  ( select DateCreated from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and DateCreated = date('now') ) is not null "
                + " then DateCreated= ( select DateCreated from observationapp where  EZID = [data].EZID  and TraitID = [data].TraitID and DateCreated = date('now'))  end end end " +
                    "AND   ( [data].DateCreated = date('now')  OR [data].Modified = 1 )) as v1  ";
                var query = "select  TrialEntryApp.EZID";

                foreach (var _trait in traits)
                {
                    var selectValue = "";
                    switch (_trait.DataType.ToText().ToUpper())
                    {
                        case "I":
                            selectValue = "V1.ObsValueInt";
                            break;
                        case "D":
                            selectValue = "V1.ObsValueDate";
                            break;
                        case "A":
                            if (UnitOfMeasure.SystemUoM == "Imperial")
                                selectValue = "V1.ObsValueDecImp";
                            else                                
                                selectValue = "V1.ObsValueDecMet";
                            break;
                        default:
                            selectValue = "V1.ObsValueChar";
                            break;

                           
                    }
                    query = query + ", max( case when v1.TraitID = " + _trait.TraitID+
                           " then " + selectValue + " else null end ) as '" + _trait.TraitID + "'";


                }
                
                //for (var i = 0; i < traits.Count(); i++)
                //{
                //    query = query + ", max( case when v1.TraitID = " + traits[i] +
                //            " then " + UoMQuery + " else null end ) as '" + traits[i] + "'";
                //}
                query = query +
                        " from TrialEntryApp left join " + observationQuery +
                        "  on TrialEntryApp.EZID = v1.EZID join Relationship on Relationship.[EZID2] = [TrialEntryApp].[EZID] where Relationship.[EZID1] = " +
                        ezID + " group by TrialEntryApp.EZID  order by TrialEntryApp.EZID";

                var command = DbContextAsync().CreateCommand();
                command.CommandText = query;
                command.CommandType = System.Data.CommandType.Text;

                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        var ezid = reader.GetString(0);
                        if(indexedEzIDs.ContainsKey(ezid))
                        {
                            var index = indexedEzIDs[ezid];
                            var item = itemSource[index] as IDictionary<string, object>;

                            foreach (var _trait in traits)
                            {
                                var ordinal = reader.GetOrdinal(_trait.TraitID.ToText());
                                var isDBNullvalue = reader.IsDBNull(ordinal);
                                if (isDBNullvalue)
                                {
                                    if (_trait.DataType.ToText().ToLower() == "d")
                                        item[_trait.TraitID.ToText()] = new DateTime();
                                    else
                                        item[_trait.TraitID.ToText()] = null;
                                }
                                else
                                {
                                    var data = reader.GetString(ordinal);
                                    if (string.IsNullOrWhiteSpace(data))
                                        item[_trait.TraitID.ToText()] = null;
                                    else
                                    {
                                        if (_trait.DataType.ToText().ToLower() == "d")
                                        {
                                            var dateVal = new DateTime();
                                            if (DateTime.TryParse(data, out dateVal))
                                                item[_trait.TraitID.ToText()] = dateVal;
                                        }
                                        else if (_trait.DataType.ToLower() == "a")
                                        {
                                            var sepp = CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator;

                                            if (sepp == ".")
                                                item[_trait.TraitID.ToText()] = data;
                                            else
                                            {
                                                var dt = Convert.ToDecimal(data, new CultureInfo("en-US"));
                                                item[_trait.TraitID.ToText()] = dt;
                                            }
                                        }
                                        else
                                            item[_trait.TraitID.ToText()] = data.Trim();
                                    }
                                }
                            }
                        }
                        
                    }
                }
                if (DbContextAsync().State == System.Data.ConnectionState.Open)
                    DbContext().Close();
            }

        }
        public void GetObsevationdata(List<int> traitIDs, List<dynamic> itemSource)
        {
            DbContextAsync().Open();
            //query here
            DbContext().Close();
        }

    }
}
