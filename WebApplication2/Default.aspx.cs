using System;
using System.Collections.Generic;
using System.Linq;
using System.Web;
using System.Web.UI;
using System.Web.UI.WebControls;
using System.Data.SqlClient;
using System.Data;
using System.Web.Services;
using System.Configuration;
using Microsoft.AspNet.Identity;
using CAMS_WCF;
using CAMS_WCF.Contracts;

namespace WebApplication2
{
  public partial class _Default : Page
  {
    public static Dictionary<int, AssetStateParams[]> AssetStates;
    protected void Page_Load(object sender, EventArgs e)
    {

      string profileId = GetProfileIdFromDatabase(User.Identity.GetUserId());
      if (profileId != null)
        HttpContext.Current.Session["CAMSProfileId"] = profileId;
      else
      {
        HttpContext.Current.Session["CAMSProfileId"] = "0";
        HttpContext.Current.Session["Email"] = "";
      }
      BindDummyItem();
      GetVehicles("", "asc", "");
      GetAssetStates();
    }


    [WebMethod]
    public static void SelectSysid(int sysid)
    {
      HttpContext.Current.Session["selectedSYSID"] = sysid.ToString();
      //HttpContext.Current.Session["UpdateAssetDetailsGrid"] = true.ToString();
      //HttpContext.Current.Session["UpdateTraceData"] = true.ToString();
    }

    [WebMethod]
    public static void SetLastHeardTime(int time)
    {
      HttpContext.Current.Session["LastHeardTime"] = time.ToString();
    }

    [WebMethod]
    public static void SetTraceTime(int hours)
    {
      HttpContext.Current.Session["TraceTime"] = hours.ToString();
    }

    [WebMethod]
    public static void UpdateTraceData(bool enabled)
    {
      HttpContext.Current.Session["EnableTrace"] = enabled.ToString();
    }

    public void BindDummyItem()
    {
      DataTable dtGetData = new DataTable();
      dtGetData.Columns.Add("Dscr");
      dtGetData.Columns.Add("Name");
      dtGetData.Columns.Add("LastSpeed");
      dtGetData.Columns.Add("LastState");
      dtGetData.Columns.Add("LastLat");
      dtGetData.Columns.Add("LastLng");
      dtGetData.Columns.Add("LastPositionHeardLocal");
      dtGetData.Columns.Add("BitmapFile");
      dtGetData.Columns.Add("SYSID");
      dtGetData.Columns.Add("ClientId");

      dtGetData.Rows.Add();

      AssetGrid.DataSource = dtGetData;
      AssetGrid.DataBind();
    }

    [WebMethod]
    public static AssertInfo[] GetAssetGridData(string time) //GetData function
    {
      List<AssertInfo> Detail = new List<AssertInfo>();

      //string time = HttpContext.Current.Session["LastHeardTime"] as String;
      int profileId = Convert.ToInt32(HttpContext.Current.Session["CAMSProfileId"] as String);
      double timeZoneOffset = Convert.ToDouble(HttpContext.Current.Session["TimeZoneOffset"] as String);
      if (time == null)
        time = "300";

      string selectString = "SELECT tblVehicleTypes.Dscr, tblVehicleTypes.BitmapFile, tblVehicles.SYSID, tblVehicles.Name, tblVehicles.ClientId, tblVehicleInfo.LastLat, tblVehicleInfo.LastLng, tblVehicleInfo.LastPositionHeardGMT, tblVehicleInfo.LastState, tblVehicleInfo.LastSpeed " +
                                        "FROM tblVehicles INNER JOIN tblVehicleInfo ON tblVehicles.SYSID = tblVehicleInfo.SYSID INNER JOIN tblVehicleTypes ON tblVehicles.VehicleTypeId = tblVehicleTypes.VehicleTypeId " +
                                        "Where tblVehicleInfo.LastPositionHeardLocal > DATEADD(second, -" + time + ", CURRENT_TIMESTAMP) and tblVehicleInfo.SYSID in  " +
                                        "(SELECT VehicleId FROM(SELECT tblUserLstPermissions.SYSID AS VehicleId FROM tblClients INNER JOIN (tblVehicleTypes INNER JOIN (tblVehicles INNER JOIN (tblUserGroupUsers RIGHT JOIN tblUserLstPermissions ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) ON tblVehicles.SYSID = tblUserLstPermissions.SYSID) ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) ON tblClients.ClientId = tblVehicles.ClientId WHERE(((tblUserGroupUsers.UserId) = " + profileId.ToString() + ") AND((tblUserLstPermissions.SYSID)Is Not Null)) " +
                                        "UNION " +
                                        "SELECT tblVehicleGroupValues.SysId AS VehicleId FROM((tblVehicleTypes INNER JOIN (tblClients INNER JOIN tblVehicles ON tblClients.ClientId = tblVehicles.ClientId) ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) INNER JOIN tblVehicleGroupValues ON tblVehicles.SYSID = tblVehicleGroupValues.SysId) INNER JOIN(tblUserGroupUsers RIGHT JOIN tblUserLstPermissions ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) ON tblVehicleGroupValues.VehicleGroupId = tblUserLstPermissions.VehicleGroupId WHERE(((tblUserLstPermissions.VehicleGroupId)Is Not Null) AND((tblUserGroupUsers.UserId) = " + profileId.ToString() + "))  " +
                                        "UNION " +
                                        "SELECT tblVehicles.SYSID AS VehicleId FROM((tblVehicleTypes INNER JOIN (tblClients INNER JOIN tblVehicles ON tblClients.ClientId = tblVehicles.ClientId) ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) INNER JOIN tblVehicleTypes AS tblVehicleTypes_1 ON tblVehicles.VehicleTypeId = tblVehicleTypes_1.VehicleTypeId) INNER JOIN(tblUserGroupUsers RIGHT JOIN tblUserLstPermissions ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) ON tblVehicleTypes_1.VehicleTypeId = tblUserLstPermissions.VehicleTypeId WHERE(((tblUserLstPermissions.ClientId)Is Null) AND((tblUserLstPermissions.VehicleTypeId)Is Not Null) AND((tblUserGroupUsers.UserId) = " + profileId.ToString() + "))  " +
                                        "UNION " +
                                        "SELECT tblVehicles.SYSID AS VehicleId FROM(tblVehicleTypes INNER JOIN (tblClients INNER JOIN tblVehicles ON tblClients.ClientId = tblVehicles.ClientId) ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) INNER JOIN(tblUserGroupUsers RIGHT JOIN tblUserLstPermissions ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) ON tblClients.ClientId = tblUserLstPermissions.ClientId WHERE(((tblUserLstPermissions.ClientId)Is Not Null) AND((tblUserLstPermissions.VehicleTypeId)Is Null) AND((tblUserGroupUsers.UserId) = " + profileId.ToString() + "))  " +
                                        "UNION " +
                                        "SELECT tblVehicles.SYSID AS VehicleId FROM(tblVehicleTypes INNER JOIN (tblClients INNER JOIN tblVehicles ON tblClients.ClientId = tblVehicles.ClientId) ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) INNER JOIN(tblUserGroupUsers RIGHT JOIN tblUserLstPermissions ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) ON(tblVehicleTypes.VehicleTypeId = tblUserLstPermissions.VehicleTypeId) AND(tblClients.ClientId = tblUserLstPermissions.ClientId) WHERE(((tblUserLstPermissions.ClientId)Is Not Null) AND((tblUserLstPermissions.VehicleTypeId)Is Not Null)  AND((tblUserGroupUsers.UserId) = " + profileId.ToString() + ")) ) AS A INNER JOIN tblVehicleLicense ON A.VehicleId = tblVehicleLicense.sysid WHERE tblVehicleLicense.Deactivated = 0)"; ;

      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(selectString, con);
      SqlDataAdapter sda = new SqlDataAdapter(cmd);
      DataTable dtGetData = new DataTable();

      sda.Fill(dtGetData);

      foreach (DataRow dtRow in dtGetData.Rows)
      {
        DateTime pos = DateTime.Parse(dtRow["LastPositionHeardGMT"].ToString());
        pos = pos.AddHours(timeZoneOffset);

        AssertInfo assetInfo = new AssertInfo
        {
          Dscr = dtRow["Dscr"].ToString(),
          Name = dtRow["Name"].ToString(),
          LastSpeed = dtRow["LastSpeed"].ToString(),
          LastState = GetAssetStateString(Convert.ToInt32(dtRow["SYSID"]), Convert.ToInt32(dtRow["LastState"])),
          LastLat = dtRow["LastLat"].ToString(),
          LastLng = dtRow["LastLng"].ToString(),
          LastPositionHeardLocal = pos.ToString(),
          BitmapFile = dtRow["BitmapFile"].ToString(),
          SYSID = dtRow["SYSID"].ToString(),
          ClientId = dtRow["ClientId"].ToString()
        };
        Detail.Add(assetInfo);
      }

      return Detail.ToArray();
    }

