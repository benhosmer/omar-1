package org.ossim.omar

import org.springframework.beans.factory.InitializingBean

import javax.media.jai.JAI

class MapViewController implements InitializingBean
{
  def grailsApplication

  def baseWMS
  def dataWMS
  def webMappingService

  def afterInterceptor = { model, modelAndView ->
    if ( request['isMobile'] )
    {
      modelAndView.viewName = modelAndView.viewName + "_mobile"
    }
  }

  def index = {
    WMSQuery query = new WMSQuery();
    def rasterEntries = []
    if(params.layers)
    {
      query.layers = params.layers

      rasterEntries = query.getRasterEntriesAsList()
    }
    /*
    def rasterEntryIds = params.rasterEntryIds?.split(',')
    def rasterEntries = RasterEntry.withCriteria {
      or
      {
        rasterEntryIds.each{id->
          try{
            eq("id", Long.valueOf(id))
          }
          catch(Exception e)
          {
            eq("indexId", id)
          }
        }
      }
//      or{
//        inList("id", rasterEntryIds)
//        inList("imageId", rasterEntryIds)
//      }
    }
    */
    def kmlOverlays = []

    rasterEntries.each { rasterEntry ->
      def overlays = RasterEntryFile.findAllByTypeAndRasterEntry("kml", rasterEntry)
      overlays?.each {overlay ->

        def kmlOverlay = [:]

        kmlOverlay.name = overlay.name
        kmlOverlay.url = createLink(action: 'getKML', params: [id: overlay?.id])


        kmlOverlays << kmlOverlay
      }
    }

    def model = [:]

    model.rasterEntries = rasterEntries
    model.kmlOverlays = kmlOverlays
    model.putAll(webMappingService.computeScales(rasterEntries))
    model.putAll(webMappingService.computeBounds(rasterEntries))

    return model
  }

  def getKML = {

    def kmlFile = RasterEntryFile.get(params.id)

    if ( !kmlFile )
    {
      flash.message = "RasterEntryFile not found with id ${params.id}"
      redirect(action: index)
    }
    else
    {
      def kmlSource = null

      if ( kmlFile?.name?.startsWith("http://") )
      {
        kmlSource = new URL(kmlFile?.name)
      }
      else
      {
        kmlSource = new File(kmlFile?.name)
      }

      def kml = kmlSource?.text
      //response.setHeader("Content-disposition", "attachment; filename=foo.kml")
      render(contentType: "application/vnd.google-earth.kml+xml", text: kml, encoding: "UTF-8")
    }
  }


  def multiLayer = {

    WMSQuery query = new WMSQuery();
    def rasterEntries = []
    if(params.layers)
    {
      query.layers = params.layers

      rasterEntries = query.getRasterEntriesAsList()
    }
    def kmlOverlays = []

    rasterEntries.each { rasterEntry ->

      RasterEntryFile.findAllByTypeAndRasterEntry("kml", rasterEntry)?.each {kmlFile ->
        kmlOverlays << kmlFile
      }
    }

    def model = [:]

    model.rasterEntries = rasterEntries
    model.kmlOverlays = kmlOverlays
    model.baseWMS= baseWMS
    model.putAll(webMappingService.computeBounds(rasterEntries))

    return model
  }

  def test = {
    [baseWMS: baseWMS, dataWMS: dataWMS]
  }

  def imageSpace = {
    //log.info(params)
    //println (params)
    def rasterEntry = RasterEntry.findByIndexId(params.layers)?:RasterEntry.get(params.layers)

    def inputFile = rasterEntry.mainFile.name
    def width
    def height

    def mode = "OSSIM"

    switch ( mode )
    {
    case "JAI":
      def image = JAI.create("imageread", inputFile)
      width = image.width
      height = image.height
      break

    case "OSSIM":

      width = rasterEntry?.width
      height = rasterEntry?.height

      break
    }

    //println "${[width: width, height: height, inputFile: inputFile, entry: rasterEntry.entryId]}"



    def model = [:]

//    model.width = rasterEntry?.width
//    model.height = rasterEntry?.height
//    model.numRLevels = rasterEntry.numberOfResLevels
    model.rasterEntry = rasterEntry
    return model
  }

  public void afterPropertiesSet()
  {
    baseWMS = grailsApplication.config.wms.base.layers
    dataWMS = grailsApplication.config.wms.data.raster
  }

  def iview = {
    def rasterEntry = RasterEntry.get(params.id)

    def inputFile = rasterEntry.mainFile.name
    def width
    def height

    def mode = "OSSIM"

    switch ( mode )
    {
    case "JAI":
      def image = JAI.create("imageread", inputFile)
      width = image.width
      height = image.height
      break

    case "OSSIM":

      width = rasterEntry?.width
      height = rasterEntry?.height

      break
    }

    def numRLevels = 1
    def tileSize = 256

    while ( width > tileSize )
    {
      width /= 2
      height /= 2
      numRLevels++
    }


    [width: rasterEntry?.width, height: rasterEntry?.height, numRLevels: numRLevels, rasterEntry: rasterEntry]

  }
}
