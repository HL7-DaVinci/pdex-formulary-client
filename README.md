# Da Vinci Plan Coverage and Medical Formulary Client Reference Implementation

## Installation and Deployment

The client reference implementation can installed and run locally on your machine.  Install the following dependencies first:

* [Ruby 2.6+](https://www.ruby-lang.org/en/)
* [Ruby Bundler](http://bundler.io/)
* [SQLite](https://www.sqlite.org/)

And run the following commands from the terminal:

```sh
# MacOS or Linux
git clone https://github.com/FHIR/dv-formulary-client
cd dv-formulary-client
bundle install
rails s
```

The client can then be accessed at http://localhost:3000 in a web browser.

If you would like to use a different port it can be specified when calling `rails`.  For example, the following command would host the client on port 4000:

```sh
rails s -p 4000
```

### Reference Implementation

While it is recommended that users install the client locally, an instance of the client is hosted at https://formulary-client.herokuapp.com

Users that would like to try out the client before installing locally can use that reference implementation.

## Supported Browsers

The client has been tested on the latest versions of Chrome and Safari.  


## Building Releases

Official releases are built automatically, but you may test the process or roll your own similar to the following:

    docker build -t hspc/davinci-pdex-formulary-client:latest .
    docker run -it --name davinci-pdex-formulary-client -p 3000:3000 --rm hspc/davinci-pdex-formulary-client:latest

## License

Copyright 2019 The MITRE Corporation

Licensed under the Apache License, Version 2.0 (the "License"); you may not use this file except in compliance with the License. You may obtain a copy of the License at
```
http://www.apache.org/licenses/LICENSE-2.0
```
Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the License for the specific language governing permissions and limitations under the License.


## Questions and Contributions
Questions about the project can be asked in the [Da Vinci Formulary stream on the FHIR Zulip Chat](https://chat.fhir.org/#narrow/stream/197730-Da-Vinci-PDex-Drug-Formulary).

This project welcomes Pull Requests. Any issues identified with the RI should be submitted via the [GitHub issue tracker](https://github.com/HL7-DaVinci/pdex-formulary-client/issues).

As of October 1, 2022, The Lantana Consulting Group is responsible for the management and maintenance of this Reference Implementation.
In addition to posting on FHIR Zulip Chat channel mentioned above you can contact [Corey Spears](mailto:corey.spears@lantanagroup.com) for questions or requests.