    [WebMethod]
    public static AssetDetails[] GetAssetDetailsGridData(string sysid)
    {
      List<AssetDetails> Detail = new List<AssetDetails>();
      if (sysid == "")
        return Detail.ToArray();


      string sql = "SELECT tblVehicleFields.Dscr as Field, tblVehicleProperties.data as Value FROM tblVehicleProperties " +
                    "INNER JOIN tblVehicleFields ON tblVehicleProperties.VehicleFieldId = tblVehicleFields.VehicleFieldId " +
                    "WHERE(tblVehicleProperties.sysid = " + sysid + " and tblVehicleFields.flags = 0) ORDER BY tblVehicleFields.fieldTypeId";

      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      SqlDataAdapter sda = new SqlDataAdapter(cmd);
      DataTable dtGetData = new DataTable();
      sda.Fill(dtGetData);

      foreach (DataRow dtRow in dtGetData.Rows)
      {
        AssetDetails assetInfo = new AssetDetails
        {
          Field = dtRow["Field"].ToString(),
          Value = dtRow["Value"].ToString()
        };
        Detail.Add(assetInfo);
      }

      return Detail.ToArray();
    }

    public class AlertData
    {
      public string sysid { get; set; }
      public string fieldName { get; set; }
      public string fieldValue { get; set; }
    }

    [WebMethod]
    public static AlertData[] GetAlertData(string sysid)
    {
      List<AlertData> alerts = new List<AlertData>();
      string sql = "SELECT tblVehicleFields.Dscr as Field, tblVehicleProperties.data as Value, tblVehicleProperties.sysid FROM tblVehicleProperties " +
                    "INNER JOIN tblVehicleFields ON tblVehicleProperties.VehicleFieldId = tblVehicleFields.VehicleFieldId " +
                    "WHERE(tblVehicleProperties.sysid in (" + sysid + 
                    ") and tblVehicleFields.flags = 4) ORDER BY tblVehicleFields.fieldTypeId";

      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      SqlDataAdapter sda = new SqlDataAdapter(cmd);
      DataTable dtGetData = new DataTable();
      sda.Fill(dtGetData);

      foreach (DataRow dtRow in dtGetData.Rows)
      {
        AlertData data = new AlertData
        {
          fieldValue = dtRow["Value"].ToString(),
          fieldName = dtRow["Field"].ToString(),
          sysid = dtRow["sysid"].ToString()
        };
        alerts.Add(data);
      }
        return alerts.ToArray();
    }

    [WebMethod]
    public static TraceData[] GetTraceData(string sysid, string traceTime)
    {
      List<TraceData> Detail = new List<TraceData>();

      if (sysid == "")
        return Detail.ToArray();

      if (traceTime == "")
        traceTime = "4";

      string sql = "Select PositionTimeGMT, Latitude, Longitude, Speed, State from tblVehicleTraceData " +
                    "where SYSID = " + sysid + " and PositionTimeLocal > DATEADD(hour, -" + traceTime + ", CURRENT_TIMESTAMP) " +
                    "order by PositionTimeGMT desc;";
      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      SqlDataAdapter sda = new SqlDataAdapter(cmd);
      DataTable dtGetData = new DataTable();
      sda.Fill(dtGetData);
      int count = 0;
      double timeZoneOffset = Convert.ToDouble(HttpContext.Current.Session["TimeZoneOffset"] as String);
      foreach (DataRow dtRow in dtGetData.Rows)
      {
        DateTime pos = DateTime.Parse(dtRow["PositionTimeGMT"].ToString());
        pos = pos.AddHours(timeZoneOffset);
        TraceData assetInfo = new TraceData
        {
          Latitude = dtRow["Latitude"].ToString(),
          Longitude = dtRow["Longitude"].ToString(),
          Speed = dtRow["Speed"].ToString(),
          State = dtRow["State"].ToString(),
          Time = pos.ToString()
        };
        Detail.Add(assetInfo);
        count++;
        //if (count > 499)
        //  break;
      }

      return Detail.ToArray();
    }

