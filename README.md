# Magistrate

## Installation

    gem install magistrate

## Description

Magistrate is a manager for workers that is cluster and network aware.  
It interacts with a centralized server to get its management and marching orders.

It's intended to be run as a cron job periodically.  Each time it's run it'll:

* Download the target state for each worker from the server
* Check each worker
* Try to get it to its target state
* POST back to the server its state

## Manual

The magistrate command line tool utilizes the following from the filesystem:

* config/magistrate.yml - The configuration file (override the path with the --config option)
* tmp/pids - stores the pids of itself and all managed workers

These are meant to coincide with easy running from a Rails app root (so that the worker config can be kept together with the app)
If you're using capistrano, then the tmp/pids directory is persisted across deploys, so Magistrate will continue to run
(with an updated config) even after a deploy.

Your user-space cron job should look like this:

*/5 0 0 0 0 magistrate run --config ~/my_app/current/config/magistrate.yml

### What if the server is down?

The magistrate request will time out after 30 seconds and then use its previously stored target_states.json file

## Command line options

See `magistrate`

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