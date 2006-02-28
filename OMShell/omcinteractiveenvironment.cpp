/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2006, Link�pings universitet,
Department of Computer and Information Science, PELAB
See also: www.ida.liu.se/projects/OpenModelica

All rights reserved.

(The new BSD license, see also
http://www.opensource.org/licenses/bsd-license.php)


Redistribution and use in source and binary forms, with or without
modification,
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice,
      this list of conditions and the following disclaimer.
    
	* Redistributions in binary form must reproduce the above copyright notice,
      this list of conditions and the following disclaimer in the documentation
      and/or other materials provided with the distribution.

    * Neither the name of Link�pings universitet nor the names of its contributors
      may be used to endorse or promote products derived from this software without
      specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE
LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
POSSIBILITY OF SUCH DAMAGE.

For more information about the Qt-library visit TrollTech:s webpage regarding
licence: http://www.trolltech.com/products/qt/licensing.html

------------------------------------------------------------------------------------
*/
#ifdef WIN32
#include "windows.h"
#endif

#include <exception>
#include <stdexcept>

#include <QtGui/QMessageBox>

#include "omcinteractiveenvironment.h"

using namespace std;

namespace IAEX
{
	/*! \class OmcInteractiveEnvironment
	 *
	 * \brief Implements evaluation for modelica code. 
	 */
	OmcInteractiveEnvironment::OmcInteractiveEnvironment()
		: comm_(OmcCommunicator::getInstance()),result_("")
	{
		//Communicate with Omc.
		if(!comm_.isConnected())
		{
			if(!comm_.establishConnection())
			{
				throw runtime_error("OmcInteractiveEnvironment(): No connection to Omc established");
			}
		}
	}
   
   OmcInteractiveEnvironment::~OmcInteractiveEnvironment(){}   

   QString OmcInteractiveEnvironment::getResult()
   {
      return result_;
   }
   
   void OmcInteractiveEnvironment::evalExpression(QString &expr)
   {
		// 2006-02-02 AF, Added try-catch
		try
		{
			result_ = comm_.callOmc(expr);
		}
		catch( exception &e )
		{
			throw e;	
		}
	}

   void OmcInteractiveEnvironment::closeConnection()
   {
	   comm_.closeConnection();
   }

   	void OmcInteractiveEnvironment::reconnect()
	{
		//Communicate with Omc.
		if(!comm_.isConnected())
		{
			if(!comm_.establishConnection())
			{
				throw runtime_error("OmcInteractiveEnvironment(): No connection to Omc established");
			}
		}
	}

	bool OmcInteractiveEnvironment::startDelegate()
	{
		// if not connected and can not establish connection, 
		// try to start OMC
		if( !comm_.isConnected() && !comm_.establishConnection() )
		{
			return  OmcInteractiveEnvironment::startOMC();
		}
		else
			return false;
	}

	bool OmcInteractiveEnvironment::startOMC()
	{
		bool flag = false;

		#ifdef WIN32
		try
		{
			// 2006-02-28 AF, use environment varable to find omc.exe
			string OMCPath( getenv( "OPENMODELICAHOME" ) );
			if( OMCPath.empty() )
				throw std::exception( "Could not find environment variable OPENMODELICAHOME" );

			// location of omc in openmodelica folder
			OMCPath += "\\bin\\";

			STARTUPINFO startinfo;
			PROCESS_INFORMATION procinfo;
			memset(&startinfo, 0, sizeof(startinfo));
			memset(&procinfo, 0, sizeof(procinfo));
			startinfo.cb = sizeof(STARTUPINFO);
			startinfo.wShowWindow = SW_MINIMIZE;
			startinfo.dwFlags = STARTF_USESHOWWINDOW;

			//string parameter = "\"omc.exe\" +d=interactiveCorba";
			string parameter = "\"" + OMCPath + "omc.exe\" +d=interactiveCorba";
			char *pParameter = new char[parameter.size() + 1];
			const char *cpParameter = parameter.c_str();
			strcpy(pParameter, cpParameter);

			flag = CreateProcess(NULL,pParameter,NULL,NULL,FALSE,CREATE_NEW_CONSOLE,NULL,NULL,&startinfo,&procinfo);

			Sleep(1000);

			if( !flag )
				throw std::exception("Was unable to start OMC");
		}
		catch( exception &e )
		{
			QString msg = e.what();
			QMessageBox::warning( 0, "Error", msg, "OK" );
		}
		#else
		QString msg = e.what();
		msg += "\nOMC not started!";
		QMessageBox::warning( 0, "Error", msg, "OK" );
		#endif

		return flag;
	}
}
