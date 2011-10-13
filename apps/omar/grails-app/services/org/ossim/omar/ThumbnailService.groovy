package org.ossim.omar

import joms.oms.Video
import java.awt.image.BufferedImage
import org.ossim.omar.RasterDataSet
import org.ossim.omar.RasterEntry
import org.ossim.omar.RasterFile
import org.ossim.omar.VideoDataSet
import org.ossim.omar.VideoFile

class ThumbnailService
{
  static transactional = false

  def nullImage = new BufferedImage(128, 128, BufferedImage.TYPE_INT_RGB);
  static int rasterFileOutputLock
  static int videoFrameOutputLock
  def grailsApplication

  def getThumbnail(HttpStatusMessage httpStatusMessage,
                   String cacheDirPath, String thumbnailPrefix, int size, String mimeType,
                   String inputFilename, String entryId, String projectionType,
                   boolean overwrite = false)
  {
    def outputFile = new File(
            cacheDirPath,
            "${thumbnailPrefix}.jpg"
    )
    httpStatusMessage.status = HttpStatus.OK
    String parent = outputFile.getParent();  // Get the destination directory
    File dir = new File(parent);          // Convert it to a file.
    if ( outputFile.exists() && !overwrite )
    {
      httpStatusMessage.status = HttpStatus.OK
      return outputFile
    }
    else if ( !checkCacheDir(dir) )
    {
      httpStatusMessage.status = HttpStatus.NOT_FOUND
      httpStatusMessage.message = "Cannot create directory: ${dir}"
      log.error(httpStatusMessage.message)
    }
    else if ( dir.isFile() )
    {
      httpStatusMessage.status = HttpStatus.NOT_FOUND
      httpStatusMessage.message = "${dir} is not a directory and can't produce raster thumbnail"
      log.error(httpStatusMessage.message)
    }
    else if ( !dir.canWrite() )
    {
      httpStatusMessage.status = HttpStatus.NOT_FOUND
      httpStatusMessage.message = "${dir} is not writeable and can't create raster thumbnails"
      log.error(httpStatusMessage.message)
    }
    if ( httpStatusMessage.status != HttpStatus.OK )
    {
      return new File("")
    }

    def histogramStretchType = "linear_auto_min_max"

    // for now we only support imagespace thumbnails
    //
    if ( projectionType != "imagespace" )
    {
      projectionType = "imagespace"
    }
    if ( !outputFile.exists() || overwrite )
    {
      synchronized ( rasterFileOutputLock )
      {
        log.info("Outputting raster thumbnail to ${outputFile as String}")
        def stretchTypeToUse = histogramStretchType

        ThumbnailGenerator.writeImageSpaceThumbnail(
                inputFilename,
                entryId,
                outputFile as String,
                mimeType,
                size, size,
                "", // use default
                stretchTypeToUse, true)
      }
    }

    return outputFile
  }

  def getFrame(String cacheDirPath, String thumbnailPrefix, int size, String inputFilename, boolean overwrite = false)
  {
    def outputFile = new File(cacheDirPath, "${thumbnailPrefix}.jpg")

    if ( !outputFile.exists() || overwrite )
    {
      Video video = new Video()

      if ( video.open(inputFilename) )
      {
        int idx = 0;
        for ( idx = 0; idx < 15; ++idx )
        {
          video.nextFrame();
        }
        synchronized ( videoFrameOutputLock )
        {
          log.info("Outputting video thumbnail to ${outputFile.absolutePath}")
          video.writeCurrentFrameToFile(outputFile.absolutePath, size);
        }
        video.close()
        video = null;
      }
      else
      {
        log.error("Unable to open video file ${outputFile.absolutePath}")
      }
    }

    return outputFile
  }

