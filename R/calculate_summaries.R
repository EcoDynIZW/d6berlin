# ------------------------------------------------------------------------------
#' Compute buffers and spatial intersections for analysis
#'
#' Core spatial processing function that creates circular buffers around origin
#' locations, intersects them with features, and computes buffer areas. Returns
#' all intermediate spatial objects needed for metric calculations. This
#' function handles CRS management and geometry validation automatically.
#'
#' @param origin An `sf` object with geometries representing the starting
#' locations for the buffers. Can be points, polygons, or linestrings.
#' CRS can be either projected (meters) or geographic (degrees); both are
#' handled transparently.
#' @param features An `sf` object with polygon or linestring geometries to
#' intersect with buffers. CRS should ideally match `origin`, but automatic
#' conversion is applied if needed. Geometries are validated and repaired
#' if necessary.
#' @param buffer_dist Buffer distance in map units. For projected CRS: meters.
#' For geographic CRS: degrees (automatically converted to meters via Web
#' Mercator projection). Must be a positive numeric value.
#'
#' @return A named list containing:
#' \itemize{
#'   \item `origin_proj`: `sf` object with the origin geometries in analysis CRS
#' (Web Mercator if input was geographic) with added `buffer_id` column
#' (sequential row numbers)
#'   \item `features_proj`: `sf` object with features in analysis CRS. All
#' non-geometry columns are prefixed with `"features_"` to avoid name
#' conflicts during later joins
#'   \item `buffers_sf`: `sf` object with circular buffer polygons, one per
#' origin location. Retains all columns from `origin_proj`
#'   \item `intersections`: `sf` object with polygon/linestring geometries
#' representing the intersection of buffers and features. Includes columns
#' from both buffers and features (prefixed)
#'   \item `buffer_area_df`: Data frame (not sf) with columns `buffer_id` and
#' `buffer_area` (in square meters). Useful for normalizing metrics per unit
#' area
#'   \item `is_lonlat`: Logical. TRUE if input `origin` CRS was geographic
#' (lon/lat), FALSE if projected. Useful for post-processing or understanding
#' original data
#' }
#'
#' @details
#' **CRS handling:**
#'   Geographic (lon/lat) input data is transparently converted to Web Mercator
#'   (EPSG:3857) for accurate distance-based buffering. All output objects
#'   (except `buffer_area_df`) retain the projected CRS; users must transform
#'   results back to original CRS if needed.
#'
#' **Geometry validation:**
#'   If `features` contains invalid geometries, they are automatically repaired
#'   via `sf::st_make_valid()`. This handles self-intersecting polygons, gaps,
#'   and other topological issues.
#'
#' **Column naming:**
#'   All columns from `features` are prefixed with `"features_"` to prevent
#'   name collisions when joining with buffer/origin columns. This is essential
#'   for metric functions that rely on specific column structures.
#'
#' **Buffer areas:**
#'   Buffer areas are computed directly from the buffer geometries and stored
#'   in the `buffer_area_df` as square meters (m²). Metric functions normalize
#'   by these areas as needed.
#'
#' @seealso
#' \code{\link{create_buffers}} for simple buffer creation without intersection
#' \code{\link{compute_summary_for_buffers}} for applying metric functions to
#' output
#' \code{\link{summarize_within_buffer}} for end-to-end analysis workflow
#' \code{\link[sf]{st_buffer}} for underlying buffering operation
#' \code{\link[sf]{st_intersection}} for intersection operation
#'
#' @examples
#' \dontrun{
#' set.seed(123456)
#' sf_points <- dplyr::sample_n(sf_metro, 5)
#' sf_features <- subset(sf_green, fclass %in% c("forest", "grass"))
#'
#' # basic usage: buffers around origins intersected with features
#' buf_info <- compute_buffer_intersections(
#'   origin = sf_points,
#'   features = sf_features,
#'   buffer_dist = 500
#' )
#'
#' # inspect intermediate objects
#' head(buf_info$buffer_area_df)
#' head(buf_info$intersections)
#' }
#'
#' @keywords internal
#' @family buffer summaries
compute_buffer_intersections <- function(origin,
                                         features,
                                         buffer_dist) {
  # pre-declaration of NSE columns
  geometry <- buffer_id <- buffer_area <- NULL

  is_lonlat <- sf::st_is_longlat(origin)

  if (is_lonlat) {
    origin_proj <- sf::st_transform(origin, 3857)
    features_proj <- sf::st_make_valid(sf::st_transform(features, 3857))
  } else {
    origin_proj <- origin
    features_proj <- features
  }

  origin_proj <- dplyr::mutate(
    origin_proj,
    buffer_id = dplyr::row_number()
  )

  buffers_sf <- create_buffers(origin_proj, buffer_dist)

  # prefix all feature columns to avoid name clashes
  feature_cols <- setdiff(
    names(features_proj), attr(features_proj, "sf_column")
  )
  names(features_proj)[names(features_proj) %in% feature_cols] <- paste0(
    "features_", feature_cols
  )

  intersections <- suppressWarnings(
    sf::st_intersection(buffers_sf, features_proj)
  )

  buffer_area_df <- buffers_sf |>
    dplyr::mutate(buffer_area = as.numeric(sf::st_area(geometry))) |>
    dplyr::select(buffer_id, buffer_area) |>
    sf::st_set_geometry(NULL)

  list(
    origin_proj    = origin_proj,
    features_proj  = features_proj,
    buffers_sf     = buffers_sf,
    intersections  = intersections,
    buffer_area_df = buffer_area_df,
    is_lonlat      = is_lonlat
  )
}


