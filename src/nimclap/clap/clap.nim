##
##  CLAP - CLever Audio Plugin
##  ~~~~~~~~~~~~~~~~~~~~~~~~~~
##
##  Copyright (c) 2014...2022 Alexandre BIQUE <bique.alexandre@gmail.com>
##
##  Permission is hereby granted, free of charge, to any person obtaining a copy
##  of this software and associated documentation files (the "Software"), to deal
##  in the Software without restriction, including without limitation the rights
##  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
##  copies of the Software, and to permit persons to whom the Software is
##  furnished to do so, subject to the following conditions:
##
##  The above copyright notice and this permission notice shall be included in
##  all copies or substantial portions of the Software.
##
##  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
##  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
##  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
##  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
##  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
##  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
##  THE SOFTWARE.
##

import
  entry, factory/pluginfactory, factory/presetdiscovery, plugin, pluginfeatures,
  host, universalpluginid, ext/ambisonic, ext/audioportsactivation,
  ext/audioportsconfig, ext/audioports, ext/configurableaudioports,
  ext/contextmenu, ext/eventregistry, ext/gui, ext/latency, ext/log, ext/notename,
  ext/noteports, ext/paramindication, ext/params, ext/posixfdsupport,
  ext/presetload, ext/remotecontrols, ext/render, ext/statecontext, ext/state,
  ext/surround, ext/tail, ext/threadcheck, ext/threadpool, ext/timersupport,
  ext/trackinfo, ext/voiceinfo