    public class UserSettings
    {
      public string MapCenterLat { get; set; }
      public string MapCenterLng { get; set; }
      public string MapCenterZoom { get; set; }
      public string TimeFilter { get; set; }
      public string TraceHours { get; set; }
      public string KeepInView { get; set; }
      public string ShowTrace { get; set; }
      public string ShowPoints { get; set; }
      public string AssetDivWidth { get; set; }
      public string TimeZoneOffset { get; set; }
    }

    [WebMethod]
    public static UserSettings[] GetUserSettings()
    {
      List<UserSettings> userSettings = new List<UserSettings>();
      string email = HttpContext.Current.Session["Email"].ToString();
      if (email == "")
        return userSettings.ToArray();

      string selectString = "Select MapCenterLat, MapCenterLng, MapCenterZoom, TimeFilter, " +
                            "TraceHours, KeepInView, ShowTrace, ShowPoints, AssetDivWidth, TimeZoneOffset " +
                            "from ASPWebUserSettings where Email = \'" + email + "\';";

      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(selectString, con);
      SqlDataAdapter sda = new SqlDataAdapter(cmd);
      DataTable dtGetData = new DataTable();

      sda.Fill(dtGetData);

      if (dtGetData.Rows.Count > 0)
      {
        UserSettings settings = new UserSettings();
        var dtRow = dtGetData.Rows[0];

        settings.MapCenterLat = dtRow["MapCenterLat"].ToString();
        settings.MapCenterLng = dtRow["MapCenterLng"].ToString();
        settings.MapCenterZoom = dtRow["MapCenterZoom"].ToString();
        settings.TimeFilter = dtRow["TimeFilter"].ToString();
        settings.TraceHours = dtRow["TraceHours"].ToString();
        settings.KeepInView = dtRow["KeepInView"].ToString();
        settings.ShowTrace = dtRow["ShowTrace"].ToString();
        settings.ShowPoints = dtRow["ShowPoints"].ToString();
        settings.AssetDivWidth = dtRow["AssetDivWidth"].ToString();
        settings.TimeZoneOffset = dtRow["TimeZoneOffset"].ToString();
        HttpContext.Current.Session["TimeZoneOffset"] = dtRow["TimeZoneOffset"].ToString();
        userSettings.Add(settings);
      }


      return userSettings.ToArray();
    }

    [WebMethod]
    public static MapKey[] GetProfileId()
    {
      List<MapKey> Detail = new List<MapKey>();
      MapKey key = new MapKey
      {
        Key = HttpContext.Current.Session["CAMSProfileId"].ToString()
      };
      Detail.Add(key);
      return Detail.ToArray();

    }

    private string GetProfileIdFromDatabase(string userId)
    {
      string selectString = "Select ProfileId, Username from ASPWebUsers where Id = \'" + userId + "\';";

      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(selectString, con);
      SqlDataAdapter sda = new SqlDataAdapter(cmd);
      DataTable dtGetData = new DataTable();

      sda.Fill(dtGetData);

      if (dtGetData.Rows.Count > 0)
      {
        var dtRow = dtGetData.Rows[0];
        HttpContext.Current.Session["Email"] = dtRow["Username"].ToString();
        return (dtRow["ProfileId"].ToString());
      }
      return null;
    }

    [WebMethod]
    public static MapKey[] GetMapKey()
    {
      List<MapKey> Detail = new List<MapKey>();
      MapKey key = new MapKey
      {
        Key = ConfigurationManager.AppSettings["BingKey"]
      };
      Detail.Add(key);
      return Detail.ToArray();

    }

