<%--
  Created by IntelliJ IDEA.
  User: sbortman
  Date: Feb 9, 2009
  Time: 10:19:01 AM
  To change this template use File | Settings | File Templates.
--%>

<%@ page contentType="text/html;charset=UTF-8" %>
<html>
<head>
  <title>OMAR Image Space Viewer</title>
  <link rel="stylesheet" href="${resource(dir: 'css', file: 'main.css')}"/>

  <openlayers:loadMapToolBar/>
  <openlayers:loadTheme theme="default"/>
  <meta name="layout" content="main6"/>

  <meta name="apple-mobile-web-app-capable" content="yes" />
  <meta name="apple-mobile-web-app-status-bar-style" content="black" />
  <meta name="viewport" content="minimum-scale=1.0, width=device-width, maximum-scale=1.6, user-scalable=no">

  <style type="text/css">
  #map {
    width: 100%;
    height: 100%;
    border: 1px solid black;
  }

  div.olControlMousePosition {
    font-family: Verdana;
    font-size: 1.0em;
    background-color: white;
    color: black;
  }

  div.olControlScale {
    background-color: #ffffff;
    font-size: 1.0em;
    font-weight: bold;
  }

    /*
    #config {
      margin-top: 1em;
      width: 1024px;
      position: relative;
      height: 8em;
    }
    */

  #controls {
    padding-left: 2em;
    margin-left: 0;
    width: 12em;
  }

  #controls li {
    padding-top: 0.5em;
    list-style: none;
  }  </style>

</head>

<body>

<content tag="north">
  <div class="nav">

    <span class="menuButton">
      <g:link class="home" uri="/">Home</g:link>
    </span>

    <span class="menuButton">
      <a href="${createLink(controller: "mapView", action: "index", params: [layers: rasterEntry?.indexId])}">
        Ground Space
      </a>
    </span>

    <span class="menuButton">
      <label>Sharpen:</label>
      <g:select id="sharpen_mode" name="sharpen_mode" from="${['none', 'light', 'heavy']}" onChange="changeSharpenOpts()" />
    </span>

    <span class="menuButton">
      <label>Stretch:</label>
      <g:select id="stretch_mode" name="stretch_mode" from="${['linear_auto_min_max', 'linear_1std_from_mean', 'linear_2std_from_mean', 'linear_3std_from_mean', 'none']}" onChange="changeHistoOpts()" />
    </span>

    <span class="menuButton">
      <label>Region:</label>
      <g:select id="stretch_mode_region" name="stretch_mode_region" from="${['global', 'viewport']}" onChange="changeHistoOpts()" />
    </span>

    <g:if test="${rasterEntry?.numberOfBands == 1}">
      <span class="menuButton">
        <label>Band:</label>
       <g:select id="bands" name="bands" from="${['0']}" onChange="changeBandsOpts()" />
       </span>
    </g:if>

    <g:if test="${rasterEntry?.numberOfBands == 2}">
      <span class="menuButton">
        <label>Bands:</label>
        <g:select id="bands" name="bands" from="${['0,1','1,0','0','1']}" onChange="changeBandsOpts()" />
      </span>
    </g:if>

    <g:if test="${rasterEntry?.numberOfBands >= 3}">
      <span class="menuButton">
        <label>Bands:</label>
        <g:select id="bands" name="bands" from="${['0,1,2','2,1,0','0','1','2']}" onChange="changeBandsOpts()" />
      </span>
    </g:if>
    
  </div>
</content>

<content tag="center">
  <%--
  <h1 id="mapTitle">${rasterEntry?.mainFile?.name}</h1>
  <g:if test="${flash.message}">
    <div class="message">${flash.message}</div>
  </g:if>
  --%>
  <div id="map"></div>
