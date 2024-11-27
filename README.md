## Build

### Requirements
- Python 3.12-dev
- ninja, meson, and ?python3.12-distutils PPA packages (sudo apt install meson ninja)
- PyPi packages from requirements.txt (pip install -r requirements.txt)


This README assumes you also have the [*optimization*](https://github.com/vadym1982/optimization) repository cloned,
and you've performed that repository's README steps successfully.

```bash
mkdir build && cd build
gfortran -c ../fortrancv/env.f90 ../fortrancv/fortrancv.f90
```

Set **your path** to *optimization* build directory without trailing slash as in the example below
```bash
export OPTIMIZATION_BUILD_FILES_FULL_PATH=/home/vadym/projects/optimization/build
```

The next couple of f2py commands will build .so files for us

```bash
f2py -c ../fortrancv/fortrancv.pyf ../fortrancv/env.f90 ../fortrancv/fortrancv.f90

f2py -c --f90flags="-fopenmp -O3 -ffast-math -I$OPTIMIZATION_BUILD_FILES_FULL_PATH" ../fortrancv/calibration.pyf \
../fortrancv/calibration.f90 $OPTIMIZATION_BUILD_FILES_FULL_PATH/optimization.a
```

Place your dlls to the right place and tide everything up
```bash
mv *.so ../fortrancv

cd ../ && rm -rf build
```


## Test
In the examples directory you'll find the test script, which requires data for evaluation.
Data is not the part of this repository. Contact contributors to get it.