    [WebMethod]
    public static Vehicle[] GetVehicles(string orderBy, string ascDesc, string typeFilters)
    {
      List<Vehicle> vehicles = new List<Vehicle>();
      string profileId = HttpContext.Current.Session["CAMSProfileId"] as String;
      string sql = "SELECT tblUserLstPermissions.SYSID AS VehicleId, " +
              "tblClients.Name AS cName, " +
              "tblClients.ClientId, " +
              "tblVehicleTypes.Dscr, " +
              "tblVehicles.Name AS vName, " +
              "tblVehicles.DeviceType as deviceType, " +
              "tblVehicles.EventDataTypeId AS dataType " +
              "FROM tblClients INNER JOIN (tblVehicleTypes " +
              "INNER JOIN (tblVehicles INNER JOIN (tblUserGroupUsers " +
              "RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblVehicles.SYSID = tblUserLstPermissions.SYSID) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "ON tblClients.ClientId = tblVehicles.ClientId " +
              "WHERE (((tblUserGroupUsers.UserId)=" + profileId + ") " +
              "AND ((tblUserLstPermissions.SYSID) Is Not Null)) " +
              "UNION " +
              "SELECT tblVehicleGroupValues.SysId AS VehicleId, " +
              "tblClients.Name AS cName, " +
              "tblClients.ClientId, " +
              "tblVehicleTypes.Dscr, " +
              "tblVehicles.Name AS vName, " +
              "tblVehicles.DeviceType as deviceType, " +
              "tblVehicles.EventDataTypeId AS dataType " +
              "FROM ((tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN tblVehicleGroupValues " +
              "ON tblVehicles.SYSID = tblVehicleGroupValues.SysId) " +
              "INNER JOIN (tblUserGroupUsers RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblVehicleGroupValues.VehicleGroupId = tblUserLstPermissions.VehicleGroupId " +
              "WHERE (((tblUserLstPermissions.VehicleGroupId) Is Not Null) " +
              "AND ((tblUserGroupUsers.UserId)=" + profileId + ")) " +
              "UNION " +
              "SELECT tblVehicles.SYSID AS VehicleId, " +
              "tblClients.Name AS cName, " +
              "tblClients.ClientId, " +
              "tblVehicleTypes.Dscr, " +
              "tblVehicles.Name AS vName, " +
              "tblVehicles.DeviceType as deviceType, " +
              "tblVehicles.EventDataTypeId AS dataType " +
              "FROM ((tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN tblVehicleTypes AS tblVehicleTypes_1 " +
              "ON tblVehicles.VehicleTypeId = tblVehicleTypes_1.VehicleTypeId) " +
              "INNER JOIN (tblUserGroupUsers RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblVehicleTypes_1.VehicleTypeId = tblUserLstPermissions.VehicleTypeId " +
              "WHERE (((tblUserLstPermissions.ClientId) Is Null) " +
              "AND ((tblUserLstPermissions.VehicleTypeId) Is Not Null) " +
              "AND ((tblUserGroupUsers.UserId)=" + profileId + ")) " +
              "UNION " +
              "SELECT tblVehicles.SYSID AS VehicleId, " +
              "tblClients.Name AS cName, " +
              "tblClients.ClientId, " +
              "tblVehicleTypes.Dscr, " +
              "tblVehicles.Name AS vName, " +
              "tblVehicles.DeviceType as deviceType, " +
              "tblVehicles.EventDataTypeId AS dataType " +
              "FROM (tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN (tblUserGroupUsers " +
              "RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblClients.ClientId = tblUserLstPermissions.ClientId " +
              "WHERE (((tblUserLstPermissions.ClientId) Is Not Null) " +
              "AND ((tblUserLstPermissions.VehicleTypeId) Is Null) " +
              "AND ((tblUserGroupUsers.UserId)=" + profileId + ")) " +
              "UNION " +
              "SELECT tblVehicles.SYSID AS VehicleId, " +
              "tblClients.Name AS cName, " +
              "tblClients.ClientId, " +
              "tblVehicleTypes.Dscr, " +
              "tblVehicles.Name AS vName, " +
              "tblVehicles.DeviceType as deviceType, " +
              "tblVehicles.EventDataTypeId AS dataType " +
              "FROM (tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN (tblUserGroupUsers RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON (tblVehicleTypes.VehicleTypeId = tblUserLstPermissions.VehicleTypeId) " +
              "AND (tblClients.ClientId = tblUserLstPermissions.ClientId) " +
              "WHERE (((tblUserLstPermissions.ClientId) Is Not Null) " +
              "AND ((tblUserLstPermissions.VehicleTypeId) Is Not Null) " +
              "AND ((tblUserGroupUsers.UserId)=" + profileId + "));";

      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      SqlDataAdapter sda = new SqlDataAdapter(cmd);
      DataTable dtGetData = new DataTable();
      sda.Fill(dtGetData);

      string[] types = typeFilters.Trim().Split(',');



      foreach (DataRow dtRow in dtGetData.Rows)
      {
        var found = false;
        if (typeFilters != "")
        {
          for (int i = 0; i < types.Length; i++)
          {
            if (types[i] == dtRow["Dscr"].ToString())
              found = true;
          }
        }
        else
          found = true;

        if (found)
        {
          Vehicle veh = new Vehicle
          {
            Name = dtRow["vName"].ToString(),
            SYSID = dtRow["VehicleId"].ToString(),
            Client = dtRow["cName"].ToString(),
            Active = "true",
            Type = dtRow["Dscr"].ToString()
          };
          vehicles.Add(veh);
        }
      }

      string sysidList = "";

      foreach (var vehicle in vehicles)
      {
        sysidList = sysidList + vehicle.SYSID.ToString() + ",";
      }

      sysidList = sysidList.Substring(0, sysidList.Length - 1);
      HttpContext.Current.Session["SysidList"] = sysidList;

      if (orderBy == "name")
      {
        if (ascDesc == "asc")
          return vehicles.OrderBy(si => si.Name).ToArray();
        else
          return vehicles.OrderByDescending(si => si.Name).ToArray();
      }
      else if (orderBy == "type")
      {
        if (ascDesc == "asc")
          return vehicles.OrderBy(si => si.Type).ToArray();
        else
          return vehicles.OrderByDescending(si => si.Type).ToArray();
      }
      else if (orderBy == "sysid")
      {
        if (ascDesc == "asc")
          return vehicles.OrderBy(si => si.Type).ToArray();
        else
          return vehicles.OrderByDescending(si => si.Type).ToArray();
      }
      else
      {
        if (ascDesc == "asc")
          return vehicles.OrderBy(si => si.Name).ToArray();
        else
          return vehicles.OrderByDescending(si => si.Name).ToArray();
      }

    }

