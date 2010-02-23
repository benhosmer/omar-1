<%--
  Created by IntelliJ IDEA.
  User: sbortman
  Date: Sep 14, 2009
  Time: 9:24:47 AM
  To change this template use File | Settings | File Templates.
--%>

<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
  <title>OMAR - Raster Search</title>
  <meta name="layout" content="main3"/>

  <style type="text/css">
  #map {
    border: 1px solid black;
    width: 100%;
    height: 100%;
  }

  #controls {
    padding-left: 2em;
    margin-left: 0;
    width: 12em;
  }

  #controls li {
    padding-top: 0.5em;
    list-style: none;
  }

  #panel {
    right: 0px;
    height: 30px;
    width: 200px;
  }

  #panel div {
    float: left;
    margin: 5px;
  }
  </style>

  <openlayers:loadMapToolBar/>
  <openlayers:loadTheme theme="default"/>
  <openlayers:loadJavascript/>
  <resource:include components="dateChooser"/>

  <g:javascript>
    var aoiLayer;
    var polygonControl;
    var map;
    var dataLayer;


    function changeMapSize()
    {
      var mapTitle = $("mapTitle");
      var mapDiv = $("map");

      mapDiv.style.width = mapTitle.offsetWidth + "px";
      mapDiv.style.height = Math.round( mapTitle.offsetWidth / 2) + "px";

      map.updateSize();
    }

    function setupDataLayer()
    {
      dataLayer = new OpenLayers.Layer.WMS(
        "${dataWMS.title}",
        "${dataWMS.url}",
        { layers: "${dataWMS.layers}", styles:"${dataWMS.styles}", format: "${dataWMS.format}", IMAGEFILTER: "true=true", transparent: true },
        {isBaseLayer:false,buffer:0,visibility:false}
      );
      map.addLayer(dataLayer);
    }

    function setupBaseLayer()
    {
      var baseLayer = new OpenLayers.Layer.WMS(
        "${baseWMS.title}",
        "${baseWMS.url}",
        {layers: '${baseWMS.layers}', format: "${baseWMS.format}" },
        {isBaseLayer:true, buffer:0}
      );
      map.addLayer(baseLayer);
      map.setBaseLayer(baseLayer);
    }

    function setupAoiLayer()
    {

      aoiLayer = new OpenLayers.Layer.Vector("Area of Interest");
      aoiLayer.events.register("featureadded", aoiLayer, setAOI );

      var polyOptions = {sides: 4, irregular: true} ;

      polygonControl = new OpenLayers.Control.DrawFeature( aoiLayer, OpenLayers.Handler.RegularPolygon,
         {handlerOptions: polyOptions});

      map.addLayer(aoiLayer);
      map.addControl(polygonControl);

      var aoiMinLon = "${queryParams?.aoiMinLon ?: ''}";
      var aoiMinLat = "${queryParams?.aoiMinLat ?: ''}";
      var aoiMaxLon = "${queryParams?.aoiMaxLon ?: ''}";
      var aoiMaxLat = "${queryParams?.aoiMaxLat ?: ''}";

      if ( aoiMinLon && aoiMinLat && aoiMaxLon && aoiMaxLat )
      {
        var bounds = new OpenLayers.Bounds( aoiMinLon, aoiMinLat, aoiMaxLon, aoiMaxLat );
        var feature = new OpenLayers.Feature.Vector(bounds.toGeometry());

        aoiLayer.addFeatures(feature, {silent: true});
      }
    }

    function setupMapWidget()
    {
       map = new OpenLayers.Map("map", { controls: [] });
       map.addControl(new OpenLayers.Control.LayerSwitcher());
       //map.addControl(new OpenLayers.Control.PanZoom());
       //map.addControl(new OpenLayers.Control.NavToolbar());
       map.addControl(new OpenLayers.Control.MousePosition());
       map.addControl(new OpenLayers.Control.Scale());
       //map.addControl(new OpenLayers.Control.Permalink("permalink"));
       map.addControl(new OpenLayers.Control.ScaleLine());
       map.addControl(new OpenLayers.Control.Attribution());
       map.events.register("moveend", map, setCenterText);
       map.events.register("zoomend", map, setView );
    }

    function setupMapView()
    {
      var viewMinLon = "${queryParams?.viewMinLon ?: -180}";
      var viewMinLat = "${queryParams?.viewMinLat ?: -90}";
      var viewMaxLon = "${queryParams?.viewMaxLon ?: 180}";
      var viewMaxLat = "${queryParams?.viewMaxLat ?: 90}";

      var bounds = new OpenLayers.Bounds(viewMinLon, viewMinLat, viewMaxLon, viewMaxLat);
      var zoom = map.getZoomForExtent(bounds, true);


      map.setCenter(bounds.getCenterLonLat(), zoom);

    }

    function zoomIn()
    {
      map.zoomIn();
    }

    function zoomOut()
    {
      map.zoomOut();

    }
      function setupToolbar()
      {

        var zoomBoxButton = new OpenLayers.Control.ZoomBox(
        {title:"Zoom into an area by clicking and dragging"});

        var zoomInButton = new OpenLayers.Control.Button({title:'Zoom in',
          displayClass: "olControlZoomIn",
          trigger: zoomIn
        });

        var zoomOutButton = new OpenLayers.Control.Button({title:'Zoom out',
          displayClass: "olControlZoomOut",
          trigger: zoomOut
        });


        var polyOptions = {sides: 4, irregular: true};

        var polygonControl = new OpenLayers.Control.DrawFeature(aoiLayer, OpenLayers.Handler.RegularPolygon,
        {handlerOptions: polyOptions, title: "Specify Area of Interest"});



        var clearAoiButton = new OpenLayers.Control.Button({title:'Clear Area of Interest',
          displayClass: "olControlClearAreaOfInterest",
          trigger: clearAOI
        });


        var container = $("panel2");

        var panel = new OpenLayers.Control.Panel(
        { div: container,defaultControl: zoomBoxButton,'displayClass': 'olControlPanel'}
                );


        var navButton = new OpenLayers.Control.NavigationHistory({
          nextOptions: {title: "Next View" },
          previousOptions: {title: "Previous View"}
        });


        map.addControl(navButton);

        var measureDistanceButton = new OpenLayers.Control.Measure(OpenLayers.Handler.Path, {
          title: "Measure Distance",
          displayClass: "olControlMeasureDistance",
          eventListeners:
          {
            measure: function(evt)
            {
              alert("Distance: " + evt.measure.toFixed(2) + evt.units);
            }
          }
        });

        var measureAreaButton = new OpenLayers.Control.Measure(OpenLayers.Handler.Polygon, {
          title: "Measure Area",
          displayClass: "olControlMeasureArea",
          eventListeners:
          {
            measure: function(evt)
            {
              alert("Area: " + evt.measure.toFixed(2) + evt.units);
            }
          }
        });
          
        panel.addControls([
          new OpenLayers.Control.MouseDefaults({title:'Drag to recenter map'}),
          zoomBoxButton,
          zoomInButton,
          zoomOutButton,
          navButton.next, navButton.previous,
          new OpenLayers.Control.ZoomToMaxExtent({title:"Zoom to the max extent"}),
          polygonControl,
          clearAoiButton,
          measureDistanceButton,
                measureAreaButton
        ]);

        map.addControl(panel);
      }

    function init()
    {
       setupMapWidget();
       setupDataLayer();
       setupBaseLayer();
       changeMapSize();
       setupAoiLayer();
       setupToolbar();
       setupMapView();
       setupQueryFields();
       updateOmarFilters();
    }

    function goto()
    {
      var centerLon = $("centerLon").value;
      var centerLat = $("centerLat").value;
      var zoom = map.getZoom();
      var center = new OpenLayers.LonLat(centerLon, centerLat);

      map.setCenter(center, zoom);
    }

     function clearAOI( e )
      {
        aoiLayer.destroyFeatures();


        // HACK - Need a better way to this
        $("aoiMinLon").value = "";
        $("aoiMaxLat").value = "";
        $("aoiMaxLon").value = "";
        $("aoiMinLat").value = "";
      }

     function setAOI( e )
      {
        var geom = e.feature.geometry;
        var bounds = geom.getBounds();
        var feature = new OpenLayers.Feature.Vector(geom);

        // HACK - Need a better way to this
        $("aoiMinLon").value = bounds.left;
        $("aoiMaxLat").value = bounds.top;
        $("aoiMaxLon").value = bounds.right;
        $("aoiMinLat").value = bounds.bottom;

        aoiLayer.destroyFeatures();
        aoiLayer.addFeatures(feature, {silent: true});

      }



    function setView( e )
    {
      var bounds = map.getExtent();

      $("viewMinLon").value = bounds.left;
      $("viewMaxLat").value = bounds.top;
      $("viewMaxLon").value = bounds.right;
      $("viewMinLat").value = bounds.bottom;
    }


    function setCenterText( e )
    {
      var center = map.getCenter();
      $("centerLon").value = center.lon;
      $("centerLat").value = center.lat;
    }

    function setupQueryFields()
    {
      var searchMethod = "${queryParams.searchMethod}";

      if ( searchMethod == "${RasterEntryQuery.RADIUS_SEARCH}")
      {
        toggleRadiusSearch();
      }
      else if ( searchMethod == "${RasterEntryQuery.BBOX_SEARCH}" )
      {
        toggleBBoxSearch();       
      }
    }

    function toggleRadiusSearch()
    {
      enableRadiusSearch();
      disableBBoxSearch();
    }

    function toggleBBoxSearch()
    {
      enableBBoxSearch();
      disableRadiusSearch();
    }

    function enableRadiusSearch()
    {
      $("aoiRadius").disabled = false;
    }

    function enableBBoxSearch()
    {
      $("aoiMinLon").disabled = false;
      $("aoiMinLat").disabled = false;
      $("aoiMaxLon").disabled = false;
      $("aoiMaxLat").disabled = false;
    }

    function disableRadiusSearch()
    {
      $("aoiRadius").disabled = true;
    }

    function disableBBoxSearch()
    {
      $("aoiMinLon").disabled = true;
      $("aoiMinLat").disabled = true;
      $("aoiMaxLon").disabled = true;
      $("aoiMaxLat").disabled = true;
    }

    function updateOmarFilters()
    {
      var wmsParams = new Array();

      var sday = $("startDate_day").value;
      var smonth = $("startDate_month").value;
      var syear = $("startDate_year").value;
      var eday = $("endDate_day").value;
      var emonth = $("endDate_month").value;
      var eyear = $("endDate_year").value;

      var hasStartDate = sday != "" && smonth != "" && syear != "";
      var startDate = "'" + smonth + "-" + sday + "-" + syear + "'";
      var startDateNoQuote = syear+smonth+sday;

      var hasEndDate = eday != "" && emonth != "" && eyear != "";
      var endDate = "'" + emonth + "-" + eday + "-" + eyear + "'";
      var wmsTime = ""
      var omarfilter = ""
      if ( hasStartDate )
      {
        omarfilter = "acquisition_date>=" + startDate;
        wmsParams["startDate"]=startDateNoQuote
        wmsTime = syear+sday+smonth
        if ( hasEndDate )
        {
          wmsTime += "/"+eyear+emonth+eday
          omarfilter += " and acquisition_date<=" + endDate;
        }
        else
        {
          wmsTime += "/P1D"

        }
        //alert(omarfilter);
      }
      else
      {
          dataLayer.mergeNewParams({startDate:""});
        if ( hasEndDate )
        {
          wmsTime += "P1000Y/" + eyear+emonth+eday
          omarfilter = "acquisition_date<=" + endDate;

          //alert(omarfilter);
        }
        else
        {
          omarfilter = "true=true";
          wmsTime = "";
          //alert(omarfilter);
        }
      }
      wmsParams["IMAGEFILTER"] = omarfilter;
      wmsParams["time"] = wmsTime;
      wmsParams["searchTagNames[0]"] =$("searchTagNames[0]").value;
      wmsParams["searchTagValues[0]"] =$("searchTagValues[0]").value;
      wmsParams["searchTagNames[1]"] =$("searchTagNames[1]").value;
      wmsParams["searchTagValues[1]"] =$("searchTagValues[1]").value;
      wmsParams["searchTagNames[2]"] =$("searchTagNames[2]").value;
      wmsParams["searchTagValues[2]"] =$("searchTagValues[2]").value;
      wmsParams["searchTagNames[3]"] =$("searchTagNames[3]").value;
      wmsParams["searchTagValues[3]"] =$("searchTagValues[3]").value;
      wmsParams["searchTagNames[4]"] =$("searchTagNames[4]").value;
      wmsParams["searchTagValues[4]"] =$("searchTagValues[4]").value;
      wmsParams["searchTagNames[5]"] =$("searchTagNames[5]").value;
      wmsParams["searchTagValues[5]"] =$("searchTagValues[5]").value;
      wmsParams["searchTagNames[6]"] =$("searchTagNames[6]").value;
      wmsParams["searchTagValues[6]"] =$("searchTagValues[6]").value;
      wmsParams["searchTagNames[7]"] =$("searchTagNames[7]").value;
      wmsParams["searchTagValues[7]"] =$("searchTagValues[7]").value;

      dataLayer.mergeNewParams(wmsParams);
    }
    function setCurrentViewport()
    {
      var bounds = map.getExtent();
      $("viewMinLon").value = bounds.left;
      $("viewMaxLat").value = bounds.top;
      $("viewMaxLon").value = bounds.right;
      $("viewMinLat").value = bounds.bottom;
    }
    
    function searchForRasters()
    {
      document.searchForm.action = "search";
      setCurrentViewport();
      document.searchForm.submit();
    }

    function generateKML()
    {
      document.searchForm.action = "kmlnetworklink";
      setCurrentViewport();
      document.searchForm.submit();
    }

  <%--
  var Dom = YAHOO.util.Dom;
  var Event = YAHOO.util.Event;

  Event.onDOMReady(function()
  {
     init();
  });
  --%>
  </g:javascript>

