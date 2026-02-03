import osmnx as ox
import rasterio
from rasterio.mask import mask
import numpy as np
import geopandas as gpd
import pandas as pd

def get_street_network(lat, lon, dist=2000):
    """
    Fetches the driving network from OSMnx.
    """
    print(f"Fetching street network for ({lat}, {lon})...")
    graph = ox.graph_from_point((lat, lon), dist=dist, network_type='drive')
    nodes, streets = ox.graph_to_gdfs(graph)
    return streets

def calculate_terrain_features(streets_gdf, dem_path):
    """
    Calculates elevation and slope for each street segment using a DEM file.
    """
    # Ensure CRS matches for metric calculations (Palestinian Grid or UTM)
    # streets_gdf = streets_gdf.to_crs(epsg=28192) 
    
    with rasterio.open(dem_path) as src:
        avg_elevations = []
        slopes = []

        for geom in streets_gdf.geometry:
            try:
                # Basic sampling or masking
                out_image, _ = mask(src, [geom.buffer(0.00005)], crop=True) # Small buffer for line
                data = out_image[0]
                valid_data = data[data > -100] # Ignore NoData

                if valid_data.size > 0:
                    avg_elev = np.mean(valid_data)
                    elev_diff = np.max(valid_data) - np.min(valid_data)
                    length = geom.length * 111000 # Deg to meters approx
                    slope = (elev_diff / max(length, 1)) * 100
                else:
                    avg_elev, slope = 0, 0
            except:
                avg_elev, slope = 0, 0

            avg_elevations.append(avg_elev)
            slopes.append(slope)

    streets_gdf['avg_elevation'] = avg_elevations
    streets_gdf['slope_percent'] = slopes
    return streets_gdf

def get_schools(lat, lon, dist=2000):
    tags = {"amenity": "school"}
    try:
        schools = ox.features_from_point((lat, lon), tags=tags, dist=dist)
        if not schools.empty:
            schools = schools[schools['name'].notnull()]
            return schools
    except:
        return pd.DataFrame()
    return pd.DataFrame()