    [WebMethod]
    public static Vehicle[] GetCurrentVehicles(string orderBy, string ascDesc, string typeFilters)
    {
      List<Vehicle> vehicles = new List<Vehicle>();
      string profileId = HttpContext.Current.Session["CAMSProfileId"] as String;
      string sql = "SELECT tblUserLstPermissions.SYSID AS VehicleId, " +
              "tblClients.Name AS cName, " +
              "tblClients.ClientId, " +
              "tblVehicleTypes.Dscr, " +
              "tblVehicles.Name AS vName, " +
              "tblVehicles.DeviceType as deviceType, " +
              "tblVehicles.EventDataTypeId AS dataType " +
              "FROM tblClients INNER JOIN (tblVehicleTypes " +
              "INNER JOIN (tblVehicles INNER JOIN (tblUserGroupUsers " +
              "RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblVehicles.SYSID = tblUserLstPermissions.SYSID) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "ON tblClients.ClientId = tblVehicles.ClientId " +
              "WHERE ((tblUserGroupUsers.UserId=" + profileId + ") " +
              "AND (tblUserLstPermissions.SYSID Is Not Null) " +
              "AND tblUserLstPermissions.SYSID in (Select sysid from tblVehicleLicense where Deactivated = 0)) " +
              "UNION " +
              "SELECT tblVehicleGroupValues.SysId AS VehicleId, " +
              "tblClients.Name AS cName, " +
              "tblClients.ClientId, " +
              "tblVehicleTypes.Dscr, " +
              "tblVehicles.Name AS vName, " +
              "tblVehicles.DeviceType as deviceType, " +
              "tblVehicles.EventDataTypeId AS dataType " +
              "FROM ((tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN tblVehicleGroupValues " +
              "ON tblVehicles.SYSID = tblVehicleGroupValues.SysId) " +
              "INNER JOIN (tblUserGroupUsers RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblVehicleGroupValues.VehicleGroupId = tblUserLstPermissions.VehicleGroupId " +
              "WHERE ((tblUserLstPermissions.VehicleGroupId Is Not Null) " +
              "AND (tblUserGroupUsers.UserId=" + profileId + ") " +
              "AND tblVehicleGroupValues.SysId in (Select sysid from tblVehicleLicense where Deactivated = 0)) " +
              "UNION " +
              "SELECT tblVehicles.SYSID AS VehicleId, " +
              "tblClients.Name AS cName, " +
              "tblClients.ClientId, " +
              "tblVehicleTypes.Dscr, " +
              "tblVehicles.Name AS vName, " +
              "tblVehicles.DeviceType as deviceType, " +
              "tblVehicles.EventDataTypeId AS dataType " +
              "FROM ((tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN tblVehicleTypes AS tblVehicleTypes_1 " +
              "ON tblVehicles.VehicleTypeId = tblVehicleTypes_1.VehicleTypeId) " +
              "INNER JOIN (tblUserGroupUsers RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblVehicleTypes_1.VehicleTypeId = tblUserLstPermissions.VehicleTypeId " +
              "WHERE ((tblUserLstPermissions.ClientId Is Null) " +
              "AND (tblUserLstPermissions.VehicleTypeId Is Not Null) " +
              "AND (tblUserGroupUsers.UserId=" + profileId + ") " +
              "AND tblVehicles.SYSID in (Select sysid from tblVehicleLicense where Deactivated = 0)) " +
              "UNION " +
              "SELECT tblVehicles.SYSID AS VehicleId, " +
              "tblClients.Name AS cName, " +
              "tblClients.ClientId, " +
              "tblVehicleTypes.Dscr, " +
              "tblVehicles.Name AS vName, " +
              "tblVehicles.DeviceType as deviceType, " +
              "tblVehicles.EventDataTypeId AS dataType " +
              "FROM (tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN (tblUserGroupUsers " +
              "RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblClients.ClientId = tblUserLstPermissions.ClientId " +
              "WHERE ((tblUserLstPermissions.ClientId Is Not Null) " +
              "AND (tblUserLstPermissions.VehicleTypeId Is Null) " +
              "AND (tblUserGroupUsers.UserId=" + profileId + ") " +
              "AND tblVehicles.SYSID in (Select sysid from tblVehicleLicense where Deactivated = 0)) " +
              "UNION " +
              "SELECT tblVehicles.SYSID AS VehicleId, " +
              "tblClients.Name AS cName, " +
              "tblClients.ClientId, " +
              "tblVehicleTypes.Dscr, " +
              "tblVehicles.Name AS vName, " +
              "tblVehicles.DeviceType as deviceType, " +
              "tblVehicles.EventDataTypeId AS dataType " +
              "FROM (tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN (tblUserGroupUsers RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON (tblVehicleTypes.VehicleTypeId = tblUserLstPermissions.VehicleTypeId) " +
              "AND (tblClients.ClientId = tblUserLstPermissions.ClientId) " +
              "WHERE ((tblUserLstPermissions.ClientId Is Not Null) " +
              "AND (tblUserLstPermissions.VehicleTypeId Is Not Null) " +
              "AND (tblUserGroupUsers.UserId=" + profileId + ") " +
              "AND tblVehicles.SYSID in (Select sysid from tblVehicleLicense where Deactivated = 0));"; 

      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      SqlDataAdapter sda = new SqlDataAdapter(cmd);
      DataTable dtGetData = new DataTable();
      sda.Fill(dtGetData);

      string[] types = typeFilters.Trim().Split(',');



      foreach (DataRow dtRow in dtGetData.Rows)
      {
        var found = false;
        if (typeFilters != "")
        {
          for (int i = 0; i < types.Length; i++)
          {
            if (types[i] == dtRow["Dscr"].ToString())
              found = true;
          }
        }
        else
          found = true;

        if (found)
        {
          Vehicle veh = new Vehicle
          {
            Name = dtRow["vName"].ToString(),
            SYSID = dtRow["VehicleId"].ToString(),
            Client = dtRow["cName"].ToString(),
            Active = "true",
            Type = dtRow["Dscr"].ToString()
          };
          vehicles.Add(veh);
        }
      }

      if (orderBy == "name")
      {
        if (ascDesc == "asc")
          return vehicles.OrderBy(si => si.Name).ToArray();
        else
          return vehicles.OrderByDescending(si => si.Name).ToArray();
      }
      else if (orderBy == "type")
      {
        if (ascDesc == "asc")
          return vehicles.OrderBy(si => si.Type).ToArray();
        else
          return vehicles.OrderByDescending(si => si.Type).ToArray();
      }
      else if (orderBy == "sysid")
      {
        if (ascDesc == "asc")
          return vehicles.OrderBy(si => si.Type).ToArray();
        else
          return vehicles.OrderByDescending(si => si.Type).ToArray();
      }
      else
      {
        if (ascDesc == "asc")
          return vehicles.OrderBy(si => si.Name).ToArray();
        else
          return vehicles.OrderByDescending(si => si.Name).ToArray();
      }

    }

    public class Vehicle
    {
      public string Name { get; set; }
      public string SYSID { get; set; }
      public string Client { get; set; }
      public string Active { get; set; }
      public string Type { get; set; }
    }

    public static Dictionary<string, EventType> EventTypeMap = null;

    [WebMethod]
    public static EventType[] GetEventTypes(string ascDesc)
    {
      if (EventTypeMap == null)
      {
        EventTypeMap = new Dictionary<string, EventType>();

        string sql = "Select dscr, eventDataTypeId, eventTypeId from tblEventTypes;";
        SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
        SqlCommand cmd = new SqlCommand(sql, con);
        SqlDataAdapter sda = new SqlDataAdapter(cmd);
        DataTable dtGetData = new DataTable();
        sda.Fill(dtGetData);

        foreach (DataRow dtRow in dtGetData.Rows)
        {
          string eName = dtRow["dscr"].ToString();
          int dataType = Convert.ToInt32(dtRow["eventDataTypeId"].ToString());
          string eventTypeId = dtRow["eventTypeId"].ToString();
          string type = "Line";
          if (dataType == 1)
          {
            type = "Point";
          }
          EventType e = new EventType
          {
            EventTypeName = eName,
            DataType = type,
            EventTypeId = eventTypeId
          };
          EventTypeMap.Add(e.EventTypeName, e);
        }
      }
      var sList = EventTypeMap.Values.ToList();
      if (ascDesc == "asc")
        return sList.OrderBy(si => si.EventTypeName).ToArray();
      else
        return sList.OrderByDescending(si => si.EventTypeName).ToArray();
    }




    public class EventType
    {
      public string EventTypeName { get; set; }
      public string VehicleType { get; set; }
      public string VehicleId { get; set; }
      public string DataType { get; set; }
      public string EventTypeId { get; set; }

    }

