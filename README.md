# Matran
A collection of functions and classes for:
- importing and visualising Nastran bulk data entries and results.
- writing bdf files 

**This repository is currently under development and is not ready for general use. Any feedback is much appreciated!**

## Getting Started
- Either clone or download the repository
- add the folder tbx to the path or instal with the Matlab Pacakge Manager (mpm)
    - mpm install ads -u <INSTALL_DIR> --local -e --force
- have a look at the examples in the 'Examples' folder to get a flavour of what you can currently do.

### Prerequisites

This product was developed in MATLAB 9.12 (2022a)

## Running the tests
Make sure you have run `add_sandbox` before attempting to run any of the tests.

- To run the core set of tests type `run_micro_tests` in the MATLAB command window.
- To run all short tests type `run_short_tests` in the MATLAB command window.
- To run all tests in the test framework type `run('TestMatran')` in the MATLAB command window. **Not reccommended** 

### Major tests

Explain what these tests test and why (TODO)

## Contributing

Please read [CONTRIBUTING.md](https://github.com/farg-bristol/Matran/blob/master/CONTRIBUTING) for details on our code of conduct, and the process for submitting pull requests to us.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/farg-bristol/Matran/tags). 

## Authors
* **fh9g12**
* **Christopher Szczyglowski** 

See also the list of [contributors](https://github.com/farg-bristol/Matran/contributors) who participated in this project.

## License

This project is licensed under the Apache License - see the [LICENSE.md](https://github.com/farg-bristol/Matran/blob/master/LICENSE) file for details

## Acknowledgments

* Inspired by the [pyNastran](https://github.com/SteveDoyle2/pyNastran) package by Steve Doyle.
