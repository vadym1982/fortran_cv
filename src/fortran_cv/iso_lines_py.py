import numpy as np
from fortrancv.iso_lines import iso_lines


def get_iso_line(heatmap, value):
    max_cnt = np.ceil(heatmap.shape[0] / 2) * np.ceil(heatmap.shape[1] / 2) * 4
    n, ends, lines, h_max, h_mean = iso_lines.get_iso_lines(heatmap, value, max_cnt)
    contours = []
    s = 0

    for i in range(n):
        contours.append(
            {"points": lines[s: ends[i]], "max": h_max[i], "mean": h_mean[i]}
        )
        s = ends[i]

    return contours


def contour_properties(points):
    perimeter, area, x0, y0, ix0, iy0, ixy0, phi, i_max, i_min = iso_lines.contour_prop(points)

    return {
        "perimeter": perimeter,
        "area": area,
        "x0": x0,
        "y0": y0,
        "Ix0": ix0,
        "Iy0": iy0,
        "Ixy0": ixy0,
        "phi": phi,
        "Imax": i_max,
        "Imin": i_min
    }
