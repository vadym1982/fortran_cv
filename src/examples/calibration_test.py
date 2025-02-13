import os
from glob import glob
from time import time

import numpy as np
from calibration import calibration
from fortran_cv import fortran_cv
import cv2

deg = np.pi / 180
images = glob(f'{os.path.dirname(os.path.abspath(__file__))}/test_data/*.png')
court_points = np.loadtxt(f'{os.path.dirname(os.path.abspath(__file__))}/test_data/court_points.txt')
lower = np.array([15 * deg, -100.0, -100.0, -50.0, -5 * deg, 150 * deg, 0 * deg, 0])
upper = np.array([120 * deg, 100.0, 100.0, 50, np.pi / 2, 220 * deg, 360 * deg, 0])

for img_path in images:
    img = cv2.imread(img_path)
    file_name = os.path.splitext(img_path)[0]
    frame_points = np.loadtxt(f"{file_name}.txt")
    height, width = img.shape[:2]

    t = time()
    mask = np.isfinite(frame_points[:, 0])

    fov, position, angles, k1, res = calibration.calibrate_camera(
        court_points[mask],
        frame_points[mask],
        np.ones_like(frame_points)[mask],
        width,
        height,
        lower,
        upper,
        2
    )

    print(f"FOV: {fov}")
    print(f"Position: {position}")
    print(f"Angles: {angles}")
    print(f"k1: {k1}")
    print(f"shape: {width, height}")

    uv = fortran_cv.project_points(
        np.concatenate([court_points, np.ones([court_points.shape[0], 1])], axis=1),
        court_points.shape[0],
        fov,
        position,
        angles,
        k1,
        width,
        height
    )

    img = cv2.resize(img, (1280, 720))
    pixels = np.round(uv * np.array([[1280 / width, 720 / height]])).astype(int)

    for i, p1 in enumerate(frame_points):
        if np.isfinite(p1).any():
            u = round(p1[0] * 1280 / width)
            v = round(p1[1] * 720 / height)
            cv2.circle(img, (u, v), 5, (0, 255, 255), 3)
            cv2.putText(img, f"{i + 1}", (u, v - 10), 1, 1.5, (0, 255, 255), 2)

    for i, p1 in enumerate(pixels):
        if np.isfinite(p1).any():
            u = round(p1[0])
            v = round(p1[1])
            cv2.circle(img, (u, v), 3, (128, 0, 255), 3)

    cv2.line(img, tuple(pixels[0]), tuple(pixels[1]), (128, 0, 255), 2)
    cv2.line(img, tuple(pixels[1]), tuple(pixels[2]), (128, 0, 255), 2)

    cv2.line(img, tuple(pixels[3]), tuple(pixels[4]), (255, 255, 0), 2)
    cv2.line(img, tuple(pixels[4]), tuple(pixels[5]), (255, 255, 0), 2)

    cv2.line(img, tuple(pixels[6]), tuple(pixels[7]), (255, 255, 0), 2)
    cv2.line(img, tuple(pixels[7]), tuple(pixels[8]), (255, 255, 0), 2)

    cv2.line(img, tuple(pixels[9]), tuple(pixels[10]), (128, 0, 255), 2)
    cv2.line(img, tuple(pixels[10]), tuple(pixels[11]), (128, 0, 255), 2)

    cv2.line(img, tuple(pixels[1]), tuple(pixels[4]), (128, 255, 0), 2)
    cv2.line(img, tuple(pixels[7]), tuple(pixels[10]), (128, 255, 0), 2)

    cv2.line(img, tuple(pixels[2]), tuple(pixels[5]), (128, 0, 255), 2)
    cv2.line(img, tuple(pixels[5]), tuple(pixels[8]), (128, 0, 255), 2)
    cv2.line(img, tuple(pixels[8]), tuple(pixels[11]), (128, 0, 255), 2)

    cv2.line(img, tuple(pixels[0]), tuple(pixels[3]), (128, 0, 255), 2)
    cv2.line(img, tuple(pixels[3]), tuple(pixels[6]), (128, 0, 255), 2)
    cv2.line(img, tuple(pixels[6]), tuple(pixels[9]), (128, 0, 255), 2)

    cv2.imshow("frame", cv2.resize(img, (1280, 720)))
    cv2.waitKey(0)

