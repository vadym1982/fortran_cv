## Build

This README assumes you also have the [*optimization*](https://github.com/vadym1982/optimization) repository cloned,
and you've performed that repository's README steps successfully.

```bash
mkdir build && cd build
gfortran -c ../camcal/env.f90 ../camcal/fortran_cv.f90
```

Set **your path** to *optimization* build directory without trailing slash as in the example below
```bash
export OPTIMIZATION_BUILD_FILES_FULL_PATH=/home/vadym/projects/optimization/build
```

The next couple of f2py commands will build .so files for us

```bash
f2py -c ../camcal/fortran_cv.pyf ../camcal/env.f90 ../camcal/fortran_cv.f90

f2py -c --f90flags="-fopenmp -O3 -ffast-math -I$OPTIMIZATION_BUILD_FILES_FULL_PATH" ../camcal/calibration.pyf \
../camcal/calibration.f90 $OPTIMIZATION_BUILD_FILES_FULL_PATH/optimization.a
```

Place your dlls to the right place and tide everything up
```bash
mv *.so ../camcal/*.so

cd ../ && rm -rf build
```


## Test
In the examples directory you'll find the test script, which requires data for evaluation.
Data is not the part of this repository. Contact contributors to get it.