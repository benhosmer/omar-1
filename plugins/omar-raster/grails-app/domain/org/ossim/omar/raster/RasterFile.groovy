package org.ossim.omar.raster

class RasterFile
{
  String name
  String type
  String format

  static belongsTo = [rasterDataSet: RasterDataSet]

  static constraints = {
    name( unique: true )
    type()
    format()
  }

  static mapping = {
    name index: 'raster_file_name_idx', unique: true
    type index: 'raster_file_type_idx'
    format index: 'raster_file_format_idx'
    rasterDataSet index: 'raster_file_raster_data_set_idx'
  }

  static RasterFile initRasterFile(def rasterFileNode)
  {
    def rasterFile = new RasterFile()

    rasterFile.name = new File( rasterFileNode?.name?.text() ).absolutePath
    rasterFile.format = rasterFileNode?.@format?.text()
    rasterFile.type = rasterFileNode?.@type?.text()
    return rasterFile
  }
}
