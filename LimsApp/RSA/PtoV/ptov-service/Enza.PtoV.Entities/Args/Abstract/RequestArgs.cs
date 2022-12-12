using System.Collections.Generic;
using Enza.PtoV.Common.Attributes;
using System.Linq;
using Enza.PtoV.Common.Extensions;
using System;

namespace Enza.PtoV.Entities.Args.Abstract
{
    public abstract class RequestArgs
    {
    }

    public abstract class PagedRequestArgs: RequestArgs
    {
        protected PagedRequestArgs()
        {
            Filter = new List<Filter>();
            Sorting = new Sort();
        }
        public int PageNumber { get; set; }
        public int PageSize { get; set; }

        [SwaggerExclude]
        public int TotalRows { get; set; }
        public List<Filter> Filter { get; set; }
        public Sort Sorting { get; set; }
        public string ToFilterString()
        {
            return PrepareFilterQuery(Filter);
        }
        public string ToFilterStringSendToVarmas()
        {
            return PrepareFilterQuerySendToVarmas(Filter);
        }

        public string ToSortString()
        {
            return PrepareSortQuery(Sorting);
        }

        private string PrepareSortQuery(Sort sorting)
        {
            var sortQuery = "";
            if (!string.IsNullOrWhiteSpace(sorting?.Name.ToText()))
            {
                sortQuery = "["+ sorting?.Name.ToText() + "] " + Sorting?.Direction.ToText();

            }
            return sortQuery;
        }

        private string PrepareFilterQuerySendToVarmas(List<Filter> filterQueury)
        {
            var filterQuery = "";
            var filterData = filterQueury.Where(x => !string.IsNullOrWhiteSpace(x.Value)).Select(x=>x.Value).ToList();
            if(filterData.Any())
            {
                filterQuery = "GID IN ( " + string.Join(",", filterData) + ")";
            }
            return filterQuery;

        }

        private string PrepareFilterQuery(List<Filter> filterQUeury)
        {
            var filterclause = "";
            filterQUeury = filterQUeury.Where(x => !string.IsNullOrWhiteSpace(x.Value)).ToList();
            //foreach (var _data in filterQUeury.Filter)
            var statusFilterList = Filter.Where(x => x.Name.EqualsIgnoreCase("statuscode")).ToList();
            var statusCodes = string.Join(",", statusFilterList.Select(x => x.Value));
            filterQUeury = filterQUeury.Except(statusFilterList).ToList();
            for (int i = 0; i < filterQUeury?.Count; i++)
            {
                var _data = filterQUeury[i];
                if (_data.Type.ToText().ToUpper() != "NVARCHAR(255)")
                {
                    _data.Type = "NVARCHAR(255)";
                }
                var op = "";
                if (i == 0)
                    filterclause = " [" + _data.Name + "] ";
                else
                {
                    var _data1 = filterQUeury[i - 1];
                    filterclause = filterclause + "  " + _data1.Operator + " [" + _data.Name + "] ";

                }
                switch (_data.Expression.ToLower())
                {
                    case "eq":
                        op = " = ";
                        break;
                    case "neq":
                    case "isnotempty":
                        op = " <> ";
                        break;
                    case "gte":
                        op = " >=  ";
                        break;
                    case "gt":
                        op = " > ";
                        break;
                    case "lte":
                        op = " <=  ";
                        break;
                    case "lt":
                        op = " <  ";
                        break;
                    case "isnotnull":
                        op = " IS NOT NULL  ";
                        break;
                    case "isnull":
                        op = " IS NULL ";
                        break;
                    case "startswith":
                    case "endswith":
                    case "contains":
                        switch (_data.Type.ToUpper())
                        {
                            case "NVARCHAR(255)":
                                op = " LIKE ";
                                break;
                        }
                        break;
                    case "doesnotcontains":
                        switch (_data.Type.ToUpper())
                        {
                            case "NVARCHAR(255)":
                                op = " NOT LIKE ";
                                break;
                        }
                        break;
                    case "isempty":
                        switch (_data.Type.ToUpper())
                        {
                            case "NVARCHAR(255)":
                                op = " = ";
                                break;
                        }
                        break;
                }
                filterclause = filterclause + " " + op;
                switch (_data.Type.ToUpper())
                {
                    case "NVARCHAR(255)":

                        switch (_data.Expression.ToLower())
                        {
                            case "startswith":
                                var val = string.IsNullOrWhiteSpace(_data.Value) ? "" : _data.Value;
                                filterclause = filterclause + " '" + val + " %' ";
                                break;
                            case "contains":
                                var val1 = string.IsNullOrWhiteSpace(_data.Value) ? "" : _data.Value;
                                filterclause = filterclause + " '%" + val1 + "%' ";
                                break;
                            case "doesnotcontains":
                                var val3 = string.IsNullOrWhiteSpace(_data.Value) ? "" : _data.Value;
                                filterclause = filterclause + " '%" + val3 + "%' ";
                                break;
                            case "endswith":
                                var val4 = string.IsNullOrWhiteSpace(_data.Value) ? "" : _data.Value;
                                filterclause = filterclause + " '%" + val4 + "'";
                                break;
                            case "isempty":
                                var val5 = string.IsNullOrWhiteSpace(_data.Value) ? "" : _data.Value;
                                filterclause = filterclause + " '' ";
                                break;
                            case "isnotempty":
                                var val6 = string.IsNullOrWhiteSpace(_data.Value) ? "" : _data.Value;
                                filterclause = filterclause + " '' ";
                                break;
                            case "isnull":
                                filterclause = filterclause + " '' ";
                                break;
                            case "isnotnull":
                                filterclause = filterclause + " '' ";
                                break;
                            default:
                                var val7 = string.IsNullOrWhiteSpace(_data.Value) ? "" : _data.Value;
                                filterclause = filterclause + " '" + val7 + "' ";
                                break;
                        }
                        break;
                    default:
                        var val8 = string.IsNullOrWhiteSpace(_data.Value) ? "" : _data.Value;
                        filterclause = filterclause + " " + val8 + " ";
                        break;
                }

                //filterclause = filterclause + "";
            }
            if (!string.IsNullOrWhiteSpace(filterclause) && !string.IsNullOrWhiteSpace(statusCodes))
                filterclause = $"[StatusCode] IN ({statusCodes}) AND {filterclause}";
            else if(!string.IsNullOrWhiteSpace(statusCodes))
                filterclause = $"[StatusCode] IN ({statusCodes})";

            return filterclause.Trim();

        }
    }

    public abstract class PagedRequest2Args : RequestArgs
    {
        public int PageNumber { get; set; }
        public int PageSize { get; set; }

        [SwaggerExclude]
        public int TotalRows { get; set; }
    }


    public class Sort
    {
        public string Name { get; set; }
        public string Direction { get; set; }
    }

    public class Filter
    {
        public string Name { get; set; }
        public string Expression { get; set; }
        public string Type { get; set; }
        public string Value { get; set; }
        public string Operator { get; set; }
    }
}
