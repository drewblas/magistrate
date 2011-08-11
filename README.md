# Magistrate

## Installation

    gem install magistrate

## Description

Magistrate is a manager for workers that is cluster and network aware.  
It interacts with a centralized server to get its management and marching orders.

## Manual

The magistrate command line tool utilizes the following from the filesystem:

* config/magistrate.yml - The configuration file (override the path with the --config option)
* tmp/pids - stores the pids of itself and all managed workers


## License

Copyright (C) 2011 by Drew Blas <drew.blas@gmail.com>
  
Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN

## Attribution

Inspiration and thanks to:

* foreman
* resque
* god