    [WebMethod]
    public static VehicleTypes[] GetVehicleTypes(string ascDesc)
    {
      List<VehicleTypes> vTypes = new List<VehicleTypes>();
      string profileId = HttpContext.Current.Session["CAMSProfileId"] as String;
      string sql = "Select DSCR, BitmapFile, VehicleTypeId from tblVehicleTypes where dscr in (" +
              "SELECT tblVehicleTypes.Dscr " +
              "FROM tblClients INNER JOIN (tblVehicleTypes " +
              "INNER JOIN (tblVehicles INNER JOIN (tblUserGroupUsers " +
              "RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblVehicles.SYSID = tblUserLstPermissions.SYSID) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "ON tblClients.ClientId = tblVehicles.ClientId " +
              "WHERE (((tblUserGroupUsers.UserId)=" + profileId + ") " +
              "AND ((tblUserLstPermissions.SYSID) Is Not Null)) " +
              "UNION " +
              "SELECT tblVehicleTypes.Dscr " +
              "FROM ((tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN tblVehicleGroupValues " +
              "ON tblVehicles.SYSID = tblVehicleGroupValues.SysId) " +
              "INNER JOIN (tblUserGroupUsers RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblVehicleGroupValues.VehicleGroupId = tblUserLstPermissions.VehicleGroupId " +
              "WHERE (((tblUserLstPermissions.VehicleGroupId) Is Not Null) " +
              "AND ((tblUserGroupUsers.UserId)=" + profileId + ")) " +
              "UNION " +
              "SELECT tblVehicleTypes.Dscr " +
              "FROM ((tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN tblVehicleTypes AS tblVehicleTypes_1 " +
              "ON tblVehicles.VehicleTypeId = tblVehicleTypes_1.VehicleTypeId) " +
              "INNER JOIN (tblUserGroupUsers RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblVehicleTypes_1.VehicleTypeId = tblUserLstPermissions.VehicleTypeId " +
              "WHERE (((tblUserLstPermissions.ClientId) Is Null) " +
              "AND ((tblUserLstPermissions.VehicleTypeId) Is Not Null) " +
              "AND ((tblUserGroupUsers.UserId)=" + profileId + ")) " +
              "UNION " +
              "SELECT tblVehicleTypes.Dscr " +
              "FROM (tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN (tblUserGroupUsers " +
              "RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON tblClients.ClientId = tblUserLstPermissions.ClientId " +
              "WHERE (((tblUserLstPermissions.ClientId) Is Not Null) " +
              "AND ((tblUserLstPermissions.VehicleTypeId) Is Null) " +
              "AND ((tblUserGroupUsers.UserId)=" + profileId + ")) " +
              "UNION " +
              "SELECT tblVehicleTypes.Dscr " +
              "FROM (tblVehicleTypes INNER JOIN (tblClients " +
              "INNER JOIN tblVehicles " +
              "ON tblClients.ClientId = tblVehicles.ClientId) " +
              "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId) " +
              "INNER JOIN (tblUserGroupUsers RIGHT JOIN tblUserLstPermissions " +
              "ON tblUserGroupUsers.UserListId = tblUserLstPermissions.UserListId) " +
              "ON (tblVehicleTypes.VehicleTypeId = tblUserLstPermissions.VehicleTypeId) " +
              "AND (tblClients.ClientId = tblUserLstPermissions.ClientId) " +
              "WHERE (((tblUserLstPermissions.ClientId) Is Not Null) " +
              "AND ((tblUserLstPermissions.VehicleTypeId) Is Not Null) " +
              "AND ((tblUserGroupUsers.UserId)=" + profileId + ")));";

      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      SqlDataAdapter sda = new SqlDataAdapter(cmd);
      DataTable dtGetData = new DataTable();
      sda.Fill(dtGetData);

      foreach (DataRow dtRow in dtGetData.Rows)
      {
        VehicleTypes veh = new VehicleTypes
        {
          Type = dtRow["DSCR"].ToString(),
          Icon = dtRow["BitmapFile"].ToString(),
          VehicleTypeId = Convert.ToInt32(dtRow["vehicleTypeId"].ToString())
        };
        vTypes.Add(veh);
      }
      if (ascDesc == "asc")
        return vTypes.OrderBy(si => si.Type).ToArray();
      else
        return vTypes.OrderByDescending(si => si.Type).ToArray();
    }

    public class VehicleTypes
    {
      public string Type { get; set; }
      public string Icon { get; set; }
      public int VehicleTypeId { get; set; }
    }

