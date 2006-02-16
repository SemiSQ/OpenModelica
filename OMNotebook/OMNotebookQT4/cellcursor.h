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
 * \file cellcursor.h 
 * \author Ingemar Axelsson (and Anders Fenstr�m)
 *
 * \brief Implementation of a marker made as an Cell.
 */

#ifndef _CELLCURSOR_H
#define _CELLCURSOR_H


//IAEX Headers
#include "cell.h"

// forward declaration
class QPaintEvent;

namespace IAEX
{     
	class CellCursor : public Cell
	{
		Q_OBJECT

	public:
		CellCursor(QWidget *parent=0);
		virtual ~CellCursor();

		//Insertion
		void addBefore(Cell *newCell);
		void deleteCurrentCell();
		void removeCurrentCell();
		void replaceCurrentWith(Cell *newCell);

		Cell *currentCell();

		//Movment
		void moveUp();
		void moveDown();

		void moveToFirstChild(Cell *parent);
		void moveToLastChild(Cell *parent);
		void moveBefore(Cell *current);
		void moveAfter(Cell *current);

		virtual void accept(Visitor &v);
		virtual QString text(){return QString::null;}

		//Flag
		bool isEditable();								// Added 2005-10-28 AF

	public slots:
		virtual void setFocus(const bool){}

	signals:
		void changedPosition();
		void positionChanged(int x, int y, int xm, int ym);

	private:
		void removeFromCurrentPosition();

	};


	class CursorWidget : public QWidget
	{
	public:
		CursorWidget(QWidget *parent=0)
			:QWidget(parent){}
			virtual ~CursorWidget(){}

	protected:
		void paintEvent(QPaintEvent *event);
	};
}
#endif
