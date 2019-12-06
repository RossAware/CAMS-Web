<%@ Page Title="CAMS Web" Language="C#" AutoEventWireup="true" CodeBehind="Default.aspx.cs" Inherits="WebApplication2._Default" %>

<!DOCTYPE html>

<html xmlns="http://www.w3.org/1999/xhtml">
<head runat="server">
  <link rel="stylesheet" type="text/css" href="MapScreenStyle.css" />
  <title>CAMS</title>

  <meta name='viewport' content='initial-scale=1,maximum-scale=1,user-scalable=no' />
  <script src='https://api.tiles.mapbox.com/mapbox-gl-js/v1.5.0/mapbox-gl.js'></script>
  <link href='https://api.tiles.mapbox.com/mapbox-gl-js/v1.5.0/mapbox-gl.css' rel='stylesheet' />
  <script src="https://ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js"></script>
  
  
  <!--
  <script src="http://ecn.dev.virtualearth.net/mapcontrol/mapcontrol.ashx?v=7.0"></script>
  <script src="https://cdnjs.cloudflare.com/ajax/libs/modernizr/2.8.3/modernizr.min.js" type="text/javascript"></script>
  
  <script src="http://jquery.com/"></script>
  <script src="http://api.jquery.com/on/"></script>
  
    -->
  <script src="Scripts/moment.js"></script>
  <script type="text/javascript">

    //Objects declarations

    //Variable declarations
    var map = null;
    var infobox;
    var curPos = null;
    var assetGridCtlId = '<%=AssetGrid.ClientID%>';
    var assetDetailsCtlId = '<%=AssetDetailsGrid.ClientID%>';
    var traceGridCtlId = '<%=AssetTraceGrid.ClientID%>';
    var assetGridCtrl = null; //variable to store assetGrid gridview control
    var assetDetailsCtrl = null; //variable to store assetDetailsGrid gridview control
    var currMapCenter = null;
    var currMapCenterLat = null;
    var currMapCenterLng = null;
    var currMapZoom;
    var assetPanelWidth = 0;
    var queryResDivHeight = 0;
    var toolBarWidth = 38;
    var resizeToolDiv = false;
    var resizeQueryResDiv = false;
    var selectedVehicleName = "";
    var selectedSYSID = 0;
    var inClick = false;
    var initialLoad = false;
    var rowTop = 0;
    var tracePins = [];
    var sysidNameList = [];
    var mapKey;
    var page = window.location.pathname;
    var iconSize = '32x32';
    var profileId = '0';
    var plottedEventIds = new Map(); // for tracking what event ids are plotted
    var eventPlotLines = new Map(); // for storing the actual plot lines objects
    var vehicleInfo = new Map();
    var updateUnits = new Map();
    var vehImages = new Map();
    var locatePin = null;
    var traceLine = null;
    var locateLoad = false;
    var mapLoaded = false;
    var lastEidPlotted = 0;
    var g_VehicleNameOrderBy = "name"; //for tracking vehicle name sorting in query filters
    var g_VehicleNameAscDesc = "asc"; //for tracking vehicle name sorting in query filters
    var g_VehicleNameTypeFilter = ""; //for tracking vehicle name filtering by vehicle type in query filters
    var g_VehicleTypeAscDesc = "asc"; //for tracking sorting of vheicle type
    var g_EventTypeAscDesc = "asc";
    var popup = new mapboxgl.Popup({
      closeButton: false,
      closeOnClick: false
    });

    var traceGeojson = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": []
        }
      }]
    };

    var plotGeojson = {
      "type": "FeatureCollection",
      "features": [{
        "type": "Feature",
        "geometry": {
          "type": "LineString",
          "coordinates": []
        }
      }]
    };


    //Event Handlers
    window.onresize = autoResizeView;
    window.onmouseup = mouseButtonUp;
    window.onmousemove = mouseMove;

    

    function setupPage() {
      
      GetProfileId();
      GetUserSettings();
      UpdateUserTimezone();
      //getControls();
      document.getElementById('adminToolsDiv').style.display = "none";
      document.getElementById('queryResultsPanelDiv').style.display = "none";
      document.getElementById('queryFiltersPanelDiv').style.display = "none";
      //autoResizeView();
      //loadInitialMap();
      //showVehiclePositions();
      //window.setInterval(timerTimeout, 15000);

    }

    function getControls() {

      if (null == assetGridCtrl) {
        assetGridCtrl = document.getElementById(assetGridCtlId);
      }
      if (null == assetDetailsCtrl) {
        assetDetailsCtrl = document.getElementById(assetDetailsCtlId);
      }

      if (currMapCenter == null) {
        //currMapCenter = new Microsoft.Maps.Location(50.419485, -101.045367);
      }


    }

    function autoResizeView() {
      //var windowHeight = Math.max(document.documentElement.clientHeight, window.innerHeight || 0);
      var windowHeight = window.innerHeight;
      var assetGridHeight = windowHeight * 0.5;
      var assetDetailsHeight = windowHeight - assetGridHeight;
      var assetGridBufferWidth = 6;
      var resizeQueryResDivHeight = 6;
      var mapDivHeight = window.innerHeight;
      var queryResultsDivDisplay = document.getElementById('queryResultsPanelDiv').style.display;

      //document.getElementById("queryResultsLoadingBarDiv").style.top = (assetGridHeight - 10) + 'px';
      //set up main divs heights
      document.getElementById('assetGridTableDiv').style.height = (window.innerHeight) + 'px'; 
      document.getElementById('sideToolbarDiv').style.height = (window.innerHeight) + 'px';
      //document.getElementById('assetPanelResizeDiv').style.height = (window.innerHeight) + 'px';
      document.getElementById('adminToolsDiv').style.height = (window.innerHeight) + 'px';
      document.getElementById('queryFiltersPanelDiv').style.height = (window.innerHeight) + 'px';

      if (queryResultsDivDisplay != "none") {
        if (queryResDivHeight == 0)
          queryResDivHeight = Math.floor(window.innerHeight * 0.25);
        document.getElementById('queryResultsPanelDiv').style.height = (queryResDivHeight - resizeQueryResDivHeight) + 'px';
        mapDivHeight = window.innerHeight - queryResDivHeight - resizeQueryResDivHeight;
        //console.log("Height: " + height + " MapDivHeight: " + mapDivHeight);
      }

      document.getElementById('divMap').style.height = (mapDivHeight) + 'px';
      document.getElementById('divMapContainer').style.height = (window.innerHeight) + 'px';

      var assetGridDisplay = document.getElementById('assetGridTableDiv').style.display;
      var adminPanelDisplay = document.getElementById('adminToolsDiv').style.display;
      var queryFiltersPanelDisplay = document.getElementById('queryFiltersPanelDiv').style.display;
      var alertPanelDisplay = document.getElementById('alertScreenDiv').style.display;

      //var windowWidth = Math.max(document.documentElement.clientWidth, window.innerWidth || 0);
      var windowWidth = window.innerWidth;
      //var assetGridWidth = Math.round(windowWidth * 0.20);
      var adminDivWidth = Math.round(windowWidth * 0.20) - 38;
      var mapWidth = windowWidth;
      var sideToolBarFixed = 0;
      var leftResizeDivWidth = 6; 
      var assetGridWidth = Math.round(windowWidth * 0.20) + 6;// + assetGridBufferWidth;
      if (assetPanelWidth == 0)
        assetPanelWidth = assetGridWidth;

      if (assetGridDisplay != "none") {
        if (assetPanelWidth == 0) {
          document.getElementById('assetGridTableDiv').style.width = assetGridWidth + 'px'; //adding the width of the divider
          document.getElementById('assetGridTable').style.width = (assetGridWidth - assetGridBufferWidth) + 'px';
          document.getElementById('assetDetailsTable').style.width = (assetGridWidth - assetGridBufferWidth) + 'px';
          mapWidth = windowWidth - assetGridWidth - toolBarWidth - leftResizeDivWidth;

        }
        else {
          document.getElementById('assetGridTableDiv').style.width = assetPanelWidth + 'px';
          document.getElementById('assetGridTable').style.width = (assetPanelWidth - assetGridBufferWidth) + 'px';
          document.getElementById('assetDetailsTable').style.width = (assetPanelWidth - assetGridBufferWidth) + 'px';
          mapWidth = windowWidth - assetPanelWidth - toolBarWidth - leftResizeDivWidth;
        }
        var divHeight = $("#assetGridTableDiv").innerHeight();
        var toolsHeight = $("#assetGridToolsDiv").outerHeight() + 6;
        //var dividerHeight = $("#assetPanelDivider").outerHeight() + 6;
        var gridHeight = Math.floor(divHeight * 0.5);
        var detailsHeight = divHeight - (toolsHeight + gridHeight + 15);

        document.getElementById('assetGridTable').style.height = gridHeight + 'px';
        document.getElementById('assetDetailsTable').style.height = detailsHeight + 'px';

        sideToolBarFixed = 1;
      }
      if (alertPanelDisplay != "none") {
        var w = windowWidth - toolBarWidth - 10;
        //document.getElementById('alertScreenDiv').style.left = toolBarWidth + 'px';  
        document.getElementById('alertScreenDiv').style.width = w + 'px';
        document.getElementById('alertScreenDiv').style.height = (window.innerHeight) + 'px';
      }

      if (adminPanelDisplay != "none") {
        document.getElementById('adminToolsDiv').style.width = adminDivWidth + 'px';
        mapWidth = mapWidth - adminDivWidth - 5 - leftResizeDivWidth;
        //mapWidth = mapWidth - 15;
        //sideToolBarFixed = 1;
      }

      if (queryFiltersPanelDisplay != "none") {
        if (assetPanelWidth == 0) {
          var filterTableWidth = assetGridWidth - 8;
          document.getElementById('queryFiltersPanelDiv').style.width = assetGridWidth + 'px';
          document.getElementById('vehicleFiltersDiv').style.width = filterTableWidth + 'px';
          document.getElementById('vehicleTypeFiltersDiv').style.width = filterTableWidth + 'px';
          document.getElementById('eventTypeFiltersDiv').style.width = filterTableWidth + 'px';
          mapWidth = windowWidth - assetGridWidth - toolBarWidth - leftResizeDivWidth;
        }
        else {
          var filterTableWidth = assetPanelWidth - 8;
          document.getElementById('queryFiltersPanelDiv').style.width = assetPanelWidth + 'px';
          document.getElementById('vehicleFiltersDiv').style.width = filterTableWidth + 'px';
          document.getElementById('vehicleTypeFiltersDiv').style.width = filterTableWidth + 'px';
          document.getElementById('eventTypeFiltersDiv').style.width = filterTableWidth + 'px';
          mapWidth = windowWidth - assetPanelWidth - toolBarWidth - leftResizeDivWidth;
        }
        var h = Math.floor(window.innerHeight * 0.25) - 3;

        document.getElementById('timeFiltersDiv').style.height = h + 'px';
        document.getElementById('vehicleFiltersDiv').style.height = h + 'px';
        document.getElementById('vehicleTypeFiltersDiv').style.height = h + 'px';
        document.getElementById('eventTypeFiltersDiv').style.height = h + 'px';

        
        var queryResDivWidth = mapWidth;
        var queryResWidth = Math.floor(queryResDivWidth * 0.7);
        document.getElementById('queryResultsTableDiv').style.width = queryResWidth + 'px';
        
        sideToolBarFixed = 1;
      }



      if (sideToolBarFixed == 0) {
        document.getElementById('sideToolbarDiv').style.position = 'fixed';
      }
      else {
        document.getElementById('sideToolbarDiv').style.position = 'relative';
      }


      document.getElementById('sideToolbarDiv').style.width = toolBarWidth + 'px';
      document.getElementById('divMapContainer').style.width = mapWidth + 'px';
      document.getElementById('divMap').style.width = (mapWidth - leftResizeDivWidth) + 'px';
      document.getElementById('bottomResizeDiv').style.width =  (mapWidth - leftResizeDivWidth) + 'px';
      document.getElementById('queryResultsPanelDiv').style.width =  (mapWidth - leftResizeDivWidth - 2) + 'px';

      if (map != null) {
        map.resize();
      }

    }

    function loadInitialMap() {


      mapboxgl.accessToken = mapKey;
      console.log(currMapCenterLat);
      console.log(currMapCenterLng);
      map = new mapboxgl.Map({
        container: 'divMap', // container id
        style: 'mapbox://styles/mapbox/streets-v11', // stylesheet location
        center: [currMapCenterLng, currMapCenterLat], // starting position [lng, lat]
        zoom: currMapZoom // starting zoom
      });


      console.log('map created');
      map.on('load',

        function () {

          map.addLayer({
            "id": "trace",
            "type": "line",
            "source": {
              'type': 'geojson',
              'data': traceGeojson
            },
            "layout": {
              "visibility": "visible",
              "line-join": "round",
              "line-cap": "round"
            },
            "paint": {
              "line-color": "#888",
              "line-width": 4
            }
          });

          map.addLayer({
            "id": "queryPlots",
            "type": "line",
            "source": {
              'type': 'geojson',
              'data': plotGeojson
            },
            "layout": {
              "visibility": "visible",
              "line-join": "round",
              "line-cap": "round"
            },
            "paint": {
              "line-color": "#888",
              "line-width": 4
            }
          });

          mapLoaded = true
          //BindAssetGrid
          window.setInterval(timerTimeout, 15000);
        });

      map.on('moveend', function () {
        updateAssetInfo();
      });
      
    }

    function refreshMap() {
      //console.log("Refresh Map Called");
      showVehiclePositions();
      BindTraceDataGrid();
    }

    function showVehiclePositions() {
      if (map == null)
        return;
      //tracePins.length = 0;

      var scrollTop = ($("#assetGridTable").scrollTop());
      var scrollLeft = ($("#assetGridTable").scrollLeft());

      var table = document.getElementById("assetGridTable");

      for (var i = table.rows.length - 1; i >= 0; i--) {
        table.deleteRow(i);
      }

      var headerRow = document.createElement("tr");
      var headerName = document.createElement("th");
      var headerSpeed = document.createElement("th");
      var headerState = document.createElement("th");
      var headerTime = document.createElement("th");
      var headerSysid = document.createElement("th");
      var hNameText = document.createTextNode("Name");
      var hSpeedText = document.createTextNode("Speed");
      var hStateText = document.createTextNode("State");
      var hTimeText = document.createTextNode("Time");
      var hSysidText = document.createTextNode("Id");
      //add labels to header row
      headerName.appendChild(hNameText);
      headerSpeed.appendChild(hSpeedText);
      headerState.appendChild(hStateText);
      headerTime.appendChild(hTimeText);
      headerSysid.appendChild(hSysidText);
      //add to table row
      headerRow.appendChild(headerName);
      headerRow.appendChild(headerSpeed);
      headerRow.appendChild(headerState);
      headerRow.appendChild(headerTime);
      headerRow.appendChild(headerSysid);
      //add to the table
      table.appendChild(headerRow);

      assetGridCtrl = document.getElementById(assetGridCtlId);
      var rowCount = assetGridCtrl.rows.length;
      var lat, lng;
      var icon, name;
      var speed, state, lastPosTime;
      var currRow;
      var sysid;
      var index = 0;
      //console.log("Start refresh rowCount:" + rowCount);

      //plotTracePoints();
      for (var i = 1; i < rowCount; i++) {
        currRow = assetGridCtrl.rows[i];
        if (currRow == null)
          return;
        speed = currRow.cells[2].innerText;
        state = currRow.cells[3].innerText;
        lastPosTime = currRow.cells[6].innerText;
        lat = parseFloat(currRow.cells[4].innerText);
        lng = parseFloat(currRow.cells[5].innerText);
        name = currRow.cells[1].innerText;
        icon = getIcon(currRow.cells[7].innerText);
        sysid = parseInt(currRow.cells[8].innerText);

        var row = document.createElement("tr");
        var nameTD = document.createElement("td");
        var speedTD = document.createElement("td");
        var stateTD = document.createElement("td");
        var timeTD = document.createElement("td");
        var sysidTD = document.createElement("td");

        var nameText = document.createTextNode(currRow.cells[1].innerText);
        var speedText = document.createTextNode(currRow.cells[2].innerText);
        var stateText = document.createTextNode(currRow.cells[3].innerText);
        var timeText = document.createTextNode(currRow.cells[6].innerText);
        var sysidText = document.createTextNode(currRow.cells[8].innerText);
        //add data to row
        nameTD.appendChild(nameText);
        speedTD.appendChild(speedText);
        stateTD.appendChild(stateText);
        timeTD.appendChild(timeText);
        sysidTD.appendChild(sysidText);
        //add to table row
        row.appendChild(nameTD);
        row.appendChild(speedTD);
        row.appendChild(stateTD);
        row.appendChild(timeTD);
        row.appendChild(sysidTD);
        row.id = sysid.toString();
        /*
        if (initialLoad == false) {
          map.setView({
            center: new Microsoft.Maps.Location(lat, lng),
            enableSearchLogo: false
          });
          initialLoad = true;
        }
        */
        var queryOpen = document.getElementById('queryFiltersPanelDiv').style.display;
        if (queryOpen != "none")
          return;

        /*
        var mapLLng = map.getBounds().getWest();
        var mapRLng = map.getBounds().getEast();
        var mapTLat = map.getBounds().getNorth();
        var mapBLat = map.getBounds().getSouth();
        */
        //var foundSelected = false;

        if (selectedSYSID == sysid) {

          row.className = 'selectedAssetRow';
          //row.scrollIntoView(true);
          index = i;
        }

        table.appendChild(row);
      }
      updateSelectedUnit();
      addAssetGridRowEvents();

      $("#assetGridTable").scrollTop(scrollTop);
      $("#assetGridTable").scrollLeft(scrollLeft);


    }

    function updateSelectedUnit() {/*
      var sel = vehicleInfo.get(parseInt(selectedSYSID));
      if (sel != null) {
        var mapLLng = map.getBounds().getWest();
        var mapRLng = map.getBounds().getEast();
        var mapTLat = map.getBounds().getNorth();
        var mapBLat = map.getBounds().getSouth();
        var width = document.getElementById('assetGridTableDiv').style.display;
        if (width != "none") {
          if (document.getElementById("EnableTrackingCheckbox").checked) {
            //console.log(lng < mapLLng || lng > mapRLng || lat > mapTLat || lat < mapBLat);
            if (sel.lng < mapLLng || sel.lng > mapRLng || sel.lat > mapTLat || sel.lat < mapBLat) {

              map.setCenter(formatLngLat(sel.lng, sel.lat));

            }
          }
        }

        if (locateLoad == false) {
          locateLoad = true;
          map.loadImage('Images/Misc/Locate.png', function (error, image) {
            if (error) throw error;
            map.addImage('cat', image);
            map.addLayer({
              "id": "locate",
              "type": "symbol",
              "source": {
                "type": "geojson",
                "data": {
                  "type": "FeatureCollection",
                  "features": [{
                    "type": "Feature",
                    "geometry": {
                      "type": "Point",
                      "coordinates": [sel.lng, sel.lat]
                    }
                  }]
                }
              },
              "layout": {
                "icon-image": "Track",
                "icon-size": 1.0
              }
            });
          });
        }
        else {
          map.getSource('locate').setData(sel.lng, sel.lat);
        }
        */
        /*
        var trackLocation = new Microsoft.Maps.Location(sel.lat, sel.lng);
        if (locatePin == null) {
          var pinLocate = new Microsoft.Maps.Pushpin(trackLocation, {
            icon: 'Images/Misc/Locate.png',
            width: 32,
            height: 32,
            draggable: false,
            anchor: new Microsoft.Maps.Point(16, 16),
            type: 'locate'
          });
          pinLocate.metadata = {
            title: name,
            description: 'Type: ' + sel.vehicleType + '<br/>Speed: ' + sel.speed + '<br/>State: ' + sel.state + '<br/>Latitude: ' + sel.lat + '<br/>Longitiude: '
              + sel.lng + '<br/>Position Time: ' + '<br/>' + sel.posTime
          };
          Microsoft.Maps.Events.addHandler(pinLocate, 'click', assetClicked);
          Microsoft.Maps.Events.addHandler(pinLocate, 'mouseover', assetHover);
          Microsoft.Maps.Events.addHandler(pinLocate, 'mouseout', assetUnhover);
          map.entities.push(pinLocate);
          locatePin = pinLocate;
        }
        else {
          locatePin.metadata = {
            title: name,
            description: 'Type: ' + sel.vehicleType + '<br/>Speed: ' + sel.speed + '<br/>State: ' + sel.state + '<br/>Latitude: ' + sel.lat + '<br/>Longitiude: '
              + sel.lng + '<br/>Position Time: ' + '<br/>' + sel.posTime
          };
          locatePin.setLocation(trackLocation);
          map.entities.push(locatePin);
        }
      }
      else {
        map.entities.remove(locatePin);
      }
      */
      //}
    }

    /*
    function updateSelectedUnitBing() {
      var sel = vehicleInfo.get(parseInt(selectedSYSID));
      if (sel != null) {
        var mapLLng = map.getBounds().getWest();
        var mapRLng = map.getBounds().getEast();
        var mapTLat = map.getBounds().getNorth();
        var mapBLat = map.getBounds().getSouth();
        var width = document.getElementById('assetGridTableDiv').style.display;
        if (width != "none") {
          if (document.getElementById("EnableTrackingCheckbox").checked) {
            //console.log(lng < mapLLng || lng > mapRLng || lat > mapTLat || lat < mapBLat);
            if (sel.lng < mapLLng || sel.lng > mapRLng || sel.lat > mapTLat || sel.lat < mapBLat) {

              map.setView({
                center: new Microsoft.Maps.Location(sel.lat, sel.lng),
                enableSearchLogo: false
              });

            }
          }
        }

        var trackLocation = new Microsoft.Maps.Location(sel.lat, sel.lng);
        if (locatePin == null) {
          var pinLocate = new Microsoft.Maps.Pushpin(trackLocation, {
            icon: 'Images/Misc/Locate.png',
            width: 32,
            height: 32,
            draggable: false,
            anchor: new Microsoft.Maps.Point(16, 16),
            type: 'locate'
          });
          pinLocate.metadata = {
            title: name,
            description: 'Type: ' + sel.vehicleType + '<br/>Speed: ' + sel.speed + '<br/>State: ' + sel.state + '<br/>Latitude: ' + sel.lat + '<br/>Longitiude: '
              + sel.lng + '<br/>Position Time: ' + '<br/>' + sel.posTime
          };
          Microsoft.Maps.Events.addHandler(pinLocate, 'click', assetClicked);
          Microsoft.Maps.Events.addHandler(pinLocate, 'mouseover', assetHover);
          Microsoft.Maps.Events.addHandler(pinLocate, 'mouseout', assetUnhover);
          map.entities.push(pinLocate);
          locatePin = pinLocate;
        }
        else {
          locatePin.metadata = {
            title: name,
            description: 'Type: ' + sel.vehicleType + '<br/>Speed: ' + sel.speed + '<br/>State: ' + sel.state + '<br/>Latitude: ' + sel.lat + '<br/>Longitiude: '
              + sel.lng + '<br/>Position Time: ' + '<br/>' + sel.posTime
          };
          locatePin.setLocation(trackLocation);
          map.entities.push(locatePin);
        }
      }
      else {
        map.entities.remove(locatePin);
      }
    }
    */
    function showDoubleClickVehiclePositions(doubleClickName) {
      if (map == null)
        return;

      var table = document.getElementById("assetGridTable");

      var scrollTop = ($("#assetGridTable").scrollTop());
      var scrollLeft = ($("#assetGridTable").scrollLeft());

      for (var i = table.rows.length - 1; i >= 0; i--) {
        table.deleteRow(i);
      }

      var headerRow = document.createElement("tr");
      var headerName = document.createElement("th");
      var headerSpeed = document.createElement("th");
      var headerState = document.createElement("th");
      var headerSysid = document.createElement("th");

      var hNameText = document.createTextNode("Name");
      var hSpeedText = document.createTextNode("Speed");
      var hStateText = document.createTextNode("State");
      var hSysidText = document.createTextNode("Id");
      //add labels to header row
      headerName.appendChild(hNameText);
      headerSpeed.appendChild(hSpeedText);
      headerState.appendChild(hStateText);
      headerSysid.appendChild(hSysidText);
      //add to table row
      headerRow.appendChild(headerName);
      headerRow.appendChild(headerSpeed);
      headerRow.appendChild(headerState);
      headerRow.appendChild(headerSysid);
      //add to the table
      table.appendChild(headerRow);

      assetGridCtrl = document.getElementById(assetGridCtlId);
      var rowCount = assetGridCtrl.rows.length;
      var lat, lng;
      var icon, name;
      var speed, state, lastPosTime;
      var currRow;
      var sysid;

      for (var i = 1; i < rowCount; i++) {
        currRow = assetGridCtrl.rows[i];
        if (currRow == null)
          continue;
        speed = currRow.cells[2].innerText;
        state = currRow.cells[3].innerText;
        lastPosTime = currRow.cells[6].innerText;
        lat = parseFloat(currRow.cells[4].innerText);
        lng = parseFloat(currRow.cells[5].innerText);
        name = currRow.cells[1].innerText;
        icon = getIcon(currRow.cells[7].innerText);
        sysid = currRow.cells[8].innerText;

        var row = document.createElement("tr");
        var nameTD = document.createElement("td");
        var speedTD = document.createElement("td");
        var stateTD = document.createElement("td");
        var sysidTD = document.createElement("td");
        var nameText = document.createTextNode(currRow.cells[1].innerText);
        var speedText = document.createTextNode(currRow.cells[2].innerText);
        var stateText = document.createTextNode(currRow.cells[3].innerText);
        var sysidText = document.createTextNode(currRow.cells[8].innerText);
        //add data to row
        nameTD.appendChild(nameText);
        speedTD.appendChild(speedText);
        stateTD.appendChild(stateText);
        sysidTD.appendChild(sysidText);
        //add to table row
        row.appendChild(nameTD);
        row.appendChild(speedTD);
        row.appendChild(stateTD);
        row.appendChild(sysidTD);

        //row.setAttribute('click', 'clickAssetGrid('+nameText+');');
        //add to the table
        //row.id = sysidText;


        if (name == doubleClickName) {

          map.setCenter(formatLngLat(lng, lat));
          
          row.className = 'selectedAssetRow';

        }

        table.appendChild(row);

      }

      addAssetGridRowEvents();

      $("#assetGridTable").scrollTop(scrollTop);
      $("#assetGridTable").scrollLeft(scrollLeft);

      //autoResizeView();
    }

    function getIcon(iconName) {
      return ('Images/VehicleIcons/' + iconSize + '/' + iconName);

    }

    function showClickedFromMap() {
      if (map == null)
        return;
      //tracePins.length = 0;

      var table = document.getElementById("assetGridTable");

      for (var i = table.rows.length - 1; i >= 0; i--) {
        table.deleteRow(i);
      }

      var headerRow = document.createElement("tr");
      var headerName = document.createElement("th");
      var headerSpeed = document.createElement("th");
      var headerState = document.createElement("th");
      var headerTime = document.createElement("th");
      var headerSysid = document.createElement("th");
      var hNameText = document.createTextNode("Name");
      var hSpeedText = document.createTextNode("Speed");
      var hStateText = document.createTextNode("State");
      var hTimeText = document.createTextNode("Time");
      var hSysidText = document.createTextNode("Id");
      //add labels to header row
      headerName.appendChild(hNameText);
      headerSpeed.appendChild(hSpeedText);
      headerState.appendChild(hStateText);
      headerTime.appendChild(hTimeText);
      headerSysid.appendChild(hSysidText);
      //add to table row
      headerRow.appendChild(headerName);
      headerRow.appendChild(headerSpeed);
      headerRow.appendChild(headerState);
      headerRow.appendChild(headerTime);
      headerRow.appendChild(headerSysid);
      //add to the table
      table.appendChild(headerRow);

      assetGridCtrl = document.getElementById(assetGridCtlId);
      var rowCount = assetGridCtrl.rows.length;
      var lat, lng;
      var icon, name;
      var speed, state, lastPosTime;
      var currRow;
      var sysid;
      var index = 0;

      //plotTracePoints();
      for (var i = 1; i < rowCount; i++) {
        currRow = assetGridCtrl.rows[i];
        if (currRow == null)
          return;
        speed = currRow.cells[2].innerText;
        state = currRow.cells[3].innerText;
        lastPosTime = currRow.cells[6].innerText;
        lat = parseFloat(currRow.cells[4].innerText);
        lng = parseFloat(currRow.cells[5].innerText);
        name = currRow.cells[1].innerText;
        icon = getIcon(currRow.cells[7].innerText);
        sysid = parseInt(currRow.cells[8].innerText);

        var row = document.createElement("tr");
        var nameTD = document.createElement("td");
        var speedTD = document.createElement("td");
        var stateTD = document.createElement("td");
        var timeTD = document.createElement("td");
        var sysidTD = document.createElement("td");

        var nameText = document.createTextNode(currRow.cells[1].innerText);
        var speedText = document.createTextNode(currRow.cells[2].innerText);
        var stateText = document.createTextNode(currRow.cells[3].innerText);
        var timeText = document.createTextNode(currRow.cells[6].innerText);
        var sysidText = document.createTextNode(currRow.cells[8].innerText);
        //add data to row
        nameTD.appendChild(nameText);
        speedTD.appendChild(speedText);
        stateTD.appendChild(stateText);
        timeTD.appendChild(timeText);
        sysidTD.appendChild(sysidText);
        //add to table row
        row.appendChild(nameTD);
        row.appendChild(speedTD);
        row.appendChild(stateTD);
        row.appendChild(timeTD);
        row.appendChild(sysidTD);
        row.id = sysid.toString();

        if (initialLoad == false) {

          map.setCenter(formatLngLat(lng, lat));
          /*
          map.setView({
            center: new Microsoft.Maps.Location(lat, lng),
            enableSearchLogo: false
          });
          */
          initialLoad = true;
        }

        if (name == selectedSYSID) {
          row.className = 'selectedAssetRow';
          row.scrollIntoView(true);
          index = i;
        }



        table.appendChild(row);

      }


      updateSelectedUnit();
      addAssetGridRowEvents();
      var selRow = document.getElementById(selectedSYSID.toString());
      selRow.scrollIntoView(true);

    }

    function addAssetGridRowEvents() {
      $("#assetGridTable tr").on("click", function () {
        // do something

        var nameText = $(this).children("td:first").text();
        var sysidText = $(this).children("td:last").text();

        //console.log("clicked");
        //removeTrace();
        if (sysidText == null) {
          return;
        }

        var table = document.getElementById("assetGridTable");
        for (var i = table.rows.length - 1; i >= 0; i--) {
          table.rows[i].class = "";
        }

        $(this).class = 'selectedAssetRow';

        selectedVehicleName = nameText;
        selectedSYSID = parseInt(sysidText);

        PageMethods.SelectSysid(sysidText);
        showVehiclePositions();
        BindAssetDetailsGrid();
        BindTraceDataGrid();
      });

      $("#assetGridTable tr").on("dblclick", function () {
        // do something

        var nameText = $(this).children("td:first").text();
        var sysidText = $(this).children("td:last").text();
        //removeTrace();
        if (sysidText == null) {
          return;
          console.log("clicked returned");
        }
        selectedVehicleName = nameText;
        selectedSYSID = parseInt(sysidText);
        PageMethods.SelectSysid(sysidText);
        BindAssetDetailsGrid();
        BindTraceDataGrid();

        showDoubleClickVehiclePositions(nameText);

      });
    }

    //event when an asset pin is clicked
    function assetHover(e) {
      //Make sure the infobox has metadata to display.
      if (e.target.metadata) {
        //Set the infobox options with the metadata of the pushpin.

        infobox.setOptions({
          location: e.target.getLocation(),
          title: e.target.metadata.title,
          description: e.target.metadata.description,
          visible: true,
          maxHeight: 256
        });


      }
    }

    function assetUnhover(e) {
      //Make sure the infobox has metadata to display.
      if (e.target.metadata) {
        //Set the infobox options with the metadata of the pushpin.

        infobox.setOptions({
          visible: false
        });


      }
    }

    //event when an asset pin is double clicked
    function assetClicked(e) {
      //Make sure the infobox has metadata to display.
      if (e.target.metadata) {
        //Set the infobox options with the metadata of the pushpin.

        infobox.setOptions({
          location: e.target.getLocation(),
          title: e.target.metadata.title,
          description: e.target.metadata.description,
          visible: true,
          maxHeight: 256
        });

        var name = e.target.metadata.title;
        selectedSYSID = getSYSID(name);
        //PageMethods.SelectSysid(selectedSYSID);
        //showClickedFromMap();
        showVehiclePositions();
        BindTraceDataGrid();

      }
    }

    //event when a trace point pin is clicked
    function traceHover(e) {
      //Make sure the infobox has metadata to display.
      if (e.target.metadata) {
        //Set the infobox options with the metadata of the pushpin.
        infobox.setOptions({
          location: e.target.getLocation(),
          title: e.target.metadata.title,
          description: e.target.metadata.description,
          visible: true,
          maxHeight: 256
        });
      }
    }

    function traceUnhover(e) {
      //Make sure the infobox has metadata to display.
      if (e.target.metadata) {
        //Set the infobox options with the metadata of the pushpin.

        infobox.setOptions({
          visible: false
        });


      }
    }

    function lineHover(e) {
      //Make sure the infobox has metadata to display.
      if (e.target.metadata) {
        //Set the infobox options with the metadata of the pushpin.
        infobox.setOptions({
          location: e.location,
          title: e.target.metadata.title,
          description: e.target.metadata.description,
          visible: true,
          maxHeight: 300,
          maxWidth: 256
        });
      }
    }

    function lineUnhover(e) {
      //Make sure the infobox has metadata to display.
      if (e.target.metadata) {
        //Set the infobox options with the metadata of the pushpin.

        infobox.setOptions({
          visible: false
        });


      }
    }


    function getKeepInViewState() {
      return (document.getElementById("EnableTrackingCheckbox").checked);
    }

    function setKeepInViewState(state) {
      document.getElementById("EnableTrackingCheckbox").checked = state;
    }

    function getShowTraceState() {
      return (document.getElementById("EnableTraceCheckbox").checked);
    }

    function setShowTraceState(state) {
      document.getElementById("EnableTraceCheckbox").checked = state;
    }

    function showTraceClicked() {
      var chk = getShowTraceState();
      if (chk == true) {
        setShowTraceState(false);
      }
      else {
        setShowTraceState(true);

      }
      showAssetTraceClick();
    }

    function showAssetTraceClick() {
      //PageMethods.UpdateTraceData(getShowTraceState());
      if (getShowTraceState() == false) {
        //removeTrace();
        if (tracePins != null) {
          for (var k = 0; k < tracePins.length; k++) {
            if (tracePins[k] != null)
            map.entities.remove(tracePins[k].pin);
          }
        }
        tracePins.length = 0;
        if(traceLine!=null)
          traceLine.setOptions({ visible: false });
      }
      else {
        BindTraceDataGrid();
      }
      showVehiclePositions();
      UpdateShowTraceValue();
    }

    function keepInViewClicked() {
      var chk = getKeepInViewState();
      if (chk == true) {
        setKeepInViewState(false);
      }
      else {
        setKeepInViewState(true);
      }
      keepInViewCheckboxClicked();
    }

    function keepInViewCheckboxClicked() {

      showVehiclePositions();
      UpdateKeepInViewValue();
    }

    function getShowTracePointsState() {
      return (document.getElementById("EnableTracePointsCheckbox").checked);
    }

    function setShowTracePointsState(state) {
      document.getElementById("EnableTracePointsCheckbox").checked = state;
    }

    function showTracePointsClicked() {
      var chk = getShowTracePointsState();
      if (chk == true) {
        setShowTracePointsState(false);
      }
      else {
        setShowTracePointsState(true);

      }
      showAssetTracePointsClick();
    }

    function showAssetTracePointsClick() {
      showVehiclePositions();
      if (getShowTraceState() == true) {
        BindTraceDataGrid();
      }
      else {
        for (var k = 0; k < tracePins.length; k++) {
          map.entities.remove(tracePins[k].pin);
          //console.log("Removed pin: " + k);
        }
        tracePins.length = 0;
      }
      UpdateShowPointsValue();
    }

    function removeTrace() {
      
      formatLine(null, traceGeojson);
      
    }

    function updateTraceHours() {
      var e = document.getElementById("TraceHours");
      if (e == null)
        return;
      var hours = e.value;
      if (hours > 8) {
        hours = 8
        e.value = 8;
      }
      UpdateTraceHoursDB(hours);
      BindTraceDataGrid();
    }

    function BindAssetGrid() {
      console.log("BindAssetGrid called");
      if (mapLoaded == false) {
        console.log("BindGrid returned");
        return;
      }
      
      var e = document.getElementById("timeFilterDropDown");
      var secs = e.options[e.selectedIndex].value;
      var timeString = JSON.stringify({ time: secs });
      $.ajax({
        type: "POST",
        url: "default.aspx/GetAssetGridData",
        contentType: "application/json;charset=utf-8",
        data: timeString,
        dataType: "json",
        success: function (data) {

          $("#AssetGrid").empty();
          sysidNameList.length = 0;

          if (data.d.length > 0) {
            $("#AssetGrid").append("<tr><th>Dscr</th><th>Name</th> <th>LastSpeed</th>  <th>LastState</th> " +
              "<th>LastLat</th><th>LastPositionHeardLocal</th><th>BitmapFile</th>" +
              "<th>SYSID</th><th>ClientId</th></tr>");
            updateUnits.clear();
            for (var i = 0; i < data.d.length; i++) {

              $("#AssetGrid").append("<tr><td>" +
                data.d[i].Dscr + "</td> <td>" +
                data.d[i].Name + "</td> <td>" +
                data.d[i].LastSpeed + "</td> <td>" +
                data.d[i].LastState + "</td> <td>" +
                data.d[i].LastLat + "</td> <td>" +
                data.d[i].LastLng + "</td> <td>" +
                data.d[i].LastPositionHeardLocal + "</td> <td>" +
                data.d[i].BitmapFile + "</td> <td>" +
                data.d[i].SYSID + "</td> <td>" +
                data.d[i].ClientId + "</td></tr>");
              var sysid = parseInt(data.d[i].SYSID);
              var asset = { name: data.d[i].Name, sysid: sysid };
              sysidNameList.push(asset);
              updateUnits.set(sysid, sysid);
              
              addUpdateAssetInfo(sysid, data.d[i].Dscr, data.d[i].Name, parseInt(data.d[i].LastSpeed),
                data.d[i].LastState, parseFloat(data.d[i].LastLat), parseFloat(data.d[i].LastLng), data.d[i].BitmapFile,
                parseInt(data.d[i].ClientId), data.d[i].LastPositionHeardLocal);
            }
            
          }
          //console.log("results: " + data.d.length);
          clearNonReporitngUnits();
          refreshMap();
        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function clearNonReporitngUnits() {
      console.log('clearNonReporitngUnits');
      var remove = [];
      for (var key of vehicleInfo.values()) {
        /*
        if (key == undefined || key == null) {
          vehicleInfo.delete(key);
          continue;
        }
        */
        console.log("removed:" + key.sysid.toString());
        var a = updateUnits.get(key.sysid);
        if (a == null || a == undefined) {
          console.log(key.sysid.toString() + ' layer removed');
          var src = map.getSource('src' + val.sysid.toString());

          if (src != undefined) {
            map.removeLayer(key.sysid.toString());
            map.removeSource('src' + key.sysid.toString());
          }
          remove.push(key);
          
        }
      }
      for (var i = 0; i < remove.length; i++) {
        vehicleInfo.delete(remove[i]);
      }
    }

    function redrawUnits() {
      updateAssetInfo();
    }

    function updateAssetInfo() {
      var bnds = map.getBounds();
      var topLat = bnds.getNorth();
      var botLat = bnds.getSouth();
      var leftLng = bnds.getWest();
      var rightLng = bnds.getEast();


      for (var val of vehicleInfo.values()) {
        console.log(val.sysid.toString());
        if (val.lat < botLat || val.lat > topLat)
          continue;
        if (val.lng < leftLng || val.lng > rightLng)
          continue;
        if (val.sysid > 0) {
          var assetDescripton = formatAssetDescription(val.vehicleType, val.speed, val.state, val.lat, val.lng, val.posTime);
          addImageToMap(getIcon(val.bitmap), val.vehicleType)
          
          console.log("building json");

          var src = map.getSource('src' + val.sysid.toString());

          if (src != undefined) {
            var point = formatPoint(val.lng, val.lat, val.name, assetDescripton);
            console.log(point.toString());
            src.setData(point);
          }
          else {
            var point = formatPoint(val.lng, val.lat, val.name, assetDescripton);
            console.log(point.toString());
            map.addSource('src' + val.sysid.toString(), { type: 'geojson', data: point });
            map.addLayer(formatLayer(val.sysid.toString(), "src" + val.sysid.toString(), val.vehicleType, 0.5));
            addEventsToAssetLayer(sysid.toString());

          }

        }
      }

    }


    function addUpdateAssetInfo(sysid, vehicleType, name, speed, state, lat, lng, bitmap, clientId, posTime) {
      var bnds = map.getBounds();
      var topLat = bnds.getNorth();
      var botLat = bnds.getSouth();
      var leftLng = bnds.getWest();
      var rightLng = bnds.getEast();

      

      console.log("bounds test passed");
      var old = vehicleInfo.get(sysid);

      if (typeof old != undefined && old) {
        old.speed = speed;
        old.state = state;
        old.lat = lat;
        old.lng = lng;
        old.posTime = posTime;
        old.location = new mapboxgl.LngLat(lng, lat);
        if (lat < botLat || lat > topLat)
          return;
        if (lng < leftLng || lng > rightLng)
          return;
        console.log(old.sysid.toString() +" vehicle already added, setting data");
        var src = map.getSource('src' + old.sysid.toString());
        var assetDescripton = formatAssetDescription(old.vehicleType, old.speed, old.state, old.lat, old.lng, old.posTime);
        if (src != undefined) {
          src.setData(formatPoint(lng, lat, name, assetDescripton));
        }
        else {
          map.addSource('src' + sysid.toString(), { type: 'geojson', data: formatPoint(lng, lat, name, assetDescripton) });
          map.addLayer(formatLayer(sysid.toString(), "src" + sysid.toString(), vehicleType, 0.5));
          addEventsToAssetLayer(sysid.toString());
        }

        console.log("data set");
      }
      else {
        console.log(sysid.toString()+" new unit");
        var location = new mapboxgl.LngLat(lng, lat);
        var info = {
          sysid: sysid,
          vehicleType: vehicleType,
          name: name,
          speed: speed,
          state: state,
          lat: lat,
          lng: lng,
          bitmap: bitmap,
          posTime: posTime,
          clientId: clientId,
          location: location
        };
        vehicleInfo.set(sysid, info);
        if (lat < botLat || lat > topLat)
          return;
        if (lng < leftLng || lng > rightLng)
          return;
        //var ico = getIcon(bitmap);
        
        var assetDescripton = formatAssetDescription(vehicleType, speed, state, lat, lng, posTime);
        
        

        var src = map.getSource('src' + sysid.toString());
        if (src != undefined) {
          src.setData(formatPoint(lng, lat, name, assetDescripton));
        }
        else {
        
          
          map.addSource('src' + sysid.toString(), { type: 'geojson', data: formatPoint(lng, lat, name, assetDescripton) });
          map.addLayer(formatLayer(sysid.toString(), "src" + sysid.toString(), vehicleType, 0.5));
          addEventsToAssetLayer(sysid.toString());
          
        }
      }
    }

    function addEventsToAssetLayer(layerId) {
      map.on('mouseenter', layerId, function (e) {
        // Change the cursor style as a UI indicator.
        map.getCanvas().style.cursor = 'pointer';

        var coordinates = e.features[0].geometry.coordinates.slice();
        var description = e.features[0].properties.description;

        // Ensure that if the map is zoomed out such that multiple
        // copies of the feature are visible, the popup appears
        // over the copy being pointed to.
        while (Math.abs(e.lngLat.lng - coordinates[0]) > 180) {
          coordinates[0] += e.lngLat.lng > coordinates[0] ? 360 : -360;
        }

        // Populate the popup and set its coordinates
        // based on the feature found.
        popup.setLngLat(coordinates)
          .setHTML(description)
          .addTo(map);
      });

      map.on('mouseleave', layerId, function () {
        map.getCanvas().style.cursor = '';
        popup.remove();
      });
    }

    function formatAssetDescription(vehicleType, speed, state, lat, lng, posTime) {
      return ('<p>Type: ' + vehicleType + '<br/>Speed: ' + speed + '<br/>State: ' + state + '<br/>Latitude: ' + lat + '<br/>Longitiude: '
        + lng + '<br/>Position Time: ' + '<br/>' + posTime +'</p>');
    }

    function formatLngLat(lng, lat) {
      return {
        "lng": lng,
        "lat": lat
      }
    }

    function addImageToMap(imageName, mapName) {
      var hasImage = map.hasImage(mapName);
      if (hasImage == true)
        return;
      map.loadImage(imageName, function (error, image) {
        if (error) throw error;
        map.addImage(mapName, image);

      });
    }

    function formatLine(points, geoIdx, geo) {
      if (geo == undefined)
        return;
      if (geo.features[geoIdx] == undefined) {
        geo.features[geoIdx] = {
          "type": "Feature",
          "geometry": {
            "type": "LineString",
            "coordinates": []
          }
        };
      }
      geo.features[geoIdx].geometry.coordinates = [];
      if (points == null)
        return;
      for (var i = 0; i < points.length; i++) {
        geo.features[geoIdx].geometry.coordinates.push([points[i].lng, points[i].lat]);
      }
    }

    function formatPoint(lng, lat, name, description) {
      return {
        "type": "Feature",
        "geometry": {
          "type": "Point",
          "coordinates": [lng, lat]
        },
        "properties": {
          "title": name,
          "description": description 
        }
      }
    }

    function formatLayer(layerName, layerSrc, icon, fontScale) {
      return {
        "id": layerName,
        "type": "symbol",
        "source": layerSrc,
        "layout": {
          "icon-image": icon,
          "text-field": ["get", "title"],
          "text-font": ["Open Sans Semibold", "Arial Unicode MS Bold"],
          "text-offset": [0, 0.6],
          "text-anchor": "top"//,
          //"font-scale": fontScale
        }
      }
    }


    function timerTimeout() {
      BindAssetGrid();
      BindAssetDetailsGrid();
      BindTraceDataGrid();
    }

    function getName(sysid) {
      var name = '';
      for (var i = 0; i < sysidNameList.length; i++) {
        if (sysidNameList[i].sysid == sysid)
          return (sysidNameList[i].name);
      }
      return (name);
    }

    function getSYSID(name) {
      var sysid = 0;
      for (var i = 0; i < sysidNameList.length; i++) {
        if (sysidNameList[i].name == name)
          return (sysidNameList[i].sysid);
      }
      return (sysid);
    }

    function BindAssetDetailsGrid() {

      $.ajax({
        type: "POST",
        url: "default.aspx/GetAssetDetailsGridData",
        contentType: "application/json;charset=utf-8",
        data: JSON.stringify({ sysid: selectedSYSID }),
        dataType: "json",
        success: function (data) {

          var table = document.getElementById("assetDetailsTable");

          var scrollTop = ($("#assetDetailsTable").scrollTop());
          var scrollLeft = ($("#assetDetailsTable").scrollLeft());

          for (var i = table.rows.length - 1; i >= 0; i--) {
            table.deleteRow(i);
          }

          if (data.d.length > 0) {
            $("#assetDetailsTable").append("<tr><th>Field</th><th>Value</th></tr>");
            for (var i = 0; i < data.d.length; i++) {

              $("#assetDetailsTable").append("<tr><td>" +
                data.d[i].Field + "</td> <td>" +
                data.d[i].Value + "</td></tr>");
            }
          }

          ($("#assetDetailsTable").scrollTop(scrollTop));
          ($("#assetDetailsTable").scrollLeft(scrollLeft));
        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function BindTraceDataGrid() {

      if (getShowTraceState() == false)
        return;

      var queryOpen = document.getElementById('queryFiltersPanelDiv').style.display;
      if (queryOpen != "none")
        return;

      $.ajax({
        type: "POST",
        url: "default.aspx/GetTraceData",
        contentType: "application/json;charset=utf-8",
        data: JSON.stringify({ sysid: selectedSYSID, traceTime: document.getElementById("TraceHours").value }),
        dataType: "json",
        success: function (data) {

          //removeTrace();


          var coords = [];
          
          tracePins.length = 0;
          if (data.d.length > 0) {

            for (var i = 0; i < data.d.length; i++) {
              var lat = parseFloat(data.d[i].Latitude);
              var lng = parseFloat(data.d[i].Longitude);
              var speed = parseInt(data.d[i].Speed);
              var state = parseInt(data.d[i].State);
              var time = data.d[i].Time;
              var trackLocation = {
                lat: lat,
                lng: lng,
                state: state,
                speed: speed,
                time: time
              };
              coords[i] = trackLocation;

              //var location = new Microsoft.Maps.Location(lat, lng);
              var pin = {
                lat: lat,
                lng: lng,
                state: state,
                speed: speed,
                time: time
              };


              tracePins.push(pin);
            }
            console.log("Drawing trace:" + coords.length.toString());
            traceLine = map.getSource('trace');
            if (traceLine == null) {

              //map.addSource('src_trace', { type: 'geojson', data: formatLine(tracePins) });
              
              formatLine(tracePins, 0, traceGeojson);



            }
            else {
              formatLine(tracePins, 0, traceGeojson);
            }
            console.log("finished trace:" + coords.length.toString());
          }
          //plotTracePoints();



        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function plotTracePoints() {
      /*
      for (var i = 0; i < tracePins.length; i++) {
        //
        map.entities.remove(tracePins[i].pin);
      }
      */
      if (getShowTraceState() == false)
        return;
      if (getShowTracePointsState() == false)
        return;

      for (var i = 0; i < tracePins.length; i++) {
        //
        map.entities.push(tracePins[i].pin);
      }

      //console.log("Trace points length: " + tracePins.length);

    }

    function GetProfileId() {
      $.ajax({
        type: "POST",
        url: "default.aspx/GetProfileId",
        contentType: "application/json;charset=utf-8",
        data: {},
        dataType: "json",
        success: function (data) {
          var id;
          if (data.d.length > 0) {
            profileId = data.d[0].Key;
          }

          setupAdminOptions();


        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function GetUserSettings() {

      $.ajax({
        type: "POST",
        url: "default.aspx/GetUserSettings",
        contentType: "application/json;charset=utf-8",
        data: {},
        dataType: "json",
        success: function (data) {
          var id;
          if (data.d.length > 0) {

            //currMapCenter = new Microsoft.Maps.Location(data.d[0].MapCenterLat, data.d[0].MapCenterLng);
            currMapCenterLat = data.d[0].MapCenterLat;
            currMapCenterLng = data.d[0].MapCenterLng;

            currMapZoom = data.d[0].MapCenterZoom;
            if (data.d[0].KeepInView == "True")
              setKeepInViewState(true);
            else
              setKeepInViewState(false);

            if (data.d[0].ShowTrace == "True")
              setShowTraceState(true);
            else
              setShowTraceState(false);

            if (data.d[0].ShowPoints == "True")
              setShowTracePointsState(true);
            else
              setShowTracePointsState(false);

            var timeFil = data.d[0].TimeFilter;
            var timeFilter = document.getElementById("timeFilterDropDown");
            if (timeFil == 300)
              timeFilter.selectedIndex = 0;
            else if (timeFil == 900)
              timeFilter.selectedIndex = 1;
            else if (timeFil == 3600)
              timeFilter.selectedIndex = 2;
            else if (timeFil == 28800)
              timeFilter.selectedIndex = 3;
            else if (timeFil == 86400)
              timeFilter.selectedIndex = 4;
            else if (timeFil == 604800)
              timeFilter.selectedIndex = 5;
            else if (timeFil == 315360000)
              timeFilter.selectedIndex = 6;
            var th = data.d[0].TraceHours;
            document.getElementById("TraceHours").value = th;
            assetPanelWidth = data.d[0].AssetDivWidth;
            autoResizeView();
            loadInitialMap();
            
            
          }

        },
        error: function (result) {
          //alert("Error login");

        }
      });

    }

    function loadKey() {

      $.ajax({
        type: "POST",
        url: "default.aspx/GetMapKey",
        contentType: "application/json;charset=utf-8",
        data: {},
        dataType: "json",
        success: function (data) {

          if (data.d.length > 0) {
            mapKey = data.d[0].Key;
          }
          
          setupPage();


        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function getQueryFilters() {
      getVehicles(g_VehicleNameOrderBy, g_VehicleNameAscDesc, g_VehicleNameTypeFilter);
      getVehicleTypes(g_VehicleTypeAscDesc);
      getEventTypes(g_EventTypeAscDesc);

    }

    function sortVehicleTypesByType() {
      getVehicleTypes(ascOrDesc(g_VehicleTypeAscDesc));
    }

    function getVehicleTypes(ascDesc) {
      g_VehicleTypeAscDesc = ascDesc;

      $.ajax({
        type: "POST",
        url: "default.aspx/GetVehicleTypes",
        contentType: "application/json;charset=utf-8",
        data: JSON.stringify({ ascDesc: g_VehicleTypeAscDesc }),
        dataType: "json",
        success: function (data) {

          var table = document.getElementById("vehicleTypeFiltersTable");

          for (var i = table.rows.length - 1; i >= 0; i--) {
            table.deleteRow(i);
          }
          // up sorting arrow code &#9650;
          // down sorting arrow code &#9660;
          if (data.d.length > 0) {
            if (g_VehicleTypeAscDesc == 'desc')
              $("#vehicleTypeFiltersTable").append("<tr><th></th><th onclick='sortVehicleTypesByType()'>Vehicle Type &#9650;</th><th class=\"hiddenData\">Vehicle Type Id</th></tr>");
            else
              $("#vehicleTypeFiltersTable").append("<tr><th></th><th onclick='sortVehicleTypesByType()'>Vehicle Type &#9660;</th><th class=\"hiddenData\">Vehicle Type Id</th></tr>");
            for (var i = 0; i < data.d.length; i++) {

              $("#vehicleTypeFiltersTable").append("<tr><td>" +
                "<input type=\"checkbox\" onclick='filterVehicleTypes()'/></td><td>" +
                data.d[i].Type + "</td> <td class=\"hiddenData\">" +
                data.d[i].VehicleTypeId + "</td></tr > ");
            }
          }



        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function filterVehicleTypes() {
      var filterString = "";
      var typeFiltersTable = document.getElementById("vehicleTypeFiltersTable");
      var typeFiltersRows = typeFiltersTable.getElementsByTagName('tr');
      for (i = 1; i < typeFiltersRows.length; i++) {


        //gets cells of current row
        var cells = typeFiltersRows[i].getElementsByTagName('td');
        var val = cells[0].getElementsByTagName('input')[0];
        if (val.checked) {
          filterString = filterString + cells[1].innerText + ',';

        }

      }
      getVehicles("name", "asc", filterString);
    }

    function sortEventTypes() {
      getEventTypes(ascOrDesc(g_EventTypeAscDesc));
    }

    function getEventTypes(ascDesc) {

      g_EventTypeAscDesc = ascDesc;

      $.ajax({
        type: "POST",
        url: "default.aspx/GetEventTypes",
        contentType: "application/json;charset=utf-8",
        data: JSON.stringify({ ascDesc: g_EventTypeAscDesc }),
        dataType: "json",
        success: function (data) {

          var table = document.getElementById("eventTypeFiltersTable");

          for (var i = table.rows.length - 1; i >= 0; i--) {
            table.deleteRow(i);
          }
          // up sorting arrow code &#9650;
          // down sorting arrow code &#9660;
          if (data.d.length > 0) {
            if (g_EventTypeAscDesc == 'desc')
              $("#eventTypeFiltersTable").append("<tr><th></th><th onclick='sortEventTypes()'>Event Type &#9650</th><th class=\"hiddenData\">Event Type Id</th><th class=\"hiddenData\">Data Type</th></tr>");
            else
              $("#eventTypeFiltersTable").append("<tr><th></th><th onclick='sortEventTypes()'>Event Type &#9660</th><th class=\"hiddenData\">Event Type Id</th><th class=\"hiddenData\">Data Type</th></tr>");
            for (var i = 0; i < data.d.length; i++) {

              $("#eventTypeFiltersTable").append("<tr><td>" +
                "<input type=\"checkbox\" /></td><td>" +
                data.d[i].EventTypeName + "</td> <td class=\"hiddenData\">" +
                data.d[i].EventTypeId + "</td> <td class=\"hiddenData\">" +
                data.d[i].DataType + "</td></tr>");
            }
          }



        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function ascOrDesc(cur) {
      if (cur == "asc")
        return "desc";
      return "asc";
    }

    function sortVehiclesByName() {
      getVehicles("name", ascOrDesc(g_VehicleNameAscDesc), g_VehicleNameTypeFilter);
    }

    function sortVehiclesByType() {
      getVehicles("type", ascOrDesc(g_VehicleNameAscDesc), g_VehicleNameTypeFilter);
    }

    function getVehicles(orderBy, ascDesc, typeFilter) {
      g_VehicleNameOrderBy = orderBy;
      g_VehicleNameAscDesc = ascDesc;
      g_VehicleNameTypeFilter = typeFilter;
      $.ajax({
        type: "POST",
        url: "default.aspx/GetVehicles",
        contentType: "application/json;charset=utf-8",
        data: JSON.stringify({ orderBy: g_VehicleNameOrderBy, ascDesc: g_VehicleNameAscDesc, typeFilters: g_VehicleNameTypeFilter }),
        dataType: "json",
        success: function (data) {
          var table = document.getElementById("vehicleFiltersTable");

          for (var i = table.rows.length - 1; i >= 0; i--) {
            table.deleteRow(i);
          }
          if (data.d.length > 0) {
            // up sorting arrow code &#9650;
            // down sorting arrow code &#9660;
            if (g_VehicleNameOrderBy == "name") {
              if (g_VehicleNameAscDesc == "desc") {
                $("#vehicleFiltersTable").append("<tr><th></th><th onclick='sortVehiclesByName()'>Name &#9650;</th><th onclick='sortVehiclesByType()'>Type</th><th class=\"hiddenData\">Client</th><th class=\"hiddenData\">Id</th></tr>");
              }
              else {
                $("#vehicleFiltersTable").append("<tr><th></th><th onclick='sortVehiclesByName()'>Name &#9660;</th><th onclick='sortVehiclesByType()'>Type</th><th class=\"hiddenData\">Client</th><th class=\"hiddenData\">Id</th></tr>");
              }
            }
            else if (g_VehicleNameOrderBy == "type") {
              if (g_VehicleNameAscDesc == "desc") {
                $("#vehicleFiltersTable").append("<tr><th></th><th onclick='sortVehiclesByName()'>Name</th><th onclick='sortVehiclesByType()'>Type &#9650;</th><th class=\"hiddenData\">Client</th><th class=\"hiddenData\">Id</th></tr>");
              }
              else {
                $("#vehicleFiltersTable").append("<tr><th></th><th onclick='sortVehiclesByName()'>Name</th><th onclick='sortVehiclesByType()'>Type &#9660;</th><th class=\"hiddenData\">Client</th><th class=\"hiddenData\">Id</th></tr>");
              }
            }
            else {
              $("#vehicleFiltersTable").append("<tr><th></th><th onclick='sortVehiclesByName()'>Name</th><th onclick='sortVehiclesByType()'>Type</th><th class=\"hiddenData\">Client</th><th class=\"hiddenData\">Id</th></tr>");
            }
            for (var i = 0; i < data.d.length; i++) {

              $("#vehicleFiltersTable").append("<tr><td>" +
                "<input type=\"checkbox\" /></td><td>" +
                data.d[i].Name + "</td> <td>" +
                data.d[i].Type + "</td> <td class=\"hiddenData\">" +
                data.d[i].Client + "</td> <td class=\"hiddenData\">" +
                data.d[i].SYSID + "</td></tr>");
            }
          }



        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function showQueryResultsLoadingBar() {
      document.getElementById("loadContainerDiv").style.display = "flex";
    }

    function hideQueryResultsLoadingBar() {
      document.getElementById("loadContainerDiv").style.display = "none";
    }

    function runQuery() {

      showQueryResultsLoadingBar();
      var vFiltersTable = document.getElementById("vehicleFiltersTable");
      var vTypeFiltersTable = document.getElementById("vehicleTypeFiltersTable");
      var eTypeFiltersTable = document.getElementById("eventTypeFiltersTable");
      var startTime = document.getElementById("queryStartTime");
      var endTime = document.getElementById("queryEndTime");
      var vFiltersString = '';
      var eTypeFiltersString = '';
      var vTypeFiltersString = '';

      var rowLength = vFiltersTable.rows.length;
      var vFilterRows = vFiltersTable.getElementsByTagName('tr');

      //loops through rows    
      for (i = 1; i < vFilterRows.length; i++) {

        //gets cells of current row  
        var cells = vFilterRows[i].getElementsByTagName('td');

        var val = cells[0].getElementsByTagName('input')[0];
        if (val.checked) {
          vFiltersString = vFiltersString + cells[4].innerText + ',';
        }
      }


      var vTypeFiltersRows = vTypeFiltersTable.getElementsByTagName('tr');

      //loops through rows    
      for (i = 1; i < vTypeFiltersRows.length; i++) {

        //gets cells of current row  
        var cells = vTypeFiltersRows[i].getElementsByTagName('td');

        var val = cells[0].getElementsByTagName('input')[0];
        if (val.checked) {
          vTypeFiltersString = vTypeFiltersString + cells[1].innerText + ',';
        }
      }

      var eTypeFiltersRows = eTypeFiltersTable.getElementsByTagName('tr');

      //loops through rows    
      for (i = 1; i < eTypeFiltersRows.length; i++) {

        //gets cells of current row  
        var cells = eTypeFiltersRows[i].getElementsByTagName('td');

        var val = cells[0].getElementsByTagName('input')[0];
        if (val.checked) {
          eTypeFiltersString = eTypeFiltersString + cells[1].innerText + ',';
        }
      }

      startTime = document.getElementById('queryStartTime').value;
      endTime = document.getElementById('queryEndTime').value;

      /*
      console.log(vFiltersString);
      console.log(vTypeFiltersString);
      console.log(eTypeFiltersString);
      console.log(startTime);
      console.log(endTime);
      */
      var queryString = JSON.stringify({ startTime: startTime, endTime: endTime, vehicleIds: vFiltersString, vehicleTypes: vTypeFiltersString, eventTypes: eTypeFiltersString });
      clearAllPlottedEvents();
      var table = document.getElementById("queryResultsTable");
      for (var i = table.rows.length - 1; i >= 0; i--) {
        table.deleteRow(i);
      }

      plottedEventIds.clear();
      eventPlotLines.clear();
      $("#queryResultsTable").append("<tr><th>Plot</th><th>Event Id</th><th>Event Type</th><th>Asset Name</th><th>Start Time</th>" +
        "<th>End Time</th><th class=\"hiddenData\">Start Time GMT</th><th class=\"hiddenData\">End Time GMT</th>" +
        "<th>Duration(h)</th><th>Distance(km)</th><th>Vehicle Id</th>" +
        "<th class=\"hiddenData\">Custom Fields</th></tr > ");

      $.ajax({
        type: "POST",
        url: "default.aspx/RunEventQuery",
        contentType: "application/json;charset=utf-8",
        data: queryString,
        dataType: "json",
        success: function (data) {
          var count = 0;
          var distTot = 0;
          var durTot = 0;
          for (var i = 0; i < data.d.length; i++) {

            $("#queryResultsTable").append("<tr id=\"row" + data.d[i].VehicleEventId + "\" >" +
              "<td><input type=\"checkbox\" id=\"cb" + data.d[i].VehicleEventId + "\" onclick='plotDataClicked(this)'/></td>" +
              "<td onclick='eventClicked(this.parentNode)' ondblclick='eventDblClicked(this.parentNode)'>" + data.d[i].VehicleEventId + "</td>" +
              "<td onclick='eventClicked(this.parentNode)' ondblclick='eventDblClicked(this.parentNode)'>" + data.d[i].EventType + "</td>" +
              "<td onclick='eventClicked(this.parentNode)' ondblclick='eventDblClicked(this.parentNode)'>" + data.d[i].VehicleName + "</td>" +
              "<td onclick='eventClicked(this.parentNode)' ondblclick='eventDblClicked(this.parentNode)'>" + data.d[i].StartTime + "</td>" +
              "<td onclick='eventClicked(this.parentNode)' ondblclick='eventDblClicked(this.parentNode)'>" + data.d[i].EndTime + "</td>" +
              "<td class=\"hiddenData\">" + data.d[i].StartTimeGMT + "</td>" +
              "<td class=\"hiddenData\">" + data.d[i].EndTimeGMT + "</td>" +
              "<td onclick='eventClicked(this.parentNode)' ondblclick='eventDblClicked(this.parentNode)'>" + data.d[i].Duration + "</td>" +
              "<td onclick='eventClicked(this.parentNode)' ondblclick='eventDblClicked(this.parentNode)'>" + data.d[i].Distance + "</td>" +
              "<td onclick='eventClicked(this.parentNode)' ondblclick='eventDblClicked(this.parentNode)'>" + data.d[i].SYSID + "</td>" +
              "<td class=\"hiddenData\">" + data.d[i].CustomFlag + "</td>" +
              "</tr>");
            distTot = distTot + parseFloat(data.d[i].Distance);
            durTot = durTot + parseFloat(data.d[i].Duration);
          }

          count = data.d.length;

          document.getElementById("queryResTotalsEventCount").innerText = count;
          document.getElementById("queryResTotalsDistance").innerText = distTot.toFixed(2) + " kms";
          document.getElementById("queryResTotalsDuration").innerText = durTot.toFixed(2) + " hrs";

          hideQueryResultsLoadingBar();
        },
        error: function (result) {
          //alert("Error login");
          hideQueryResultsLoadingBar();
        }
      });
    }

    function eventClicked(tr) {

      var cells = tr.getElementsByTagName('td');
      var val = cells[0].getElementsByTagName('input')[0];
      if (val.checked == false)
        val.checked = true;
      else
        val.checked = false;

      plotDataClicked(val);
      lastEidPlotted = parseInt(cells[1].innerText);
      showPlottedEvents();
    }

    function eventDblClicked(tr) {
      var cells = tr.getElementsByTagName('td');
      var val = cells[0].getElementsByTagName('input')[0];
      val.checked = true;
      var eid = parseInt(cells[1].innerText);
      lastEidPlotted = parseInt(cells[1].innerText);
      plotDataClicked(val);
      showPlottedEvents();
    }

    function plotDataClicked(cb) {
      if (cb != null) {

        if (cb.checked != true) {
          showPlottedEvents();
          return;
        }
      }

      showQueryResultsLoadingBar();
      var queryResultsString = "";
      var queryResultsTable = document.getElementById("queryResultsTable");
      var queryResultsRows = queryResultsTable.getElementsByTagName('tr');
      for (i = 1; i < queryResultsRows.length; i++) {


        //gets cells of current row
        var cells = queryResultsRows[i].getElementsByTagName('td');
        var val = cells[0].getElementsByTagName('input')[0];
        if (val.checked) {
          var eid = parseInt(cells[1].innerText);
          lastEidPlotted = parseInt(cells[1].innerText);
          var found = false;
          var event = eventPlotLines.get(eid);
          if (event != null) {
            found = true;
          }
          /*
          for (var j = 0; j < eventPlotLines.length; j++) {
            var event = eventPlotLines[j].eventId;
            if (event == eid) {
              found = true;
              break;
            }
          */
        }

        if (found == false) {
          queryResultsString = queryResultsString + cells[1].innerText + ',' + cells[10].innerText + ',' + cells[6].innerText + ',' + cells[7].innerText + ',';
        }
      }

      if (queryResultsString == "") {
        showPlottedEvents();
        hideQueryResultsLoadingBar();
        return;
      }

      $.ajax({
        type: "POST",
        url: "default.aspx/GetPlotData",
        contentType: "application/json;charset=utf-8",
        data: JSON.stringify({ events: queryResultsString }),
        dataType: "json",
        success: function (data) {


          for (var j = 0; j < data.d.length; j++) {
            var eId = parseInt(data.d[j].EventId);
            var pins = [];
            var coords = [];

            var row = document.getElementById("row" + eId);
            var cols = row.getElementsByTagName("td");

            for (var i = 0; i < data.d[j].Points.length; i++) {
              var lat = parseFloat(data.d[j].Points[i].Latitude);
              var lng = parseFloat(data.d[j].Points[i].Longitude);
              var speed = parseInt(data.d[j].Points[i].Speed);
              var state = parseInt(data.d[j].Points[i].State);
              var time = data.d[j].Points[i].Time;

               var desc = "Event Id: " + cols[1].innerText + "<br/>" + "Event Type: " + cols[2].innerText + "<br/>" +
              "Asset Name: " + cols[3].innerText + "<br/>" + "Start Time: " + cols[4].innerText + "<br/>" +
              "End Time: " + cols[5].innerText + "<br/>" + "Duration(h): " + cols[8].innerText + "<br/>" +
                "Distance(km): " + cols[9].innerText + "<br/>" + "Vehicle Id: " + cols[10].innerText + "<br/>";

              var pin = {
                lat: lat,
                lng: lng,
                speed: speed,
                state: state,
                time: time,
                description: desc
              };
                           
              pins[i] = pin;
            }

            
            
            var metaString = "Event Id: " + cols[1].innerText + "<br/>" + "Event Type: " + cols[2].innerText + "<br/>" +
              "Asset Name: " + cols[3].innerText + "<br/>" + "Start Time: " + cols[4].innerText + "<br/>" +
              "End Time: " + cols[5].innerText + "<br/>" + "Duration(h): " + cols[8].innerText + "<br/>" +
              "Distance(km): " + cols[9].innerText + "<br/>" + "Vehicle Id: " + cols[10].innerText + "<br/>";
            
            


            var plot = {
              points: pins,
              
              plotted: false
            }
            formatLine(pins, j, plotGeojson);

            eventPlotLines.set(eId, plot);
          }

          showPlottedEvents();
          hideQueryResultsLoadingBar();

        },
        error: function (result) {
          //alert("Error login");
          hideQueryResultsLoadingBar();
        }
      });
    }

    function plotAllDataClicked() {

      var queryResultsString = "";
      var queryResultsTable = document.getElementById("queryResultsTable");
      var queryResultsRows = queryResultsTable.getElementsByTagName('tr');
      for (i = 1; i < queryResultsRows.length; i++) {


        //gets cells of current row
        var cells = queryResultsRows[i].getElementsByTagName('td');
        var val = cells[0].getElementsByTagName('input')[0];

        if (val.checked == false) {
          val.checked = true;
          var eid = parseInt(cells[1].innerText);
          lastEidPlotted = parseInt(cells[1].innerText);
          var found = false;
          var event = eventPlotLines.get(eid);
          if (event != null) {
            found = true;
          }
          /*
          for (var j = 0; j < eventPlotLines.length; j++) {
            var event = eventPlotLines[j].eventId;
            if (event == eid) {
              found = true;
              break;
            }
          */
        }

        if (found == false) {
          queryResultsString = queryResultsString + cells[1].innerText + ',' + cells[10].innerText + ',' + cells[6].innerText + ',' + cells[7].innerText + ',';
        }
      }

      if (queryResultsString == "") {
        showPlottedEvents();
        return;
      }
      showQueryResultsLoadingBar();

      $.ajax({
        type: "POST",
        url: "default.aspx/GetPlotData",
        contentType: "application/json;charset=utf-8",
        data: JSON.stringify({ events: queryResultsString }),
        dataType: "json",
        success: function (data) {


          for (var j = 0; j < data.d.length; j++) {
            var eId = parseInt(data.d[j].EventId);
            var pins = [];
            var row = document.getElementById("row" + eId);
            var cols = row.getElementsByTagName("td");
            for (var i = 0; i < data.d[j].Points.length; i++) {
              var lat = parseFloat(data.d[j].Points[i].Latitude);
              var lng = parseFloat(data.d[j].Points[i].Longitude);
              var speed = parseInt(data.d[j].Points[i].Speed);
              var state = parseInt(data.d[j].Points[i].State);
              var time = data.d[j].Points[i].Time;

              

              
              
              var desc = "Event Id: " + cols[1].innerText + "<br/>" + "Event Type: " + cols[2].innerText + "<br/>" +
              "Asset Name: " + cols[3].innerText + "<br/>" + "Start Time: " + cols[4].innerText + "<br/>" +
              "End Time: " + cols[5].innerText + "<br/>" + "Duration(h): " + cols[8].innerText + "<br/>" +
                "Distance(km): " + cols[9].innerText + "<br/>" + "Vehicle Id: " + cols[10].innerText + "<br/>";

              var pin = {
                lat: lat,
                lng: lng,
                speed: speed,
                state: state,
                time: time,
                description: desc
              };
                           
              pins[i] = pin;
            }

            
            
            var metaString = "Event Id: " + cols[1].innerText + "<br/>" + "Event Type: " + cols[2].innerText + "<br/>" +
              "Asset Name: " + cols[3].innerText + "<br/>" + "Start Time: " + cols[4].innerText + "<br/>" +
              "End Time: " + cols[5].innerText + "<br/>" + "Duration(h): " + cols[8].innerText + "<br/>" +
              "Distance(km): " + cols[9].innerText + "<br/>" + "Vehicle Id: " + cols[10].innerText + "<br/>";
            
            


            var plot = {
              points: pins,
              
              plotted: false
            }
            formatLine(pins, j, plotGeojson);

            eventPlotLines.set(eId, plot);
          }

          showPlottedEvents();
          hideQueryResultsLoadingBar();

        },
        error: function (result) {
          //alert("Error login");
          hideQueryResultsLoadingBar();
        }
      });
    }

    function showPlottedEvents() {
      //removeTrace();
      var width = document.getElementById('queryFiltersPanelDiv').style.display;
      if (width == "none")
        return;
      var lines = [];
      var coords = [];
      var val = null;
      for (var [key, value] of eventPlotLines.entries()) {
        var cbChecked = document.getElementById("cb" + key);
        if (cbChecked.checked != true) {
          for (var i = 0; i < value.points.length; i++) {
            //map.entities.remove(value.points[i]);
          }
          //map.entities.remove(value.line);
          value.plotted = false;
        }
        else {
          if (key == lastEidPlotted) {
            val = value;
            continue;
          }
          if (value.plotted == false) {
            /*
            if (value.points.length > 0)
              map.entities.push(value.points[0]);
            if (value.points.length > 1)
              map.entities.push(value.points[value.points.length - 1]);
            
            map.entities.push(value.line);
            */
            value.plotted = true;
          }
          //value.line.setOptions({ strokeColor: 'red' });
        }

      }
      if (val != null) {

        for (var i = 0; i < val.points.length; i++) {
          //map.entities.remove(val.points[i]);
        }
       // map.entities.remove(val.line);

        //var rect = Microsoft.Maps.LocationRect.fromLocations(val.line.getLocations());
        //map.setView({ bounds: rect, padding: 80 });
        //val.line.setOptions({ strokeColor: 'blue' });
        /*
        if (val.points.length > 0)
          map.entities.push(val.points[0]);
        if (val.points.length > 1)
          map.entities.push(val.points[val.points.length - 1]);

        for (var i = 1; i < val.points.length - 1; i++) {
          map.entities.push(val.points[i]);
        }
        */
        //map.entities.push(val.line);
        val.plotted = true;
      }

    }

    function showAllPlottedEvents() {
      var curLoc = [];
      for (var i = map.entities.getLength() - 1; i >= 0; i--) {
        var obj = map.entities.get(i);
        if (obj instanceof Microsoft.Maps.Polyline) {
          curLoc = curLoc.concat(obj.getLocations());

        }
      }
      //var rect = Microsoft.Maps.LocationRect.fromLocations(curLoc);
      //map.setView({ bounds: rect, padding: 80 });

    }

    function clearAllPlottedEvents() {
      //clear all checkboxes on queryResultsTable
      var queryResultsTable = document.getElementById("queryResultsTable");
      var queryResultsRows = queryResultsTable.getElementsByTagName('tr');
      if (queryResultsRows.length >= 2) {
        for (i = 1; i < queryResultsRows.length; i++) {


          //gets cells of current row
          var cells = queryResultsRows[i].getElementsByTagName('td');
          var val = cells[0].getElementsByTagName('input')[0].checked = false;

        }
      }
      //remove all plot objects from the map and set them to false
      for (var [key, value] of eventPlotLines.entries()) {

        for (var i = 0; i < value.points.length; i++) {
          //map.entities.remove(value.points[i]);
        }
        //map.entities.remove(value.line);
        value.plotted = false;
      }
    }

    function setupAdminOptions() {
      var div = document.getElementById("adminToolsDiv");
      if (profileId == '1') {
        div.innerHTML = div.innerHTML + "<br /> " +
          "<br /><a href=\"Account/Register\" class=\"adminToolItem\">Register User</a>" +
          "<br /><br /><a href=\"Account/ManageUsers\" class=\"adminToolItem\">Manage Users</a>";
      }
    }

    function vehiclePanelButtonClick() {
      closeDivs();
      var width = document.getElementById('assetGridTableDiv').style.display;
      if (width != "none") {
        document.getElementById('assetGridTableDiv').style.display = "none";
        //document.getElementById('assetPanelResizeDiv').style.display = "none";
      }
      else {
        document.getElementById('queryFiltersPanelDiv').style.display = "none";
        document.getElementById('queryResultsPanelDiv').style.display = "none";
        document.getElementById('assetGridTableDiv').style.display = "inline-block";
        clearAllPlottedEvents();
        BindTraceDataGrid();
        //document.getElementById('assetPanelResizeDiv').style.display = "inline-block";
      }
      autoResizeView();
    }

    function adminPanelButtonClick() {
      closeDivs();
      var width = document.getElementById('adminToolsDiv').style.display;
      if (width != "none") {
        document.getElementById('adminToolsDiv').style.display = "none";
      }
      else {
        document.getElementById('adminToolsDiv').style.display = "inline-block";
      }
      autoResizeView();
    }

    function queryPanelButtonClick() {
      closeDivs();
      var width = document.getElementById('queryFiltersPanelDiv').style.display;
      if (width != "none") {
        document.getElementById('queryFiltersPanelDiv').style.display = "none";
        document.getElementById('queryResultsPanelDiv').style.display = "none";
        clearAllPlottedEvents();
        BindTraceDataGrid();
      }
      else {
        document.getElementById('assetGridTableDiv').style.display = "none";
        //document.getElementById('assetPanelResizeDiv').style.display = "none";
        document.getElementById('adminToolsDiv').style.display = "none";
        document.getElementById('queryResultsPanelDiv').style.display = "inline-block";
        document.getElementById('queryFiltersPanelDiv').style.display = "inline-block";
        var time = moment();
        document.getElementById('queryEndTime').value = time.format('YYYY-MM-DDThh:mm:ss');
        //time = time
        document.getElementById('queryStartTime').value = moment().subtract(7, 'days').format('YYYY-MM-DDThh:mm:ss');
        getQueryFilters();
        removeTrace();
      }
      autoResizeView();
      
    }

    function alertPanelButtonClick() {
      var width = document.getElementById('alertScreenDiv').style.display;
      if (width != "none") {
        document.getElementById('alertScreenDiv').style.display = "none";
        setupAlertDiv();
      }
      else {
        document.getElementById('alertScreenDiv').style.display = "inline-block";

      }
    }

    function closeDivs() {
      
        document.getElementById('alertScreenDiv').style.display = "none";
      
    }

    function timeFilterChange() {
      BindAssetGrid();
      UpdateTimeFilterValue();
    }

    function UpdateTimeFilterValue() {
      var e = document.getElementById("timeFilterDropDown");
      var secs = e.options[e.selectedIndex].value;
      var timeString = JSON.stringify({ setting: secs });
      $.ajax({
        type: "POST",
        url: "default.aspx/setTimeFilter",
        contentType: "application/json;charset=utf-8",
        data: timeString,
        dataType: "json",
        success: function () {

        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function UpdateKeepInViewValue() {
      var chk = getKeepInViewState();
      var timeString = JSON.stringify({ setting: chk });
      $.ajax({
        type: "POST",
        url: "default.aspx/SetKeepInView",
        contentType: "application/json;charset=utf-8",
        data: timeString,
        dataType: "json",
        success: function () {

        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function UpdateShowTraceValue() {
      var chk = getShowTraceState();
      var timeString = JSON.stringify({ setting: chk });
      $.ajax({
        type: "POST",
        url: "default.aspx/SetShowTrace",
        contentType: "application/json;charset=utf-8",
        data: timeString,
        dataType: "json",
        success: function () {

        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function UpdateShowPointsValue() {
      var chk = getShowTracePointsState();
      var timeString = JSON.stringify({ setting: chk });
      $.ajax({
        type: "POST",
        url: "default.aspx/SetShowPoints",
        contentType: "application/json;charset=utf-8",
        data: timeString,
        dataType: "json",
        success: function () {

        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function UpdateMapCenter() {
      if (map == null)
        return;
      var center = map.getCenter();
      var mLat = center.lat;
      var mLat = map.lng;
      var JSONString = JSON.stringify({ lat: mLat, lng: mLng });
      $.ajax({
        type: "POST",
        url: "default.aspx/SetMapCenter",
        contentType: "application/json;charset=utf-8",
        data: JSONString,
        dataType: "json",
        success: function () {

        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function UpdateMapZoomLevel() {
      if (map == null)
        return;
      var mapZoom = map.getZoom();
      var JSONString = JSON.stringify({ setting: mapZoom });
      $.ajax({
        type: "POST",
        url: "default.aspx/SetShowPoints",
        contentType: "application/json;charset=utf-8",
        data: JSONString,
        dataType: "json",
        success: function () {

        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function UpdateMapDetails() {
      if (map == null)
        return;
      var center = map.getCenter();
      var mLat = center.lat;
      var mLng = center.lng;
      var mapZoom = map.getZoom();
      var JSONString = JSON.stringify({ lat: mLat, lng: mLng, zoom: mapZoom });
      $.ajax({
        type: "POST",
        url: "default.aspx/SetMapDetails",
        contentType: "application/json;charset=utf-8",
        data: JSONString,
        dataType: "json",
        success: function () {
          alert("Map details saved.");
        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function UpdateAssetDivWidth(width) {
      var timeString = JSON.stringify({ setting: width });
      $.ajax({
        type: "POST",
        url: "default.aspx/SetAssetDivWidth",
        contentType: "application/json;charset=utf-8",
        data: timeString,
        dataType: "json",
        success: function () {

        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function UpdateUserTimezone() {
      var d = new Date();
      var offset = ((d.getTimezoneOffset())/60)*-1;
      var timeString = JSON.stringify({ setting: offset });
      $.ajax({
        type: "POST",
        url: "default.aspx/SetTimeZoneOffset",
        contentType: "application/json;charset=utf-8",
        data: timeString,
        dataType: "json",
        success: function () {
          BindAssetGrid();
        },
        error: function (result) {
          //alert("Error login");
          BindAssetGrid();
        }
      });
    }

    function UpdateTraceHoursDB(hours) {
      
      $.ajax({
        type: "POST",
        url: "default.aspx/SetTraceHours",
        contentType: "application/json;charset=utf-8",
        data: JSON.stringify({ setting: hours }),
        dataType: "json",
        success: function () {

        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

    function saveMapButtonClick() {
      UpdateMapDetails();
    }

    function initAssetPanelResize(e) {
      resizeToolDiv = true;
      document.body.style.cursor = 'col-resize';
      console.log('down');
      
    }

    function initQueryResultsResize(e) {
      resizeQueryResDiv = true;
      document.body.style.cursor = 'row-resize';
    }

    function mouseMove(e) {
      if (resizeToolDiv == true) {
        e.stopPropagation();
        e.preventDefault();
      }
      else if (resizeQueryResDiv == true) {
        e.stopPropagation();
        e.preventDefault();
      }
    }

    function mouseButtonUp(e) {
      //alert('stop');
      console.log('up');
      if (resizeToolDiv == true) {
        var element = document.getElementById('leftResizeDiv');
        assetPanelWidth = e.clientX - toolBarWidth;
        document.body.style.cursor = 'default';
        e.stopPropagation();
        resizeToolDiv = false;
        autoResizeView();
        UpdateAssetDivWidth(assetPanelWidth);
      }
      else if (resizeQueryResDiv == true) {
        var element = document.getElementById('bottomResizeDiv');
        queryResDivHeight = window.innerHeight - e.clientY;
        document.body.style.cursor = 'default';
        e.stopPropagation();
        resizeQueryResDiv = false;
        autoResizeView();
      }
    }

    function setupAlertDiv() {
      $.ajax({
        type: "POST",
        url: "default.aspx/GetCurrentVehicles",
        contentType: "application/json;charset=utf-8",
        data: JSON.stringify({ orderBy: "name", ascDesc: "asc", typeFilters: "" }),
        dataType: "json",
        success: function (data) {

          var dropDown = document.getElementById("alertAssetSelection");

          

          if (data.d.length > 0) {
            
            for (var i = 0; i < data.d.length; i++) {
              var opt = document.createElement('option');
              opt.value = data.d[i].SYSID;
              opt.innerHTML = data.d[i].Name;
              dropDown.appendChild(opt);
            }
            dropDown.selectedIndex = 0;
          }
        },
        error: function (result) {
          //alert("Error login");

        }
      }); 
      
      setupAlertGrid()
      
    }

    function setupAlertGrid() {
      var e = document.getElementById("alertAssetSelection");
      var sysid = e.options[e.selectedIndex].value;
      $.ajax({
        type: "POST",
        url: "default.aspx/GetAlertData",
        contentType: "application/json;charset=utf-8",
        data: JSON.stringify({ sysid: sysid }),
        dataType: "json",
        success: function (data) {

          var table = document.getElementById("alertValuesTable");

          for (var i = table.rows.length - 1; i >= 0; i--) {
            table.deleteRow(i);
          }

          if (data.d.length > 0) {
            $("#alertValuesTable").append("<tr><th>Sysid</th><th>Field</th><th>Value</th></tr>");
            for (var i = 0; i < data.d.length; i++) {

              $("#alertValuesTable").append("<tr><td>" +
                data.d[i].sysid + "</td> <td>" +
                data.d[i].fieldName + "</td> <td>" +
                data.d[i].fieldValue + "</td></tr>");
            }
          }
        },
        error: function (result) {
          //alert("Error login");

        }
      });
    }

  </script>
</head>

<body onload="loadKey()">
  <form id="form1" runat="server">

    <asp:ScriptManager ID="ScriptManager" runat="server" EnablePageMethods="True">
    </asp:ScriptManager>
    <div id="loadContainerDiv">
      <div id="queryResultsLoadingBarDiv"></div>
    </div>
    <div id="sideToolbarDiv">
      <img src="Images/Aware_360_A_Only.png" class="sideToolBarImage" />
      <img src="Images/Buttons/Car_Right_Red.png" class="sideToolBarButton" onclick="vehiclePanelButtonClick()" />
      <img src="Images/Buttons/TableGraph.png" class="sideToolBarButton" onclick="queryPanelButtonClick()" />
      <!--img src="Images/Buttons/Warning_Triangle.png" class="sideToolBarButton" onclick="alertPanelButtonClick()" /-->
      <img src="Images/Buttons/Gears.png" class="sideToolBarButton" onclick="adminPanelButtonClick()" />
      <img src="Images/Buttons/Save.png" class="sideToolBarButton" onclick="saveMapButtonClick()" />
    </div>
    <div id="alertScreenDiv">
      Select Unit: 
      <select size="1" onchange="setupAlertGrid()" id="alertAssetSelection"></select>
      <table id="alertValuesTable"></table>
    </div>
    <div id="assetGridTableDiv">
      
      <div id="assetGridToolsDiv">
        <div class="topToolDivClass">
          Time Filter:
        <select size="1" onchange="timeFilterChange()" id="timeFilterDropDown">
          <option value="300">5 Minutes</option>
          <option value="900">15 Minutes</option>
          <option value="3600">1 Hour</option>
          <option value="28800">8 Hours</option>
          <option value="86400">1 Day</option>
          <option value="604800">7 Days</option>
          <option value="315360000">No Filter</option>
        </select>
        </div>
        <div class="topToolDivClass">
          <input id="EnableTrackingCheckbox" type="checkbox" onclick="keepInViewCheckboxClicked()" class="keepInViewClass" />
          <p onclick="keepInViewClicked()" class="keepInViewClass">Keep In View</p>
        </div>
        <div class="topToolDivClass">
          <input id="EnableTraceCheckbox" type="checkbox" onclick="showAssetTraceClick()" class="showTraceClass" />
          <p onclick="showTraceClicked()" class="showTraceClass">Show Trace</p>
          <p class="showTraceClass">Trace Hours:</p>
          <input id="TraceHours" type="text" value="4" style="width: 20px;" class="showTraceClass" />
          <input id="UpdateTraceHours" type="button" value="Update" onclick="updateTraceHours()" class="showTraceClass" />
        </div>
        <div class="topToolDivClass">
          <input id="EnableTracePointsCheckbox" type="checkbox" onclick="showAssetTracePointsClick()" class="showTraceClass" />
          <p onclick="showTracePointsClicked()" class="showTraceClass">Show Points</p>
        </div>
      </div>

      <table id="assetGridTable">
      </table>
      <!-- hr id="assetPanelDivider" style="float: left; margin: 2px; width: 100%;" /-->
      <table id="assetDetailsTable">
      </table>

    </div>
    <div id="queryFiltersPanelDiv">
      <div id="timeFiltersDiv" class="queryFiltersSubDivs">
        <p>Query Filters</p>
        <br />
        <table>
          <tr>
            <td>Start Time:</td>
            <td>
              <input type="datetime-local" id="queryStartTime" /></td>
          </tr>
          <tr>
            <td>End Time:</td>
            <td>
              <input type="datetime-local" id="queryEndTime" /></td>
          </tr>
        </table>
        <br />
        <input type="button" value="Run Query" onclick="runQuery()" />
      </div>
      <div id="vehicleFiltersDiv" class="queryFiltersSubDivs">
        <table id="vehicleFiltersTable" class="queryFiltersTable"></table>
      </div>
      <div id="vehicleTypeFiltersDiv" class="queryFiltersSubDivs">
        <table id="vehicleTypeFiltersTable" class="queryFiltersTable"></table>
      </div>
      <div id="eventTypeFiltersDiv" class="queryFiltersSubDivs">
        <table id="eventTypeFiltersTable" class="queryFiltersTable"></table>
      </div>
    </div>
    <div id="assetGridUpdatePanelDiv" style="display: none">


      <asp:UpdatePanel ID="VehiclePanel" runat="server" UpdateMode="Conditional">
        <ContentTemplate>
          <div id="assetVehiclePanelDiv">
            <asp:GridView ID="AssetGrid" runat="server" AllowSorting="True" AutoGenerateColumns="False" BackColor="White" BorderColor="Black" BorderStyle="None"
              BorderWidth="1px" CellPadding="3" GridLines="Horizontal" HorizontalAlign="Left"
              ShowHeaderWhenEmpty="True" EmptyDataText="No units to display." RowStyle-Wrap="False"
              Font-Size="Small" DataKeyNames="SYSID"
              CssClass="assetGridCSS" SelectedIndex="0" EnablePersistedSelection="True"
              EnableTheming="False" Height="100px">
              <AlternatingRowStyle BackColor="White" />
              <Columns>
                <asp:BoundField DataField="Dscr" HeaderText="Type" SortExpression="Dscr" />
                <asp:BoundField DataField="Name" HeaderText="Name" SortExpression="Name" />
                <asp:BoundField DataField="LastSpeed" HeaderText="Spd" SortExpression="LastSpeed" />
                <asp:BoundField DataField="LastState" HeaderText="State" SortExpression="LastState" />
                <asp:BoundField DataField="LastLat" HeaderText="Lat" SortExpression="LastLat" />
                <asp:BoundField DataField="LastLng" HeaderText="Lng" SortExpression="LastLng" />
                <asp:BoundField DataField="LastPositionHeardLocal" HeaderText="Time" SortExpression="LastPositionHeardLocal" />
                <asp:BoundField DataField="BitmapFile" HeaderText="BitmapFile" SortExpression="BitmapFile" Visible="True" />
                <asp:BoundField DataField="SYSID" HeaderText="SYSID" ReadOnly="True" SortExpression="SYSID" Visible="True" />
                <asp:BoundField DataField="ClientId" HeaderText="ClientId" SortExpression="ClientId" />
              </Columns>
              <FooterStyle BackColor="#B5C7DE" ForeColor="#4A3C8C" />
              <HeaderStyle BackColor="#0099FF" Font-Bold="True" ForeColor="#F7F7F7" />
              <PagerStyle BackColor="#E7E7FF" ForeColor="#4A3C8C" HorizontalAlign="Right" />
              <RowStyle BackColor="White" ForeColor="#4A3C8C" CssClass="assetGridRow" />
              <SelectedRowStyle Font-Bold="True" ForeColor="#F7F7F7" />
              <SortedAscendingCellStyle BackColor="White" />
              <SortedAscendingHeaderStyle BackColor="#5A4C9D" />
              <SortedDescendingCellStyle BackColor="White" />
              <SortedDescendingHeaderStyle BackColor="#3E3277" />
            </asp:GridView>
          </div>

          <div id="assetDetailsGridDiv">
            <asp:GridView ID="AssetDetailsGrid" runat="server" AutoGenerateColumns="True" HorizontalAlign="Left" BorderWidth="1px" CellPadding="3"
              BackColor="White" BorderColor="Black" BorderStyle="None" Font-Size="Small" GridLines="Horizontal">
              <FooterStyle BackColor="#B5C7DE" ForeColor="#4A3C8C" />
              <HeaderStyle BackColor="#0099FF" Font-Bold="True" ForeColor="#F7F7F7" />
              <PagerStyle BackColor="#E7E7FF" ForeColor="#4A3C8C" HorizontalAlign="Right" />
              <RowStyle BackColor="White" ForeColor="#4A3C8C" />
            </asp:GridView>
          </div>

          <div>
            <asp:GridView ID="AssetTraceGrid" runat="server" AutoGenerateColumns="True" HorizontalAlign="Left" BorderWidth="1px" CellPadding="3"
              BackColor="White" BorderColor="Black" BorderStyle="None" Font-Size="Small" GridLines="Horizontal">
            </asp:GridView>
          </div>

        </ContentTemplate>

      </asp:UpdatePanel>



    </div>
    <div id="divMapContainer">
      <div id="leftResizeDiv" onmousedown="initAssetPanelResize()"></div>
      <div id="divMap" runat="server">
        
      </div>
      <div id="bottomResizeDiv" onmousedown="initQueryResultsResize()"></div>
      <div id="queryResultsPanelDiv">
        <div id="queryResultsToolsDiv">
          <input type="button" value="Plot All" onclick="plotAllDataClicked()" class="queryResultsTools" />
          <input type="button" value="View All" onclick="showAllPlottedEvents()" class="queryResultsTools" />
          <input type="button" value="Clear All" onclick="clearAllPlottedEvents()" class="queryResultsTools" />
        </div>
        <div id="queryResultsTableDiv">

          <table id="queryResultsTable" class="queryResultsTable"></table>
        </div>
        <div id="queryResultsTotalsDiv">
          <table id="queryResultsTotalsTable">
            <tr>
              <td>Event Count:</td>
              <td id="queryResTotalsEventCount"></td>
            </tr>
            <tr>
              <td>Total Distance:</td>
              <td id="queryResTotalsDistance"></td>
            </tr>
            <tr>
              <td>Total Duration:</td>
              <td id="queryResTotalsDuration"></td>
            </tr>
          </table>
        </div>
      </div>
    </div>
    <div id="adminToolsDiv">
      <p>Admin Tools</p>
      <br />
      <a runat="server" href="~/Account/Manage" title="Manage your account" class="adminToolItem"><%: Context.User.Identity.GetUserName()  %></a>
    </div>
  </form>
</body>
</html>
