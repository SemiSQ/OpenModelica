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
 * \file GraphCell.h
 * \author Ingemar Axelsson and Anders Fernstr�m
 * \date 2005-10-27 (update)
 *
 * \brief Describes a GraphCell.
 */

#ifndef GraphCell_H_
#define GraphCell_H_


//QT Headers
#include <QtGui/QWidget>
#include <QtGui/QTextBrowser>
//Added by qt3to4:
#include <QtGui/QMouseEvent>
#include <QtGui/QGridLayout>
#include <QtGui/QResizeEvent>
#include <QtCore/QEvent>
#include "../Pltpkg2/compoundWidget.h"
#include <QPushButton>
#include <QTemporaryFile>
//IAEX Headers
#include "cell.h"
#include "inputcelldelegate.h"
#include "syntaxhighlighter.h"
//#include "highlighter.h"
#include "document.h"
//#include <QToolBar>

class IndentationState;

namespace IAEX
{   
	enum graphCellStates {FINISHED, EVAL, ERROR, MODIFIED};

	class MyTextEdit2;
	class GraphCell : public Cell
	{
		Q_OBJECT

	public:
		GraphCell(Document *doc, QWidget *parent=0);	// Changed 2005-11-23 AF
		virtual ~GraphCell();

		QString text();
		QString textHtml();						// Added 2005-10-27 AF
		virtual QString textOutput();			// Added 2005-11-23 AF
		virtual QString textOutputHtml();		// Added 2005-11-23 AF
		virtual QTextCursor textCursor();		// Added 2005-10-27 AF
		virtual QTextEdit* textEdit();			// Added 2006-01-05 AF
		virtual QTextEdit* textEditOutput();	// Added 2006-02-03 AF
		virtual void viewExpression(const bool){} 

		virtual void addCellWidgets();
		virtual void removeCellWidgets();

//		void setDelegate(GraphCellDelegate *d);
		void setDelegate(InputCellDelegate *d);
		virtual void accept(Visitor &v);
		virtual bool isClosed();							// Added 2006-01-17 AF
		virtual bool isEditable();
		virtual bool isEvaluated();							// Added 2005-11-23 AF
		virtual bool isPlot(QString text = QString::null);	// Added 2005-11-23 AF
		virtual bool isPlot2(QString text = QString::null);
		virtual bool isVisualize(QString text = QString::null);			


	signals:
		void heightChanged();
		void textChanged();
		void textChanged( bool );
		void clickedOutput( Cell* );					// Added 2006-02-03 AF
		void forwardAction( int );						// Added 2006-04-27 AF
		void newExpr(QString);
		void updatePos(int, int);
		void newState(QString);
		void setStatusMenu(QList<QAction*>);

	public slots:
		void eval();
		void command();									// Added 2005-12-15 AF
		void nextCommand();								// Added 2005-12-15 AF
		void nextField();								// Added 2005-12-15 AF
		void clickEvent();
		void clickEventOutput();						// Added 2006-02-03 AF
		void contentChanged();
		void setText(QString text);
		void setTextHtml(QString html);					// Added 2005-11-01 AF
		virtual void setTextOutput(QString output);		// Added 2005-11-23 AF
		virtual void setTextOutputHtml(QString html);	// Added 2005-11-23 AF
		void setStyle(const QString &stylename);		// Changed 2005-10-28 AF
		void setStyle(CellStyle style);					// Changed 2005-10-27 AF
		void setChapterCounter(QString number);			// Added 2006-03-02 AF
		QString ChapterCounter();						// Added 2006-03-02 AF
		QString ChapterCounterHtml();					// Added 2006-03-03 AF
		void setReadOnly(const bool readonly);			// Added 2005-11-01 AF
		void setEvaluated(const bool evaluated);		// Added 2006-01-16 AF
		void setClosed(const bool closed, bool update = true); //Changed 2006-08-24
		virtual void setFocus(const bool focus);
		virtual void setFocusOutput(const bool focus);	// Added 2006-02-03 AF
		void setExpr(QString);
		void showVariableButton(bool);
		
		void delegateFinished();
		void setState(int state);
		void showGraphics();
		

	protected:
		void resizeEvent(QResizeEvent *event);		//AF
		void mouseDoubleClickEvent(QMouseEvent *);
		void clear();

		bool hasDelegate();
		InputCellDelegate *delegate();

	private slots:
		void addToHighlighter();							// Added 2005-12-29 AF
		void charFormatChanged(const QTextCharFormat &);	// Added 2006-01-17 AF

	private:
		void createGraphCell();
		void createOutputCell();
//		void createGraphWidget();
		void createCompoundWidget();
		void createChapterCounter();
		void exceptionInEval(exception &e);					// Added 2006-02-02 AF
		void setOutputStyle();								// Added 2006-04-21 AF

	private:
		bool evaluated_;
		bool closed_;
		static int numEvals_;
		int oldHeight_;										// Added 2006-04-10 AF

	public:
		MyTextEdit2* input_;
		QTextBrowser *output_;
	private:
		QTextBrowser *chaptercounter_;

//		GraphCellDelegate *delegate_;
		InputCellDelegate *delegate_;
		//SyntaxHighlighter *syntaxHighlighter_;

		QGridLayout *layout_;
		Document *document_;

//		GraphWidget* graphwidget;
	public:
		CompoundWidget* compoundwidget;
		bool showGraph;
		QPushButton* variableButton;
		QTemporaryFile* imageFile;

//		QToolBar *toolbar;
		//		QSlider* slider;
	};


	//***************************************************
	// 2005-12-13 AF, changed from QTextEdit to QTextBrowser (browser better when working with images)
	class MyTextEdit2 : public QTextBrowser
	{
		Q_OBJECT

	public:
		MyTextEdit2(QWidget *parent=0);
		virtual ~MyTextEdit2();

		bool isStopingHighlighter();		// Added 2006-01-16 AF
		int state;

	public slots:
		void goToPos(const QUrl&);
		void updatePosition();
		void setModified();
		void indentText();
		bool lessIndented(QString);
		void setAutoIndent(bool);

	signals:
		void clickOnCell();					// Added 2005-11-01 AF
		void wheelMove( QWheelEvent* );		// Added 2005-11-28 AF
		void command();						// Added 2005-12-15 AF
		void nextCommand();					// Added 2005-12-15 AF
		void nextField();					// Added 2005-12-15 AF
		void eval();						// Added 2005-12-15 AF
		void forwardAction( int );			// Added 2006-04-27 AF
		void updatePos(int, int);
		void setState(int);
		void showVariableButton(bool);

	protected:
		void mousePressEvent(QMouseEvent *event);			// Added 2005-11-01 AF
		void wheelEvent(QWheelEvent *event);				// Added 2005-11-28 AF
		void keyPressEvent(QKeyEvent *event );				// Added 2005-12-15 AF
		void insertFromMimeData(const QMimeData *source);	// Added 2006-01-23 AF
		void focusInEvent(QFocusEvent* event);

	private:
		bool inCommand;						// Added 2005-12-15 AF
		bool stopHighlighter;				// Added 2006-01-16 AF
		int indentationLevel(QString, bool b=true);
		bool autoIndent;
		QMap<int, IndentationState*> indentationStates;

	};

	class MyAction: public QAction
	{
		Q_OBJECT
	public:
		MyAction(const QString& text, QObject* parent);
	public slots:
		void triggered2();
	signals:
		void urlClicked(const QUrl& u);

	};

}
#endif
