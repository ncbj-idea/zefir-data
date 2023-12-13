
import pandas as pd
from IPython.core.display_functions import display
from h3 import h3
from collections.abc import Iterable
import numpy as np
import folium
import matplotlib.pyplot as plt
import matplotlib as mpl
import matplotlib.colors as mcolors

class calculate_connectivities:
    def __init__(self, df:pd.DataFrame):
        self.df = df.copy(deep=True) #Here a copy is used to avoid modification of the input df
        self.dictOfH3aggregates = {} #a dict of different H3 sizes.
        self.debug = True

    def genH3(self, h3Size = 8):
        """
        Calculate H3 index for the dataframe delivered to the constructur.
        The function also returns the obtained DataFrame with H3 indexes. It can be used
        to speed up the process by generating H3 indexes only ones
        :return:
        """
        df = self.df
        #Get centres of houses
        map_center = [df.loc[:, "latitude_centroid"].mean(),
                      df.loc[:, "longitude_centroid"].mean()]
        # Generate H3 mask
        h3Cells = {}

        if not isinstance(h3Size, Iterable):
            h3Size = [h3Size]
        for _h3Size in h3Size:
            h3Cells[f"H3_{_h3Size}"] = (df.loc[:, ["latitude_centroid", "longitude_centroid"]]
                                       .apply(lambda x: str(h3.geo_to_h3(
                                                    x["latitude_centroid"],
                                                    x["longitude_centroid"],
                                                    _h3Size)), axis="columns"))
        df_h3 = pd.DataFrame(h3Cells)
        df = pd.concat((df, df_h3), axis=1)
        self.df = df
        return df

    def run_calculations(self, h3Size = 8, epsilon = 0.1):
        """
        Calculate the heat_connectivity first by "pow_uzytkowa_ogrzewana"/"pow_obrysu_m2" and then the obtained value
        is standarized and divided by standarized "heat_distance". Standarized is defined by column/std(column)
        At last step the heat_connectivity is log determining the log_heat_connectivity column (to reduce the influence of extreme values)
        :param epsilon: - if heat_connectivity==0 then epsilon is used instead of 0. This is to avoid log(0)
        :return:
        """
        df = self.df
        if not isinstance(h3Size, Iterable):
            h3Size = [h3Size]
        dfas = {}
        for i in h3Size:
            key = f"H3_{i}"
            dfa = df.groupby(by=key).aggregate({"pow_obrysu_m2": "sum",
                                                      "pow_uzytkowa_ogrzewana": "sum",
                                                      "heat_distance": "mean"})
            dfa.reset_index(inplace=True)
            id = dfa.loc[:, "heat_distance"] <= 0
            if self.debug:
                print(f"Number of cells with o mean distance = {id.sum()}")
            dfa.loc[id, "heat_distance"] = epsilon  # If distance is 0 then replace 0 by small const. ex. 0.01

            cellArea = dfa.loc[:,key].apply(lambda x : h3.cell_area(x,'m^2'))


            density = dfa.loc[:, f"pow_uzytkowa_ogrzewana"] / cellArea #dfa.loc[:, f"pow_obrysu_m2"]  # Do usunięcia
            dfa.loc[:, f"heat_density"] = density
            densityNorm = density / np.std(density)
            dist = dfa.loc[:, f"heat_distance"]
            distNorm = dist / np.std(dist)
            hcon = densityNorm / distNorm
            dfa.loc[:, "heat_connectivity"] = hcon
            #hcon[hcon==0] = 0.0000001
            dfa.loc[:, "log_heat_connectivity"] = np.log(hcon)
            dfas[f"H3_{i}"] = dfa
        self.dictOfH3aggregates = dfas

    def hist(self, column, bins = 40):
        """
        Show histograms of hexagones. The calues to be shown are determine by the column name
        :param column:
        :param bins:
        :return:
        """
        dfas = self.dictOfH3aggregates
        n = len(dfas)
        f, axs = plt.subplots(1, n)
        i = 0
        for k, dfa in dfas.items():
            ax = axs[i]
            col = dfa[column]
            ax.hist(col, bins=bins)
            ax.set_title(k)
            if i==0:
                ax.set_ylabel(column)
            i += 1
        plt.show()
        return f, axs


    def show_on_map(self, h3Size, column = "log_heat_connectivity"):
        """
        Display a map with the use of folium framework and displays hexagons of given resolution
        :param h3Size: Size of the H3 hexagones
        :param column:  Column shich will be used to color the hexagones. By default it is "log_heat_connectivity"
        :return:
        """
        df = self.df
        dfas = self.dictOfH3aggregates
        key = f'H3_{h3Size}'
        dfa = dfas[key]
        map_center = [df.loc[:, "latitude_centroid"].mean(),
                      df.loc[:, "longitude_centroid"].mean()]
        my_map = folium.Map(location=map_center, zoom_start=12)

        colToPlot = dfa.loc[:, column]
        norm = mcolors.Normalize(vmin=colToPlot.min(), vmax=colToPlot.max())
        colormap = mpl.colormaps['jet']# cm.get_cmap('jet')
        colors = colormap(norm(colToPlot))
        hex_colors = [mcolors.to_hex(color) for color in colors]

        for (index, row), fillColor in zip(dfa.iterrows(), hex_colors):
            # fillColor = colors[colorId]
            h3_polygon = {"type": "Polygon", "coordinates": [h3.h3_to_geo_boundary(row[key], geo_json=True)]}
            style_function = lambda x, fillColor=fillColor: {'fillColor': fillColor,  # s_map.to_rgba(color),
                                                             "color": "black",
                                                             "fillOpacity": 0.4}

            folium.GeoJson(h3_polygon, style_function=style_function).add_to(my_map)

        display(my_map)
        # m = visualize_hexagons(list(dfa.index))
        # display(m)


    def get_connectivity(self, h3Size:int=8, column:str = "log_heat_connectivity", bins:int = 4):
        """
        Generate connectivity index based on given H3 size rosolution and returns a DataFrame which was delivered to the
        constructer with additional H3 indexes and a column called heat_connectivity_index
        :param h3Size: a h3 resolution size used for generating the index. Id None raw values are used
        :param column: a column name which is used to generate the index by discretization on given number of bins
        :param bins: the number of bins used for the discretization. The bins are of fixed width
        :return: DataFrame which was delivered to the constructor extended with connectivity index
        """
        df = self.df
        key = f"H3_{h3Size}"
        dfa = self.dictOfH3aggregates[key]
        mi = dfa.loc[:,column].min()
        mx = dfa.loc[:, column].max()
        dx = (mx-mi)/bins
        th = np.arange(mi,mx+dx,dx)
        th[0] = -np.inf
        th[-1] = np.inf
        for i in range(th.shape[0]-1):
            id = (dfa.loc[:,column] > th[i]) & (dfa.loc[:,column] <= th[i+1])
            dfa.loc[id,"heat_connectivity_index"] =  bins-i
        subset = dfa.loc[:,[key,"heat_connectivity_index"]]
        df = df.merge(subset, on=key)
        return df

        # th = 0.05




