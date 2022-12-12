using System;
using System.Collections.Generic;
using System.Globalization;
using System.Linq;
using System.Text.RegularExpressions;

namespace TrialApp.Common
{
    public class TraitFieldValidation
    {
        //public List<TraitValidation> listOfTraitToValidate = new List<TraitValidation>();

        public string validCharacters = @"[^a-zA-Z0-9.!@,#;:|""$£%^&*() _+?=\-\\\ \\/ \\\n']"; //slash and backslash added for valid character by adding two \\ and than actual \ with one escape sequence and same for /, first two slash for letting regex to know \ is comming and one space is added to make it validated.
        //public string validatecol(string colname, string actualtext)
        //{
        //    try
        //    {
        //        var value = listOfTraitToValidate.FirstOrDefault(validation => validation.TraitID == colname);
        //        return validatescreen(value, actualtext);
        //    }
        //    catch (Exception e)
        //    {
        //        //Logger.Writelog(e);
        //        return "";
        //    }
        //}
        
        public string validateTrait(string datatype, string format, string value)
        {
            if (string.IsNullOrWhiteSpace(datatype))
                datatype = "c";
            if (string.IsNullOrWhiteSpace(format))
                format = "x(50)";
            if (string.IsNullOrWhiteSpace(value))
                return "";
            if (datatype.ToLower() == "d")
                return "";
            var checkRegix = Regex.Match(value, validCharacters);
            if (checkRegix.Success)
                return "Invalid special character/s.";
            return Validate(datatype, format, value);
        }

        //method to validate trait field 
        //public string validatescreen(TraitValidation value, string actualtext)
        //{
        //    if (value == null) return "";
        //    if (string.IsNullOrWhiteSpace(actualtext))
        //        return "";
        //    if (actualtext.Trim() != "")
        //    {
        //        var checkRegix = Regex.Match(actualtext, validCharacters);
        //        if (checkRegix.Success)
        //            return "Invalid special character/s.";
        //    }
        //    if (value.maxvalue != null)
        //    {
        //        if (value.decimalplaces <= 0)
        //        {
        //            int i;
        //            if (!int.TryParse(actualtext, out i))
        //            {
        //                return "value|integer";
        //            }
        //            //if (actualtext.Contains(","))
        //            //{
        //            //    return "value|integer";
        //            //}
        //        }
        //        else if (value.decimalplaces > 0)
        //        {
        //            decimal d;
        //            if (!decimal.TryParse(actualtext, out d))
        //            {
        //                return "value|decimal";
        //            }
        //            var decimals = d.ToString().Split('.');
        //            if (decimals.Length == 2)
        //            {
        //                if (decimals[1].Length > value.decimalplaces)
        //                {
        //                    return "Maximum decimal digit|" + value.decimalplaces;
        //                }
        //            }

        //            //if (actualtext.Contains(","))
        //            //{
        //            //    var val = actualtext.Split(',');
        //            //    if (Convert.ToInt32(val[1]) > value.decimalplaces)
        //            //    {
        //            //        return "Maximum decimal digit|" + value.decimalplaces;
        //            //    }
        //            //}
        //        }
        //        if (value.minvalue == null)
        //        {
        //            if (actualtext.StartsWith("-"))
        //            {
        //                return "value|positive";
        //            }
        //        }

        //        if (value.minvalue != null)
        //        {
        //            try
        //            {
        //                if (actualtext != "")
        //                {
        //                    if (Convert.ToDecimal(value.maxvalue) < Convert.ToDecimal(actualtext) ||
        //                        Convert.ToDecimal(value.minvalue) > Convert.ToDecimal(actualtext))
        //                    {
        //                        return "value range|" + value.minvalue + " to " + value.maxvalue;
        //                    }
        //                }
        //            }
        //            catch (Exception excep)
        //            {
        //                return "format|valid";
        //            }
        //        }
        //        else
        //        {
        //            try
        //            {
        //                if (actualtext != "")
        //                {
        //                    if (Convert.ToDecimal(value.maxvalue) < Convert.ToDecimal(actualtext))
        //                    {
        //                        return "maxvalue|" + value.maxvalue;
        //                    }
        //                }
        //            }
        //            catch (Exception ex)
        //            {
        //                return "format|valid";
        //            }
        //        }
        //    }
        //    else if (value.maxlength != null)
        //    {
        //        if (actualtext.Length > Convert.ToInt32(value.maxlength))
        //        {
        //            return "maxlength|" + value.maxlength;
        //        }
        //    }
        //    return "";
        //}

