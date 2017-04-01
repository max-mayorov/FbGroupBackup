<%@ Page Language="C#" %>
<%@ Import Namespace="System.IO" %>
<%@ Import Namespace="System.Net" %>
<%@ Import Namespace="Newtonsoft.Json" %>
<%@ Import Namespace="System.Text.RegularExpressions" %>
<!DOCTYPE html>

<script runat="server">
    private const string graphApi = "https://graph.facebook.com/v2.8";
    private readonly string clientSecret = ConfigurationManager.AppSettings["ClientSecret"];
    private const string clientId = "1699915190325737";
    private const string logFilePath = "~/.log";
    private const string host = "dev.mayorov.photography";

    public enum LogLevel{
        ALL = 0,
        DEBUG = 1,
        SUCCESS = 2,
        ERROR = 3
    }

    private readonly object _lock = new object();

    public string Token { get; set; }
    public string Groups { get; set; }

    public string AuthError {get;set;}

    public bool IsAuthenticated {get;set;}
    public bool HasPermission {get;set;}

    private void Log(string status, string uri, string message)
    {
        Log((LogLevel)Enum.Parse(typeof(LogLevel),status), uri, message);
    }
    private void Log(LogLevel status, string uri, string message)
    {
        if((int)status < (int)(LogLevel)Enum.Parse(typeof(LogLevel),ConfigurationManager.AppSettings["LogLevel"]) )
            return;

        var s = string.Format("\n{0}\t{1}\t{2} - {3}", status, DateTime.Now, uri, message);
        var logFile = Server.MapPath(logFilePath);
        lock(_lock)
        {
            if(!File.Exists(logFile))
                File.WriteAllText(logFile, s);
            else
                File.AppendAllText(logFile, s);
        }
    }

    private string GetToken(string code)
    {
        Log("DEBUG", "", "GetToken Code -> " + code);
        
        var uri = graphApi + "/oauth/access_token?client_id=" + Server.UrlEncode(clientId) + "&redirect_uri=http://" + Server.UrlEncode(host)
                + "/fbgroupbackup.aspx&scope=user_managed_groups&client_secret=" + Server.UrlEncode(clientSecret) 
                + "&code=" + Server.UrlEncode(code);

        Log("DEBUG", uri, "Getting token");

        string auth = null;
        using (var webclient = new WebClient())
        {
            try
            {
                auth = webclient.DownloadString(uri);
                Log("SUCCESS", uri, auth);
            }
            catch (WebException ex)
            {
                using (var sr = new StreamReader(ex.Response.GetResponseStream()))
                {
                    var s = sr.ReadToEnd();
                    Log("ERROR", uri, s);
                    AuthError += "<br/>" + s;
                }
            }
        }

        if (auth == null)
            return "";

        var re = new Regex(@"[""']access_token[""']\s?:\s?[""']([^""']+)[""']", RegexOptions.Compiled);
        var match = re.Match(auth);
        if (!match.Success)
            return "";

        return match.Groups[1].Value;
    }

    private string GetShortToken()
    {
        var uri = graphApi + "/oauth/access_token?client_id=" + Server.UrlEncode(clientId) 
                + "&client_secret=" + Server.UrlEncode(clientSecret)
                + "&grant_type=client_credentials";

        string auth = null;
        using (var webclient = new WebClient())
        {
            try
            {
                auth = webclient.DownloadString(uri);
                Log("SUCCESS", uri, auth);
            }
            catch (WebException ex)
            {
                using (var sr = new StreamReader(ex.Response.GetResponseStream()))
                {
                    var s = sr.ReadToEnd();
                    Log("ERROR", uri, s);
                    AuthError += "<br/>" + s;
                }
            }
        }

        if (auth == null)
            return "";

        var re = new Regex(@"[""']access_token[""']\s?:\s?[""']([^""']+)[""']", RegexOptions.Compiled);
        var match = re.Match(auth);
        if (!match.Success)
            return "";

        return match.Groups[1].Value.Split('|')[1];
    }

    protected void Page_Init(object sender, EventArgs e)
    {
        AuthError = "";
        IsAuthenticated = false;
        HasPermission    = false;

        // use cookies to check authentication

        var code = Request.QueryString["code"];
        Log("DEBUG", "", "Code = " + code);
        if(!string.IsNullOrEmpty(code))
        {
            Token = GetToken(code);
            Log("DEBUG", "", "Token = " + code);
            if(String.IsNullOrEmpty(Token))
            {
                Log("ERROR", "", "GetToken");
                Response.Redirect(Request.Url.GetLeftPart(UriPartial.Path));
                return;
            }
            Token = Server.UrlEncode(Token);
    
    
            var uri = graphApi + "/me?fields=id,name,permissions&access_token=" + Token;
            string meStr = "";
            using(var webClient = new WebClient())
            {
                try
                {
                    meStr = webClient.DownloadString(uri);
                    Log("SUCCESS", uri, meStr);
                }
                catch (WebException ex)
                {
                    using (var sr = new StreamReader(ex.Response.GetResponseStream()))
                    {
                        var s = sr.ReadToEnd();
                        Log("ERROR", uri, s);
                        AuthError += "<br/>" + s;
                    }
                }
            }

            var rePermission = new Regex(@"\{.?[""']permission[""'].?\:.?[""']user_managed_groups[""'].?[""']status[""'].?:.?[""']granted[""'].?\}");
            var reIsAuthenticated = new Regex(@"[""']id[""'].?\:.?[""']\d+[""']");
            HasPermission = rePermission.IsMatch(meStr);
            IsAuthenticated = reIsAuthenticated.IsMatch(meStr);


        
            if(IsAuthenticated && HasPermission)
            {
                // Read current FB authentication status ? Or client side.
                uri = graphApi + "/me/groups?access_token=" + Token;
                using (var webclient = new WebClient())
                {
                    try
                    {
                        Groups = webclient.DownloadString(uri);
                        Log("SUCCESS", uri, Groups);
                    }
                    catch (WebException ex)
                    {
                        using (var sr = new StreamReader(ex.Response.GetResponseStream()))
                        {
                            var s = sr.ReadToEnd();
                            Log("ERROR", uri, s);
                            AuthError += "<br/>" + s;
                        }
                    }
                }
            }
        }
//else
//    Token = GetShortToken();


    }