  public File getRasterEntryThumbnailFile(def httpStatusMessage, RasterEntry rasterEntry, Map params)
  {
    def projectionType = params.projectionType;
    RasterDataSet rasterDataSet = rasterEntry.rasterDataSet
    RasterFile rasterFile = RasterFile.findWhere(rasterDataSet: rasterDataSet, type: "main")
    def size = params.size?.toInteger()
    def mimeType = params?.mimeType ?: "image/jpeg"
    boolean overwrite = params.overwrite ?: false
    int resLevels = rasterEntry.numberOfResLevels;
    int maxSize = rasterEntry.width > rasterEntry.height ? rasterEntry.width : rasterEntry.height

    if ( !size )
    size = grailsApplication.config.thumbnail.defaultSize
    if ( size > maxSize )
    {
      size = maxSize
    }

    // check if size request for thumbnail can be generated
    // we will allow generation to 1 r-level downsample.
    // So if we have only 2 rlevels for an image but need 4 r-levels
    // we will error out
    //
    int smallestWidth = maxSize / (2 ** (resLevels + 2))

    if ( size < smallestWidth )
    {
      httpStatusMessage.status = HttpStatus.NOT_FOUND
      httpStatusMessage.message = "Not enough overviews to satisfy request for ${rasterFile.name}"
      return new File("")
    }

    String cacheDirPath = grailsApplication.config.thumbnail.cacheDir
    String thumbnailPrefix = "${rasterEntry.id}-${size}-${projectionType}"

    File outputFile = this.getThumbnail(httpStatusMessage,
            cacheDirPath,
            thumbnailPrefix,
            size,
            mimeType,
            rasterFile.name,
            rasterEntry.entryId,
            projectionType,
            overwrite
    )
    return outputFile
  }

  public File getVideoDataSetThumbnailFile(def httpStatusMessage, VideoDataSet videoDataSet, Map params)
  {
    VideoFile videoFile = VideoFile.findWhere(videoDataSet: videoDataSet, type: "main")
    def size = params.size?.toInteger() ?: grailsApplication.config.thumbnail.defaultSize
    String cacheDirPath = grailsApplication.config.thumbnail.cacheDir
    String thumbnailPrefix = "video-${videoDataSet.id}-${size}"
    boolean overwrite = params.overwrite ?: false
    File dir = new File(cacheDirPath);          // Convert it to a file.
    File outputFile = new File("")

    if ( !dir.exists() )
    {
      httpStatusMessage.status = HttpStatus.NOT_FOUND
      httpStatusMessage.message = "Cache directory ${dir} does not exist and can't create video thumbnail"
      log.error(httpStatusMessage.message)
    }
    else if ( !checkCacheDir(dir) )
    {
      httpStatusMessage.status = HttpStatus.NOT_FOUND
      httpStatusMessage.message = "Cannot create directory: ${dir}"
      log.error(httpStatusMessage.message)
    }
    else if ( dir.isFile() )
    {
      httpStatusMessage.status = HttpStatus.NOT_FOUND
      httpStatusMessage.message = "${dir} is not a directory and can't produce video thumbnail"
      log.error(httpStatusMessage.message)
    }
    else if ( !dir.canWrite() )
    {
      httpStatusMessage.status = HttpStatus.NOT_FOUND
      httpStatusMessage.message = "${dir} is not writeable and can't create video thumbnail"
      log.error(httpStatusMessage.message)
    }
    else
    {
      outputFile = this.getFrame(cacheDirPath, thumbnailPrefix, size, videoFile.name, overwrite)
    }

    if ( !outputFile.exists() )
    {
      httpStatusMessage.status = HttpStatus.NOT_FOUND
      httpStatusMessage.message = "Unable to write video thumbnail to directory ${cacheDirPath}"
      log.error(httpStatusMessage.message)
    }
    return outputFile
  }


  private boolean checkCacheDir(File dir)
  {
    boolean status = dir.exists()

    if ( !status )
    {
      try
      {
        status = dir.mkdirs()
      }
      catch (Exception e)
      {
      }
    }

    return status
  }
}
