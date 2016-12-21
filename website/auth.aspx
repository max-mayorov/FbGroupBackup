<%@ Page Language="C#" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<!DOCTYPE html>

<script runat="server">
    private const string graphApi = "https://graph.facebook.com/v2.8";
    private readonly string clientSecret = ConfigurationManager.AppSettings["ClientSecret"];
    private const string clientId = "1699915190325737";
    private const string logFilePath = "~/.log";

    private readonly object _lock = new object();

    public string Token { get; set; }
    public string Groups { get; set; }

    public string AuthError {get;set;}

    private void Log(string uri, string message)
    {
        var s = string.Format("{0:u} - {1} - {2}", DateTime.Now, uri, message);
        var logFile = Server.MapPath(logFilePath);
        lock(_lock)
        {
            if(!File.Exists(logFile))
                File.WriteAllText(logFile, s);
            else
                File.AppendAllText(logFile, s);
        }
    }

    protected void Page_Init(object sender, EventArgs e)
    {
        var code = Request.QueryString["code"];
        AuthError = "";

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
                {
                    var s = sr.ReadToEnd();
                    Log(uri, s);
                    AuthError += "<br/>" + s;
                    
                }
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
                {
                    var s = sr.ReadToEnd();
                    Log(uri, s);
                    AuthError += "<br/>" + s;
                }
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
        

        <h1>Facebook group backup</h1>

        <p>Downloads content of a Facebook group to a local drive, including attached to the post photos and videos.</p>

        <%if(!String.IsNullOrEmpty(AuthError))
          {%>

        <p> <strong>Facebook authentication error:</strong> <br/><%= AuthError %> </p>
        <p> Try to <a href="index.html">reauthenticate</a> on facebook</p>
        <%}%>

        <h2>How to use:</h2>
        <p>
            <ol>
                <li>Download installation <a href="package.zip">package</a></li>
                <li>Unzip the package to a folder where group will be downloaded</li>
                <li>Select a group where you are admin in the select below and download settings.json to the folder where package.zip is extracted</li>
                <li>Run <tt>python3 feed.py</tt></li>
            </ol>
        </p>

        <p>If the list below is empty, try to <a href="index.html">authenticate this app</a> on facebook</p>
        <select id="group" onselect="groupSelect"></select><br />
        <pre id="settings" ></pre><br />
        <a href="" id="a">Download settings.json</a>

        <h2>Prerequisites:</h2>
        <p>
            <ul>
                <li>Python 3</li>
            </ul>
        </p>

        <h2>What is in the package</h2>
        <p>
            <ul>
                <li><tt>feed.py</tt> - main script, retrieves the backup of a facebook group</li>
                <li><tt>feed.xsl</tt> - transformation script for the XML created by feed.py</li>
                <li><tt>feed.css</tt> - css for the transformed XML</li>
                <li><tt>fbgroupbackup.sh</tt> - example of a bash script to retrieve a backup of a group</li>
                <li><tt>fbgroupbackupcron</tt> - example of a cron job to download daily backup of a group</li>
                <li><tt>fbgroupbackuphttpd</tt> - example of a http daemon to show the backed up group contents</li>
                <li><tt>index.html</tt> - example of a default index page which redirects to group backup xml</li>
            </ul>
        </p>
        
        <h2>How does it work</h2>
        <p>
            The python 3 script <tt>feed.py</tt> uses Facebook API to download contents of a group. 
            <br/>Everytime script runs it retrieves all posts in the group since the last execution of the script.
            <br/>The posts are saved in an XML file named <tt>feed-&lt;group_id&gt;.xml</tt>.
            <br/>All content linked to a post, like attached photos, facebook videos as well as certain types of linked content is downloaded locally into <tt>data</tt> folder. If linked content is not supported, only thumbnail ttview is downloaded. 
        </p>
        <p>Supported external content:
            <ul>
                <li>Giphy</li>
                <li>Google Photos shared video or gifs (googleusercontent)</li>
            </ul>
        </p>

        <h2>External links</h2>
        <p><a href="https://github.com/mcsdwarken/FbGroupBackup">Github</a></p>


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
