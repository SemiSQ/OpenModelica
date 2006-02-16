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

//STD Headers
#include <fstream>
#include <iostream>

//QT Headers
#include <QtGui/QMessageBox>

//IAEX Headers
#include "cellcommandcenter.h"


using namespace std;

namespace IAEX
{
   /*! \class CellCommandCenter
    *
    * \brief Executes and store commands.
    *
    * This class has the responsibility of storing and executing
    * commands. Support for undo is not implemented yet.
    *
    * \todo implement undo/redo functionality. This needs some changes
    * in the command classes.(Ingemar Axelsson)
    */
   CellCommandCenter::CellCommandCenter(Application *a)
      : app_(a)
   {
   }
   
   CellCommandCenter::~CellCommandCenter()
   {
      storeCommands();
   }
   
	void CellCommandCenter::executeCommand(Command *cmd)
	{
		cmd->setApplication(application());

		//Save for undo redo, or atleast for printing.
		storage_.push_back(cmd);

		// 2005-12-01 AF, Added try-catch and messagebox
		try
		{
			cmd->execute();
		}
		catch( exception &e )
		{
			QString msg = e.what();
			
			if( 0 <= msg.indexOf( "OpenFileCommand()", 0, Qt::CaseInsensitive ))
			{
				msg += QString("\r\n\r\nIf you are trying to open an old ") + 
					QString("OMNotebook file, use menu 'File->Import->") + 
					QString("Old OMNotebook file' instead.");
			}

			// display message box
			QMessageBox::warning( 0, "Warning", msg, "OK" );
		}
	}
   
   Application *CellCommandCenter::application()
   {
      return app_;
   }
   
   void CellCommandCenter::setApplication(Application *app)
   {
      app_ = app;
   }
   
   void CellCommandCenter::storeCommands()
   {
      ofstream diskstorage("lastcommands.txt");
      
      vector<Command *>::iterator i = storage_.begin();
      
      for(;i!= storage_.end();++i)
      {
		  diskstorage << (*i)->commandName().toStdString() << endl;
      }
   }
}

