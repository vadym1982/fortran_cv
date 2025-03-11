## Build

### Requirements
- Python 3.10 !
- ninja, meson, and ?python3.12-distutils PPA packages (sudo apt install meson ninja)
- PyPi packages from requirements.txt (pip install -r requirements.txt)


This README assumes you also have the [*optimization*](https://github.com/vadym1982/optimization) repository cloned,
and you've performed that repository's README steps successfully.   

```bash
mkdir build && cd build
gfortran -c ../src/fortran_cv/env.f90 ../src/fortran_cv/fortran_cv.f90
```

Set **your path** to *optimization* build directory without trailing slash as in the example below
```bash
export OPTIMIZATION_BUILD_FILES_FULL_PATH=../optimization/build
```

The next couple of f2py commands will build .so files for us

```bash
#after running command below you'll get fortran_cv.cpython-<...>.so file
f2py -c ../src/fortran_cv/fortran_cv.pyf ../src/fortran_cv/env.f90 ../src/fortran_cv/fortran_cv.f90

f2py -c --f90flags="-I/home/vadym/projects/optimization/src" calibration.pyf calibration.f90 fortran_cv.f90 env.f90 /home/vadym/projects/optimization/src/optimization.a
#after running this command calibration.cpython-<...>.so file is created
f2py -c --f90flags="-fopenmp -O3 -ffast-math -I$OPTIMIZATION_BUILD_FILES_FULL_PATH" ../src/fortran_cv/calibration.pyf \
../src/fortran_cv/fortran_cv.f90 ../src/fortran_cv/env.f90 ../src/fortran_cv/calibration.f90 $OPTIMIZATION_BUILD_FILES_FULL_PATH/optimization.a
```

Place your dlls to the right place and tide everything up
```bash
mv *.so ../src/fortran_cv

cd ../ && rm -rf build
```


## Test
In the examples directory you'll find the test script, which requires data for evaluation.
Data is not the part of this repository. Contact contributors to get it.