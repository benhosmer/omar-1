import org.springframework.beans.factory.InitializingBean

import javax.media.jai.JAI

class MapViewController implements InitializingBean
{
  def grailsApplication

  def baseWMS
  def dataWMS

  def index = {

    def rasterEntryIds = params.rasterEntryIds?.split(',')
    def left = null
    def right = null
    def top = null
    def bottom = null

    def rasterEntries = []
    def kmlOverlays = []

    rasterEntryIds.each {
      def rasterEntry = RasterEntry.get(it)

      rasterEntries << rasterEntry

      if ( left == null || rasterEntry.groundGeom?.bounds?.minLon < left )
      {
        left = rasterEntry?.groundGeom?.bounds?.minLon
      }

      if ( bottom == null || rasterEntry.groundGeom?.bounds?.minLat < bottom )
      {
        bottom = rasterEntry?.groundGeom?.bounds?.minLat
      }

      if ( right == null || rasterEntry.groundGeom?.bounds?.maxLon > right )
      {
        right = rasterEntry?.groundGeom?.bounds?.maxLon
      }

      if ( top == null || rasterEntry.groundGeom?.bounds?.maxLat > top )
      {
        top = rasterEntry?.groundGeom?.bounds?.maxLat
      }

      def overlays = RasterEntryFile.findAllByTypeAndRasterEntry("kml", rasterEntry)

      overlays?.each {overlay ->

        def kmlOverlay = [:]

        kmlOverlay.name = overlay.name
        kmlOverlay.url = createLink(action: 'getKML', params: [id: overlay?.id])


        kmlOverlays << kmlOverlay
      }
    }

    [rasterEntries: rasterEntries, left: left, top: top, right: right, bottom: bottom, kmlOverlays: kmlOverlays]
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

    def rasterEntryIds = params.rasterEntryIds?.split(',')
    def left = null
    def right = null
    def top = null
    def bottom = null

    def rasterEntries = []
    def kmlOverlays = []

    def hasKML = false

    rasterEntryIds.each {
      def rasterEntry = RasterEntry.get(it)

      rasterEntries << rasterEntry

      if ( left == null || rasterEntry.groundGeom?.bounds?.minLon < left )
      {
        left = rasterEntry.groundGeom?.bounds?.minLon
      }

      if ( bottom == null || rasterEntry.groundGeom?.bounds?.minLat < bottom )
      {
        bottom = rasterEntry.groundGeom?.bounds?.minLat
      }

      if ( right == null || rasterEntry.groundGeom?.bounds?.maxLon > right )
      {
        right = rasterEntry.groundGeom?.bounds?.maxLon
      }

      if ( top == null || rasterEntry.groundGeom?.bounds?.maxLat > top )
      {
        top = rasterEntry.groundGeom?.bounds?.maxLat
      }

      RasterEntryFile.findAllByTypeAndRasterEntry("kml", rasterEntry)?.each {kmlFile ->
        kmlOverays << kmlFile
      }
    }

    [rasterEntries: rasterEntries, kmlOverays: kmlOverlays,
        left: left, top: top, right: right, bottom: bottom,
        baseWMS: baseWMS]
  }

  def test = {
    [baseWMS: baseWMS, dataWMS: dataWMS]
  }

  def imageSpace = {
    //println params

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

    //println "${[width: width, height: height, inputFile: inputFile, entry: rasterEntry.entryId]}"

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

  public void afterPropertiesSet()
  {
    baseWMS = grailsApplication.config.wms.base
    dataWMS = grailsApplication.config.wms.data.raster
  }
}
