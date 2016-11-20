<%@ Page Language="C#" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<!DOCTYPE html>

<script runat="server">
    private const string graphApi = "https://graph.facebook.com/v2.8";
    private const string clientSecret = "173e4f460136161376ccfb49536746a7";
    private const string clientId = "1699915190325737";

    public string Token { get; set; }
    public string Groups { get; set; }

    protected void Page_Init(object sender, EventArgs e)
    {
        var code = Request.QueryString["code"];

        if (String.IsNullOrEmpty(code))
            return;

        var host = "dev.mayorov.photography";

        var uri = graphApi + "/oauth/access_token?client_id=" + Server.UrlEncode(clientId) + "&redirect_uri=http://" + Server.UrlEncode(host)
            + "/auth.aspx&scope=user_managed_groups&client_secret=" + Server.UrlEncode(clientSecret) + "&code=" + Server.UrlEncode(code);

        string auth = null;
        using (var webclient = new WebClient())
        {
            try
            {
                auth = webclient.DownloadString(uri);
            }
            catch (WebException ex)
            {
                using (var sr = new StreamReader(ex.Response.GetResponseStream()))
                    Response.Write("\nError: " + uri + "\n" + sr.ReadToEnd());
            }
        }

        if (auth == null)
            return;

        var re = new Regex(@"[""']access_token[""']\s?:\s?[""']([^""']+)[""']", RegexOptions.Compiled);
        var match = re.Match(auth);
        if (!match.Success)
            return;

        Token = match.Groups[1].Value;

        uri = graphApi + "/me/groups?access_token=" + Token;
        using (var webclient = new WebClient())
        {
            try
            {
                Groups = webclient.DownloadString(uri);
            }
            catch (WebException ex)
            {
                using (var sr = new StreamReader(ex.Response.GetResponseStream()))
                    Response.Write("\nError: " + uri + "\n" + sr.ReadToEnd());
            }
        }
    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>FbGroupBackup</title>
</head>
<body>
    <div>
        <select id="group" onselect="groupSelect"></select><br />
        <pre id="settings" ></pre><br />
        <a href="" id="a">Download settings.json</a>
    </div>
    <script type="text/javascript">

        function download(text, name, type) {
            var a = document.getElementById("a");
            var file = new Blob([text], { type: type });
            a.href = URL.createObjectURL(file);
            a.download = name;
        }

        function groupSelected(e) {
            var settings = '{\n    "token":"' + token + '",\n    "group_id":"' + select.options[select.selectedIndex].value + '"\n}';
            document.getElementById("settings").innerHTML = settings;
            download(settings, 'settings.json', 'text/json')
        }

        var token = "<%= Token %>";
        var groups = <%= Groups %>;

        var select = document.getElementById("group");
        groups.data.forEach(function (item) {
            var opt = document.createElement('option');
            opt.value = item.id;
            opt.innerHTML = item.name;
            select.appendChild(opt);
        });
        select.onchange = groupSelected;
        groupSelected();

    </script>
</body>
</html>