    [WebMethod]
    public static QueryResults[] RunEventQuery(DateTime startTime, DateTime endTime, string vehicleIds, string vehicleTypes, string eventTypes)
    {
      List<QueryResults> results = new List<QueryResults>();
      if (vehicleTypes != null && vehicleIds == "")
      {
        Vehicle[] vehs = GetVehicles("", "", "");
        string[] vTypes = vehicleTypes.Split(',');
        foreach (Vehicle v in vehs)
        {
          foreach (string t in vTypes)
          {
            if (t == v.Type)
            {
              vehicleIds = vehicleIds + v.SYSID.ToString() + ',';
            }
          }
        }

      }

      string[] vIds = vehicleIds.Split(',');
      //string[] vTypes = vehicleTypes.Split(',');
      if (eventTypes.Length > 0)
      {


        if (EventTypeMap == null)
        {
          GetEventTypes("asc");
        }
        string[] eTypes = eventTypes.Split(',');
        eventTypes = "";
        foreach (string s in eTypes)
        {
          if (s == "" || s == null)
            continue;
          EventType e = EventTypeMap[s];
          eventTypes = eventTypes + e.EventTypeId + ',';
        }
        eventTypes = eventTypes.Substring(0, eventTypes.Length - 1);
      }

      if (vehicleIds.Length > 0)
        vehicleIds = vehicleIds.Substring(0, vehicleIds.Length - 1);


      string sql = "SELECT DISTINCT tblVehicleEvents.StartTimeGMT, " +
        "tblVehicleEvents.EndTimeGMT, " +
        "tblVehicleEvents.StartTimeLocal AS StartTime, " +
        "tblVehicleEvents.EndTimeLocal AS EndTime, " +
        "tblVehicleEvents.StartTimeGMT, " +
        "tblVehicleEvents.EndTimeGMT, " +
        "tblVehicleEvents.AppDist AS Distance, " +
        "tblVehicleEvents.SYSID, " +
        "tblVehicleEvents.VehicleEventId AS EID, " +
        "tblVehicleEvents.CustomFlag, " +
        "tblVehicleTypes.Dscr AS VehicleDscr, " +
        "tblVehicles.Name, " +
        "tblEventTypes.Dscr AS EventDscr, " +
        "tblClients.Name AS ClientName " +
        "FROM tblVehicleTypes " +
        "INNER JOIN ((tblClients " +
        "INNER JOIN tblVehicles " +
        "ON tblClients.ClientId = tblVehicles.ClientId) " +
        "INNER JOIN (tblEventTypes " +
        "INNER JOIN tblVehicleEvents " +
        "ON tblEventTypes.EventTypeId = tblVehicleEvents.EventTypeId) " +
        "ON tblVehicles.SYSID = tblVehicleEvents.SYSID) " +
        "ON tblVehicleTypes.VehicleTypeId = tblVehicles.VehicleTypeId Where(";
      bool addFilter = false;
      if (eventTypes.Length > 0)
      {
        sql = sql + " tblVehicleEvents.eventTypeId in (" + eventTypes + ")";
        addFilter = true;
      }

      if (vehicleIds.Length > 0)
      {
        if (addFilter)
        {
          sql = sql + " AND tblVehicleEvents.sysid in (" + vehicleIds + ") ";
        }
        else
        {
          sql = sql + " tblVehicleEvents.sysid in (" + vehicleIds + ") ";
        }
        addFilter = true;

      }
      else
      {
        if (addFilter)
        {
          sql = sql + " AND tblVehicleEvents.sysid in (" + HttpContext.Current.Session["SysidList"] + ") ";
        }
        else
        {
          sql = sql + " tblVehicleEvents.sysid in (" + HttpContext.Current.Session["SysidList"] + ") ";
        }
        addFilter = true;

      }

      if (startTime != null)
      {
        if (addFilter)
        {
          sql = sql + " AND tblVehicleEvents.startTimeLocal > '" + startTime.ToString() + "\' ";
        }
        else
        {
          sql = sql + " tblVehicleEvents.startTimeLocal > '" + startTime.ToString() + "' ";
        }
        addFilter = true;
      }
      if (endTime != null)
      {
        if (addFilter)
        {
          sql = sql + " AND tblVehicleEvents.endTimeLocal < '" + endTime.ToString() + "' ";
        }
        else
        {
          sql = sql + " tblVehicleEvents.endTimeLocal < '" + endTime.ToString() + "' ";
        }
        addFilter = true;
      }
      sql = sql + ") Order by tblVehicleEvents.StartTimeGMT DESC ";

      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      SqlDataAdapter sda = new SqlDataAdapter(cmd);
      DataTable dtGetData = new DataTable();
      sda.Fill(dtGetData);
      int count = Convert.ToInt32(ConfigurationManager.AppSettings["MaxQueryResults"]);
      foreach (DataRow dtRow in dtGetData.Rows)
      {
        var start = Convert.ToDateTime(dtRow["StartTime"].ToString());
        var end = Convert.ToDateTime(dtRow["EndTime"].ToString());
        var startGMT = Convert.ToDateTime(dtRow["StartTimeGMT"].ToString());
        var endGMT = Convert.ToDateTime(dtRow["EndTimeGMT"].ToString());
        TimeSpan dur = new TimeSpan(end.Ticks - start.Ticks);
        QueryResults res = new QueryResults
        {

          VehicleEventId = Convert.ToInt32(dtRow["EID"].ToString()),
          StartTime = start.ToString(),
          EndTime = end.ToString(),
          StartTimeGMT = startGMT.ToString(),
          EndTimeGMT = endGMT.ToString(),
          Distance = Math.Round(Convert.ToDouble(dtRow["Distance"].ToString()) * 0.001, 2),
          Duration = Math.Round(dur.TotalHours, 2),
          SYSID = Convert.ToInt32(dtRow["SYSID"].ToString()),
          EventType = dtRow["EventDscr"].ToString(),
          VehicleType = dtRow["VehicleDscr"].ToString(),
          VehicleName = dtRow["Name"].ToString(),
          CustomFlag = Convert.ToInt32(dtRow["CustomFlag"].ToString())
        };

        results.Add(res);
        count--;
        if (count <= 0)
          break;
      }

      return results.ToArray();
    }

    public class QueryResults
    {
      public int VehicleEventId { get; set; }
      public string StartTime { get; set; }
      public string EndTime { get; set; }
      public string StartTimeGMT { get; set; }
      public string EndTimeGMT { get; set; }
      public double Distance { get; set; }
      public double Duration { get; set; }
      public string EventType { get; set; }
      public string VehicleType { get; set; }
      public string VehicleName { get; set; }
      public int SYSID { get; set; }
      public int CustomFlag { get; set; }
    }

    public class MapKey
    {
      public string Key { get; set; }
    }
    public class AssertInfo //Class for binding data
    {
      public string Dscr { get; set; }
      public string Name { get; set; }
      public string LastSpeed { get; set; }
      public string LastState { get; set; }
      public string LastLat { get; set; }
      public string LastLng { get; set; }
      public string LastPositionHeardLocal { get; set; }
      public string BitmapFile { get; set; }
      public string SYSID { get; set; }
      public string ClientId { get; set; }

    }

    public class AssetDetails //Class for binding data
    {
      public string Field { get; set; }
      public string Value { get; set; }

    }

    public class TraceData
    {
      public string Latitude { get; set; }
      public string Longitude { get; set; }
      public string Speed { get; set; }
      public string State { get; set; }
      public string Time { get; set; }
    }

    public class PlotData
    {
      public uint EventId { get; set; }
      public TraceData[] Points { get; set; }
    }

    [WebMethod]
    public static PlotData[] GetPlotData(string events)
    {
      List<PlotData> data = new List<PlotData>();
      //events is a comma seperated string with parameters in the order of vehicleEventId, SYSID, startTimeGMt, endTimeGMT repeating
      if (events == "")
      {

      }
      else
      {
        events = events.Substring(0, events.Length - 1);

        CAMSDataInterfaceClient client = new CAMSDataInterfaceClient();
        client.ClientCredentials.UserName.UserName = ConfigurationManager.AppSettings["CDIUsername"];
        client.ClientCredentials.UserName.Password = ConfigurationManager.AppSettings["CDIPassword"];
        List<PlotPointRequest> req = new List<PlotPointRequest>();
        string[] parsedEvents = events.Split(',');
        for (int i = 0; i < parsedEvents.Length; i += 4)
        {

          AssetId a = new AssetId
          {
            Id = Convert.ToUInt16(parsedEvents[i + 1]),
            ServerName = ConfigurationManager.AppSettings["CDIServer"]

          };
          EventAssetId e = new EventAssetId
          {
            Id = Convert.ToUInt32(parsedEvents[i]),
            Assetid = a
          };
          PlotPointRequest r = new PlotPointRequest
          {
            EAId = e,
            StartGMT = Convert.ToDateTime(parsedEvents[i + 2]),
            EndGMT = Convert.ToDateTime(parsedEvents[i + 3])

          };
          req.Add(r);
        }
        var results = client.GetPlotData(req.ToArray());
        if (results != null)
        {
          foreach (var plot in results.PlotPoints)
          {
            PlotData p = new PlotData();
            p.EventId = plot.Key.Id;
            TraceData[] Points = new TraceData[plot.Value.Length];
            int i = 0;
            foreach (var point in plot.Value)
            {
              TraceData trace = new TraceData()
              {
                Latitude = point.Lat.ToString(),
                Longitude = point.Lng.ToString(),
                Speed = point.Speed.ToString(),
                State = point.State.ToString(),
                Time = point.TimeGMT.ToString()
              };
              Points[i++] = trace;
            }
            p.Points = Points;
            data.Add(p);
          }
        }
        client.Close();
      }

      return data.ToArray();
    }

