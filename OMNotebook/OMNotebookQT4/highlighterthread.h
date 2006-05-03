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

/*! 
 * \file highlighterthread.h
 * \author Anders Fernstr�m
 * \date 2005-12-16
 */

#ifndef HIGHLIGHTERTHREAD_H
#define HIGHLIGHTERTHREAD_H


//QT Headers
#include <QtCore/QStack>
#include <QtCore/QQueue>
#include <QtCore/QThread>

//IAEX Headers
#include "openmodelicahighlighter.h"

//farward declaration
class QTextEdit;

using namespace std;
namespace IAEX
{   
	class HighlighterThread : public QThread
	{
	public:
		static HighlighterThread *instance( SyntaxHighlighter *highlighter = 0, QObject *parent = 0 );
		void run();
		void addEditor( QTextEdit *editor );		// Added 2005-12-29 AF
		void removeEditor( QTextEdit *editor );		// Added 2006-01-05 AF
		bool haveEditor( QTextEdit *editor );		// Added 2006-01-05 AF
		void setStop( bool stop );					// Added 2006-05-03 AF

	private:
		HighlighterThread( SyntaxHighlighter *highlighter = 0, QObject *parent = 0 );

	private:
		static HighlighterThread *instance_;
		bool stopHighlighting_;

		SyntaxHighlighter *highlighter_;
		QStack<QTextEdit*> stack_;
		QQueue<QTextEdit*> removeQueue_;
	};
}
#endif