# ------------------------------------------------------------------------------
#' Calculate area shares of features within buffers
#'
#' Computes the proportion of each buffer area covered by features, optionally
#' stratified by feature type/class. This is a foundational metric for
#' landscape composition analysis, measuring what fraction of each buffer is
#' occupied by different feature types.
#'
#' @param origin_proj An `sf` object with geometries that define the starting
#' location for the buffer calculation and a `buffer_id` column. Typically
#' returned from `compute_buffer_intersections()`.
#' @param intersections An `sf` object with polygon geometries representing
#' buffer-feature intersections. Typically returned from
#' `compute_buffer_intersections()`. Feature columns must be prefixed with
#' `"features_"` (e.g., `features_habitat_type`).
#' @param buffer_area_df A data frame with columns `buffer_id` and `buffer_area`
#' (in m²). Typically returned from `compute_buffer_intersections()`.
#' @param type_col Optional character string specifying the feature type column
#' (WITHOUT the `"features_"` prefix, e.g., `"habitat_type"`). The function
#' automatically handles the `"features_"` prefix internally. If NULL, computes
#' aggregate share across all features.
#'
#' @return An `sf` object with `origin_proj` geometry and added columns:
#' \itemize{
#'   \item If `type_col = NULL`:
#' \itemize{
#'   \item `area_total`: Total area (m²) of features in buffer
#'   \item `share_total`: Proportion of buffer covered (0–1 scale)
#' }
#'   \item If `type_col` specified:
#' \itemize{
#'   \item `area_<type>`: Area (m²) for each unique type value
#'   \item `share_<type>`: Proportion for each unique type value
#' }
#' (one pair of columns per unique class in `type_col`)
#' }
#' Empty buffers (no feature intersections) have share = 0.
#'
#' @details
#' **Calculation:**
#'   Share = (intersection area) / (buffer area), capped at 1.0 to account for
#'   minor overlay artifacts. Buffers with zero area are handled gracefully
#'   (share = 0).
#'
#' **Type-stratification:**
#'   When `type_col` is specified, the function creates separate columns for
#'   each unique class value found in the data. This enables comparison of
#'   composition across landscape types. Missing type combinations are filled
#'   with 0.
#'
#' **Missing data:**
#'   Buffers with no intersections return share = 0 for all types, indicating
#'   complete absence of features.
#'
#' **Metric interpretation:**
#'   - share = 0: Feature type absent from buffer
#'   - share = 0.5: Feature type covers 50% of buffer
#'   - share = 1.0: Feature type covers entire buffer
#'   - For type-specific calculations, shares per type sum to ≤ 1.0
#'     (can be < 1.0 if multiple types overlap or features don't fill buffer)
#'
#' @seealso
#' \code{\link{compute_buffer_intersections}} for buffer-feature intersection
#' \code{\link{shd_index}} for diversity-based metric using shares
#' \code{\link{summarize_within_buffer}} for complete analysis workflow
#'
#' @examples
#' \dontrun{
#' set.seed(123456)
#' sf_points <- dplyr::sample_n(sf_metro, 5)
#' sf_features <- subset(sf_green, fclass %in% c("forest", "grass"))
#'
#' # get buffer-feature intersections
#' buf <- compute_buffer_intersections(sf_points, sf_features, buffer_dist = 500)
#'
#' # aggregate share across all features
#' shares_total <- area_shares(
#'   buf$origin_proj,
#'   buf$intersections,
#'   buf$buffer_area_df,
#'   type_col = NULL
#' )
#'
#' head(shares_total[c("buffer_id", "area_total", "share_total")])
#'
#' # type-stratified shares (requires 'type_col' column in features)
#' area_shares(
#'   buf$origin_proj,
#'   buf$intersections,
#'   buf$buffer_area_df,
#'   type_col = "fclass"
#' )
#'
#' head(shares_by_type[c("buffer_id", "share_forest", "share_grass")])
#' }
#'
#' @keywords internal
#' @family buffer summaries
#'
#' @importFrom tidyr pivot_wider expand_grid
#' @importFrom rlang sym .data :=
area_shares <- function(origin_proj,
                        intersections,
                        buffer_area_df,
                        type_col = NULL) {
  # pre-declaration of NSE columns
  geometry <- buffer_id <- area_total <- share_total <- buffer_area <-
    area <- share <- NULL

  # validate geometry type
  if (nrow(intersections) > 0) {
    geom_types <- unique(sf::st_geometry_type(intersections))
    if (!any(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
      stop(
        "area_shares() requires POLYGON/MULTIPOLYGON features. Got: ",
        paste(geom_types, collapse = ", ")
      )
    }
  }

  # extract type_col from features only
  if (!is.null(type_col)) {
    feature_col <- paste0("features_", type_col)
    if (!(feature_col %in% names(intersections))) {
      stop(
        "Feature type column '", feature_col,
        "' not found in intersections. ",
        "Check naming in compute_buffer_intersections()."
      )
    }
    intersections[[type_col]] <- intersections[[feature_col]]
    if (type_col %in% names(origin_proj)) origin_proj[[type_col]] <- NULL
  }

  if (nrow(intersections) > 0) {
    intersections_df <- intersections |>
      dplyr::mutate(area = as.numeric(sf::st_area(geometry))) |>
      sf::st_drop_geometry() |>
      dplyr::select(buffer_id, dplyr::any_of(type_col), area)

    if (!is.null(type_col)) {
      area_summary <- intersections_df |>
        dplyr::group_by(buffer_id, .data[[type_col]]) |>
        dplyr::summarise(area = sum(area), .groups = "drop")

      types <- unique(intersections[[type_col]])

      # ensure all buffer/type combinations (including empty ones)
      all_buffers <- tidyr::expand_grid(
        buffer_id = unique(origin_proj$buffer_id),
        !!rlang::sym(type_col) := types # nolint
      )

      area_summary <- all_buffers |>
        dplyr::left_join(area_summary, by = c("buffer_id", type_col)) |>
        dplyr::mutate(area = dplyr::coalesce(area, 0)) |>
        dplyr::left_join(buffer_area_df, by = "buffer_id") |>
        # prevent division by zero and cap share at 1.0
        dplyr::mutate(
          share = dplyr::if_else(
            buffer_area > 0,
            area / buffer_area,
            pmin(area / buffer_area, 1.0),
            0
          )
        ) |>
        tidyr::pivot_wider(
          id_cols = buffer_id,
          names_from = !!rlang::sym(type_col),
          values_from = c(area, share),
          names_sep = "_",
          values_fill = 0
        )
    } else {
      # no type column: calculate total area and share
      area_summary <- intersections_df |>
        dplyr::group_by(buffer_id) |>
        dplyr::summarise(area = sum(area), .groups = "drop") |>
        dplyr::right_join(buffer_area_df, by = "buffer_id") |>
        dplyr::mutate(
          area_total = dplyr::coalesce(area, 0),
          # prevent division by zero
          share_total = dplyr::if_else(
            buffer_area > 0,
            area_total / buffer_area,
            # pmin(area_total / buffer_area, 1.0), # cap share at 1.0 (?)
            0
          )
        ) |>
        dplyr::select(buffer_id, area_total, share_total)
    }
  } else {
    # no intersections → fill zeros for all buffers
    if (!is.null(type_col)) {
      # cannot know type values without intersections
      # return only total area/share and warn user
      warning("No intersections found. Type-specific columns will not be created.") # nolint
      area_summary <- buffer_area_df |>
        dplyr::mutate(
          area_total = 0,
          share_total = 0
        )
    } else {
      area_summary <- buffer_area_df |>
        dplyr::mutate(
          area_total = 0,
          share_total = 0
        )
    }
  }

  # ensure all buffers are in output
  dplyr::left_join(origin_proj, area_summary, by = "buffer_id")
}


# ------------------------------------------------------------------------------
#' Calculate Shannon Diversity Index within buffers
#'
#' Computes the Shannon Diversity Index (SHDI) for categorical features within
#' each buffer. SHDI quantifies landscape diversity based on the proportional
#' representation of different feature types. Higher values indicate greater
#' diversity (more balanced mix of types); lower values indicate dominance by
#' few types.
#'
#' @param origin_proj An `sf` object with geometries that define the starting
#' location for the buffer calculation and a `buffer_id` column. Typically
#' returned from `compute_buffer_intersections()`.
#' @param intersections An `sf` object with polygon/linestring geometries
#' representing buffer-feature intersections. Typically returned from
#' `compute_buffer_intersections()`. Feature columns must be prefixed with
#' `"features_"`.
#' @param buffer_area_df A data frame with columns `buffer_id` and `buffer_area`
#' (in m²). Typically returned from `compute_buffer_intersections()`.
#' @param type_col Character string specifying the feature type column
#' (WITHOUT the `"features_"` prefix, e.g., `"landcover_class"`).
#' The function automatically handles the `"features_"` prefix internally.
#' Feature types are identified from unique values in this column.
#'
#' @return An `sf` object with `origin_proj` geometry and added column:
#' \itemize{
#'   \item `shdi`: Shannon Diversity Index value per buffer (numeric)
#' }
#' Empty buffers (no intersections or single feature type) have shdi = 0.
#'
#' @details
#' **Formula:**
#'   SHDI = -Σ(p_i * ln(p_i)) where p_i is the proportion of type i.
#'   By convention, 0 * ln(0) = 0 (handled numerically).
#'
#' **Range and interpretation:**
#'   - SHDI = 0: Only one feature type present (no diversity)
#'   - SHDI = ln(n): Maximum diversity (all n types equally represented)
#'   - Example: 3 types with equal proportions → SHDI = ln(3) ≈ 1.099
#'   - Example: 2 types at 50/50 → SHDI = ln(2) ≈ 0.693
#'   - Example: 2 types at 90/10 → SHDI ≈ 0.325
#'
#' **Ecological meaning:**
#'   Higher SHDI indicates more complex landscape structure and potentially
#'   greater ecosystem resilience. Lower SHDI indicates landscape simplification
#'   or specialization (e.g., monoculture, urban sprawl).
#'
#' **Computation:**
#'   Proportions are calculated from intersection areas. Division by zero is
#'   protected (buffers with zero area have SHDI = 0). Missing type values
#'   or NA entries are excluded from calculations.
#'
#' @seealso
#' \code{\link{area_shares}} for proportion calculations used internally
#' \code{\link{compute_buffer_intersections}} for buffer-feature intersection
#' \code{\link{summarize_within_buffer}} for complete analysis workflow
#'
#' @examples
#' \dontrun{
#' set.seed(123456)
#' sf_points <- dplyr::sample_n(sf_metro, 5)
#' sf_features <- subset(sf_green, fclass %in% c("forest", "grass"))
#'
#' # get buffer-feature intersections
#' buf <- compute_buffer_intersections(
#'   sf_points,
#'   sf_features,
#'   buffer_dist = 500
#' )
#'
#' # calculate SHDI
#' diversity <- shd_index(
#'   buf$origin_proj,
#'   buf$intersections,
#'   buf$buffer_area_df,
#'   type_col = "fclass"
#' )
#'
#' head(diversity[c("buffer_id", "shdi")])
#' }
#'
#' @importFrom rlang sym
#'
#' @keywords internal
#' @family buffer summaries
shd_index <- function(origin_proj,
                      intersections,
                      buffer_area_df,
                      type_col) {
  # pre-declaration of NSE columns
  geometry <- buffer_id <- buffer_area <- area <- p <- shdi <- NULL

  if (is.null(type_col)) {
    stop("type_col must be provided for SHDI calculation.")
  }

  # validate geometry type
  if (nrow(intersections) > 0) {
    geom_types <- unique(sf::st_geometry_type(intersections))
    if (!any(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
      stop(
        "shd_index() requires POLYGON/MULTIPOLYGON features. Got: ",
        paste(geom_types, collapse = ", ")
      )
    }
  }

  # validate inputs
  if (!inherits(origin_proj, "sf")) {
    stop("origin_proj must be an sf object")
  }
  if (!inherits(intersections, "sf")) {
    stop("intersections must be an sf object")
  }

  # extract type_col from features
  feature_col <- paste0("features_", type_col)
  if (!(feature_col %in% names(intersections))) {
    stop(
      "Feature type column '", feature_col,
      "' not found in intersections. ", "
      Check naming in compute_buffer_intersections()."
    )
  }
  intersections[[type_col]] <- intersections[[feature_col]]

  # remove type_col from origin if it exists
  if (type_col %in% names(origin_proj)) {
    origin_proj[[type_col]] <- NULL
  }

  if (nrow(intersections) == 0) {
    # no intersections → SHDI = 0 for all buffers
    shdi_df <- buffer_area_df |>
      dplyr::select(buffer_id) |>
      dplyr::mutate(shdi = 0)

    return(origin_proj |> dplyr::left_join(shdi_df, by = "buffer_id"))
  }

  inter_df <- intersections |>
    dplyr::mutate(area = as.numeric(sf::st_area(geometry))) |>
    sf::st_drop_geometry() |>
    dplyr::select(buffer_id, !!rlang::sym(type_col), area)

  # compute proportion per buffer and class
  inter_df <- inter_df |>
    dplyr::group_by(buffer_id, .data[[type_col]]) |>
    dplyr::summarise(area = sum(area, na.rm = TRUE), .groups = "drop") |>
    dplyr::left_join(buffer_area_df, by = "buffer_id") |>
    # handle division by zero
    dplyr::mutate(
      p = dplyr::if_else(buffer_area > 0, area / buffer_area, 0)
    )

  # compute SHDI per buffer: SHDI = -Σ(p_i * ln(p_i))
  # note: p * ln(p) = 0 when p = 0 (by convention in diversity calculations)
  shdi_df <- inter_df |>
    dplyr::group_by(buffer_id) |>
    dplyr::summarise(
      shdi = -sum(
        dplyr::if_else(p > 0, p * log(p), 0),
        na.rm = TRUE
      ),
      .groups = "drop"
    ) |>
    # ensure all buffers are present (even those with no intersections)
    dplyr::right_join(
      dplyr::select(buffer_area_df, buffer_id),
      by = "buffer_id"
    ) |>
    dplyr::mutate(shdi = dplyr::coalesce(shdi, 0))

  # join back to origin_proj
  dplyr::left_join(origin_proj, shdi_df, by = "buffer_id")
}


# ------------------------------------------------------------------------------
#' Calculate line density of features within buffers
#'
#' Computes the density of linear features (km of line per km² of buffer area)
#' within each buffexr, optionally stratified by feature type/class. This metric
#' quantifies linear infrastructure or network intensity in the landscape
#' (e.g., road density, stream density, utility line density).
#'
#' @param origin_proj An `sf` object with geometries that define the starting
#' location for the buffer calculation and a `buffer_id` column. Typically
#' returned from `compute_buffer_intersections()`.
#' @param intersections An `sf` object with linestring geometries representing
#' buffer-feature intersections. Typically returned from
#' `compute_buffer_intersections()`. Feature columns must be prefixed with
#' `"features_"`. ONLY LINESTRING/MULTILINESTRING geometries supported.
#' @param buffer_area_df A data frame with columns `buffer_id` and `buffer_area`
#' (in m²). Typically returned from `compute_buffer_intersections()`.
#' @param type_col Optional character string specifying the feature type column
#' (WITHOUT the `"features_"` prefix, e.g., `"road_type"`). If provided,
#' density is calculated separately for each unique type category. If NULL,
#' computes aggregate density across all linear features.
#'
#' @return An `sf` object with `origin_proj` geometry and added columns:
#'   \itemize{
#'     \item If `type_col = NULL`:
#'       \itemize{
#'         \item `length_km`: Total line length (km) of all features in buffer
#'         \item `density_km2_total`: Line density (km/km²)
#'       }
#'     \item If `type_col` specified:
#'       \itemize{
#'         \item `length_km_<type>`: Line length (km) for each type
#'         \item `density_km2_<type>`: Density for each type
#'       }
#'       (one pair of columns per unique class in `type_col`)
#'   }
#'   Empty buffers (no line intersections) have density = 0.
#'
#' @details
#' **Calculation:**
#'   Density = (total line length in km) / (buffer area in km²).
#'   Buffers with zero area are handled gracefully (density = 0).
#'
#' **Units:**
#'   Input CRS must be projected with units in meters (e.g., UTM, Web Mercator).
#'   Output is always in km/km² (line kilometers per square kilometer of
#'   buffer).
#'
#' **CRS requirements:**
#'   If data is in geographic coordinates (lon/lat), a warning is issued.
#'   The function requires projected coordinates for accurate distance
#'   calculation. Use `sf::st_transform()` to project to appropriate CRS
#'   (e.g., UTM zone, Web Mercator EPSG:3857).
#'
#' **Type-stratification:**
#'   When `type_col` is specified, creates separate columns for each unique
#'   class value. Useful for comparing densities across road types (major/
#'   minor), stream orders, or utility types. Missing type combinations are
#'   filled with 0.
#'
#' **Missing data:**
#'   Buffers with no intersections return length = 0 and density = 0 for all
#'   types, indicating complete absence of linear features.
#'
#' **Metric interpretation:**
#'   - density = 0: No linear features in buffer
#'   - density = 1: 1 km of features per km² (moderate)
#'   - density = 5: 5 km of features per km² (high fragmentation/intensity)
#'
#' @seealso
#'   \code{\link{compute_buffer_intersections}} for buffer-feature intersection
#'   \code{\link{area_shares}} for composition metrics (polygons)
#'   \code{\link{summarize_within_buffer}} for complete analysis workflow
#'
#' @examples
#' \dontrun{
#' set.seed(123456)
#' sf_points <- dplyr::sample_n(sf_metro, 5)
#' sf_lines <- subset(sf_railways, fclass %in% c("subway", "rail"))
#'
#' # get buffer-line intersections
#' buf <- compute_buffer_intersections(
#'   origin = sf_points,
#'   features = sf_lines,
#'   buffer_dist = 1000
#' )
#'
#' # aggregate density across all linestrings
#' total_density <- line_density(
#'   buf$origin_proj,
#'   buf$intersections,
#'   buf$buffer_area_df,
#'   type_col = NULL
#' )
#'
#' head(total_density[c("buffer_id", "length_km", "density_km2_total")])
#'
#' # type-stratified density (e.g., by railway type)
#' # requires 'type_col' column in original features
#' density_by_type <- line_density(
#'   buf$origin_proj,
#'   buf$intersections,
#'   buf$buffer_area_df,
#'   type_col = "fclass"
#' )
#'
#' head(density_by_type[
#'   c(
#'     "buffer_id", "length_km_rail", "density_km2_rail",
#'     "length_km_subway", "density_km2_subway"
#'   )
#' ])
#' }
#'
#' @keywords internal
#' @family buffer summaries
#'
#' @importFrom tidyr pivot_wider expand_grid
#' @importFrom rlang sym
line_density <- function(origin_proj,
                         intersections,
                         buffer_area_df,
                         type_col = NULL) {
  # pre-declaration of NSE columns
  geometry <- buffer_id <- buffer_area <- length_km <- area_km2 <-
    density_km2 <- density_km2_total <- NULL

  # validate geometry type
  if (nrow(intersections) > 0) {
    geom_types <- unique(sf::st_geometry_type(intersections))
    if (!any(geom_types %in% c("LINESTRING", "MULTILINESTRING"))) {
      stop(
        "line_density() requires LINESTRING/MULTILINESTRING features. Got: ",
        paste(geom_types, collapse = ", ")
      )
    }
  }

  # validate inputs
  if (!inherits(origin_proj, "sf")) {
    stop("origin_proj must be an sf object")
  }
  if (!inherits(intersections, "sf")) {
    stop("intersections must be an sf object")
  }

  # check if CRS is projected (not geographic)
  crs_info <- sf::st_crs(origin_proj)
  if (!is.na(crs_info$epsg) && crs_info$epsg == 4326) {
    warning(
      "Data appears to be in geographic coordinates (EPSG:4326). ",
      "Line density calculations require projected coordinates in meters."
    )
  }

  # ensure buffer area in km²
  buffer_area_df <- buffer_area_df |>
    dplyr::mutate(area_km2 = buffer_area / 1e6)

  # extract type_col from features/intersections
  if (!is.null(type_col)) {
    feature_col <- paste0("features_", type_col)
    if (!(feature_col %in% names(intersections))) {
      stop(
        "Feature type column '", feature_col,
        "' not found in intersections. ", "
        Check naming in compute_buffer_intersections()."
      )
    }
    intersections[[type_col]] <- intersections[[feature_col]]
    # remove type_col from origin if it exists (avoid conflicts)
    if (type_col %in% names(origin_proj)) {
      origin_proj[[type_col]] <- NULL
    }
  }

  # handle case with intersections
  if (nrow(intersections) > 0) {
    # calculate length BEFORE dropping geometry
    df <- intersections |>
      dplyr::mutate(length_km = as.numeric(sf::st_length(geometry)) / 1000) |>
      sf::st_drop_geometry() |>
      dplyr::select(buffer_id, dplyr::any_of(type_col), length_km)

    if (!is.null(type_col)) {
      # summarize per buffer and feature type
      summary_df <- df |>
        dplyr::group_by(buffer_id, .data[[type_col]]) |>
        dplyr::summarise(
          length_km = sum(length_km, na.rm = TRUE), .groups = "drop"
        )

      # ensure all buffer/type combinations exist (fill missing with 0)
      types <- unique(intersections[[type_col]])
      all_combinations <- tidyr::expand_grid(
        buffer_id = unique(origin_proj$buffer_id),
        !!rlang::sym(type_col) := types
      )

      density_df <- all_combinations |>
        dplyr::left_join(summary_df, by = c("buffer_id", type_col)) |>
        dplyr::mutate(length_km = dplyr::coalesce(length_km, 0)) |>
        dplyr::left_join(buffer_area_df, by = c("buffer_id")) |>
        dplyr::mutate(density_km2 = length_km / area_km2) |>
        tidyr::pivot_wider(
          id_cols = buffer_id,
          names_from = !!rlang::sym(type_col),
          values_from = c(length_km, density_km2),
          names_sep = "_",
          values_fill = 0
        )
    } else {
      # total length/density across all types
      density_df <- df |>
        dplyr::group_by(buffer_id) |>
        dplyr::summarise(
          length_km = sum(length_km, na.rm = TRUE), .groups = "drop"
        ) |>
        dplyr::right_join(buffer_area_df, by = "buffer_id") |>
        dplyr::mutate(
          length_km = dplyr::coalesce(length_km, 0),
          density_km2_total = length_km / area_km2
        ) |>
        dplyr::select(buffer_id, length_km, density_km2_total)
    }
  } else {
    # no intersections → all buffers get 0 length and density
    if (!is.null(type_col)) {
      warning(
        "No intersections found. Type-specific columns will not be created."
      )

      density_df <- dplyr::mutate(
        buffer_area_df,
        length_km = 0, density_km2_total = 0
      )
    } else {
      density_df <- dplyr::mutate(
        buffer_area_df,
        length_km = 0, density_km2_total = 0
      )
    }
  }

  # join back to origin_proj
  dplyr::left_join(origin_proj, density_df, by = "buffer_id")
}


# ------------------------------------------------------------------------------
#' Calculate Aggregation Index within buffers
#'
#' Computes the Aggregation Index (AI) following FRAGSTATS methodology. AI
#' quantifies the spatial clustering of feature patches and indicates how much
#' patches of the same type are aggregated versus scattered across the buffer.
#' This is a configuration metric (not composition).
#'
#' @param origin_proj An `sf` object with geometries that define the starting
#' location for the buffer calculation and a `buffer_id` column. Typically
#' returned from `compute_buffer_intersections()`.
#' @param intersections An `sf` object with polygon geometries representing
#' buffer-feature intersections. Typically returned from
#' `compute_buffer_intersections()`. Feature columns must be prefixed with
#' `"features_"`. Only POLYGON/MULTIPOLYGON geometries are supported.
#' @param buffer_area_df A data frame with columns `buffer_id` and `buffer_area`
#' (in m²). Typically returned from `compute_buffer_intersections()`.
#' @param type_col Character string specifying the feature type column
#' (WITHOUT the `"features_"` prefix, e.g., `"patch_type"`).
#' AI is calculated separately per type.
#' @param raster_res Numeric: raster resolution in map units (meters for
#' projected CRS). Controls grain of spatial analysis. Too fine (<5% feature
#' size) biases AI low (~50 convergence due to noise); too coarse (>2x feature
#' size) biases high/unreliable. Default: auto-set to median(polygon length/10,
#' poly diagonals/20), clipped 1-50m. Suggested: 1-50m matching polygon scale.
#'
#' @return An `sf` object with `origin_proj` geometry and added columns:
#' \itemize{
#'   \item `ai_<type>`: Aggregation Index for each unique type (0–100 scale)
#' }
#' Empty buffers or buffers without a given type have ai = NA.
#'
#' @details
#' **Formula:**
#'   AI = (gii / max_gii) * 100, where:
#'   - gii = number of like-adjacencies (4-neighbor rule)
#'   - max_gii = maximum possible adjacencies for n cells in compact form
#'   - Result capped at 100
#'
#' **Range and interpretation:**
#'   - AI = 0: Patches completely dispersed (checkerboard pattern)
#'   - AI = 50: Intermediate aggregation
#'   - AI = 100: Patches maximally aggregated (single compact cluster)
#'   - NA: Type absent from buffer
#'
#' **Ecological meaning:**
#'   High AI indicates habitat clustering (may support species requiring large
#'   contiguous patches). Low AI indicates fragmentation (may benefit species
#'   using dispersed resources or harm those needing large patches).
#'
#' **Implementation details:**
#'   - Buffers are rasterized at specified resolution
#'   - 4-neighbor adjacency rule (diagonal neighbors not counted)
#'   - Cells on buffer edges are included in calculations
#'   - Single-cell patches have AI = 0 (no adjacencies possible)
#'
#' **Raster resolution considerations:**
#' Auto-set (if NULL) to median of intersection polygon median side_length/10
#' (~10%) and diagonal/20 (~5%), clipped 1-50m. Rationale: Ensures polygons span
#' multiple cells for meaningful adjacencies, avoiding AI convergence near 50
#' (too fine, noisy) or unreliability (too coarse). Varies with clipped features
#' for scale-adaptive analysis.
#'
#'   - Finer (1-5m): Fine fragmentation; risk of bias if << feature size
#'   - Coarse (10-50m): Faster; loses detail if >> feature size
#'
#' Warnings flag extremes relative to feature specifications when set manually.
#'
#' @seealso
#' \code{\link{compute_buffer_intersections}} for buffer-feature intersection
#' \code{\link{area_shares}} for composition metrics
#' \code{\link{summarize_within_buffer}} for complete analysis workflow
#'
#' @examples
#' \dontrun{
#' set.seed(123456)
#' sf_points <- dplyr::sample_n(sf_metro, 5)
#' sf_features <- subset(sf_green, fclass %in% c("forest", "grass"))
#'
#' # get buffer-feature intersections
#' buf <- compute_buffer_intersections(
#'   origin = sf_points,
#'   features = sf_features,
#'   buffer_dist = 1000
#' )
#'
#' # calculate AI (default 1m resolution)
#' aggregation <- aggregation_index(
#'   buf$origin_proj,
#'   buf$intersections,
#'   buf$buffer_area_df,
#'   type_col = "fclass"
#' )
#'
#' head(aggregation[c("buffer_id", "ai_forest", "ai_grass")])
#'
#' # coarser resolution for faster computation on large buffers
#' aggregation_fast <- aggregation_index(
#'   buf$origin_proj,
#'   buf$intersections,
#'   buf$buffer_area_df,
#'   type_col = "fclass",
#'   raster_res = 25 # 25m cells
#' )
#'
#' head(aggregation_fast[c("buffer_id", "ai_forest", "ai_grass")])
#' }
#'
#' @keywords internal
#' @family buffer summaries
#'
#' @importFrom tidyr pivot_wider
#' @importFrom stats setNames
aggregation_index <- function(origin_proj,
                              intersections,
                              buffer_area_df,
                              type_col,
                              raster_res = NULL) {
  # pre-declaration of NSE columns
  buffer_id <- ai <- NULL

  if (is.null(raster_res)) {
    # compute meaningful defaults based on polygon features and buffer
    suppressWarnings({
      side_len <- max(median(units::drop_units(sf::st_length(sf::st_cast(intersections, "LINESTRING")))), 1)
      poly_diag <- max(median(units::drop_units(sqrt(sf::st_area(intersections))) * 2), 10)
    })

    raster_res_cand <- c(side_len / 10, poly_diag / 20)
    raster_res <- median(pmax(pmin(raster_res_cand, 50), 1))

    message(sprintf(
      "raster_res = %.1f m based on feature specifications: median of side/10 = %.0fm and diag/2 = %.0fm (limited to a range of 1-50m)",
      raster_res, side_len / 10, poly_diag / 20
    ))
  } else {
    # warn for too small (detail loss, convergence issues) or too coarse resolutions
    warned_too_small <- FALSE
    warned_too_large <- FALSE

    suppressWarnings({
      intersections_clean <- sf::st_cast(intersections, "POLYGON")
      min_side_len <- max(median(units::drop_units(sf::st_length(sf::st_cast(intersections_clean, "LINESTRING")))), 1)
      poly_diag <- max(median(units::drop_units(sqrt(sf::st_area(intersections_clean))) * 2), 10)
    })

    if (raster_res < min_side_len / 20 && !warned_too_small) {
      warning(sprintf(
        "raster_res = %.0fm very fine: <5%% median side length (%.0fm).
May cause AI convergence near 50%% due to noise -> consider coarser resolution.",
        raster_res, min_side_len
      ), call. = FALSE)
      warned_too_small <- TRUE
    }

    if (raster_res > poly_diag / 5 && !warned_too_large) {
      warning(sprintf(
        "raster_res = %.0fm very coarse: >20%% median polygon diagonal (%.0fm).
AI calculations may be unreliable or result in NA -> consider finer resolution.",
        raster_res, poly_diag
      ), call. = FALSE)
      warned_too_large <- TRUE
    }
  }

  # type_col required here
  if (missing(type_col)) {
    stop("type_col is required for AI calculation.")
  }

  if (is.null(type_col)) {
    stop("type_col cannot be NULL for AI calculation.")
  }

  # validate geometry type
  if (nrow(intersections) > 0) {
    geom_types <- unique(sf::st_geometry_type(intersections))
    if (!any(geom_types %in% c("POLYGON", "MULTIPOLYGON"))) {
      stop(
        "aggregation_index() requires POLYGON/MULTIPOLYGON features. Got: ",
        paste(geom_types, collapse = ", ")
      )
    }
  }

  # validate inputs
  if (!inherits(origin_proj, "sf")) {
    stop("origin_proj must be an sf object")
  }
  if (!inherits(intersections, "sf")) {
    stop("intersections must be an sf object")
  }

  # extract type_col with proper error handling
  feature_col <- paste0("features_", type_col)
  if (!(feature_col %in% names(intersections))) {
    stop(
      "Feature type column '", feature_col,
      "' not found in intersections. ",
      "Check naming in compute_buffer_intersections()."
    )
  }
  intersections[[type_col]] <- intersections[[feature_col]]

  # remove type_col from origin if present
  if (type_col %in% names(origin_proj)) {
    origin_proj[[type_col]] <- NULL
  }

  # handle empty intersections
  if (nrow(intersections) == 0) {
    # all buffers get NA (no data to calculate)
    return(origin_proj |> dplyr::mutate(ai = NA_real_))
  }

  # get all classes and buffers
  all_classes <- unique(intersections[[type_col]])
  all_classes <- all_classes[!is.na(all_classes)]

  if (length(all_classes) == 0) {
    return(dplyr::mutate(origin_proj, ai = NA_real_))
  }

  all_buffers <- unique(origin_proj$buffer_id)

  # calculate AI for each buffer and class combination
  ai_list <- lapply(all_buffers, function(bid) {
    # polygons in this buffer
    buf_poly <- intersections |> dplyr::filter(buffer_id == bid)

    if (nrow(buf_poly) == 0) {
      # empty buffer gets NA for all classes
      return(setNames(rep(NA_real_, length(all_classes)), all_classes))
    }

    bid <- unique(buf_poly$buffer_id)
    buffer_area <- buffer_area_df$buffer_area[buffer_area_df$buffer_id == bid]
    est_radius_m <- sqrt(buffer_area / pi) # EXACT from area

    # create raster template from the intersections extent (not from origin!)
    buf_vect <- terra::vect(buf_poly)
    e <- terra::ext(buf_vect)
    r <- terra::rast(e, resolution = raster_res)

    # check if raster creation succeeded
    if (is.null(r)) {
      return(setNames(rep(NA_real_, length(all_classes)), all_classes))
    }

    # rasterize polygons with class values
    r_binary <- terra::rasterize(
      terra::vect(buf_poly),
      r,
      field = type_col,
      background = NA
    )

    # calculate AI for each class present in this buffer
    ai_vals <- sapply(all_classes, function(cls) {
      # get numeric presence matrix directly (no == comparison)
      r_class <- (r_binary == cls) * 1 # numeric 0/1
      mat <- terra::as.matrix(r_class, wide = TRUE)
      mat[is.na(mat)] <- 0 # background = 0

      n_cells <- sum(mat)

      if (n_cells == 0) {
        return(NA_real_)
      }
      if (n_cells == 1) {
        return(0)
      }

      # 4-neighbor adjacencies (single-count)
      gii_h <- sum(mat[, -ncol(mat)] & mat[, -1], na.rm = TRUE)
      gii_v <- sum(mat[-nrow(mat), ] & mat[-1, ], na.rm = TRUE)
      gii <- (gii_h + gii_v) / 2

      # FRAGSTATS max_gii
      n_side <- floor(sqrt(n_cells))
      m_rem <- n_cells - n_side^2
      if (m_rem == 0) {
        max_gii <- 2 * n_side * (n_side - 1)
      } else if (m_rem <= n_side) {
        max_gii <- 2 * n_side * (n_side - 1) + 2 * m_rem - 1
      } else {
        max_gii <- 2 * n_side * (n_side - 1) + 2 * m_rem - 2
      }

      if (max_gii == 0) {
        return(0)
      }

      ai <- pmin((gii / max_gii) * 100, 100)
      ai
    })

    ai_vals
  })

  # flatten to data frame
  ai_df <- data.frame(
    buffer_id = rep(all_buffers, lengths(ai_list)),
    class = unlist(lapply(ai_list, names), use.names = FALSE),
    ai = unlist(ai_list, use.names = FALSE)
  )

  # pivot to wide format
  ai_wide <- tidyr::pivot_wider(
    ai_df,
    id_cols = buffer_id,
    names_from = class,
    values_from = ai,
    names_prefix = "ai_",
    values_fill = NA_real_
  )

  # join back to origin_proj
  dplyr::left_join(origin_proj, ai_wide, by = "buffer_id")
}


# ------------------------------------------------------------------------------
#' Compute buffer intersections and apply summary function
#'
#' Internal helper function that helps executing the spatial summary workflow.
#' This function handles the core pipeline: creating buffers around geometries,
#' intersecting them with features, and applying a user-specified summary metric
#' function.
#'
#' @param origin An `sf` object with geometries representing the starting
#' locations for the buffers. Can be points, polygons, or linestrings.
#' CRS can be either projected (meters) or geographic (degrees); both are
#' handled transparently.
#' @param features An `sf` object with POLYGON or LINESTRING geometries to
#' summarize within buffers.
#' @param buffer_dist Buffer distance in map units (meters if projected CRS,
#' degrees if geographic CRS).
#' @param summary_fn A function that computes the desired spatial metric. Must
#' accept arguments: `(origin_proj, intersections, buffer_area_df, type_col)`.
#' Expected functions include `area_shares()`, `line_density()`, `shd_index()`,
#' or `aggregation_index()`.
#' @param type_col Optional character string specifying a column in `features`
#' to group summary calculations by class/type. If NULL, computes summary
#' across all features.
#'
#' @return A list containing:
#' \itemize{
#'   \item `result`: An `sf` object with summary metrics joined to origin.
#' Exact columns depend on `summary_fn`.
#'   \item `buf_info`: A list containing intermediate spatial objects:
#' \itemize{
#'   \item `origin_proj`: Origin geometries in projected CRS with `buffer_id`
#'   \item `features_proj`: Features in projected CRS with prefixed column names
#'   \item `buffers_sf`: Buffer polygons
#'   \item `intersections`: Intersection of buffers with features
#'   \item `buffer_area_df`: Data frame with buffer areas
#'   \item `is_lonlat`: Logical indicating if original CRS was geographic
#' }
#' }
#'
#' @details
#' This function is the internal backbone of `summarize_within_buffer()`.
#' It separates buffer creation (via `compute_buffer_intersections()`) from
#' metric calculation, enabling flexible reuse of buffer objects and supporting
#' both single and multiple metric calculations on the same buffers.
#'
#' Automatically handles CRS conversion: if input data is in geographic
#' coordinates, converts to Web Mercator (EPSG:3857) for accurate distance
#' calculations.
#'
#' @keywords internal
#' @seealso
#' \code{\link{compute_buffer_intersections}} for buffer creation details
#' \code{\link{area_shares}} for example metric function
#' \code{\link{summarize_within_buffer}} for user-facing wrapper
#'
#' @examples
#' \dontrun{
#' set.seed(123456)
#' sf_points <- dplyr::sample_n(sf_metro, 5)
#' sf_features <- subset(sf_green, fclass %in% c("forest", "grass"))
#'
#' # using area_shares metric
#' result_list <- compute_summary_for_buffers(
#'   origin = sf_points,
#'   features = sf_features,
#'   buffer_dist = 500,
#'   summary_fn = area_shares,
#'   type_col = "fclass"
#' )
#'
#' metrics <- result_list$result # get the sf object with metrics
#' metrics
#'
#' buffers <- result_list$buf_info # access intermediate spatial data
#' buffers
#' }
#'
#' @family buffer summaries
compute_summary_for_buffers <- function(origin,
                                        features,
                                        buffer_dist,
                                        summary_fn,
                                        type_col = NULL,
                                        ...) {
  buf <- compute_buffer_intersections(origin, features, buffer_dist)
  result <- do.call(
    summary_fn,
    c(
      list(
        buf$origin_proj, buf$intersections, buf$buffer_area_df,
        type_col = type_col
      ),
      list(...)
    )
  )
  list(result = result, buf_info = buf)
}


# ------------------------------------------------------------------------------
#' Generalized buffer-based spatial summary wrapper
#'
#' Computes buffers around origin geometries and calculates spatial metrics for
#' features within those buffers. This is the primary user-facing function for
#' buffer-based spatial analysis. Supports flexible metric selection and
#' optional aggregation across all buffers.
#'
#' @param origin An `sf` object with geometries representing the starting
#' locations for the buffers. Can be points, polygons, or linestrings.
#' CRS can be either projected (meters) or geographic (degrees); both are
#' handled transparently.
#' @param features An `sf` object with polygon or linestring geometries to
#' summarize.
#' Geometry type should match the requirements of `summary_metric`.
#' @param buffer_dist Buffer distance in map units. Interpreted as meters for
#' projected CRS or degrees for geographic CRS (lon/lat). Automatically handles
#' CRS conversion if needed.
#' @param type_col Optional character string specifying a column in `features`
#' for grouping calculations by class or category. If provided, metrics are
#' calculated separately per class and output as columns `<metric>_<class>`.
#' If NULL, computes aggregate metrics across all features.
#' @param summary_metric Function to calculate the spatial metric. Defaults to
#' `area_shares()`. Other built-in options: `line_density()`, `shd_index()`,
#' `aggregation_index()`. Custom functions must accept arguments:
#' `(origin_proj, intersections, buffer_area_df, type_col)`.
#' @param summary Logical. If TRUE, returns aggregated statistics (mean, SD,
#' etc.) across all buffers instead of per-origin results. Useful for
#' landscape-level summaries. Default: FALSE.
#' @param metric_pattern Character string containing a regular expression for
#' identifying metric columns in results. Used only when `summary = TRUE`.
#' Default pattern matches common metric prefixes:
#' `"^(share_|shdi|ai|density_)"`. Customize for custom metrics, e.g.,
#' `"^my_metric"`.
#' @param ... Additional arguments passed to `summary_metric`. Use this to pass
#' metric-specific parameters, e.g., `raster_res = 10` for
#' `aggregation_index()`.
#'
#' @return
#' If `summary = FALSE` (default):
#' An `sf` object with the same rows as `origin` and added metric columns.
#' Column names depend on `summary_metric` and `type_col`. Retains original
#' geometry and CRS of the origin locations.
#'
#' If `summary = TRUE`:
#' A data frame with one row per metric containing aggregated statistics:
#' \itemize{
#'   \item `variable`: Metric name
#'   \item `mean`: Mean value across all buffers
#'   \item `sd`: Standard deviation
#'   \item `n`: Count of non-NA values
#'   \item `n_nonzero`: Number of buffers where metric > 0
#'   \item `prop_nonzero`: Proportion of buffers with metric > 0
#' }
#' Rows sorted by proportion nonzero (descending) then mean (descending).
#'
#' @details
#' This function provides a complete workflow for buffer-based spatial analysis:
#'
#' 1. **Buffer creation**: Automatically creates circular buffers at specified
#'    buffer_dist
#' 2. **Spatial intersection**: Intersects buffers with features
#' 3. **Metric calculation**: Applies user-selected metric function
#' 4. **Optional aggregation**: Summarizes across buffers for landscape-level
#'    insights
#'
#' **CRS handling**: Automatically detects and converts geographic (lon/lat)
#'   data to Web Mercator (EPSG:3857) for accurate distance calculations, then
#'   transforms results back to original CRS.
#'
#' **Metric functions**: Built-in metrics include:
#'   - `area_shares()`: Proportion of buffer covered by each feature type
#'   - `line_density()`: Length per unit area of linear features (km/km²)
#'   - `shd_index()`: Shannon Diversity Index for categorical features
#'   - `aggregation_index()`: Aggregation index following FRAGSTATS methodology
#'
#' **Type-specific calculations**: When `type_col` is provided, creates separate
#'   columns for each unique class value, enabling comparison across landscape
#'   types.
#'
#' **Landscape summary**: The `summary = TRUE` option calculates mean, SD, and
#'   presence statistics across all buffers, useful for characterizing overall
#'   landscape patterns. The `prop_nonzero` column indicates spatial prevalence
#'   (e.g., 0.5 = metric present in 50% of buffers).
#'
#' @seealso
#' \code{\link{compute_summary_for_buffers}} for internal orchestration
#' \code{\link{area_shares}} for area-based metrics
#' \code{\link{line_density}} for linear feature metrics
#' \code{\link{shd_index}} for diversity metrics
#' \code{\link{aggregation_index}} for spatial configuration metrics
#' \code{\link{summarize_overall}} for landscape-level statistics
#'
#' @examples
#' \dontrun{
#' set.seed(123456)
#' sf_points <- dplyr::sample_n(sf_metro, 5)
#' sf_features <- subset(sf_green, fclass %in% c("forest", "grass"))
#' sf_lines <- subset(sf_railways, fclass %in% c("subway", "rail"))
#'
#' # per-origin area shares by habitat type (500m buffers)
#' summarize_within_buffer(
#'   origin = sf_points,
#'   features = sf_features,
#'   buffer_dist = 500,
#'   summary_metric = area_shares,
#'   type_col = "fclass"
#' )
#'
#' # landscape-level line density summary
#' summarize_within_buffer(
#'   origin = sf_points,
#'   features = sf_lines,
#'   buffer_dist = 1000,
#'   summary_metric = line_density,
#'   summary = TRUE
#' )
#'
#' # Shannon diversity with custom metric pattern
#' summarize_within_buffer(
#'   origin = sf_points,
#'   features = sf_features,
#'   buffer_dist = 250,
#'   type_col = "fclass",
#'   summary_metric = shd_index,
#'   summary = TRUE,
#'   metric_pattern = "^shdi"
#' )
#'
#' # aggregation index with custom raster resolution
#' ai_analysis <- summarize_within_buffer(
#'   origin = sf_points,
#'   features = sf_features,
#'   buffer_dist = 2000,
#'   type_col = "fclass",
#'   summary_metric = aggregation_index,
#'   raster_res = 5 # passed to aggregation_index()
#' )
#' }
#'
#' @export
#'
#' @family buffer summaries
summarize_within_buffer <- function(origin,
                                    features,
                                    buffer_dist,
                                    type_col = NULL,
                                    summary_metric = area_shares,
                                    summary = FALSE,
                                    metric_pattern = "^(share_|shdi|ai|density_)", # nolint
                                    ...) {
  res_list <- compute_summary_for_buffers(
    origin, features, buffer_dist, summary_metric, type_col, ...
  )
  res <- res_list$result

  # clean up duplicate geometry columns
  geom_cols <- names(res)[sapply(res, function(x) inherits(x, "sfc"))]
  if (length(geom_cols) > 1) {
    # remove all but the first (active) geometry
    cols_to_remove <- geom_cols[-1]
    res <- res |> dplyr::select(-dplyr::all_of(cols_to_remove))
  }

  # ensure buffer_id is present
  if (!"buffer_id" %in% names(res)) {
    res <- res |>
      dplyr::select(
        buffer_id = dplyr::starts_with("buffer"), dplyr::everything()
      )
  }

  # rename any remaining duplicate columns
  names(res) <- make.names(names(res), unique = TRUE)

  if (summary) {
    summary_df <- summarize_overall(res, metric_pattern = metric_pattern)

    if (any(grepl("shdi", names(res)))) {
      summary_df <- summary_df[, !(names(summary_df) %in% c("n_nonzero", "prop_nonzero"))] # nolint
    }

    return(summary_df)
  }

  res
}


# ------------------------------------------------------------------------------
#' Calculate landscape-level statistical summaries for spatial metrics
#'
#' Aggregates metric values across all buffers to produce landscape-level
#' statistics. This function computes descriptive statistics for all metric
#' columns identified by a regex pattern, providing an overview of metric
#' distributions and spatial prevalence across the study area.
#'
#' @param summarized_sf An `sf` object (or data.frame/tibble) returned by buffer
#' summary functions such as `summarize_within_buffer()` with `summary = FALSE`.
#' Must contain numeric metric columns to summarize.
#' @param metric_pattern Character string containing a regular expression for
#' identifying metric columns. Only columns matching this pattern are included
#' in the summary. Defaults to common metric prefixes from the buffer pipeline:
#' `share_`, `shdi`, `density`, `pland_`, `ai_`, `density_km2_`.
#' Customize to match custom metric names, e.g., `"^my_custom_metric"`.
#'
#' @return A data frame with one row per identified metric column, containing:
#' \itemize{
#'   \item `variable`: Name of the metric column
#'   \item `max`: Maximum value across all buffers (3 decimal places)
#'   \item `min`: Minimum value across all buffers (3 decimal places)
#'   \item `median`: Median value (3 decimal places)
#'   \item `mean`: Mean value (3 decimal places)
#'   \item `sd`: Standard deviation (3 decimal places); NA if n < 2
#'   \item `n`: Total non-NA observations
#'   \item `n_nonzero`: Count of buffers where metric > 0
#'   \item `prop_nonzero`: Proportion of buffers with metric > 0 (0–1 scale)
#' }
#' Rows are sorted by `prop_nonzero` (descending) then `mean` (descending),
#' so metrics present in more buffers and with higher values appear first.
#'
#' @details
#' This function is useful for understanding landscape-level patterns:
#'
#' **Interpreting output:**
#' - `prop_nonzero = 1.0` indicates metric present in all buffers
#' - `prop_nonzero = 0.5` indicates metric present in 50% of buffers
#' - `prop_nonzero = 0.0` indicates metric is zero everywhere
#' - `sd = NA` occurs when fewer than 2 non-NA values exist
#' - Rows with high `mean` and low `sd` indicate consistent, prevalent features
#' - Rows with low `prop_nonzero` indicate spatially sparse features
#'
#' **Metric pattern matching:**
#' The default pattern is permissive and captures most common metrics. For
#' precise control, specify patterns such as:
#' - `"^share_"` for area share metrics only
#' - `"^ai_"` for aggregation index metrics
#' - `"density"` for any density-type metric
#' - `"^(?!buffer_id)"` to exclude specific columns
#'
#' All numeric values are automatically rounded to 3 decimal places for
#' readability.
#'
#' @seealso
#' \code{\link{summarize_within_buffer}} for per-origin and landscape summaries
#' \code{\link{area_shares}} and other metric functions
#'
#' @examples
#' \dontrun{
#' set.seed(123456)
#' sf_points <- dplyr::sample_n(sf_metro, 5)
#' sf_features <- subset(sf_green, fclass %in% c("forest", "grass"))
#'
#' # compute per-origin metrics
#' metrics_sf <- summarize_within_buffer(
#'   origin = sf_points,
#'   features = sf_features,
#'   buffer_dist = 500,
#'   type_col = "fclass"
#' )
#'
#' # get landscape-level summary
#' summarize_overall(metrics_sf)
#'
#' # custom pattern for specific metrics
#' summarize_overall(
#'   metrics_sf,
#'   metric_pattern = "_forest$"
#' )
#' }
#'
#' @export
#' @importFrom stats median
#'
#' @family buffer summaries
summarize_overall <- function(summarized_sf,
                              metric_pattern = "^(share_|shdi|density|pland_|ai_|density_km2_)") { # nolint
  # pre-declaration of NSE columns
  variable <- prop_nonzero <- NULL

  obj <- summarized_sf

  candidate_cols <- names(obj)[grepl(metric_pattern, names(obj), perl = TRUE)]
  numeric_cols <- candidate_cols[sapply(obj[candidate_cols], is.numeric)]

  if (length(numeric_cols) == 0L) {
    stop("No metric columns found matching pattern: ", metric_pattern)
  }

  summary_list <- lapply(numeric_cols, function(col) {
    vec <- obj[[col]]
    n_total <- sum(!is.na(vec))
    n_nonzero <- sum(vec > 0, na.rm = TRUE)

    data.frame(
      variable = col,
      max = if (n_total > 0L) max(vec, na.rm = TRUE) else NA_real_,
      min = if (n_total > 0L) min(vec, na.rm = TRUE) else NA_real_,
      median = if (n_total > 0L) median(vec, na.rm = TRUE) else NA_real_,
      mean = if (n_total > 0L) mean(vec, na.rm = TRUE) else NA_real_,
      sd = if (n_total > 1L) stats::sd(vec, na.rm = TRUE) else NA_real_,
      n = n_total,
      n_nonzero = n_nonzero,
      prop_nonzero = if (n_total > 0L) n_nonzero / n_total else NA_real_,
      stringsAsFactors = FALSE
    )
  })

  summary_df <- dplyr::bind_rows(summary_list) |>
    dplyr::mutate(dplyr::across(-variable, ~ round(.x, 3))) |>
    dplyr::arrange(dplyr::desc(prop_nonzero), dplyr::desc(mean))

  summary_df
}


# ------------------------------------------------------------------------------
#' Create buffer polygons around geometries
#'
#' Generates circular buffer zones around origin locations. Useful for defining
#' analysis areas, visualizing buffer extents, or preparing geometries for
#' spatial intersection operations. Automatically handles CRS conversion for
#' geographic (lon/lat) data.
#'
#' @param origin An `sf` object with geometries representing the starting
#' locations for the buffers. Can be points, polygons, or linestrings.
#' CRS can be either projected (meters) or geographic (degrees); both are
#' handled transparently.
#' @param buffer_dist Buffer distance in map units. Interpreted as meters for
#' projected CRS or degrees for geographic CRS. The function automatically
#' converts geographic data to Web Mercator (EPSG:3857) for accurate distance
#' calculations and transforms results back to the original CRS.
#'
#' @return An `sf` object with:
#' \itemize{
#'   \item Circular polygon geometries (buffer zones around origin geometries)
#'   \item All original columns from `origin`
#'   \item New `buffer_id` column with unique integer identifiers (row numbers)
#'   \item Same CRS as input `origin`
#' }
#' If input already contains a `buffer_id` column, it is regenerated.
#'
#' @details
#' This function is a convenience wrapper around `st_buffer()` that handles
#' CRS-aware buffering:
#'
#' **For projected data (e.g., UTM, Web Mercator):**
#' Buffers are created directly in the original CRS at the specified distance.
#'
#' **For geographic data (lon/lat, EPSG:4326):**
#' Data is temporarily converted to Web Mercator (EPSG:3857), buffered with
#' the distance in meters, then converted back to the original CRS.
#'
#' The `buffer_id` column provides unique identifiers that remain stable across
#' row ordering and can be used to track buffers through subsequent operations.
#'
#' @seealso
#' \code{\link[sf]{st_buffer}} for underlying buffering operation
#' \code{\link{compute_buffer_intersections}} for integration with spatial
#' summaries
#' \code{\link{summarize_within_buffer}} for complete buffer-based analysis
#' workflow
#'
#' @examples
#' \dontrun{
#' set.seed(123456)
#' sf_points <- dplyr::sample_n(sf_metro, 5)
#'
#' # create 500-meter buffers around study points
#' buffers <- create_buffers(sf_points, buffer_dist = 500)
#'
#' # visualize buffer extent
#' plot(buffers["buffer_id"])
#' }
#'
#' @export
#'
#' @family buffer summaries
create_buffers <- function(origin,
                           buffer_dist) {
  # pre-declaration of NSE columns
  geometry <- NULL

  # check CRS and transform if lon/lat
  if (sf::st_is_longlat(origin)) {
    origin_proj <- sf::st_transform(origin, 3857)
  } else {
    origin_proj <- origin
  }

  # remove existing buffer_id if present
  if ("buffer_id" %in% names(origin_proj)) origin_proj$buffer_id <- NULL
  origin_proj <- dplyr::mutate(origin_proj, buffer_id = dplyr::row_number())

  # generate buffers
  buffers_sf <- dplyr::mutate(
    origin_proj,
    geometry = sf::st_buffer(geometry, dist = buffer_dist)
  )

  buffers_sf
}

# ------------------------------------------------------------------------------
#' Visualize buffers and spatial features
#'
#' Creates a publication-quality map showing origin locations, buffers, and
#' overlaid feature geometries. Useful for visually inspecting buffer extents,
#' feature coverage, and spatial relationships before conducting quantitative
#' analysis. Automatically handles CRS conversion and supports categorical
#' coloring by feature type.
#'
#' @param origin An `sf` object with geometries representing the starting
#' locations for the buffers. Can be points, polygons, or linestrings.
#' CRS can be either projected (meters) or geographic (degrees).
#' @param features Optional `sf` object with polygon or linestring geometries to
#' overlay. If NULL, only origin geometries and buffers are plotted. Features
#' are automatically transformed to match the origin geometry CRS if needed.
#' @param buffer_dist Buffer distance in map units (meters for projected CRS,
#' degrees for geographic CRS). Must be a positive numeric value.
#' @param type_col Optional character string specifying a column in `features`
#' for categorical coloring. If provided:
#' - Polygons are colored by fill according to type
#' - Lines are colored by stroke according to type
#' - A legend is displayed showing the mapping
#' If NULL, features are shown in uniform gray.
#' @param origin_size Numeric value representing either the overall size of the
#' geometry (when `origin` are points) or the width of the line or the polygon
#' border (when `origin` are linestrings or polygons, respectively).
#' @param origin_color Character string representing a color as name or
#' hexadecimal code used for the origin geometries.
#' @param buffer_linewidth Numeric value representing the width of the
#' buffer line.
#' @param buffer_color Character string representing a color as name or
#' hexadecimal code used for the buffer geometries.
#' @param id Optional character string specifying a column in `origin` to use
#' as buffer identifiers (labels). If provided, these values are plotted
#' above each buffer. Defaults to using the sequential `buffer_id` from
#' `create_buffers()`. Useful when origin geometries have meaningful identifiers
#' (e.g., site names, OSM IDs).
#' @param plot_ids Logical indicating whether to display buffer identifiers
#' as text labels. Defaults to TRUE if `id` is provided, FALSE otherwise.
#' Set explicitly to override default behavior.
#' @param use_label Logical indicating if buffer identifiers should be shown
#' as plain text without a background (`FALSE`) or as text labels with a
#' surrounding box (`TRUE`). Defaults to `FALSE`, displaying identifiers as
#' plain text.
#' @param id_fontsize Numerical value specifying the font size of the buffer
#' identifiers. Defaults to 2.5.
#' @param id_fontfamily Character string specifying the typeface for the buffer
#' identifiers. Uses the system default for sans serif text.
#' @param id_xpos Numerical value specifying the horizontal position of the
#' buffer identifiers. Use positive numbers to push ID labels to the top or
#' negative values to move them down. Defaults to 0, placing labels in the
#' center of the origin geometries.
#' @param id_ypos Numerical value specifying the vertical position of the
#' buffer identifiers. Use positive numbers to push ID labels to the top or
#' negative values to move them down. Defaults to 1200, placing labels slightly
#' above the origin geometries.
#'
#' @return A `ggplot` object that can be further customized with ggplot2
#' functions (e.g., `+ ggplot2::theme_dark()`). The plot includes:
#' \itemize{
#'   \item Background map (Berlin boundary if available)
#'   \item Buffer polygons (red dashed circles)
#'   \item Feature geometries (gray or colored by type)
#'   \item Origin locations (black dots)
#'   \item Optional buffer ID labels
#'   \item Legend for feature types (if `type_col` specified)
#' }
#'
#' @details
#' **Visual design:**
#' - Buffers: semi-transparent red dashed outlines for easy distinction
#' - Features: semi-transparent fills/strokes (alpha = 0.4)
#' - Origin Geometries: small black dots at buffer centers
#' - Categorical colors: uses a 9-color palette optimized for colorblind vision
#'
#' **CRS handling:**
#' If `features` and `origin` are in different CRS, features are
#' automatically transformed to match origin geometries. Geographic (lon/lat)
#' data is handled transparently by `create_buffers()`.
#'
#' **Geometry type handling:**
#' - Polygons: rendered with fill color (type_col controls fill)
#' - Lines: rendered with stroke color (type_col controls color)
#' - Mixed geometries: automatically detected and rendered appropriately
#' - Note: If features contain both lines and polygons, only one type
#' is rendered (lines take precedence)
#'
#' **Feature type coloring:**
#' `type_col` should not contain more than 9 unique values.
#' The 9-color palette is accessible to colorblind viewers:
#' Orange, Blue, Teal, Green, Dark Teal, Yellow, Light Blue, Purple, Gray.
#'
#' **Coordinate display:**
#' X and Y axis labels are suppressed for cleaner visualization. Use
#' `+ ggplot2::labs(x = "Longitude", y = "Latitude")` to add them back.
#'
#' @seealso
#' \code{\link{create_buffers}} for buffer creation details
#' \code{\link{summarize_within_buffer}} for analysis workflow
#' \code{\link[ggplot2]{ggplot}} for customizing the plot
#'
#' @examples
#' \dontrun{
#' set.seed(123456)
#' sf_points <- dplyr::sample_n(sf_metro, 5)
#' sf_features <- subset(sf_green, fclass %in% c("forest", "grass"))
#' sf_lines <- subset(sf_railways, fclass %in% c("subway", "rail"))
#'
#' # 1. Basic plot: buffers and points only
#' plot_buffers(sf_points, buffer_dist = 500)
#' plot_buffers(sf_points, buffer_dist = 2000)
#'
#' # 2. Add origin identifiers (buffer ID by default)
#' plot_buffers(
#'   origin = sf_points,
#'   buffer_dist = 500,
#'   plot_ids = TRUE
#' )
#'
#' # 3. Use origin identifiers from data (`id`) and control position (`id_ypos`)
#' plot_buffers(
#'   origin = sf_points,
#'   buffer_dist = 2000,
#'   id = "name", # column in sf_points
#'   id_ypos = 2 # use negative values to keep above points
#' )
#'
#' # 4. Plot with feature overlay, colored by habitat type
#' # 4a. POLYGONS / MULTIPOLYGONS
#' plot_buffers(
#'   origin = sf_points,
#'   features = sf_features,
#'   buffer_dist = 2000,
#'   type_col = "fclass"
#' )
#' # 4b. LINESTRINGS / MULTILINESTRINGS
#' plot_buffers(
#'   origin = sf_points,
#'   features = sf_lines,
#'   buffer_dist = 2000,
#'   type_col = "fclass"
#' )
#'
#' # 5. Control buffer and origin colors plus point size
#' plot_buffers(
#'   origin = sf_points,
#'   features = sf_lines,
#'   buffer_dist = 1000,
#'   type_col = "fclass",
#'   plot_ids = TRUE,
#'   buffer_color = "black",
#'   origin_color = "transparent" # set to NA or "transparent" to remove geometry
#' )
#'
#' # 6. Customize the plot further with ggplot2
#' #    (message about "Adding another scale" can be ignored safely)
#' plot_buffers(sf_points, sf_features, 2000, type_col = "fclass") +
#'   ggplot2::scale_fill_manual(
#'     values = c("#003314", "#868B06"),
#'     name = "Natural area:"
#'   ) +
#'   ggplot2::theme_bw() +
#'   ggplot2::theme(
#'     legend.position = "inside",
#'     legend.position.inside = c(.9, .9)
#'   ) +
#'   ggplot2::labs(title = "My Study Area", subtitle = "Buffer analysis")
#' }
#'
#' @export
#' @importFrom rlang sym
#'
#' @family buffer summaries
plot_buffers <- function(origin,
                         features = NULL,
                         buffer_dist,
                         type_col = NULL,
                         origin_size = .5,
                         origin_color = "black",
                         buffer_linewidth = 0.4,
                         buffer_color = "red",
                         id = NULL,
                         plot_ids = NULL,
                         use_label = FALSE,
                         id_fontfamily = "",
                         id_fontsize = 2.5,
                         id_xpos = 0,
                         id_ypos = 1200) {
  # pre-declaration of NSE columns
  buffer_id <- NULL

  # determine whether to plot IDs
  if (!is.null(id) && is.null(plot_ids)) plot_ids <- TRUE
  if (is.null(plot_ids)) plot_ids <- FALSE

  # generate buffers
  buffers_sf <- create_buffers(origin, buffer_dist)

  # overwrite default buffer_id if custom ID is provided
  if (!is.null(id)) {
    if (!id %in% names(origin)) {
      stop(paste0("Column '", id, "' not found in origin object."))
    }
    buffers_sf$buffer_id <- origin[[id]]
  }

  pal <- c(
    "#E58606", "#5D69B1", "#52BCA3", "#99C945", "#24796C",
    "#DAA51B", "#2F8AC4", "#764E9F", "#A5AA99"
  )

  # base plot with background map and titles
  p <- ggplot2::ggplot() +
    suppressWarnings(
      ggplot2::geom_sf(
        data = sf::st_transform(d6berlin::sf_berlin, 3857),
        fill = NA,
        linewidth = 0.5
      )
    ) +
    ggplot2::labs(
      title = paste0("Buffer distance: ", buffer_dist, " m"),
      x = NULL, y = NULL
    ) +
    ggplot2::theme_minimal()

  # add feature layer if provided
  if (!is.null(features)) {
    # transform features to buffer CRS
    if (!sf::st_crs(buffers_sf) == sf::st_crs(features)) {
      features <- sf::st_transform(features, sf::st_crs(buffers_sf))
    }

    geom_type <- unique(sf::st_geometry_type(features))
    if (any(geom_type %in% c("LINESTRING", "MULTILINESTRING"))) {
      # use color for linestrings
      feature_layer <- if (!is.null(type_col)) {
        ggplot2::geom_sf(
          data = features,
          mapping = ggplot2::aes(color = !!rlang::sym(type_col)),
          linewidth = 0.4,
          alpha = 0.8,
          show.legend = TRUE
        )
      } else {
        ggplot2::geom_sf(
          data = features,
          color = "grey50",
          linewidth = 0.4,
          alpha = 0.8,
          show.legend = FALSE
        )
      }

      p <- p + feature_layer + ggplot2::scale_color_manual(values = pal)
    } else {
      # polygons: use fill, optional border
      feature_layer <- if (!is.null(type_col)) {
        ggplot2::geom_sf(
          data = features,
          mapping = ggplot2::aes(fill = !!rlang::sym(type_col)),
          color = NA,
          alpha = 0.75,
          show.legend = TRUE
        )
      } else {
        ggplot2::geom_sf(
          data = features,
          fill = "grey50",
          color = NA,
          alpha = 0.75,
          show.legend = FALSE
        )
      }

      p <- p + feature_layer + ggplot2::scale_fill_manual(values = pal)
    }
  }

  # add origin geometries + buffer areas
  p <- p +
    ggplot2::geom_sf(
      data = buffers_sf,
      color = buffer_color,
      fill = "transparent",
      linetype = "41",
      linewidth = buffer_linewidth
    ) +
    ggplot2::geom_sf(
      data = origin,
      color = origin_color,
      fill = origin_color,
      size = origin_size
    )

  # add buffer ID labels if requested
  if (plot_ids) {
    if (use_label) {
      p <- p + ggplot2::geom_sf_label(
        data = buffers_sf,
        mapping = ggplot2::aes(label = buffer_id),
        family = id_fontfamily,
        size = id_fontsize,
        nudge_x = id_xpos,
        nudge_y = id_ypos,
        fontface = "bold"
      )
    } else {
      p <- p + ggplot2::geom_sf_text(
        data = buffers_sf,
        mapping = ggplot2::aes(label = buffer_id),
        family = id_fontfamily,
        size = id_fontsize,
        nudge_x = id_xpos,
        nudge_y = id_ypos,
        fontface = "bold"
      )
    }
  }

  p
}
