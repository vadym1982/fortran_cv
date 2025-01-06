from pathlib import Path
from time import time
import cv2
import numpy as np

from fortrancv.iso_lines_py import get_iso_line, contour_properties

image_path = str(Path(__file__).parent) + "/media/heatmap2.png"
scale = 2

img = cv2.imread(image_path)
heatmap = (img[:, :, 0].astype(float) / 255)

t = time()
contours = get_iso_line(heatmap, 0.5)
print(f"Computation time: {time() - t}")

tmp = cv2.resize(img, (img.shape[1] * scale, img.shape[0] * scale), interpolation=cv2.INTER_NEAREST)

for k, c in enumerate(contours):
    prop = contour_properties(c["points"])
    print(f"Contour: {k}, {prop}")

    for i in range(len(c["points"])):
        j = i + 1
        if j == len(c["points"]):
            j = 0
        u1 = round(c["points"][i, 0] * scale)
        v1 = round(c["points"][i, 1] * scale)
        u2 = round(c["points"][j, 0] * scale)
        v2 = round(c["points"][j, 1] * scale)
        cv2.line(tmp, (u1, v1), (u2, v2), (127, 0, 255), 1)

    uc = round(prop["x0"] * scale)
    vc = round(prop["y0"] * scale)

    ux = round(prop["x0"] * scale + 25 * scale * np.cos(prop["phi"]))
    vx = round(prop["y0"] * scale + 25 * scale * np.sin(prop["phi"]))

    uy = round(prop["x0"] * scale + 25 * scale * np.cos(prop["phi"] + np.pi / 2))
    vy = round(prop["y0"] * scale + 25 * scale * np.sin(prop["phi"] + np.pi / 2))

    cv2.line(tmp, (uc, vc), (ux, vx), (0, 128, 255), 2)
    cv2.line(tmp, (uc, vc), (uy, vy), (0, 255, 0), 2)
    cv2.circle(tmp, (uc, vc), 3, (255, 0, 0), -1)

cv2.imshow("tmp", tmp)
cv2.waitKey(0)