</script>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
    <title>FbGroupBackup</title>
</head>
<body>

    
<%= IsAuthenticated %>
| <%= HasPermission %>

    <div id="fb-root"></div>
    <script>(function(d, s, id) {
        var js, fjs = d.getElementsByTagName(s)[0];
        if (d.getElementById(id)) return;
        js = d.createElement(s); js.id = id;
        js.src = "//connect.facebook.net/en_GB/sdk.js#xfbml=1&version=v2.8&appId=1699915190325737";
        fjs.parentNode.insertBefore(js, fjs);
    }(document, 'script', 'facebook-jssdk'));</script>

    <div>
        

        <h1>Facebook group backup</h1>
        <p>Downloads content of a Facebook group to a local drive, including attached to the post photos and videos.</p>

        <div id="fbstatus">

<% if(!IsAuthenticated)
{ %>                
                <div class="fb-login-button" data-max-rows="1" data-size="xlarge" data-show-faces="false" data-auto-logout-link="true" data-scope="user_managed_groups"></div>

                You need to authenticate on facebook before using this app
                <a href="https://www.facebook.com/v2.8/dialog/oauth?client_id=1699915190325737&redirect_uri=http://dev.mayorov.photography/fbgroupbackup.aspx&response_type=code&scope=user_managed_groups">
                <img src="facebook-login.png"/>
                </a>
<% } else { %>

                Current FB status: <div class="fb-login-status" data-max-rows="1" data-size="xlarge" data-show-faces="false" data-auto-logout-link="true" data-scope="user_managed_groups"></div>
                Logout: <div class="fb-login-button" data-max-rows="1" data-size="xlarge" data-show-faces="false" data-auto-logout-link="true" data-scope="user_managed_groups"></div>

                Log out
                <a href="https://www.facebook.com/v2.8/dialog/oauth?client_id=1699915190325737&redirect_uri=http://dev.mayorov.photography/fbgroupbackup.aspx&response_type=code&scope=user_managed_groups">
                <img src="facebook-logout.png"/>
                </a>
                

<% } %>

<% if(IsAuthenticated && !HasPermission)
{ %>                
                You need to grant this app permission to read user managed groups on facebook. Please authorise the app:
                <a href="https://www.facebook.com/v2.8/dialog/oauth?client_id=1699915190325737&redirect_uri=http://dev.mayorov.photography/fbgroupbackup.aspx&response_type=code&scope=user_managed_groups">
                <img src="https://scontent.xx.fbcdn.net/t39.2178-6/851579_209602122530903_1060396115_n.png"/>
                </a>
<% } %>

        </div>

<% if(HasPermission)
{ %>        

        <select id="group" onselect="groupSelect"></select><br />
        <pre id="settings" ></pre><br />
        <a href="" id="a">Download settings.json</a>

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



<% } %>


        <%if(!String.IsNullOrEmpty(AuthError))
          {%>

        <p> <strong>Facebook authentication error:</strong> <br/><%= AuthError %> </p>
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


        <h2>Prerequisites:</h2>
        <p>
            <ul>
                <li>Python 3</li>
            </ul>
        </p>

        <h2>What is in the package</h2>
        <p>
            <ul>
                <li><tt>feed.py</tt> - main script, retrieves a backup of a facebook group</li>
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
</body>
</html>
