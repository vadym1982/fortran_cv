import os
import subprocess
from setuptools import setup, find_packages, Command

OPTIMIZATION_REPO = "https://github.com/vadym1982/optimization.git"
OPTIMIZATION_PATH = os.path.join("build", "optimization")
OUTPUT_DIR = os.path.abspath("build")


class BuildFortranExtensions(Command):
    description = "Build Fortran extensions with f2py"
    user_options = []  # No custom options needed for now

    def initialize_options(self):
        pass

    def finalize_options(self):
        pass

    def run(self):
        # Clone and build the optimization library
        if not os.path.exists(OPTIMIZATION_PATH):
            print(f"Cloning optimization repository into {OPTIMIZATION_PATH}...")
            subprocess.check_call(["git", "clone", OPTIMIZATION_REPO, OPTIMIZATION_PATH])

        optimization_build_dir = os.path.join(OPTIMIZATION_PATH, "build")
        os.makedirs(optimization_build_dir, exist_ok=True)

        # Compile Fortran source files in the optimization repository
        print(f"Compiling Fortran optimization source files from {os.getcwd()}...")
        subprocess.check_call(
            [
                "gfortran",
                "-c",
                f"{os.getcwd()}/build/optimization/src/env.f90",
                f"{os.getcwd()}/build/optimization/src/interfaces.f90",
                f"{os.getcwd()}/build/optimization/src/utils.f90",
                f"{os.getcwd()}/build/optimization/src/conjugate_gradient.f90",
                f"{os.getcwd()}/build/optimization/src/differential_evolution.f90",
                f"{os.getcwd()}/build/optimization/src/particle_swarm.f90",
                f"{os.getcwd()}/build/optimization/src/robust_regression.f90",
            ],
            cwd=optimization_build_dir,
        )
        # Archive object files into `optimization.a`
        print("Archiving object files into optimization.a...")
        object_files = [f for f in os.listdir(optimization_build_dir) if f.endswith(".o")]
        if not object_files:
            raise RuntimeError("No object files found to archive.")
        subprocess.check_call(
            ["ar", "-r", "optimization.a"] + object_files,
            cwd=optimization_build_dir,
        )

        # Compile fortran_cv module using f2py
        print("Building Fortran extensions with f2py...")
        os.makedirs(OUTPUT_DIR, exist_ok=True)

        subprocess.check_call(
            [
                "gfortran",
                "-c",
                f"{os.getcwd()}/src/fortran_cv/env.f90",
                f"{os.getcwd()}/src/fortran_cv/fortran_cv.f90"
            ],
            cwd=OUTPUT_DIR,
        )
        subprocess.check_call(
            [
                "f2py",
                "-c",
                f"{os.getcwd()}/src/fortran_cv/fortran_cv.pyf",
                f"{os.getcwd()}/src/fortran_cv/env.f90",
                f"{os.getcwd()}/src/fortran_cv/fortran_cv.f90"
            ],
            cwd=OUTPUT_DIR,
        )
        print(f"OPTIMIZATION BUILD FILES FULL PATH: {os.getcwd()}/build/optimization/build")
        subprocess.check_call(
            [
                "f2py",
                "-c",
                f"--f90flags=-fopenmp -O3 -ffast-math -I{os.getcwd()}/build/optimization/build",
                f"{os.getcwd()}/src/fortran_cv/calibration.pyf",
                f"{os.getcwd()}/src/fortran_cv/calibration.f90",
                f"{os.getcwd()}/build/optimization/build/optimization.a",
            ],
            cwd=OUTPUT_DIR,
        )

        # Check if .so file was created
        # expected_so_file = os.path.join(OUTPUT_DIR, "calibration.cpython-*.so")
        if not any(f.endswith(".so") for f in os.listdir(OUTPUT_DIR)):
            raise RuntimeError(f".so file not found in {OUTPUT_DIR}.")


setup(
    name="fortran_cv",
    version="0.1.0",
    description="Fortran-based calibration tools.",
    long_description=open("README.md").read(),
    long_description_content_type="text/markdown",
    author="Vadym Stavychenko",
    author_email="vadym.stavychenko@gmail.com",
    url="https://github.com/vadym1982/fortran_cv",
    license="MIT",
    packages=find_packages(where="src"),
    package_dir={"": "src"},
    cmdclass={"build": BuildFortranExtensions},
    python_requires=">=3.6",
    install_requires=["numpy"],
    classifiers=[
        "Programming Language :: Python :: 3",
        "Programming Language :: Fortran",
        "License :: OSI Approved :: MIT License",
        "Operating System :: OS Independent",
    ],
)