        public string Validate(string datatype, string format, string value)
        {
            switch(datatype.ToLower())
            {
                case "i":
                    int intvalue;
                    if (!int.TryParse(value, out intvalue))
                        return "Invalid integer value";
                    int maxintvalue;
                    format = format.Replace(",", "");
                    format = format.Replace(">", "9");
                    if (!int.TryParse(format, out maxintvalue))
                        return "Invalid format";
                    if (value.StartsWith("-") && maxintvalue > 0)
                        return "Value cannot be negative";
                    if(Math.Abs(maxintvalue) < Math.Abs(intvalue))
                    {
                        if (format.StartsWith("-"))
                            return "Value range -" + Math.Abs(maxintvalue) + " to " + Math.Abs(maxintvalue);
                        else
                            return "Max value " + Math.Abs(maxintvalue);
                    }
                    break;
                case "d":
                    DateTime dt;
                    if (!DateTime.TryParse(value, out dt))
                        return "Invalid date value";
                    break;
                case "a":
                    var decSeparator = CultureInfo.CurrentCulture.NumberFormat.NumberDecimalSeparator;
                    var separators = ",.";
                    var decimalSeparator = Convert.ToChar(decSeparator).ToString();
                    separators = separators.Replace(decimalSeparator, "");
                    if(value.Contains(separators))
                        return "Invalid decimal value";

                    decimal decval;
                    if (!decimal.TryParse(value, out decval) || value.Contains(",.") || value.Contains(".,") || value.Contains(",,") || value.Contains(".."))
                        return "Invalid decimal value";
                    decimal maxdecvalue;
                    format = format.Replace(",", "");
                    format = format.Replace(">", "9");
                    
                    if (format.EndsWith("."))
                    {
                        format = format.Remove(format.Length - 1, 1);
                    }
                    format = format.Replace(".", decSeparator);
                    if (format.Contains(decSeparator))
                    {
                        var format1 = format.Split(Convert.ToChar(decSeparator));
                        if(format1.Length <2)
                            return "Invalid format";
                        if (value.Contains(decSeparator))
                        {
                            var decPoint = value.Split(Convert.ToChar(decSeparator))[1];
                            var maxDecPoint = format1[1].ToString().Length;
                            if (maxDecPoint < decPoint.Length)
                                return "Maximum decimal point length " + maxDecPoint;
                        }
                            

                    }
                    if (!decimal.TryParse(format, out maxdecvalue))
                        return "Invalid format";
                    if (value.StartsWith("-") && maxdecvalue > 0)
                        return "Value cannot be negative";
                    if (Math.Abs(maxdecvalue) < Math.Abs(decval))
                    {
                        if (format.Contains("-"))
                            return "Value range -" + Math.Abs(maxdecvalue) + " to " + Math.Abs(maxdecvalue);
                        else
                            return "Max value " + Math.Abs(maxdecvalue);
                    }
                    break;
                case "c":
                    //int startindex = format.IndexOf("(")
                    if (string.IsNullOrWhiteSpace(format))
                        return "";
                    var lengthdigit = format.Split('(', ')')[1];
                    int length;
                    if (!int.TryParse(lengthdigit, out length))
                        return "Invalid format";
                    if (length < value.Length)
                        return "Max character length " + length;                    
                    break;
            }

            return "";
        }
        //public void AddValidation(string[] TraitList, string[] Format, int?[] minvalue, int?[] maxvalue)
        //{
        //    try
        //    {
        //        listOfTraitToValidate.Clear();
        //        for (var i = 0; i < TraitList.Count(); i++)
        //        {
        //            var validation = new TraitValidation();
        //            validation.TraitID = TraitList[i];
        //            if (Format[i] != null)
        //            {
        //                var format = Format[i];
        //                //validation.needtovalidate = true;
        //                if (format.ToLower().StartsWith("x("))
        //                {
        //                    var maxlength = Regex.Match(format, "[0-9]+").Value;
        //                    validation.maxlength = maxlength;
        //                    listOfTraitToValidate.Add(validation);
        //                }
        //                else if (format.StartsWith("-"))
        //                {
        //                    format = format.Replace(",", "");
        //                    format = format.Replace("-", "");
        //                    if (format.StartsWith("9"))
        //                    {
        //                        if (format.Contains("."))
        //                        {
        //                            var values = format.Split('.');
        //                            validation.decimalplaces = values.Length == 2 ? values[1].Length :0;//values[1].Length;
        //                            //format = format.Replace(".", ",");
        //                            var maxval = Convert.ToInt32(values[0].Replace(">", "9")) + 1;
        //                            validation.maxvalue = maxval.ToString();//format;
        //                            validation.minvalue = "-" + maxval;//"-" + format;
        //                            listOfTraitToValidate.Add(validation);
        //                        }
        //                        else
        //                        {
        //                            validation.maxvalue = format;
        //                            validation.minvalue = "-" + format;
        //                            listOfTraitToValidate.Add(validation);
        //                        }
        //                    }
        //                    else if (format.StartsWith(">"))
        //                    {
        //                        format = format.Replace(",", "");
        //                        if (format.Contains("."))
        //                        {
        //                            var values = format.Split('.');
        //                            var rounddecimalval = values.Length == 2 ? values[1].Length : 0;//values[1].Length;
        //                            validation.decimalplaces = rounddecimalval;
        //                            //format = format.Replace(".", ",");
        //                            var maxval = Convert.ToInt32(values[0].Replace(">", "9")) + 1;
        //                            validation.maxvalue = maxval.ToString();//format.Replace(">", "9");
        //                            validation.minvalue = "-" + maxval;//"-" + format.Replace(">", "9");
        //                            listOfTraitToValidate.Add((validation));
        //                        }
        //                        else
        //                        {
        //                            validation.maxvalue = format.Replace(">", "9");
        //                            listOfTraitToValidate.Add(validation);
        //                        }
        //                    }
        //                }
        //                else if (format.ToLower().StartsWith("9") && format.Contains("/"))
        //                {
        //                    //this is for date field.
        //                }
        //                else if (format.StartsWith("9"))
        //                {
        //                    format = format.Replace(",", "");
        //                    if (format.Contains("."))
        //                    {
        //                        var values = format.Split('.');
        //                        validation.decimalplaces = values.Length == 2 ? values[1].Length : 0;//values[1].Length;
        //                        //format = format.Replace(".", ",");
        //                        var maxval = Convert.ToInt32(values[0].Replace(">", "9")) + 1;
        //                        validation.maxvalue = maxval.ToString();//format;
        //                        listOfTraitToValidate.Add((validation));
        //                    }
        //                    else
        //                    {
        //                        validation.maxvalue = format;
        //                        listOfTraitToValidate.Add((validation));
        //                    }
        //                }
        //                else if (format.StartsWith(">"))
        //                {
        //                    format = format.Replace(",", "");
        //                    if (format.Contains("."))
        //                    {
        //                        var values = format.Split('.');
        //                        validation.decimalplaces = values.Length == 2 ? values[1].Length : 0;//values[1].Length;
        //                        //format = format.Replace(".", ",");
        //                        var maxval = Convert.ToInt32(values[0].Replace(">", "9")) + 1;
        //                        validation.maxvalue = maxval.ToString();//format;
        //                        listOfTraitToValidate.Add((validation));
        //                    }
        //                    else
        //                    {
        //                        validation.maxvalue = format.Replace(">", "9");
        //                        listOfTraitToValidate.Add(validation);
        //                    }
        //                }
        //            }
        //        }
        //    }
        //    catch (Exception e)
        //    {
        //        // await Logger.Writelog(e);
        //    }
        //}
    }
    //public class TraitValidation
    //{
    //    public string TraitID { get; set; }
    //    public string maxvalue { get; set; }
    //    public string minvalue { get; set; }
    //    public string maxlength { get; set; }
    //    public int decimalplaces { get; set; }
    //    public bool negativeval { get; set; }
    //}
}