</head>
<body class="yui-skin-sam" onload="init( );">
<content tag="banner">
  <img id="logo" src="${createLinkTo(dir: 'images', file: 'OMARLarge.png', absolute)}" alt="OMAR-2.0 Logo"/>
</content>
<content tag="main">
  <div id="nav" class="nav">
    <span class="menuButton">
      <a class="home" href="${createLinkTo(dir: '')}">Home</a>
    </span>
    <span class="menuButton">
      <a href="javascript:searchForRasters();">Search</a>
    </span>
    <span class="menuButton">
      <a href="javascript:generateKML();">KML</a>
    </span>
    <span class="menuButton">
      <a href="javascript:updateOmarFilters();">Update footprints</a>
    </span>
    <%--
        <div id="panel2" class="olControlPanel"></div>
    --%>
  </div>
  <div class="body">
    <h1 id="mapTitle">Search for Imagery:</h1>
    <g:if test="${flash.message}">
      <div class="message">${flash.message}</div>
    </g:if>
    <div id="map"></div>

  </div>
</content>
<content tag="search">
  <g:form name="searchForm">
    <div class="niceBox">
      <div class="niceBoxHd">Map Center:</div>
      <div class="niceBoxBody">
        <ol>
          <li>
            <label for='centerLat'>Lat:</label>
          </li>
          <li>
            <g:textField name="centerLat" value="${queryParams?.centerLat}"/>
          </li>
          <li>
            <label for='centerLon'>Lon:</label><br/>
          </li>
          <li>
            <g:textField name="centerLon" value="${queryParams?.centerLon}"/>
          </li>
          <li><br/></li>
          <li>
            <g:radio name="searchMethod" value="${RasterEntryQuery.RADIUS_SEARCH}" checked="${queryParams?.searchMethod == RasterEntryQuery.RADIUS_SEARCH}" onclick="toggleRadiusSearch()"/>
            <label>Use Radius Search</label>
          </li>
          <li><br/></li>
          <li>
            <label for='aoiRadius'>Radius in Meters:</label><br/>
          </li>
          <li>
            <g:textField name="aoiRadius" value="${fieldValue(bean: queryParams, field: 'aoiRadius')}"/>
          </li>
          <li><br/></li>
          <li>
            <span class="formButton">
              <input type="button" onclick="goto( )" value="Set Center">
            </span>
          </li>
        </ol>
      </div>
    </div>

    <div class="niceBox">
      <div class="niceBoxHd">Geospatial Criteria:</div>
      <div class="niceBoxBody">
        <input type="hidden" id="viewMinLon" name="viewMinLon" value="${fieldValue(bean: queryParams, field: 'viewMinLon')}"/>
        <input type="hidden" id="viewMinLat" name="viewMinLat" value="${fieldValue(bean: queryParams, field: 'viewMinLat')}"/>
        <input type="hidden" id="viewMaxLon" name="viewMaxLon" value="${fieldValue(bean: queryParams, field: 'viewMaxLon')}"/>
        <input type="hidden" id="viewMaxLat" name="viewMaxLat" value="${fieldValue(bean: queryParams, field: 'viewMaxLat')}"/>
        <ol>
          <li>
            <g:radio name="searchMethod" value="${RasterEntryQuery.BBOX_SEARCH}" checked="${queryParams?.searchMethod == RasterEntryQuery.BBOX_SEARCH}" onclick="toggleBBoxSearch()"/>
            <label>Use BBox Search</label>
          </li>
          <li><br/></li>
          <li>
            <label for='aoiMaxLat'>North Lat:</label>
          </li>
          <li>
            <input type="text" id="aoiMaxLat" name="aoiMaxLat" value="${fieldValue(bean: queryParams, field: 'aoiMaxLat')}"/>
          </li>
          <li>
            <label for='aoiMinLon'>West Lon:</label>
          </li>
          <li>
            <input type="text" id="aoiMinLon" name="aoiMinLon" value="${fieldValue(bean: queryParams, field: 'aoiMinLon')}"/>
          </li>
          <li>
            <label for='aoiMinLat'>South Lat:</label>
          </li>
          <li>
            <input type="text" id="aoiMinLat" name="aoiMinLat" value="${fieldValue(bean: queryParams, field: 'aoiMinLat')}"/>
          </li>
          <li>
            <label for='aoiMaxLon'>East Lon:</label>
          </li>
          <li>
            <input type="text" id="aoiMaxLon" name="aoiMaxLon" value="${fieldValue(bean: queryParams, field: 'aoiMaxLon')}"/>
          </li>
          <li><br/></li>
          <li>
            <input type="button" onclick="clearAOI( )" value="Clear AOI">
          </li>
        </ol>
      </div>
    </div>

    <div class="niceBox">
      <div class="niceBoxHd">Temporal Criteria:</div>
      <div class="niceBoxBody">
        <ol>
          <li>
            <label for='startDate'>Start Date:</label>
          </li>
          <li>
            <richui:dateChooser name="startDate" format="MM/dd/yyyy" value="${queryParams.startDate}" onChange="updateOmarFilters()"/>
          </li>
          <li>
            <label for='endDate'>End Date:</label>
          </li>
          <li>
            <richui:dateChooser name="endDate" format="MM/dd/yyyy" value="${queryParams.endDate}" onChange="updateOmarFilters()"/>
          </li>
        </ol>
      </div>
    </div>

    <div class="niceBox">
      <div class="niceBoxHd">Metadata Criteria:</div>
      <div class="niceBoxMetadataBody">
        <ol>
          <g:each in="${queryParams?.searchTagValues}" var="searchTagValue" status="i">
            <g:select
                    noSelection="${['null':'Select One...']}"
                    name="searchTagNames[${i}]"
                    value="${queryParams?.searchTagNames[i]}"
                    from="${RasterEntrySearchTag.list()}"
                    optionKey="name" optionValue="description"/>
            </li>
            <li>
              <g:textField name="searchTagValues[${i}]" value="${searchTagValue} onChange="updateOmarFilters()"/>
            </li>
          </g:each>
        </ol>
      </div>
    </div>

    <div class="niceBox">
      <div class="niceBoxHd">Options:</div>
      <div class="niceBoxBody">
        <ol>
          <li><label for="max">Max Results:</label></li>
          <li><input type="text" id="max" name="max" value="${params?.max}"></li>
        </ol>
      </div>
    </div>
    <br/>
  <%--
  <g:actionSubmit value="Search"/>&nbsp;<g:actionSubmit action="kmlnetworklink" value="KML"/>
  --%>
  </g:form>
</content>
<content tag="contentinfo">
</content>
</body>
</html>
