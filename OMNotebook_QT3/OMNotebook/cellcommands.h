/*
------------------------------------------------------------------------------------
This file is part of OpenModelica.

Copyright (c) 1998-2005, Link�pings universitet,
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

#ifndef _CELLCOMMANDS_H
#define _CELLCOMMANDS_H

#include <vector>

#include "command.h"
#include "factory.h"
#include "cellcursor.h"
#include "document.h"
#include "application.h"

using namespace std;

namespace IAEX
{
   class AddCellCommand : public Command
   {
   public:
      AddCellCommand(){}
      virtual ~AddCellCommand(){}
      virtual QString commandName(){ return QString("AddCellCommand");}
      void execute();
   };

   class CreateNewCellCommand : public Command
   {
   public:
      CreateNewCellCommand(const QString &style) : style_(style){}
      virtual ~CreateNewCellCommand(){}
      virtual QString commandName(){ return QString("CreateNewCellCommand");}
      void execute();
   private:
      QString style_;
   };

   //\todo rename to cut command instead.o
   class DeleteCurrentCellCommand : public Command
   {
   public:
      DeleteCurrentCellCommand(){}
      virtual ~DeleteCurrentCellCommand(){}
      void execute();
      virtual QString commandName(){ return QString("DeleteCurrentCellCommand");}
   }; 

   class PasteCellsCommand : public Command
   {
   public:
      PasteCellsCommand(){}
      virtual ~PasteCellsCommand(){}
      void execute();
      QString commandName(){return QString("PasteCellsCommand");}
   private:
   };

   class CopySelectedCellsCommand : public Command
   {
   public:
      CopySelectedCellsCommand(){}
      virtual ~CopySelectedCellsCommand(){}
      void execute();
      QString commandName(){return QString("CopySelectedCellsCommand");}
   private:
   };

   

   class DeleteSelectedCellsCommand : public Command
   {
   public:
      DeleteSelectedCellsCommand(){}
      virtual ~DeleteSelectedCellsCommand(){}
      void execute();
      virtual QString commandName(){ return QString("DeleteSelectedCellsCommand");}
   }; 


   class ChangeStyleOnSelectedCellsCommand : public Command
   {
   public:
      ChangeStyleOnSelectedCellsCommand(const QString &style):style_(style){}
      virtual ~ChangeStyleOnSelectedCellsCommand(){}
      void execute();
      virtual QString commandName(){ return QString("ChangeStyleOnSelectedCellsCommand");}
   private:
      QString style_;
   };

   class ChangeStyleOnCurrentCellCommand : public Command
   {
   public:
      ChangeStyleOnCurrentCellCommand(const QString &style):style_(style){}
      virtual ~ChangeStyleOnCurrentCellCommand(){}
      void execute();
      virtual QString commandName(){ return QString("ChangeStyleOnCurrentCellCommand");}
   private:
      QString style_;
   };

   /*! Makes a groupcell of current cell. Just move the cell down.
    *
    * \todo Create a command for converting selected cells into a
    * groupcell.
    * 
    * \todo Create commands for moving a cell.
    *
    * \todo Implement DRAG and DROP with cells.
    */
   class MakeGroupCellCommand : public Command
   {
   public:
      MakeGroupCellCommand(){}
      virtual ~MakeGroupCellCommand(){}
      void execute();
   };
};
#endif