</div>
</content>
<content tag="south">
  <openlayers:loadJavascript/>
  <g:javascript plugin="omar-core" src="touch.js"/>
  
  <g:javascript>
  var map;
  var layer;

  function changeMapSize(mapWidth, mapHeight)
  {
//    var mapTitle = document.getElementById("mapTitle");
//    var mapDiv = document.getElementById("map");
//
//    mapDiv.style.width = mapTitle.offsetWidth + "px";
//    mapDiv.style.height = Math.round(mapTitle.offsetWidth / 2) + "px";

    var Dom = YAHOO.util.Dom;

    Dom.get( "map" ).style.width = mapWidth + "px";
    Dom.get( "map" ).style.height = mapHeight + "px";
    
    map.updateSize();
  }
  
 function changeHistoOpts()
{
  var stretch_mode = $("stretch_mode").value;
  var stretch_mode_region = $("stretch_mode_region").value;


  layer.mergeNewParams({stretch_mode:stretch_mode, stretch_mode_region: stretch_mode_region});
}

  function get_my_url (bounds)
  {
      var res = this.map.getResolution();
      var x = /*Math.round*/ ((bounds.left - this.maxExtent.left) / (res * this.tileSize.w));
      var y = /*Math.round*/ ((this.maxExtent.top - bounds.top) / (res * this.tileSize.h));
      var z = this.map.getZoom();
      var sharpen_mode = $("sharpen_mode").value;
      var stretch_mode = $("stretch_mode").value;
      var stretch_mode_region = $("stretch_mode_region").value;
      var bands = $("bands").value;

      var path = "?z=" + z + "&x=" + x + "&y=" + y + "&format=" + this.type
          + "&tileWidth=" + this.tileSize.w + "&tileHeight=" + this.tileSize.h
          + "&id=" + ${rasterEntry?.id}
          + "&sharpen_mode=" + sharpen_mode
          + "&stretch_mode=" + stretch_mode
          + "&stretch_mode_region=" + stretch_mode_region
          + "&bands=" + bands;

//      var path = "?bbox=" + x + "," + y + "," + bounds.right + "," + bounds.top

      var url = this.url;
      if (url instanceof Array) {
          url = this.selectUrl(path, url);
      }
      return url + path;
  }

  function init(mapWidth, mapHeight)
  {
    map = new OpenLayers.Map('map', { controls: [], numZoomLevels: 32 } );
    map.addControl(new OpenLayers.Control.LayerSwitcher())
    //map.addControl(new OpenLayers.Control.PanZoom())
    //map.addControl(new OpenLayers.Control.NavToolbar())
    map.addControl(new OpenLayers.Control.MousePosition());
    map.addControl(new OpenLayers.Control.Scale());
    map.addControl(new OpenLayers.Control.ScaleLine());

    var options = {
      maxExtent: new OpenLayers.Bounds(0,0,${width},${height}),
      maxResolution: ${width} / map.getTileSize().w,
        numZoomLevels: 30,
//        numZoomLevels: ${numRLevels},
      type:'jpeg',
      getURL: get_my_url,
      isBaseLayer: true,
      buffer: 0,
      singleTile: true,
      ratio: 1.0,
      transitionEffect: "resize"
    };

    layer = new OpenLayers.Layer.TMS("Layer",
        "${createLink(controller: 'ogc', action: 'getTile')}",
        options
    );

    changeMapSize(mapWidth, mapHeight);
    
    map.addLayers([layer]);
    map.zoomToMaxExtent();
    setupToolbar();

    this.touchhandler = new TouchHandler( map, 4 );  
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

        var container = $("panel2");

        var panel = new OpenLayers.Control.Panel(
        { div: container,defaultControl: zoomBoxButton,'displayClass': 'olControlPanel'}
                );


        var navButton = new OpenLayers.Control.NavigationHistory({
          nextOptions: {title: "Next View" },
          previousOptions: {title: "Previous View"}
        });

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


        map.addControl(navButton);

        panel.addControls([
          new OpenLayers.Control.MouseDefaults({title:'Drag to recenter map'}),
          zoomBoxButton,
          zoomInButton,
          zoomOutButton,
          navButton.next, navButton.previous,
          new OpenLayers.Control.ZoomToMaxExtent({title:"Zoom to the max extent"}),
          measureDistanceButton,
          measureAreaButton
        ]);

        map.addControl(panel);
      }

  </g:javascript>
</content>
</body>
</html>
