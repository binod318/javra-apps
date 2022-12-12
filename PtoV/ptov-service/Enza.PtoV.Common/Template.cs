namespace Enza.PtoV.Common
{
    public class Template
    { 
        public static string Render(string template, object model)
        {
            var tpl = new Antlr4.StringTemplate.Template(template, '$', '$');
            tpl.Add("Model", model);
            return tpl.Render();
        }
    }
}
