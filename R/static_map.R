#' Get static map
#'
#' Get static Mapbox map as a georeferenced raster
#' @name get_static_map
#' @param area the map area
#' @param map_style mapbox style, see `stylebox::mapbox_styles`
#' @param mapbox_api_access_token mapbox api access token
#' @param retina render the map at 2x scale if `TRUE`
#' @param scale_ratio ratio to scale the output image; `scale_ratio = 1` will give the largest image and smallest zoom.
#' @param area_buffer a buffer to appear around the `area` geometry in meters (web mercator projection, EPSG 3857).
#' Use this to create space around your data in the map visual.
#' @param mapbox_logo include mapbox logo on the image if TRUE
#' @param attribution include attribution on the image if TRUE.
#' You still have a legal responsibility to attribute maps that use OpenStreetMap data, which includes most maps from Mapbox.
#' If you specify attribution=FALSE, you are legally required to include proper attribution elsewhere on the webpage or document.
#' <https://docs.mapbox.com/api/maps/#static-images> and <https://docs.mapbox.com/help/how-mapbox-works/attribution/#static--print>
#' @param purge_cache forget cached api calls and responses before making api call if TRUE.
#' @export
get_static_map <- function(area,
                           map_style = mapbox_dark(),
                           mapbox_api_access_token = Sys.getenv("MAPBOX_ACCESS_TOKEN"),
                           retina = TRUE,
                           scale_ratio = 1,
                           area_buffer = 0,
                           mapbox_logo = TRUE,
                           attribution = TRUE,
                           purge_cache = FALSE) {
  stopifnot(inherits(area, c("sf", "sfc", "bbox")))

  max_dim <- min(1280, round(1280 * scale_ratio))

  mercator_bbox <- get_mercator_bbox(area, area_buffer)
  aspect_ratio <- get_aspect_ratio(mercator_bbox)

  width <- min(max_dim, round(max_dim * aspect_ratio))
  height <- min(max_dim, round(max_dim / aspect_ratio))

  map_img <- get_map_image(
    bbox = mercator_bbox,
    map_style = map_style,
    width = width,
    height = height,
    retina = retina,
    mapbox_logo = mapbox_logo,
    attribution = attribution,
    mapbox_api_access_token = mapbox_api_access_token,
    purge_cache = purge_cache
  )

  tile <- raster::brick(map_img) %>%
    raster::setExtent(raster::extent(
      mercator_bbox$xmin,
      mercator_bbox$xmax,
      mercator_bbox$ymin,
      mercator_bbox$ymax
    ))

  raster::crs(tile) <- "+proj=merc +a=6378137 +b=6378137 +lat_ts=0.0 +lon_0=0.0 +x_0=0.0 +y_0=0 +k=1.0 +units=m +nadgrids=@null +wktext +no_defs"

  tile
}
