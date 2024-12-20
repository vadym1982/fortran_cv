"""
f2py -c --f90flags='-fopenmp -O3 -ffast-math -I//home/vadym/projects/optimization/fortrancv' calibration.pyf calibration.f90  env.f90 fortrancv.f90 /home/vadym/projects/optimization/fortrancv/optimization.a
"""
import os
import pickle
from glob import glob
from time import time

import numpy as np
from fortrancv.calibration import calibration
from fortrancv.fortran_cv import fortran_cv
import cv2

PM_HEIGHT = 0.0
PITCH_DISTANCE = 30
BASE_DISTANCE  = 60


def get_field_points(pith_distance, base_distance, pitch_mound_height=0.0):
    """
    :param pith_distance: Distance from home plate to pitching circle center
    :param base_distance: Base distance in feet
    :param pitch_mound_height: Pitch mound height in feet
    :return: [[x, y, z], ...]
    """
    c = np.sqrt(2.0) / 2.0
    points = np.array([
        [0.0, 0.0, 0.0],
        [base_distance * c, base_distance * c, 0.0],
        [2 * base_distance * c, 0.0, 0.0],
        [base_distance * c, -base_distance * c, 0.0],
        [pith_distance, 0.0, pitch_mound_height]
    ])

    return points


def get_masked_points(points: dict):
    image_points = np.array([
        points['home_plate'],
        points['1B'],
        points['2B'],
        points['3B'],
        points['pitch_mount']
    ], dtype=np.float32)

    return image_points


deg = np.pi / 180
images = glob(f"/home/vadym/Downloads/dump_baseball/*.png")
court_points = get_field_points(PITCH_DISTANCE, BASE_DISTANCE)[:4]
lower = np.array([15 * deg, -100.0, -100.0, -50.0, 0, -np.pi, 0])
upper = np.array([120 * deg, 100.0, 100.0, 50.0, np.pi / 2, np.pi, 360 * deg])

for img_path in images:
    img = cv2.imread(img_path)
    file_name = os.path.splitext(img_path)[0]
    with open(f"{file_name}.pkl", "rb") as f:
        data = pickle.load(f)
    frame_points = get_masked_points(data["points"])[:4]
    height, width = img.shape[:2]

    t = time()
    mask = np.isfinite(frame_points[:, 0])

    fov, position, angles, res = calibration.calibrate_camera(
        court_points[mask],
        frame_points[mask],
        width,
        height,
        lower,
        upper
    )
    print(time() - t)
    print(res)
    print(fov, position, angles)

    uv = fortran_cv.project_points(
        np.concatenate([court_points, np.ones([court_points.shape[0], 1])], axis=1),
        court_points.shape[0],
        fov,
        position,
        angles,
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

    for i, p in enumerate(pixels):
        cv2.circle(img, tuple(pixels[i]), 7, (255, 0, 0), 2)
        cv2.putText(img, f"{i + 1}", (pixels[i, 0], pixels[i, 1] - 10), 1, 1.5, (255, 0, 0), 2)

    cv2.line(img, tuple(pixels[0]), tuple(pixels[1]), (255, 0, 0), 3)
    cv2.line(img, tuple(pixels[1]), tuple(pixels[2]), (255, 0, 0), 3)
    cv2.line(img, tuple(pixels[2]), tuple(pixels[3]), (255, 0, 0), 3)
    cv2.line(img, tuple(pixels[3]), tuple(pixels[0]), (255, 0, 0), 3)
    # cv2.line(img, tuple(pixels[3]), tuple(pixels[5]), (255, 255, 0), 3)
    # cv2.line(img, tuple(pixels[6]), tuple(pixels[8]), (255, 255, 0), 3)
    # cv2.line(img, tuple(pixels[1]), tuple(pixels[4]), (255, 255, 0), 3)
    # cv2.line(img, tuple(pixels[7]), tuple(pixels[10]), (255, 255, 0), 3)

    cv2.imshow("frame", cv2.resize(img, (1280, 720)))
    cv2.waitKey(0)