    [WebMethod]
    public static void SetTimeFilter(string setting)
    {
      string email = HttpContext.Current.Session["Email"].ToString();
      string sql = "Update ASPWebUserSettings set TimeFilter = " + setting + " Where Email = \'" + email + "\';";
      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      con.Open();
      try
      {

        cmd.ExecuteNonQuery();
      }
      catch { }
      con.Close();

    }

    [WebMethod]
    public static void SetMapCenter(double lat, double lng)
    {
      string email = HttpContext.Current.Session["Email"].ToString();
      string sql = "Update ASPWebUserSettings set MapCenterLat = " + lat.ToString() + ", MapCenterLng = " + lng.ToString() + " Where Email = \'" + email + "\';";
      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      con.Open();
      try
      {

        cmd.ExecuteNonQuery();
      }
      catch { }
      con.Close();
    }

    [WebMethod]
    public static void SetMapZoom(string setting)
    {
      string email = HttpContext.Current.Session["Email"].ToString();
      string sql = "Update ASPWebUserSettings set MapCenterZoom = " + setting + " Where Email = \'" + email + "\';";
      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      con.Open();
      try
      {

        cmd.ExecuteNonQuery();
      }
      catch { }
      con.Close();
    }

    [WebMethod]
    public static void SetMapDetails(double lat, double lng, int zoom)
    {
      string email = HttpContext.Current.Session["Email"].ToString();
      string sql = "Update ASPWebUserSettings set MapCenterLat = " + lat.ToString() + ", MapCenterLng = " + lng.ToString() + ", MapCenterZoom = " + zoom.ToString() + " Where Email = \'" + email + "\';";
      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      con.Open();
      try
      {

        cmd.ExecuteNonQuery();
      }
      catch { }
      con.Close();
    }

    [WebMethod]
    public static void SetShowTrace(string setting)
    {
      string email = HttpContext.Current.Session["Email"].ToString();
      int val = 0;
      if (setting.ToUpper() == "TRUE")
        val = 1;
      string sql = "Update ASPWebUserSettings set ShowTrace = " + val.ToString() + " Where Email = \'" + email + "\';";
      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      con.Open();
      try
      {

        cmd.ExecuteNonQuery();
      }
      catch { }
      con.Close();
    }
    [WebMethod]
    public static void SetShowPoints(string setting)
    {
      string email = HttpContext.Current.Session["Email"].ToString();
      int val = 0;
      if (setting.ToUpper() == "TRUE")
        val = 1;
      string sql = "Update ASPWebUserSettings set ShowPoints = " + val.ToString() + " Where Email = \'" + email + "\';";
      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      con.Open();
      try
      {

        cmd.ExecuteNonQuery();
      }
      catch { }
      con.Close();
    }

    [WebMethod]
    public static void SetKeepInView(string setting)
    {
      string email = HttpContext.Current.Session["Email"].ToString();
      int val = 0;
      if (setting.ToUpper() == "TRUE")
        val = 1;
      string sql = "Update ASPWebUserSettings set KeepInView = " + val.ToString() + " Where Email = \'" + email + "\';";
      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      con.Open();
      try
      {

        cmd.ExecuteNonQuery();
      }
      catch { }
      con.Close();
    }

    [WebMethod]
    public static void SetTraceHours(string setting)
    {
      string email = HttpContext.Current.Session["Email"].ToString();

      string sql = "Update ASPWebUserSettings set TraceHours = " + setting.ToString() + " Where Email = \'" + email + "\';";
      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      con.Open();
      try
      {

        cmd.ExecuteNonQuery();
      }
      catch { }
      con.Close();
    }
    [WebMethod]
    public static void SetAssetDivWidth(string setting)
    {
      string email = HttpContext.Current.Session["Email"].ToString();

      string sql = "Update ASPWebUserSettings set AssetDivWidth = " + setting.ToString() + " Where Email = \'" + email + "\';";
      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      con.Open();
      try
      {

        cmd.ExecuteNonQuery();
      }
      catch { }
      con.Close();
    }

    [WebMethod]
    public static void SetTimeZoneOffset(string setting)
    {
      string email = HttpContext.Current.Session["Email"].ToString();
      HttpContext.Current.Session["TimeZoneOffset"] = setting;
      string sql = "Update ASPWebUserSettings set timeZoneOffset = " + setting.ToString() + " Where Email = \'" + email + "\';";
      SqlConnection con = new SqlConnection(ConfigurationManager.ConnectionStrings["DefaultConnection"].ConnectionString);
      SqlCommand cmd = new SqlCommand(sql, con);
      con.Open();
      try
      {

        cmd.ExecuteNonQuery();
      }
      catch { }
      con.Close();
    }

    public static void GetAssetStates()
    {
      if (AssetStates == null)
        AssetStates = new Dictionary<int, AssetStateParams[]>();
      CAMSDataInterfaceClient client = new CAMSDataInterfaceClient();
      client.ClientCredentials.UserName.UserName = ConfigurationManager.AppSettings["CDIUsername"];
      client.ClientCredentials.UserName.Password = ConfigurationManager.AppSettings["CDIPassword"];
      var assetList = client.GetAssetFilters();
      List<AssetId> list = new List<AssetId>();
      foreach (var asset in assetList.Assets)
      {
        AssetId a = new AssetId();
        a.Id = asset.AInfo.Assetid.Id;
        a.ServerName = ConfigurationManager.AppSettings["CDIServer"];
        list.Add(a);

      }
      var states = client.GetAssetStates(list.ToArray());
      foreach (var s in states.AssetStates)
      {
        try
        {
          AssetStates.Add(s.Key.Id, s.Value);
        }
        catch (ArgumentException) { }
      }
      var count = states.AssetStates.ToArray().Length;

    }

    public static string GetAssetStateString(int id, int state)
    {
      string stateStr = "";

      AssetStateParams[] p = AssetStates[id];
      foreach (var s in p)
      {

        if ((state & Convert.ToInt32(s.State)) != 0)
        {
          stateStr = stateStr + " " + s.StateDscr;
        }
      }
      
      if (stateStr == "")
        return ("---");
      else
        return (stateStr);
    }
  }
  
}