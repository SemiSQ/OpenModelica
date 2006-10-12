package Corba "
This file is part of OpenModelica.

Copyright (c) 1998-2006, Link�pings universitet, Department of
Computer and Information Science, PELAB

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are
met:

 Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

 Redistributions in binary form must reproduce the above copyright
  notice, this list of conditions and the following disclaimer in
  the documentation and/or other materials provided with the
  distribution.

 Neither the name of Link�pings universitet nor the names of its
  contributors may be used to endorse or promote products derived from
  this software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
\"AS IS\" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
(INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

  
  file:        Corba.mo
  module:      Corba
  description: Modelica Corba communication module
 
  RCS: $Id$
 
  This is the CORBA connection module of the compiler
  
  The actual implementation differs between Windows and Unix versions. 
  The Windows implementation and the Unix
  version lies in ./runtime but they use C ifdefs to provide different
  implementation
  
  OpenModelica does not in itself include a complete CORBA implementaton.
  You need to download one, for example MICO from http://www.mico.org.
 
  There exists some options that can be sent to configure concerinng 
  the usage of corba: 
     --with-CORBA=/location/of/corba/library
     --without-CORBA
"

public function initialize

  external "C" ;
end initialize;

public function waitForCommand
  output String outString;

  external "C" ;
end waitForCommand;

public function sendreply
  input String inString;

  external "C" ;
end sendreply;

public function close

  external "C" ;
end close;
end Corba;

