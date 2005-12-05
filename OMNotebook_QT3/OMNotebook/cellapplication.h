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

#ifndef _CELLAPPLICATION_H
#define _CELLAPPLICATION_H

#include <qapplication.h>
#include <qobject.h>

#include "application.h"
#include "commandcenter.h"
#include "documentview.h"

namespace IAEX
{
   class CellApplication : public QObject, public Application
   {
      Q_OBJECT
   public:
      CellApplication(int &argc, char **argv);
      virtual ~CellApplication();
      
      virtual CommandCenter *commandCenter();
      virtual void setCommandCenter(CommandCenter *c);
      
      virtual void addToPasteboard(Cell *c);
      virtual void clearPasteboard();
      vector<Cell *> pasteboard();

      int exec();
      void add(Document *doc);
      void add(DocumentView *view);
      
      void open(const QString filename);
	  
   protected:
      //bool eventFilter(QObject *o, QEvent *e);

   private:
      QApplication *app_;
      vector<Document *> documents_;
      vector<DocumentView *>views_;
      CommandCenter *cmdCenter_;
      vector<Cell*> pasteboard_;
   };
};

#endif
