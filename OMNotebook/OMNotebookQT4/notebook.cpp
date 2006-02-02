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

/*! 
 * \file notebook.h
 * \author Ingemar Axelsson and Anders Fernstr�m
 * \date 2005-02-07
 */


//STD Headers
#include <exception>
#include <stdexcept>
#include <fstream>
#include <algorithm>

//QT Headers
#include <QtCore/QTimer>
#include <QtGui/QAction>
#include <QtGui/QApplication>
#include <QtGui/QColorDialog>
#include <QtGui/QFileDialog>
#include <QtGui/QFontDatabase>
#include <QtGui/QFontDialog>
#include <QtGui/QImageReader>
#include <QtGui/QKeyEvent>
#include <QtGui/QMenuBar>
#include <QtGui/QMessageBox>
#include <QtGui/QPrinter>
#include <QtGui/QPrintDialog>
#include <QtGui/QStatusBar>
#include <QtGui/QTextCursor>
#include <QtGui/QTextEdit>
#include <QtGui/QTextFrame>

//IAEX Headers
#include "command.h"
#include "cellcommands.h"
#include "celldocument.h"
#include "cursorcommands.h"
#include "imagesizedlg.h"
#include "notebook.h"
#include "notebookcommands.h"
#include "otherdlg.h"
#include "stylesheet.h"
#include "xmlparser.h"
#include "removehighlightervisitor.h"

using namespace std;

namespace IAEX
{
	/*! 
	 * \class SleeperThread
	 * \author Anders Ferstr�m
	 *
	 * \brief Extends QThread. A small trick to get access to protected
	 * function in QThread.
	 */
	class SleeperThread : public QThread
	{
	public:
		static void msleep(unsigned long msecs)
		{
			QThread::msleep(msecs);
		}
	};


	/*! 
	 * \class NotebookWindow 
	 * \author Ingemar Axelsson and Anders Fernstr�m
	 *
	 * \brief This class describes a mainwindow using the CellDocument
	 * 
	 * This is the main applicationwindow. It contains of a menu, a
	 * toolbar, a statusbar and a workspace. The workspace will contain a
	 * celldocument view.
	 * 
	 *
	 * \todo implement a timer that saves a document every 5 minutes 
	 * or so.
	 *
	 * \todo Implement section numbering. Could be done with some kind 
	 * of vistors.
	 *
	 * 
	 * \bug Segmentation fault when quit. Only sometimes.
	 */


	/*! 
	 * \author Ingemar Axelsson and Anders Fernstr�m
	 * \date 2006-01-17 (update)
	 *
	 * \brief The class constructor
	 *
	 * 2006-01-16 AF, Added an icon to the window
	 * Also made som other updates /AF
	 */
	NotebookWindow::NotebookWindow(Document *subject, 
		const QString &filename, QWidget *parent)
		: DocumentView(parent),
		subject_(subject),
		filename_(filename),
		app_( subject->application() ) //AF
	{
		if( filename_ != QString::null )
			qDebug( filename_.toStdString().c_str() );

		subject_->attach(this);
		setMinimumSize( 150, 220 );		//AF

		createFileMenu();
		createEditMenu();
		createCellMenu();
		createFormatMenu();
		createInsertMenu();
		createWindowMenu();
		createAboutMenu();
		
		// 2006-01-16 AF, Added an icon to the window
		setWindowIcon( QIcon(":/omnotebook_png.png") );

		statusBar()->showMessage("Ready");
		resize(800, 600);

		connect( subject_->getCursor(), SIGNAL( changedPosition() ),
			this, SLOT( updateMenus() ));
		connect( subject_, SIGNAL( contentChanged() ),
			this, SLOT( updateWindowTitle() ));

		updateWindowTitle();
		update();
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernstr�m
	 * \date 2006-01-05 (update)
	 *
	 * \brief The class destructor
	 *
	 * 2005-11-03/04/07 AF, added som things that should be deleted.
	 * 2006-01-05 AF, added code so all inputcells are added to the
	 * removelist in the highlighter
	 * 2006-01-27 AF, remove this notebook window from the list of
	 * notebook windows in the main applicaiton
	 */
	NotebookWindow::~NotebookWindow()
	{
		//2006-01-27 AF, remove document view from application lsit
		application()->removeDocumentView( this );

		//2006-01-05 AF, add all inputcell to removelist on highlighter
		RemoveHighlighterVisitor visitor;
		subject_->runVisitor( visitor );

		subject_->detach(this);
		delete subject_;
		//subject_ = 0;

		// 2005-11-03/04/07 AF, remova all created QAction
		map<QString, QAction*>::iterator s_iter = styles_.begin();
		while( s_iter != styles_.end() )
		{
			delete (*s_iter).second;
			++s_iter;
		}

		QHash<QString, QAction*>::iterator f_iter = fonts_.begin();
		while( f_iter != fonts_.end() )
		{
			delete f_iter.value();
			++f_iter;
		}

		QHash<QAction*, QColor*>::iterator c_iter = colors_.begin();
		while( c_iter != colors_.end() )
		{
			delete c_iter.value();
			++c_iter;
		}

		QHash<QAction*, DocumentView*>::iterator w_iter = windows_.begin();
		while( w_iter != windows_.end() )
		{
			delete w_iter.key();
			++w_iter;
		}

		delete stylesgroup;
		delete fontsgroup;
		delete sizesgroup;
		delete stretchsgroup;
		delete colorsgroup;
		delete alignmentsgroup;
		delete verticalAlignmentsgroup;
		delete bordersgroup;
		delete marginsgroup;
		delete paddingsgroup;


		delete newAction;
		delete openFileAction;
		delete saveAsAction;
		delete saveAction;
		delete printAction;
		delete closeFileAction;
		delete quitWindowAction;

		delete undoAction;
		delete redoAction;
		delete searchAction;
		delete showExprAction;

		delete cutCellAction;
		delete copyCellAction;
		delete pasteCellAction;
		delete addCellAction;
		delete deleteCellAction;
		delete nextCellAction;
		delete previousCellAction;
		
		delete groupAction;
		delete inputAction;

		delete aboutAction;

		delete facePlain;
		delete faceBold;
		delete faceItalic;
		delete faceUnderline;

		delete sizeSmaller;
		delete sizeLarger;
		delete size8pt;
		delete size9pt;
		delete size10pt;
		delete size12pt;
		delete size14pt;
		delete size16pt;
		delete size18pt;
		delete size20pt;
		delete size24pt;
		delete size36pt;
		delete size72pt;
		delete sizeOther;

		delete stretchUltraCondensed;
		delete stretchExtraCondensed;
		delete stretchCondensed;
		delete stretchSemiCondensed;
		delete stretchUnstretched;
		delete stretchSemiExpanded;
		delete stretchExpanded;
		delete stretchExtraExpanded;
		delete stretchUltraExpanded;

		delete colorBlack;
		delete colorWhite;
		delete color10Gray;
		delete color33Gray;
		delete color50Gray;
		delete color66Gray;
		delete color90Gray;
		delete colorRed;
		delete colorGreen;
		delete colorBlue;
		delete colorCyan;
		delete colorMagenta;
		delete colorYellow;
		delete colorOther;

		delete chooseFont;

		delete alignmentLeft;
		delete alignmentRight;
		delete alignmentCenter;
		delete alignmentJustify;
		delete verticalNormal;
		delete verticalSub;
		delete verticalSuper;

		delete borderOther;
		delete marginOther;
		delete paddingOther;

		delete insertImageAction;
		delete insertLinkAction;
		delete importOldFile;
		delete exportPureText;
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	void NotebookWindow::update()
	{
		QFrame *mainWidget = subject_->getState();
		
		mainWidget->setParent(this);
		mainWidget->move( QPoint(0,0) );

		setCentralWidget(mainWidget);
		mainWidget->show();
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-30
	 *
	 * \brief Return the notebook windons document
	 */
	Document* NotebookWindow::document()
	{
		return subject_;
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	Application *NotebookWindow::application()
	{
		return subject_->application();
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-12-01 (update)
	 *
	 * \brief Method for creating file nemu.
	 *
	 * 2005-10-07 AF, Updated/Remade the function when porting to QT4.
	 * 2005-11-21 AF, Added a export menu
	 * 2005-12-01 AF, Added a import menu
	 */
	void NotebookWindow::createFileMenu()
	{
		// NEW
		newAction = new QAction( tr("&New"), this );
		newAction->setShortcut( tr("Ctrl+N") );
		newAction->setStatusTip( tr("Create a new document") );
		connect(newAction, SIGNAL(triggered()), this, SLOT(newFile()));

		// OPEN FILE
		openFileAction = new QAction( tr("&Open"), this );
		openFileAction->setShortcut( tr("Ctrl+O") );
		openFileAction->setStatusTip( tr("Open a file") );
		connect(openFileAction, SIGNAL(triggered()), this, SLOT(openFile()));

		// SAVE AS
		saveAsAction = new QAction( tr("Save &As..."), this );
		saveAsAction->setShortcut( tr("Ctrl+Shift+S") );
		saveAsAction->setStatusTip( tr("Save the document as a new file") );
		connect(saveAsAction, SIGNAL(triggered()), this, SLOT(saveas()));

		// SAVE
		saveAction = new QAction( tr("&Save"), this );
		saveAction->setShortcut( tr("Ctrl+S") );
		saveAction->setStatusTip( tr("Save the document") );
		connect(saveAction, SIGNAL(triggered()), this, SLOT(save()));

		// CLOSE FILE
		closeFileAction = new QAction( tr("&Close"), this );
		closeFileAction->setShortcut( tr("Ctrl+F4") );
		closeFileAction->setStatusTip( tr("Close the window") );
		connect(closeFileAction, SIGNAL(triggered()), this, SLOT(closeFile())); 

		// PRINT
		printAction = new QAction( tr("&Print"), this );
		printAction->setShortcut( tr("Ctrl+P") );
		printAction->setStatusTip( tr("Print the document") );
		connect(printAction, SIGNAL(triggered()), this, SLOT(print()));

		// QUIT WINDOW
		quitWindowAction = new QAction( tr("&Quit"), this );
		quitWindowAction->setShortcut( tr("Ctrl+Q") );
		quitWindowAction->setStatusTip( tr("Quit OMNotebook") );
		connect(quitWindowAction, SIGNAL(triggered()), this, SLOT(quitOMNotebook())); 

		// CREATE MENU
		fileMenu = menuBar()->addMenu( tr("&File") );
		fileMenu->addAction( newAction );
		fileMenu->addAction( openFileAction );
		fileMenu->addAction( saveAction );
		fileMenu->addAction( saveAsAction );
		fileMenu->addAction( closeFileAction );
		fileMenu->addSeparator();
		fileMenu->addAction( printAction );
		fileMenu->addSeparator();
		importMenu = fileMenu->addMenu( tr("&Import") );
		exportMenu = fileMenu->addMenu( tr("E&xport") );
		fileMenu->addSeparator();
		fileMenu->addAction( quitWindowAction );


		// IMPORT MENU
		// Added 2005-12-01
		importOldFile = new QAction( tr("&Old OMNotebook file"), this );
		importOldFile->setStatusTip( tr("Import an old OMNotebook file") );
		connect( importOldFile, SIGNAL( triggered() ),
			this, SLOT( openOldFile() ));

		importMenu->addAction( importOldFile );


		// EXPORT MENU
		// Added 2005-11-21
		exportPureText = new QAction( tr("&Pure text"), this );
		exportPureText->setStatusTip( tr("Export the document content to pure text") );
		connect( exportPureText, SIGNAL( triggered() ), 
			this, SLOT( pureText() ));

		exportMenu->addAction( exportPureText );
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-10-07 (update)
	 *
	 * \brief Method for creating edit nemu.
	 *
	 * Remade the function when porting to QT4.
	 */
	void NotebookWindow::createEditMenu()
	{
		// 2005-10-07 AF, Porting, replaced this
		//QAction *undoAction = new QAction("Undo", "&Undo", 0, this, "undoaction");
		undoAction = new QAction( tr("&Undo"), this);
		undoAction->setStatusTip( tr("Undo last action") );
		undoAction->setEnabled(false);

		// 2005-10-07 AF, Porting, replaced this
		//QAction *redoAction = new QAction("Redo", "&Redo", 0, this, "redoaction");
		redoAction = new QAction( tr("&Redo"), this);
		redoAction->setStatusTip( tr("Redo last action") );
		redoAction->setEnabled(false);

		// 2005-10-07 AF, Porting, replaced this
		//QAction *searchAction = new QAction("Search", "&Search", 0, this, "search");
		searchAction = new QAction( tr("&Search"), this);
		searchAction->setStatusTip( tr("Search through the document") );
		searchAction->setEnabled(false);

		// 2005-10-07 AF, Porting, replaced this
		//QAction *showExprAction = new QAction("View Expression", "&View Expression",0, this, "viewexpr");
		//QObject::connect(showExprAction, SIGNAL(toggled(bool)), subject_, SLOT(showHTML(bool)));
		showExprAction = new QAction( tr("&View Expression"), this);
		showExprAction->setStatusTip( tr("View the expression in the cell") );
		showExprAction->setCheckable(true);
		showExprAction->setChecked(false);
		connect(showExprAction, SIGNAL(toggled(bool)), subject_, SLOT(showHTML(bool)));

		// 2005-10-07 AF, Porting, new code for creating menu
		editMenu = menuBar()->addMenu( tr("&Edit") );
		editMenu->addAction( undoAction );
		editMenu->addAction( redoAction );
		editMenu->addSeparator();
		editMenu->addAction( searchAction );
		editMenu->addAction( showExprAction );


		/* Old menu code //AF
		editMenu = new Q3PopupMenu(this);
		menuBar()->insertItem("&Edit", editMenu);
		undoAction->addTo(editMenu);
		redoAction->addTo(editMenu);
		editMenu->insertSeparator(3);
		searchAction->addTo(editMenu);      
		showExprAction->addTo(editMenu);
		*/

		
		QObject::connect(editMenu, SIGNAL(aboutToShow()),
			this, SLOT(updateEditMenu()));
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-10-07 (update)
	 *
	 * \brief Method for creating cell nemu.
	 *
	 * Remade the function when porting to QT4.
	 */
	void NotebookWindow::createCellMenu()
	{
		// 2005-10-07 AF, Porting, replaced this
		//QAction *cutCellAction = new QAction("Cut cell", "&Cut Cell", CTRL+SHIFT+Key_X, this, "cutcell");
		//QObject::connect(cutCellAction, SIGNAL(activated()), this, SLOT(cutCell()));
		cutCellAction = new QAction( tr("Cu&t Cell"), this);
		cutCellAction->setShortcut( tr("Ctrl+Shift+X") );
		cutCellAction->setStatusTip( tr("Cut selected cell") );
		connect(cutCellAction, SIGNAL(triggered()), this, SLOT(cutCell()));

		// 2005-10-07 AF, Porting, replaced this
		//QAction *copyCellAction = new QAction("Copy cell", "&Copy Cell", CTRL+SHIFT+Key_C, this, "copycell");
		//QObject::connect(copyCellAction, SIGNAL(activated()), this, SLOT(copyCell()));
		copyCellAction = new QAction( tr("&Copy Cell"), this);
		copyCellAction->setShortcut( tr("Ctrl+Shift+C") );
		copyCellAction->setStatusTip( tr("Copy selected cell") );
		connect(copyCellAction, SIGNAL(triggered()), this, SLOT(copyCell()));

		// 2005-10-07 AF, Porting, replaced this
		//QAction *pasteCellAction = new QAction("Paste cell", "&Paste Cell", CTRL+SHIFT+Key_V, this, "pastecell");
		//QObject::connect(pasteCellAction, SIGNAL(activated()), this, SLOT(pasteCell()));
		pasteCellAction = new QAction( tr("&Paste Cell"), this);
		pasteCellAction->setShortcut( tr("Ctrl+Shift+V") );
		pasteCellAction->setStatusTip( tr("Paste in a cell") );
		connect(pasteCellAction, SIGNAL(triggered()), this, SLOT(pasteCell()));

		// 2005-10-07 AF, Porting, replaced this
		//QAction *addCellAction = new QAction("Add cell", "&Add Cell", CTRL+Key_A, this, "addcell");
		//QObject::connect(addCellAction, SIGNAL(activated()), this, SLOT(createNewCell()));
		addCellAction = new QAction( tr("&Add Cell (previus cell style)"), this);
		addCellAction->setShortcut( tr("Alt+Enter") );
		addCellAction->setStatusTip( tr("Add a new textcell with the previuos cells style") );
		connect(addCellAction, SIGNAL(triggered()), this, SLOT(createNewCell()));

		// 2005-10-07 AF, Porting, replaced this
		//QAction *inputAction = new QAction("Inputcell", "&Input cell", CTRL+SHIFT+Key_I, this, "inputcells");
		//QObject::connect(inputAction, SIGNAL(activated()), this, SLOT(inputCellsAction()));  
		inputAction = new QAction( tr("Add &Inputcell"), this);
		inputAction->setShortcut( tr("Ctrl+Shift+I") );
		inputAction->setStatusTip( tr("Add a input cell") );
		connect(inputAction, SIGNAL(triggered()), this, SLOT(inputCellsAction()));

		// 2005-10-07 AF, Porting, replaced this
		//QAction *deleteCellAction = new QAction("Delete cell", "&Delete Cell", CTRL+SHIFT+Key_D, this, "deletecell");
		//QObject::connect(deleteCellAction, SIGNAL(activated()), this, SLOT(deleteCurrentCell()));
		deleteCellAction = new QAction( tr("&Delete Cell"), this);
		deleteCellAction->setShortcut( tr("Ctrl+Shift+D") );
		deleteCellAction->setStatusTip( tr("Delete selected cell") );
		connect(deleteCellAction, SIGNAL(triggered()), this, SLOT(deleteCurrentCell()));

		// 2005-10-07 AF, Porting, replaced this
		//QAction *nextCellAction = new QAction("next cell", "&Next Cell", 0, this, "nextcell");
		//QObject::connect(nextCellAction, SIGNAL(activated()), this, SLOT(moveCursorDown()));
		nextCellAction = new QAction( tr("&Next Cell"), this);
		nextCellAction->setStatusTip( tr("Move to next cell") );
		connect(nextCellAction, SIGNAL(triggered()), this, SLOT(moveCursorDown()));

		// 2005-10-07 AF, Porting, replaced this
		//QAction *previousCellAction = new QAction("previous cell", "&Previous Cell", 0, this, "prevoiscell");
		//QObject::connect(previousCellAction, SIGNAL(activated()), this, SLOT(moveCursorUp()));
		previousCellAction = new QAction( tr("&Previous Cell"), this);
		previousCellAction->setStatusTip( tr("Move to previous cell") );
		connect(previousCellAction, SIGNAL(triggered()), this, SLOT(moveCursorUp()));


		// 2005-10-07 AF, Porting, new code for creating menu
		cellMenu = menuBar()->addMenu( tr("&Cell") );
		cellMenu->addAction( cutCellAction );
		cellMenu->addAction( copyCellAction );
		cellMenu->addAction( pasteCellAction );
		cellMenu->addSeparator();
		cellMenu->addAction( addCellAction );
		cellMenu->addAction( inputAction );
		cellMenu->addAction( deleteCellAction );
		cellMenu->addSeparator();
		cellMenu->addAction( nextCellAction );
		cellMenu->addAction( previousCellAction );


		/* Old menu code //AF
		cellMenu = new Q3PopupMenu(this);
		menuBar()->insertItem("&Cell", cellMenu);
		cutCellAction->addTo(cellMenu);
		copyCellAction->addTo(cellMenu);
		pasteCellAction->addTo(cellMenu);
		addCellAction->addTo(cellMenu);
		deleteCellAction->addTo(cellMenu);
		nextCellAction->addTo(cellMenu);
		previousCellAction->addTo(cellMenu);
		cellMenu->insertSeparator(3);
		cellMenu->insertSeparator(5);
		*/
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-10-07
	 * \date 2005-11-03 (update)
	 *
	 * \brief Method for creating format nemu.
	 *
	 * Remade the function when porting to QT4.
	 *
	 * 2005-11-03 AF, Updated this function with functionality for
	 * changes text settings.
	 */
	void NotebookWindow::createFormatMenu()
	{
		// 2005-10-07 AF, Portin, Removed
		//Create style menus.
		//Q3ActionGroup *stylesgroup = new Q3ActionGroup(this, 0, true);
		
		// 2005-10-07 AF, Portin, Removed
		//formatMenu = new Q3PopupMenu(this);


		// 2005-10-03 AF, get the stylesheet instance
		Stylesheet *sheet = Stylesheet::instance("stylesheet.xml");
	
		// Create the style actions //AF
		stylesgroup = new QActionGroup( this );
		formatMenu = menuBar()->addMenu( tr("&Format") );
		styleMenu = formatMenu->addMenu( tr("&Styles") );

		vector<QString> styles = sheet->getAvailableStyleNames();
		vector<QString>::iterator i = styles.begin();
		for(;i != styles.end(); ++i)
		{
			QAction *tmp = new QAction( tr( (*i).toStdString().c_str() ), this );
			tmp->setCheckable( true );
			styleMenu->addAction( tmp );
			stylesgroup->addAction( tmp );
			styles_[(*i)] = tmp;
		
			/* old action/menu code
			QAction *tmp = new QAction((*i),(*i),0, this, (*i));
			tmp->setToggleAction(true);
			stylesgroup->add(tmp);
			//tmp->addTo(styleMenu);
			styles_[(*i)] = tmp;
			*/
		}

		// 2005-10-07 AF, Porting, replaced this
		//QObject::connect(stylesgroup, SIGNAL(selected (QAction*)), this, SLOT(changeStyle(QAction*)));
		connect( styleMenu, SIGNAL(triggered(QAction*)), this, SLOT(changeStyle(QAction*)));


		// 2005-10-07 AF, Portin, Removed
		//stylesgroup->setUsesDropDown(true);
		//stylesgroup->setMenuText("&Styles");



		// FONT
		// -----------------------------------------------------
		// Code for createn the font menu
		formatMenu->addSeparator();
		fontsgroup = new QActionGroup( this );
		fontMenu = formatMenu->addMenu( tr("&Font") );
		
		QFontDatabase fontDatabase;
		QStringList fonts = fontDatabase.families( QFontDatabase::Latin );
		for( int index = 0; index < fonts.count(); ++index )
		{
			QAction *tmp = new QAction( fonts[index], this );
			tmp->setCheckable( true );
			fontMenu->addAction( tmp );
			fontsgroup->addAction( tmp );
			fonts_.insert( fonts[index], tmp );
		}

		connect( fontMenu, SIGNAL( triggered(QAction*) ), 
			this, SLOT( changeFont(QAction*) ));
		connect( fontMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateFontMenu() ));
		
		// -----------------------------------------------------
		// END: FONT


		// FACE
		// -----------------------------------------------------
		// Code for createn the face menu
		faceMenu = formatMenu->addMenu( tr("Fa&ce") );

		facePlain = new QAction( tr("&Plain"), this);
		facePlain->setCheckable( false );
		facePlain->setStatusTip( tr("Set font face to Plain") );

		faceBold = new QAction( tr("&Bold"), this);
		faceBold->setShortcut( tr("Ctrl+B") );
		faceBold->setCheckable( true );
		faceBold->setStatusTip( tr("Set font face to Bold") );

		faceItalic = new QAction( tr("&Italic"), this);
		faceItalic->setShortcut( tr("Ctrl+I") );
		faceItalic->setCheckable( true );
		faceItalic->setStatusTip( tr("Set font face to Italic") );

		faceUnderline = new QAction( tr("&Underline"), this);
		faceUnderline->setShortcut( tr("Ctrl+U") );
		faceUnderline->setCheckable( true );
		faceUnderline->setStatusTip( tr("Set font face to Underline") );
		

		connect( faceMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateFontFaceMenu() ));
		connect( faceMenu, SIGNAL( triggered(QAction*) ),
			this, SLOT( changeFontFace(QAction*) ));

		faceMenu->addAction( facePlain );
		faceMenu->addAction( faceBold );
		faceMenu->addAction( faceItalic );
		faceMenu->addAction( faceUnderline );

		// -----------------------------------------------------
		// END: FONT



		// SIZE
		// -----------------------------------------------------
		// Code for createn the size menu

		sizeMenu = formatMenu->addMenu( tr("Si&ze") );
		sizesgroup = new QActionGroup( this );

		sizeSmaller = new QAction( tr("&Smaller"), this);
		sizeSmaller->setShortcut( tr("Alt+-") );
		sizeSmaller->setCheckable( false );
		sizeSmaller->setStatusTip( tr("Set font size smaller") );

		sizeLarger = new QAction( tr("&Larger"), this);
		sizeLarger->setShortcut( tr("Alt+=") );
		sizeLarger->setCheckable( false );
		sizeLarger->setStatusTip( tr("Set font size larger") );

		size8pt = new QAction( tr("8"), this);
		size8pt->setCheckable( true );
		sizes_.insert( "8", size8pt );
		sizesgroup->addAction( size8pt );

		size9pt = new QAction( tr("9"), this);
		size9pt->setCheckable( true );
		sizes_.insert( "9", size9pt );
		sizesgroup->addAction( size9pt );

		size10pt = new QAction( tr("10"), this);
		size10pt->setCheckable( true );
		sizes_.insert( "10", size10pt );
		sizesgroup->addAction( size10pt );

		size12pt = new QAction( tr("12"), this);
		size12pt->setCheckable( true );
		sizes_.insert( "12", size12pt );
		sizesgroup->addAction( size12pt );

		size14pt = new QAction( tr("14"), this);
		size14pt->setCheckable( true );
		sizes_.insert( "14", size14pt );
		sizesgroup->addAction( size14pt );

		size16pt = new QAction( tr("16"), this);
		size16pt->setCheckable( true );
		sizes_.insert( "16", size16pt );
		sizesgroup->addAction( size16pt );

		size18pt = new QAction( tr("18"), this);
		size18pt->setCheckable( true );
		sizes_.insert( "18", size18pt );
		sizesgroup->addAction( size18pt );

		size20pt = new QAction( tr("20"), this);
		size20pt->setCheckable( true );
		sizes_.insert( "20", size20pt );
		sizesgroup->addAction( size20pt );

		size24pt = new QAction( tr("24"), this);
		size24pt->setCheckable( true );
		sizes_.insert( "24", size24pt );
		sizesgroup->addAction( size24pt );

		size36pt = new QAction( tr("36"), this);
		size36pt->setCheckable( true );
		sizes_.insert( "36", size36pt );
		sizesgroup->addAction( size36pt );

		size72pt = new QAction( tr("72"), this);
		size72pt->setCheckable( true );
		sizes_.insert( "72", size72pt );
		sizesgroup->addAction( size72pt );

		sizeOther = new QAction( tr("&Other..."), this);
		sizeOther->setCheckable( true );
		sizeOther->setStatusTip( tr("Select font size") );

		
		connect( sizeMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateFontSizeMenu() ));
		connect( sizeMenu, SIGNAL( triggered(QAction*) ),
			this, SLOT( changeFontSize(QAction*) ));


		sizeMenu->addAction( sizeSmaller );
		sizeMenu->addAction( sizeLarger );
		sizeMenu->addSeparator();
		sizeMenu->addAction( size8pt );
		sizeMenu->addAction( size9pt );
		sizeMenu->addAction( size10pt );
		sizeMenu->addAction( size12pt );
		sizeMenu->addAction( size14pt );
		sizeMenu->addAction( size16pt );
		sizeMenu->addAction( size18pt );
		sizeMenu->addAction( size20pt );
		sizeMenu->addAction( size24pt );
		sizeMenu->addAction( size36pt );
		sizeMenu->addAction( size72pt );
		sizeMenu->addSeparator();
		sizeMenu->addAction( sizeOther );

		// -----------------------------------------------------
		// END: Size



		// STRETCH
		// -----------------------------------------------------
		// Code for createn the stretch menu

		stretchMenu = formatMenu->addMenu( tr("S&tretch") );
		stretchsgroup = new QActionGroup( this );

		stretchUltraCondensed = new QAction( tr("U&ltra Condensed"), this);
		stretchUltraCondensed->setCheckable( true );
		stretchUltraCondensed->setStatusTip( tr("Set font stretech to Ultra Condensed") );
		stretchs_.insert( QFont::UltraCondensed, stretchUltraCondensed );
		stretchsgroup->addAction( stretchUltraCondensed );
	
		stretchExtraCondensed = new QAction( tr("E&xtra Condensed"), this);
		stretchExtraCondensed->setCheckable( true );
		stretchExtraCondensed->setStatusTip( tr("Set font stretech to Extra Condensed") );
		stretchs_.insert( QFont::ExtraCondensed, stretchExtraCondensed );
		stretchsgroup->addAction( stretchExtraCondensed );

		stretchCondensed = new QAction( tr("&Condensed"), this);
		stretchCondensed->setCheckable( true );
		stretchCondensed->setStatusTip( tr("Set font stretech to Condensed") );
		stretchs_.insert( QFont::Condensed, stretchCondensed );
		stretchsgroup->addAction( stretchCondensed );

		stretchSemiCondensed = new QAction( tr("S&emi Condensed"), this);
		stretchSemiCondensed->setCheckable( true );
		stretchSemiCondensed->setStatusTip( tr("Set font stretech to Semi Condensed") );
		stretchs_.insert( QFont::SemiCondensed, stretchSemiCondensed );
		stretchsgroup->addAction( stretchSemiCondensed );

		stretchUnstretched = new QAction( tr("&Unstretched"), this);
		stretchUnstretched->setCheckable( true );
		stretchUnstretched->setStatusTip( tr("Set font stretech to Unstretched") );
		stretchs_.insert( QFont::Unstretched, stretchUnstretched );
		stretchsgroup->addAction( stretchUnstretched );

		stretchSemiExpanded = new QAction( tr("&Semi Expanded"), this);
		stretchSemiExpanded->setCheckable( true );
		stretchSemiExpanded->setStatusTip( tr("Set font stretech to Semi Expanded") );
		stretchs_.insert( QFont::SemiExpanded, stretchSemiExpanded );
		stretchsgroup->addAction( stretchSemiExpanded );

		stretchExpanded = new QAction( tr("&Expanded"), this);
		stretchExpanded->setCheckable( true );
		stretchExpanded->setStatusTip( tr("Set font stretech to Expanded") );
		stretchs_.insert( QFont::Expanded, stretchExpanded );
		stretchsgroup->addAction( stretchExpanded );

		stretchExtraExpanded = new QAction( tr("Ex&tra Expanded"), this);
		stretchExtraExpanded->setCheckable( true );
		stretchExtraExpanded->setStatusTip( tr("Set font stretech to Extra Expanded") );
		stretchs_.insert( QFont::ExtraExpanded, stretchExtraExpanded );
		stretchsgroup->addAction( stretchExtraExpanded );

		stretchUltraExpanded = new QAction( tr("Ult&ra Expanded"), this);
		stretchUltraExpanded->setCheckable( true );
		stretchUltraExpanded->setStatusTip( tr("Set font stretech to Ultra Expanded") );
		stretchs_.insert( QFont::UltraExpanded, stretchUltraExpanded );
		stretchsgroup->addAction( stretchUltraExpanded );

		connect( stretchMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateFontStretchMenu() ));
		connect( stretchMenu, SIGNAL( triggered(QAction*) ),
			this, SLOT( changeFontStretch(QAction*) ));


		stretchMenu->addAction( stretchUltraCondensed );
		stretchMenu->addAction( stretchExtraCondensed );
		stretchMenu->addAction( stretchCondensed );
		stretchMenu->addAction( stretchSemiCondensed );
		stretchMenu->addSeparator();
		stretchMenu->addAction( stretchUnstretched );
		stretchMenu->addSeparator();
		stretchMenu->addAction( stretchSemiExpanded );
		stretchMenu->addAction( stretchExpanded );
		stretchMenu->addAction( stretchExtraExpanded );
		stretchMenu->addAction( stretchUltraExpanded );

		// -----------------------------------------------------
		// END: Stretch



		// COLOR
		// -----------------------------------------------------
		// Code for createn the color menu
		colorMenu = formatMenu->addMenu( tr("&Color") );
		colorsgroup = new QActionGroup( this );

		colorBlack = new QAction( tr("Blac&k"), this);
		colorBlack->setCheckable( true );
		colorBlack->setStatusTip( tr("Set font color to Black") );
		colors_.insert( colorBlack, new QColor(0,0,0) );
		colorsgroup->addAction( colorBlack );

		colorWhite = new QAction( tr("&White"), this);
		colorWhite->setCheckable( true );
		colorWhite->setStatusTip( tr("Set font color to White") );
		colors_.insert( colorWhite, new QColor(255,255,255) );
		colorsgroup->addAction( colorWhite );
		
		color10Gray = new QAction( tr("&10% Gray"), this);
		color10Gray->setCheckable( true );
		color10Gray->setStatusTip( tr("Set font color to 10% Gray") );
		colors_.insert( color10Gray, new QColor(25,25,25) );
		colorsgroup->addAction( color10Gray );

		color33Gray = new QAction( tr("&33% Gray"), this);
		color33Gray->setCheckable( true );
		color33Gray->setStatusTip( tr("Set font color to 33% Gray") );
		colors_.insert( color33Gray, new QColor(85,85,85) );
		colorsgroup->addAction( color33Gray );

		color50Gray = new QAction( tr("&50% Gray"), this);
		color50Gray->setCheckable( true );
		color50Gray->setStatusTip( tr("Set font color to 50% Gray") );
		colors_.insert( color50Gray, new QColor(128,128,128) );
		colorsgroup->addAction( color50Gray );

		color66Gray = new QAction( tr("&66% Gray"), this);
		color66Gray->setCheckable( true );
		color66Gray->setStatusTip( tr("Set font color to 66% Gray") );
		colors_.insert( color66Gray, new QColor(170,170,170) );
		colorsgroup->addAction( color66Gray );

		color90Gray = new QAction( tr("&90% Gray"), this);
		color90Gray->setCheckable( true );
		color90Gray->setStatusTip( tr("Set font color to 90% Gray") );
		colors_.insert( color90Gray, new QColor(230,230,230) );
		colorsgroup->addAction( color90Gray );

		colorRed = new QAction( tr("&Red"), this);
		colorRed->setCheckable( true );
		colorRed->setStatusTip( tr("Set font color to Red") );
		colors_.insert( colorRed, new QColor(255,0,0) );
		colorsgroup->addAction( colorRed );

		colorGreen = new QAction( tr("&Green"), this);
		colorGreen->setCheckable( true );
		colorGreen->setStatusTip( tr("Set font color to Green") );
		colors_.insert( colorGreen, new QColor(0,255,0) );
		colorsgroup->addAction( colorGreen );

		colorBlue = new QAction( tr("&Blue"), this);
		colorBlue->setCheckable( true );
		colorBlue->setStatusTip( tr("Set font color to Blue") );
		colors_.insert( colorBlue, new QColor(0,0,255) );
		colorsgroup->addAction( colorBlue );

		colorCyan = new QAction( tr("&Cyan"), this);
		colorCyan->setCheckable( true );
		colorCyan->setStatusTip( tr("Set font color to Cyan") );
		colors_.insert( colorCyan, new QColor(0,255,255) );
		colorsgroup->addAction( colorCyan );

		colorMagenta = new QAction( tr("&Magenta"), this);
		colorMagenta->setCheckable( true );
		colorMagenta->setStatusTip( tr("Set font color to Magenta") );
		colors_.insert( colorMagenta, new QColor(255,0,255) );
		colorsgroup->addAction( colorMagenta );

		colorYellow = new QAction( tr("&Yellow"), this);
		colorYellow->setCheckable( true );
		colorYellow->setStatusTip( tr("Set font color to Yellow") );
		colors_.insert( colorYellow, new QColor(255,255,0) );
		colorsgroup->addAction( colorYellow );

		colorOther = new QAction( tr("&Other..."), this);
		colorOther->setCheckable( true );
		colorOther->setStatusTip( tr("Select font color") );


		connect( colorMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateFontColorMenu() ));
		connect( colorMenu, SIGNAL( triggered(QAction*) ),
			this, SLOT( changeFontColor(QAction*) ));


		colorMenu->addAction( colorBlack );
		colorMenu->addAction( colorWhite );
		colorMenu->addAction( color10Gray );
		colorMenu->addAction( color33Gray );
		colorMenu->addAction( color50Gray );
		colorMenu->addAction( color66Gray );
		colorMenu->addAction( color90Gray );
		colorMenu->addAction( colorRed );
		colorMenu->addAction( colorGreen );
		colorMenu->addAction( colorBlue );
		colorMenu->addAction( colorCyan );
		colorMenu->addAction( colorMagenta );
		colorMenu->addAction( colorYellow );
		colorMenu->addSeparator();
		colorMenu->addAction( colorOther );
	
		// -----------------------------------------------------
		// END: Color


		// Extra meny for choosing font from a dialog, because all fonts 
		// can't be displayed in the font menu
		chooseFont = new QAction( tr("C&hoose Font..."), this);
		chooseFont->setCheckable( false );
		chooseFont->setStatusTip( tr("Select font") );
		connect(chooseFont, SIGNAL(triggered()), this, SLOT(selectFont()));
		formatMenu->addAction( chooseFont );


		// ALIGNMENT
		// -----------------------------------------------------
		// Code for createn the alignment menus
		formatMenu->addSeparator();

		alignmentMenu = formatMenu->addMenu( tr("&Alignment") );
		alignmentsgroup = new QActionGroup( this );
		verticalAlignmentMenu = formatMenu->addMenu( tr("&Vertical Alignment") );
		verticalAlignmentsgroup = new QActionGroup( this );

		alignmentLeft = new QAction( tr("&Left"), this);
		alignmentLeft->setCheckable( true );
		alignmentLeft->setStatusTip( tr("Set text alignment to Left") );
		alignments_.insert( Qt::AlignLeft, alignmentLeft );
		alignmentsgroup->addAction( alignmentLeft );

		alignmentRight = new QAction( tr("&Right"), this);
		alignmentRight->setCheckable( true );
		alignmentRight->setStatusTip( tr("Set text alignment to Right") );
		alignments_.insert( Qt::AlignRight, alignmentRight );
		alignmentsgroup->addAction( alignmentRight );

		alignmentCenter = new QAction( tr("&Center"), this);
		alignmentCenter->setCheckable( true );
		alignmentCenter->setStatusTip( tr("Set text alignment to Center") );
		alignments_.insert( Qt::AlignHCenter, alignmentCenter );
		alignmentsgroup->addAction( alignmentCenter );

		alignmentJustify = new QAction( tr("&Justify"), this);
		alignmentJustify->setCheckable( true );
		alignmentJustify->setStatusTip( tr("Set text alignment to Justify") );
		alignments_.insert( Qt::AlignJustify, alignmentJustify );
		alignmentsgroup->addAction( alignmentJustify );

		verticalNormal = new QAction( tr("&Normal/Baseline"), this);
		verticalNormal->setCheckable( true );
		verticalNormal->setStatusTip( tr("Set vertical text alignment to Normal") );
		verticals_.insert( QTextCharFormat::AlignNormal, verticalNormal );
		verticalAlignmentsgroup->addAction( verticalNormal );

		verticalSub = new QAction( tr("&Subscript"), this);
		verticalSub->setCheckable( true );
		verticalSub->setStatusTip( tr("Set vertical text alignment to Subscript") );
		verticals_.insert( QTextCharFormat::AlignSubScript, verticalSub );
		verticalAlignmentsgroup->addAction( verticalSub );

		verticalSuper = new QAction( tr("S&uperscript"), this);
		verticalSuper->setCheckable( true );
		verticalSuper->setStatusTip( tr("Set vertical text alignment to Superscript") );
		verticals_.insert( QTextCharFormat::AlignSuperScript, verticalSuper );
		verticalAlignmentsgroup->addAction( verticalSuper );

		connect( alignmentMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateTextAlignmentMenu() ));
		connect( alignmentMenu, SIGNAL( triggered(QAction*) ),
			this, SLOT( changeTextAlignment(QAction*) ));
		connect( verticalAlignmentMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateVerticalAlignmentMenu() ));
		connect( verticalAlignmentMenu, SIGNAL( triggered(QAction*) ),
			this, SLOT( changeVerticalAlignment(QAction*) ));


		alignmentMenu->addAction( alignmentLeft );
		alignmentMenu->addAction( alignmentRight );
		alignmentMenu->addAction( alignmentCenter );
		alignmentMenu->addAction( alignmentJustify );
		verticalAlignmentMenu->addAction( verticalNormal );
		verticalAlignmentMenu->addAction( verticalSub );
		verticalAlignmentMenu->addAction( verticalSuper );

		// -----------------------------------------------------
		// END: Text Alignment


		// BORDER
		// -----------------------------------------------------
		// Code for createn the border menu
		formatMenu->addSeparator();
		borderMenu = formatMenu->addMenu( tr("&Border") );
		bordersgroup = new QActionGroup( this );
		
		int borderSizes[] = { 0,1,2,3,4,5,6,7,8,9,10 };
		for( int i = 0; i < sizeof(borderSizes)/sizeof(int); i++ )
		{
			QString name;
			name.setNum( borderSizes[i] );
			QAction *tmp = new QAction( name, this );
			tmp->setCheckable( true );
			borders_.insert( borderSizes[i], tmp );
			borderMenu->addAction( tmp );
			bordersgroup->addAction( tmp );
		}


		connect( borderMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateBorderMenu() ));
		connect( borderMenu, SIGNAL( triggered(QAction*) ),
			this, SLOT( changeBorder(QAction*) ));


		borderMenu->addSeparator();
		borderOther = new QAction( "&Other...", this );
		borderOther->setCheckable( true );
		borderMenu->addAction( borderOther );

		// -----------------------------------------------------
		// END: Border


		// MARGIN
		// -----------------------------------------------------
		// Code for createn the margin menu
		marginMenu = formatMenu->addMenu( tr("&Margin") );
		marginsgroup = new QActionGroup( this );

		int marginSizes[] = { 0,1,2,3,4,5,6,7,8,9,10,15,20,25,30 };
		for( int i = 0; i < sizeof(marginSizes)/sizeof(int); i++ )
		{
			QString name;
			name.setNum( marginSizes[i] );
			QAction *tmp = new QAction( name, this );
			tmp->setCheckable( true );
			margins_.insert( marginSizes[i], tmp );
			marginMenu->addAction( tmp );
			marginsgroup->addAction( tmp );
		}


		connect( marginMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateMarginMenu() ));
		connect( marginMenu, SIGNAL( triggered(QAction*) ),
			this, SLOT( changeMargin(QAction*) ));


		marginMenu->addSeparator();
		marginOther = new QAction( "&Other...", this );
		marginOther->setCheckable( true );
		marginMenu->addAction( marginOther );

		// -----------------------------------------------------
		// END: Margin


		// PADDING
		// -----------------------------------------------------
		// Code for createn the padding menu
		paddingMenu = formatMenu->addMenu( tr("&Padding") );
		paddingsgroup = new QActionGroup( this );

		int paddingSizes[] = { 0,2,4,6,8,10,15 };
		for( int i = 0; i < sizeof(paddingSizes)/sizeof(int); i++ )
		{
			QString name;
			name.setNum( paddingSizes[i] );
			QAction *tmp = new QAction( name, this );
			tmp->setCheckable( true );
			paddings_.insert( paddingSizes[i], tmp );
			paddingMenu->addAction( tmp );
			paddingsgroup->addAction( tmp );
		}


		connect( paddingMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updatePaddingMenu() ));
		connect( paddingMenu, SIGNAL( triggered(QAction*) ),
			this, SLOT( changePadding(QAction*) ));


		paddingMenu->addSeparator();
		paddingOther = new QAction( "&Other...", this );
		paddingOther->setCheckable( true );
		paddingMenu->addAction( paddingOther );

		// -----------------------------------------------------
		// END: Padding




		// 2005-10-07 AF, Porting, replaced this
		//QAction *groupAction = new QAction("Group Cells", "&Group cells", CTRL+SHIFT+Key_G, this, "groupcells");
		//QObject::connect(groupAction, SIGNAL(activated()), this, SLOT(groupCellsAction()));
		groupAction = new QAction( tr("&Groupcell"), this);
		groupAction->setShortcut( tr("Ctrl+Shift+G") );
		groupAction->setStatusTip( tr("Groupcell") );
		connect(groupAction, SIGNAL(triggered()), this, SLOT(groupCellsAction()));

		// 2005-10-07 AF, Porting, new code for creating menu
		formatMenu->addSeparator();
		formatMenu->addAction( groupAction );


		/* Old menu code //AF
		menuBar()->insertItem("&Format", formatMenu);
		stylesgroup->addTo(formatMenu);
		groupAction->addTo(formatMenu);
		inputAction->addTo(formatMenu);
		formatMenu->insertSeparator(1);
		*/

		connect(formatMenu, SIGNAL(aboutToShow()),
			this, SLOT(updateStyleMenu()));
		connect( formatMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateMenus() ));
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-18
	 *
	 * \brief Method for creating insert nemu.
	 */
	void NotebookWindow::createInsertMenu()
	{
		// IMAGE
		insertImageAction = new QAction( tr("&Image"), this );
		insertImageAction->setShortcut( tr("Ctrl+Shift+M") );
		insertImageAction->setStatusTip( tr("Insert a image into the cell") );
		connect( insertImageAction, SIGNAL( triggered() ),
			this, SLOT( insertImage() ));

		// LINK
		insertLinkAction = new QAction( tr("&Link"), this );
		insertLinkAction->setShortcut( tr("Ctrl+Shift+L") );
		insertLinkAction->setStatusTip( tr("Insert a link to the selected text") );
		connect( insertLinkAction, SIGNAL( triggered() ),
			this, SLOT( insertLink() ));
		
		// MENU
		insertMenu = menuBar()->addMenu( tr("&Insert") );
		insertMenu->addAction( insertImageAction );
		insertMenu->addAction( insertLinkAction );

		connect( insertMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateMenus() ));
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2006-01-27
	 *
	 * \brief Method for creating window nemu.
	 */
	void NotebookWindow::createWindowMenu()
	{
		windowMenu = menuBar()->addMenu( tr("&Window") );

		connect( windowMenu, SIGNAL( triggered(QAction *) ),
			this, SLOT( changeWindow(QAction *) ));
		connect( windowMenu, SIGNAL( aboutToShow() ),
			this, SLOT( updateWindowMenu() ));
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-10-07 (update)
	 *
	 * \brief Method for creating about nemu.
	 *
	 * Remade the function when porting to QT4.
	 */
	void NotebookWindow::createAboutMenu()
	{
		// 2005-10-07 AF, Porting, replaced this
		//QAction *aboutAction = new QAction("About", "&About", 0, this, "about");
		//QObject::connect(aboutAction, SIGNAL(activated()), this, SLOT(aboutQTNotebook()));
		aboutAction = new QAction( tr("&About"), this);
		aboutAction->setStatusTip( tr("Display OMNotebook's About dialog") );
		connect(aboutAction, SIGNAL(triggered()), this, SLOT(aboutQTNotebook()));

		// 2005-10-07 AF, Porting, new code for creating menu
		aboutMenu = menuBar()->addMenu( tr("&Help") );
		aboutMenu->addAction( aboutAction );	

		/* Old menu code //AF
		aboutMenu = new Q3PopupMenu(this);
		menuBar()->insertItem("&Help", aboutMenu);
		aboutAction->addTo(aboutMenu);
		*/
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-11
	 *
	 * \brief Check if the currentCell is editable
	 */
	bool NotebookWindow::cellEditable()
	{
		return subject_->getCursor()->currentCell()->isEditable();
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	void NotebookWindow::createSavingTimer()
	{
		//start a saving timer.
		savingTimer_ = new QTimer();	    
		savingTimer_->start(30000);

		connect(savingTimer_, SIGNAL(timeout()),
			this, SLOT(save()));
	}




	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 * \date 2005-11-15 (update)
	 *
	 * \brief Method for enabling/disabling the menus depended on what have
	 * been selected in the mainwindow
	 *
	 * 2005-11-15 AF, implemented the function
	 */
	void NotebookWindow::updateMenus()
	{
		bool editable = false;


		if( cellEditable() || 
			(subject_->getCursor()->currentCell()->hasChilds() &&
			subject_->getCursor()->currentCell()->isClosed() &&
			subject_->getCursor()->currentCell()->child()->isEditable()) )
		{
			editable = true;
		}

		styleMenu->setEnabled( editable );
		fontMenu->setEnabled( editable );
		faceMenu->setEnabled( editable );
		sizeMenu->setEnabled( editable );
		stretchMenu->setEnabled( editable );
		colorMenu->setEnabled( editable );
		alignmentMenu->setEnabled( editable );
		verticalAlignmentMenu->setEnabled( editable );
		borderMenu->setEnabled( editable );
		marginMenu->setEnabled( editable );
		paddingMenu->setEnabled( editable );

		chooseFont->setEnabled( editable );
		insertImageAction->setEnabled( editable );
		insertLinkAction->setEnabled( editable );
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernstr�m
	 * \date 2005-11-02 (update)
	 *
	 * \brief Method for unpdating the style menu
	 *
	 * 2005-10-28 AF, changed style from QString to CellStyle.
	 * 2005-11-02 AF, changed from '->toggle()' to '->setChevked(true)'
	 */
	void NotebookWindow::updateStyleMenu()
	{
		CellStyle style = subject_->getCursor()->currentCell()->style();      
		map<QString, QAction*>::iterator cs = styles_.find(style.name());

		if(cs != styles_.end())
		{
			(*cs).second->setChecked( true );
		}
		else
		{
			qDebug("No styles found");
			cs = styles_.begin();
			for(;cs != styles_.end(); ++cs)
			{
				(*cs).second->setChecked(false);
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-02
	 *
	 * \brief Method for updating the edit menu
	 */
	void NotebookWindow::updateEditMenu()
	{
		showExprAction->setChecked( subject_->getCursor()->currentCell()->isViewExpression() );
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-03
	 *
	 * \brief Method for updating the font menu
	 */
	void NotebookWindow::updateFontMenu()
	{
		QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
		if( !cursor.isNull() )
		{
			QString family = cursor.charFormat().fontFamily();
			if( fonts_.contains( family ))
			{
				fonts_[family]->setChecked( true );
			}
			else
			{
				cout << "No font found" << endl;
				QHash<QString, QAction*>::iterator f_iter = fonts_.begin();
				while( f_iter != fonts_.end() )
				{
					f_iter.value()->setChecked( false );
					++f_iter;
				}
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-03
	 *
	 * \brief Method for updating the face menu
	 */
	void NotebookWindow::updateFontFaceMenu()
	{
		QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
		if( !cursor.isNull() )
		{
			if( cursor.charFormat().fontWeight() > QFont::Normal )
				faceBold->setChecked( true );
			else
				faceBold->setChecked( false );

			if( cursor.charFormat().fontItalic() )
				faceItalic->setChecked( true );
			else
				faceItalic->setChecked( false );

			if( cursor.charFormat().fontUnderline() )
				faceUnderline->setChecked( true );
			else
				faceUnderline->setChecked( false );
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-04
	 *
	 * \brief Method for updating the size menu
	 */
	void NotebookWindow::updateFontSizeMenu()
	{
		QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
		if( !cursor.isNull() )
		{
			int size = cursor.charFormat().font().pointSize();
			if( size > 0 )
			{
				QString txt;
				txt.setNum( size );

				if( sizes_.contains( txt ))
				{
					sizes_[txt]->setChecked( true );
					sizeOther->setChecked( false );
				}
				else
				{
					cout << "No size found" << endl;
					sizeOther->setChecked( true );

					QHash<QString, QAction*>::iterator s_iter = sizes_.begin();
					while( s_iter != sizes_.end() )
					{
						s_iter.value()->setChecked( false );
						++s_iter;
					}
				}
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-04
	 *
	 * \brief Method for updating the stretch menu
	 */
	void NotebookWindow::updateFontStretchMenu()
	{
		QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
		if( !cursor.isNull() )
		{
			int stretch = cursor.charFormat().font().stretch();
			if( stretchs_.contains( stretch ))
				stretchs_[stretch]->setChecked( true );
			else
			{
				cout << "No stretch found" << endl;
				QHash<int, QAction*>::iterator s_iter = stretchs_.begin();
				while( s_iter != stretchs_.end() )
				{
					s_iter.value()->setChecked( false );
					++s_iter;
				}
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for updating the color menu
	 */
	void NotebookWindow::updateFontColorMenu()
	{
		QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
		if( !cursor.isNull() )
		{
			QColor color = cursor.charFormat().foreground().color();

			QHash<QAction*, QColor*>::iterator c_iter = colors_.begin();
			while( c_iter != colors_.end() )
			{
				if( (*c_iter.value()) == color )
				{
					c_iter.key()->setChecked( true );
					colorOther->setChecked( false );
					break;
				}
				else
					c_iter.key()->setChecked( false );

				++c_iter;
			}


			if( c_iter == colors_.end() )
				colorOther->setChecked( true );
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for updating the alignment menu
	 */
	void NotebookWindow::updateTextAlignmentMenu()
	{
		QTextEdit *editor = subject_->getCursor()->currentCell()->textEdit();

		if( editor )
		{
			int alignment = editor->alignment();
			if( alignments_.contains( alignment ))
				alignments_[alignment]->setChecked( true );
			else
			{
				cout << "No alignment found" << endl;
				QHash<int, QAction*>::iterator a_iter = alignments_.begin();
				while( a_iter != alignments_.end() )
				{
					a_iter.value()->setChecked( false );
					++a_iter;
				}
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for updating the vertical alignment menu
	 */
	void NotebookWindow::updateVerticalAlignmentMenu()
	{
		QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
		if( !cursor.isNull() )
		{
			int alignment = cursor.charFormat().verticalAlignment();
			if( verticals_.contains( alignment ))
				verticals_[alignment]->setChecked( true );
			else
			{
				cout << "No vertical alignment found" << endl;
				QHash<int, QAction*>::iterator v_iter = verticals_.begin();
				while( v_iter != verticals_.end() )
				{
					v_iter.value()->setChecked( false );
					++v_iter;
				}
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for updating the border menu
	 */
	void NotebookWindow::updateBorderMenu()
	{
		QTextEdit *editor = subject_->getCursor()->currentCell()->textEdit();

		if( editor )
		{
			int border = editor->document()->rootFrame()->frameFormat().border();
			if( borders_.contains( border ))
			{
				borders_[border]->setChecked( true );
				borderOther->setChecked( false );
			}
			else
			{
				cout << "No border found" << endl;
				borderOther->setChecked( true );

				QHash<int, QAction*>::iterator b_iter = borders_.begin();
				while( b_iter != borders_.end() )
				{
					b_iter.value()->setChecked( false );
					++b_iter;
				}
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for updating the margin menu
	 */
	void NotebookWindow::updateMarginMenu()
	{
		QTextEdit *editor = subject_->getCursor()->currentCell()->textEdit();

		if( editor )
		{
			int margin = editor->document()->rootFrame()->frameFormat().margin();
			if( margins_.contains( margin ))
			{
				margins_[margin]->setChecked( true );
				marginOther->setChecked( false );
			}
			else
			{
				cout << "No margin found" << endl;
				marginOther->setChecked( true );

				QHash<int, QAction*>::iterator m_iter = margins_.begin();
				while( m_iter != margins_.end() )
				{
					m_iter.value()->setChecked( false );
					++m_iter;
				}
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for updating the padding menu
	 */
	void NotebookWindow::updatePaddingMenu()
	{
		QTextEdit *editor = subject_->getCursor()->currentCell()->textEdit();

		if( editor )
		{
			int padding = editor->document()->rootFrame()->frameFormat().padding();
			if( paddings_.contains( padding ))
			{
				paddings_[padding]->setChecked( true );
				paddingOther->setChecked( false );
			}
			else
			{
				cout << "No padding found" << endl;
				paddingOther->setChecked( true );

				QHash<int, QAction*>::iterator p_iter = paddings_.begin();
				while( p_iter != paddings_.end() )
				{
					p_iter.value()->setChecked( false );
					++p_iter;
				}
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2006-01-27
	 *
	 * \brief Method for updating the window menu
	 */
	void NotebookWindow::updateWindowMenu()
	{
		// remove old windows
		windows_.clear();
		windowMenu->clear();

		// add new menu items
		vector<DocumentView *> windowViews = application()->documentViewList();
		vector<DocumentView *>::iterator v_iter = windowViews.begin();
		while( v_iter != windowViews.end() )
		{
			QString title = (*v_iter)->windowTitle();
			title.remove( "OMNotebook: " );

			QAction *action = new QAction( title, windowMenu );
			windows_[action] = (*v_iter);
			windowMenu->addAction( action );
			++v_iter;
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2006-01-17
	 *
	 * \brief Method for updateing the window title
	 */
	void NotebookWindow::updateWindowTitle()
	{
		// QT functionality to stripp the filepath and only keep
		// the filename.
		QString title = QFileInfo( subject_->getFilename() ).fileName();
		title.remove( "\n" );

		// if no name, set name to '(untitled)'
		if( title.isEmpty() )
			title = "(untitled)";
		
		title = QString( "OMNotebook: " ) + title;
		
		if( subject_->hasChanged() )
			title.append( "*" );

		setWindowTitle( title );
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernstr�m
	 *
	 */
	void NotebookWindow::keyPressEvent(QKeyEvent *event)
	{
		// 2006-01-30 AF, check if 'Alt+Enter'
		if( event->modifiers() == Qt::AltModifier )
		{
			if( event->key() == Qt::Key_Enter || 
				event->key() == Qt::Key_Return )
			{
				createNewCell();
			}
			else
				QMainWindow::keyPressEvent(event);
		}
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernstr�m
	 * \date 2005-11-22 (update)
	 *
	 * \brief Method for catching some keyevent, and given them 
	 * new functionality
	 *
	 * 2005-11-22 AF, Added support for deleting cells with 'DEL'
	 * key.
	 */
	void NotebookWindow::keyReleaseEvent(QKeyEvent *event)
	{
		// if Ctrl is pressed
		if(event->modifiers() == Qt::ControlModifier)
		{
			if(event->key() == Qt::Key_Up)
			{
				moveCursorUp();
				event->accept();
			}
			else if(event->key() == Qt::Key_Down)
			{
				moveCursorDown();
				event->accept();
			}
			else
				QMainWindow::keyReleaseEvent(event);
		}
		else
		{
			// 2005-11-22 AF, Support for deleting cells with 'DEL' key.
			if( event->key() == Qt::Key_Delete )
			{
				vector<Cell *> cells = subject_->getSelection();
				if( !cells.empty() )
				{
					subject_->cursorDeleteCell();
					event->setAccepted( true );
				}
				else
					QMainWindow::keyReleaseEvent(event);
			}
			else
				QMainWindow::keyReleaseEvent(event);
		}
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernstr�m
	 *
	 * \todo Fix the code, when the window dosen't have any file open,
	 * the command should create the new document, not this function //AF
	 */
	void NotebookWindow::newFile()
	{
		/*
		application()->commandCenter()->executeCommand(new NewFileCommand());

		closeFile();

		createSavingTimer();

		subject_ = new CellDocument(this);

		connect(subject_, SIGNAL(cursorChanged()),
		this, SLOT(setSelectedStyle()));

		setCentralWidget(subject_);

		subject_->show();
		*/

		// AF
		if( subject_->isOpen() )
		{
			// a file is open, open a new window with the new file //AF
			application()->commandCenter()->executeCommand(new OpenFileCommand(QString::null));
		}
		else
		{
			subject_ = new CellDocument(app_, QString::null);
			subject_->executeCommand(new NewFileCommand());
			subject_->attach(this);

			update();
		}
	}

	/*! 
	 * \author Ingemar Axelsson and Anders Fernstr�m
	 *
	 * \brief Open a file. Shows a file dialog.
	 */
	void NotebookWindow::openFile(const QString &filename)
	{      
		try
		{
			//Open a new document
			if(filename.isEmpty())
			{    
				//Show a dialog for choosing a file.
				filename_ = QFileDialog::getOpenFileName(
					this,
					"OMNotebook -- File Open",
					QString::null,
					"Notebooks (*.onb *.nb)" );
			}
			else
			{
				filename_ = filename;
			}

			if(!filename_.isEmpty())
			{
				application()->commandCenter()->executeCommand(new OpenFileCommand(filename_));
			}
			else
			{
				//Cancel pushed. Do nothing
			}
		}
		catch(exception &e)
		{
			QString msg = QString("In OpenFile(), Exception: \n") + e.what();
			QMessageBox::warning( 0, "Warning", msg, "OK" );
			openFile();
		}
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernstr�m
	 * 
	 */
	void NotebookWindow::closeFile()
	{
		// TODO: the function isn't used correctly, this funciton 
		// should also close the window, if it isn't the last window
		//subject_->executeCommand(new CloseFileCommand());
		
		close();

		//application()->

		// if(savingTimer_)
		//       {
		// 	 savingTimer_->stop();
		// 	 delete savingTimer_;
		//       }
		//delete subject_;
	}

	/*!
	 * \author Anders Fernstr�m
	 * \date 2006-01-19
	 *
	 * \brief Reimplemented closeEvent so all close event are handled 
	 * correctly. If the document is unsaved, the applicaiton will ask
	 * the user if he/she wants to save before closing the document.
	 */
	void NotebookWindow::closeEvent( QCloseEvent *event )
	{
		QString filename = QFileInfo( filename_ ).fileName();
		filename.remove( "\n" );

		// if no name, set name to '(untitled)'
		if( filename.isEmpty() )
			filename = "(untitled)";

		// if the document have been changed, ask if the
		// user wants to save the document
		while( subject_->hasChanged() )
		{
			int res = QMessageBox::question( this, "Document is unsaved",
				QString( "The document \"") + filename + 
					QString( "\" is unsaved, do you want to save the document" ),
				QMessageBox::Yes | QMessageBox::Default, 
				QMessageBox::No, QMessageBox::NoButton );

			if( res == QMessageBox::No )
				break;
			else
				save();
		}
	}

	/*! 
	 * \author Anders Fernstr�m and Ingemar Axelsson
	 *
	 * \brief display an ABOUT message box with information about
	 * OMNotebook.
	 */
	void NotebookWindow::aboutQTNotebook()
	{
		QString abouttext = QString("OMNotebook version 2.0 (for OpenModelica v1.3.1)\r\n") + 
			QString("Copyright 2004-2006, PELAB, Linkoping Univerity\r\n\r\n") + 
			QString("Created by Ingemar Axelsson (2004-2005) and Anders Fernstr�m (2005-2006), part of there final thesis.");

		QMessageBox::about( this, "OMNotebook", abouttext );
	}

	/*! 
	 * \author Anders Fernstr�m and Ingemar Axelsson
	 * \date 2005-09-30 (update)
	 * 
	 * \breif Save As function
	 *
	 * 2005-09-22 AF, added code for updating window title
	 * 2005-09-30 AF, add check for fileend when saving.
	 *
	 *
	 * \todo Some of this code should be moved to CellDocument
	 *  instead. The filename should be connected to the document, not
	 *  to the window for example.(Ingemar Axelsson)
	 */
	void NotebookWindow::saveas()
	{
		// open save as dialog
		QString filename = QFileDialog::getSaveFileName(
			this,
			"Choose a filename to save under",
			QString::null,
			"OpenModelica Notebooks (*.onb)");

		if(!filename.isEmpty())
		{
			// 2005-09-30 AF, add check for fileend when saving.
			if( !filename.endsWith( ".onb", Qt::CaseInsensitive ) )
			{
				qDebug( ".onb not found" );
				filename.append( ".onb" );
			}

			statusBar()->showMessage("Saving file");
			application()->commandCenter()->executeCommand(
				new SaveDocumentCommand(subject_, filename));

			filename_ = filename;
			statusBar()->showMessage("Ready");

			// 2005-09-22 AF, update window title
			updateWindowTitle();
		}
	}

	/*!
	 * \author Anders Fernstr�m and Ingemar Axelsson
	 *
	 * Added a check that controlls if the user have saved before, 
	 * if not the function saveas should be used insted. //AF
	 */
	void NotebookWindow::save()
	{
		// Added a check to see if the document have been saved before,
		// if the document havn't been saved before - call saveas() insted.
		if( !subject_->isSaved() )
		{
			saveas();
		}
		else
		{
			statusBar()->showMessage("Saving file");
			application()->commandCenter()->executeCommand(new SaveDocumentCommand(subject_));
			statusBar()->showMessage("Ready");

			updateWindowTitle();
		}
	}

	/*!
	 * \author Anders Fernstr�m
	 * \date 2006-01-18
	 *
	 * \brief Quit OMNotebook
	 */
	void NotebookWindow::quitOMNotebook()
	{
		qApp->closeAllWindows();
	}

	/*!
	 * \author Anders Fernstr�m
	 * \date 2005-12-19
	 *
	 * \brief Open printdialog and print the document
	 */
	void NotebookWindow::print()
	{
		QPrinter printer( QPrinter::HighResolution );
	    //printer.setFullPage( true );
		printer.setColorMode( QPrinter::GrayScale );

		QPrintDialog *dlg = new QPrintDialog(&printer, this);
		if( dlg->exec() == QDialog::Accepted )
		{
			application()->commandCenter()->executeCommand(
				new PrintDocumentCommand(subject_, &printer));

			//currentEditor->document()->print(&printer);
		}
		delete dlg;
	}

	/*!
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for changing the font
	 */
	void NotebookWindow::selectFont()
	{
		if( !cellEditable() )
			return;

	    bool ok;
		QFont font = QFontDialog::getFont(&ok, QFont("Times New Roman", 12), this);
		
		if( ok ) 
		{
			subject_->textcursorChangeFontFamily( font.family() );
			subject_->textcursorChangeFontSize( font.pointSize() );

			// s�tt f�rst plain text
			subject_->textcursorChangeFontFace( 0 );

			if( font.underline() )
				subject_->textcursorChangeFontFace( 3 );

			if( font.italic() )
				subject_->textcursorChangeFontFace( 2 );

			if( font.weight() > QFont::Normal )
				subject_->textcursorChangeFontFace( 1 );

			if( font.strikeOut() )
				subject_->textcursorChangeFontFace( 4 );
		} 
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	void NotebookWindow::changeStyle(QAction *action)
	{
		// 2005-10-28 changed here because style changed from QString 
		// to CellStyle /AF
		//subject_->cursorChangeStyle(action->text());

		Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" );
		CellStyle style = sheet->getStyle( action->text() );

		if( style.name() != "null" )
			subject_->cursorChangeStyle( style );
		else
		{
			// 2006-01-30 AF, add message box
			QString msg = "Not a valid style name: " + action->text();
			QMessageBox::warning( 0, "Warning", msg, "OK" );			
		}
	}

	/*! 
	 * \author Ingemar Axelsson (and Anders Fernstr�m)
	 */
	void NotebookWindow::changeStyle()
	{ 
		// 2005-10-28 changed in the funtion here because style changed 
		// from QString  to CellStyle /AF
		map<QString, QAction*>::iterator cs = styles_.begin();
		Stylesheet *sheet = Stylesheet::instance( "stylesheet.xml" ); //AF
		for(;cs != styles_.end(); ++cs)
		{
			if( (*cs).second->isChecked( ))
			{
				// look up style /AF
				CellStyle style = sheet->getStyle( (*cs).first );
				if( style.name() != "null" )
					subject_->cursorChangeStyle( style );
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-03
	 *
	 * \brief Method for changing font on selected text
	 */
	void NotebookWindow::changeFont(QAction *action)
	{
		if( !cellEditable() )
			return;

		subject_->textcursorChangeFontFamily( action->text() );
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-03
	 *
	 * \brief Method for changing face on selected text
	 */
	void NotebookWindow::changeFontFace( QAction *action )
	{
		if( !cellEditable() )
			return;

		if( action->text() == "&Plain" )
			subject_->textcursorChangeFontFace( 0 );
		else if( action->text() == "&Bold" )
			subject_->textcursorChangeFontFace( 1 );
		else if( action->text() == "&Italic" )
			subject_->textcursorChangeFontFace( 2 );
		else if( action->text() == "&Underline" )
			subject_->textcursorChangeFontFace( 3 );
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-04
	 *
	 * \brief Method for changing size on selected text
	 */
	void NotebookWindow::changeFontSize( QAction *action )
	{
		if( !cellEditable() )
			return;

		if( action->text() == "&Smaller" )
		{ // SMALLER
			QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
			if( !cursor.isNull() )
			{
				int size = cursor.charFormat().font().pointSize();
				if( size < 2 )
					size = 2;

				subject_->textcursorChangeFontSize( size - 1 );
			}
		}
		else if( action->text() == "&Larger" )
		{ // LARGER
			QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
			if( !cursor.isNull() )
			{
				int size = cursor.charFormat().fontPointSize();
				subject_->textcursorChangeFontSize( size + 1 ); 
			}

		}
		else if( action->text() == "&Other..." )
		{ // OTHER
			OtherDlg other(this, 6, 200);
			if( QDialog::Accepted == other.exec() )
			{
				int size = other.value();
				if( size > 0 )
					subject_->textcursorChangeFontSize( size );
				else
				{
					// 2006-01-30 AF, add message box
					QString msg = "Not a value between 6 and 200";
					QMessageBox::warning( 0, "Warning", msg, "OK" );
				}
			}
		}
		else
		{ // MISC
			bool ok;
			int size = action->text().toInt(&ok);

			if( ok )
				subject_->textcursorChangeFontSize( size );
			else
			{
				// 2006-01-30 AF, add message box
				QString msg = "Not a correct font size";
				QMessageBox::warning( 0, "Warning", msg, "OK" );
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-04
	 *
	 * \brief Method for changing stretch on selected text
	 */
	void NotebookWindow::changeFontStretch( QAction *action )
	{
		if( !cellEditable() )
			return;

		if( action->text() == "U&ltra Condensed" )
			subject_->textcursorChangeFontStretch( QFont::UltraCondensed );
		else if( action->text() == "E&xtra Condensed" )
			subject_->textcursorChangeFontStretch( QFont::ExtraCondensed );
		else if( action->text() == "&Condensed" )
			subject_->textcursorChangeFontStretch( QFont::Condensed );
		else if( action->text() == "S&emi Condensed" )
			subject_->textcursorChangeFontStretch( QFont::SemiCondensed );
		else if( action->text() == "&Unstretched" )
			subject_->textcursorChangeFontStretch( QFont::Unstretched );
		else if( action->text() == "&Semi Expanded" )
			subject_->textcursorChangeFontStretch( QFont::SemiExpanded );
		else if( action->text() == "&Expanded" )
			subject_->textcursorChangeFontStretch( QFont::Expanded );
		else if( action->text() == "Ex&tra Expanded" )
			subject_->textcursorChangeFontStretch( QFont::ExtraExpanded );
		else if( action->text() == "Ult&ra Expanded" )
			subject_->textcursorChangeFontStretch( QFont::UltraExpanded );	
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for changing color on selected text
	 */
	void NotebookWindow::changeFontColor( QAction *action )
	{
		if( !cellEditable() )
			return;

		if( colors_.contains( action ))
		{
			subject_->textcursorChangeFontColor( (*colors_[action]) );
		}
		else
		{
			QColor color;
			QTextCursor cursor( subject_->getCursor()->currentCell()->textCursor() );
			if( !cursor.isNull() )
				color = cursor.charFormat().foreground().color();
			else
				color = Qt::black;

            QColor newColor = QColorDialog::getColor( color, this );
			if( newColor.isValid() )
				subject_->textcursorChangeFontColor( newColor );
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for changing alignment on selected paragraf
	 */
	void NotebookWindow::changeTextAlignment( QAction *action )
	{
		if( !cellEditable() )
			return;

		QHash<int, QAction*>::iterator a_iter = alignments_.begin();
		while( a_iter != alignments_.end() )
		{
			if( a_iter.value() == action )
			{
				subject_->textcursorChangeTextAlignment( a_iter.key() );
				break;
			}

			++a_iter;
		}

		if( a_iter == alignments_.end() )
		{
			// 2006-01-30 AF, add message box
			QString msg = "Unable to find the correct alignment";
			QMessageBox::warning( 0, "Warning", msg, "OK" );
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for changing vertical alignment on selected text
	 */
	void NotebookWindow::changeVerticalAlignment( QAction *action )
	{
		if( !cellEditable() )
			return;

		QHash<int, QAction*>::iterator v_iter = verticals_.begin();
		while( v_iter != verticals_.end() )
		{
			if( v_iter.value() == action )
			{
				subject_->textcursorChangeVerticalAlignment( v_iter.key() );
				break;
			}

			++v_iter;
		}

		if( v_iter == verticals_.end() )
		{
			// 2006-01-30 AF, add message box
			QString msg = "Unable to find the correct vertical alignment";
			QMessageBox::warning( 0, "Warning", msg, "OK" );
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for changing border on selected cell
	 */
	void NotebookWindow::changeBorder( QAction *action )
	{
		if( !cellEditable() )
			return;

		if( action->text() == "&Other..." )
		{
			OtherDlg other(this, 0, 30);
			if( QDialog::Accepted == other.exec() )
			{
				int border = other.value();
				if( border > 0 )
					subject_->textcursorChangeBorder( border );
				else
				{
					// 2006-01-30 AF, add message box
					QString msg = "Not a value between 0 and 30";
					QMessageBox::warning( 0, "Warning", msg, "OK" );
				}
			}
		}
		else
		{
			bool ok;
			int border = action->text().toInt( &ok );

			if( ok )
				subject_->textcursorChangeBorder( border );
			else
			{
				// 2006-01-30 AF, add message box
				QString msg = "Error converting QString to Int (border)";
				QMessageBox::warning( 0, "Warning", msg, "OK" );
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for changing margin on selected cell
	 */
	void NotebookWindow::changeMargin( QAction *action )
	{
		if( !cellEditable() )
			return;

		if( action->text() == "&Other..." )
		{
			OtherDlg other(this, 0, 80);
			if( QDialog::Accepted == other.exec() )
			{
				int margin = other.value();
				if( margin > 0 )
					subject_->textcursorChangeMargin( margin );
				else
				{
					// 2006-01-30 AF, add message box
					QString msg = "Not a value between 0 and 80.";
					QMessageBox::warning( 0, "Warning", msg, "OK" );
				}
			}
		}
		else
		{
			bool ok;
			int margin = action->text().toInt( &ok );

			if( ok )
				subject_->textcursorChangeMargin( margin );
			else
			{
				// 2006-01-30 AF, add message box
				QString msg = "Error converting QString to Int (margin)";
				QMessageBox::warning( 0, "Warning", msg, "OK" );
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-07
	 *
	 * \brief Method for changing padding on selected cell
	 */
	void NotebookWindow::changePadding( QAction *action )
	{
		if( !cellEditable() )
			return;

		if( action->text() == "&Other..." )
		{
			OtherDlg other(this, 0, 60);
			if( QDialog::Accepted == other.exec() )
			{
				int padding = other.value();
				if( padding > 0 )
					subject_->textcursorChangePadding( padding );
				else
				{
					// 2006-01-30 AF, add message box
					QString msg = "Not a value between 0 and 60.";
					QMessageBox::warning( 0, "Warning", msg, "OK" );
				}
			}
		}
		else
		{
			bool ok;
			int padding = action->text().toInt( &ok );

			if( ok )
				subject_->textcursorChangePadding( padding );
			else
			{
				// 2006-01-30 AF, add message box
				QString msg = "Error converting QString to Int (padding)";
				QMessageBox::warning( 0, "Warning", msg, "OK" );
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2006-01-27
	 *
	 * \brief Method for changing the current notebook window
	 */
	void NotebookWindow::changeWindow(QAction *action)
	{
		if( !windows_[action]->isActiveWindow() )
			windows_[action]->activateWindow();
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-18
	 *
	 * \brief Method for inserting an image into the cell
	 */
	void NotebookWindow::insertImage()
	{
		if( !cellEditable() )
			return;

		QString imageformat = "Images (";
		QList<QByteArray> list = QImageReader::supportedImageFormats();
		for( int i = 0; i < list.size(); ++i )
			imageformat += QString("*.") + QString(list.at(i)) + " ";
		imageformat += ")";

		QString filepath = QFileDialog::getOpenFileName(
			this, "Insert Image - Select Image", QString::null,
			imageformat );

		if( !filepath.isNull() )
		{
			QImage image( filepath );
			if( !image.isNull() )
			{
				ImageSizeDlg imageSize( this, &image );
				if( QDialog::Accepted == imageSize.exec() )
				{
					QSize size = imageSize.value();
					if( size.isValid() )
						subject_->textcursorInsertImage( filepath, size );
					else
						cout << "Not a valid image size" << endl;
				}
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-12-05
	 *
	 * \brief Method for inserting an link to the selected cell
	 */
	void NotebookWindow::insertLink()
	{
		if( !cellEditable() )
			return;

		// check if text is selected
		QTextCursor cursor = subject_->getCursor()->currentCell()->textCursor();
		if( !cursor.isNull() )
		{
			if( cursor.hasSelection() )
			{
				QString filepath = QFileDialog::getOpenFileName(
				this, "Insert Link - Select Document", QString::null,
				"Notebooks (*.onb *.nb)" );

				if( !filepath.isNull() )
					subject_->textcursorInsertLink( filepath );
			}
			else
			{
				QMessageBox::warning( this, "- No text is selected -", 
					"A text that should make up the link, must be selected", 
					"OK" );
			}
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-12-01
	 *
	 * \brief Method for opening an old file, saved with OMNotebook (QT3)
	 */
	void NotebookWindow::openOldFile()
	{
		try
		{
			QString filename = QFileDialog::getOpenFileName(
				this,
				"OMNotebook -- Open old OMNotebook file",
				QString::null,
				"Old OMNotebook (*.xml)" );

			if( !filename.isEmpty() )
			{
				application()->commandCenter()->executeCommand(
					new OpenOldFileCommand( filename, READMODE_OLD ));
			}
		}
		catch( exception &e )
		{
			QString msg = QString("In NotebookWindow(), Exception:\r\n") + e.what();
			QMessageBox::warning( 0, "Warning", msg, "OK" );
			openOldFile();
		}
	}

	/*! 
	 * \author Anders Fernstr�m
	 * \date 2005-11-21
	 *
	 * \brief Method for exporting the document content to a file with
	 * pure text only
	 */
	void NotebookWindow::pureText()
	{
		QString filename = QFileDialog::getSaveFileName(
			this,
			"Choose a filename to export text to",
			QString::null,
			"Textfile (*.txt)");

		if( !filename.isEmpty() )
		{
			if( !filename.endsWith( ".txt", Qt::CaseInsensitive ) )
			{
				qDebug( ".txt not found" );
				filename.append( ".txt" );
			}

			application()->commandCenter()->executeCommand(
				new ExportToPureText(subject_, filename) );
		}
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	void NotebookWindow::createNewCell()
	{
		subject_->cursorAddCell();
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	void NotebookWindow::deleteCurrentCell()
	{
		subject_->cursorDeleteCell();
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	void NotebookWindow::cutCell()
	{
		subject_->cursorCutCell();
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	void NotebookWindow::copyCell()
	{
		subject_->cursorCopyCell();
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	void NotebookWindow::pasteCell()
	{
		subject_->cursorPasteCell();
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	void NotebookWindow::moveCursorDown()
	{
		subject_->cursorStepDown();
	}

	/*! 
	 * \author Ingemar Axelsson
	 */
	void NotebookWindow::moveCursorUp()
	{
		subject_->cursorStepUp();
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernstr�m
	 * \date 2005-11-29 (update)
	 *
	 * 2005-11-29 AF, addad call to updateScrollArea, so the scrollarea
	 * are updated when new cell is added.
	 */
	void NotebookWindow::groupCellsAction()
	{
		subject_->executeCommand(new MakeGroupCellCommand());
		subject_->updateScrollArea();
	}

	/*!
	 * \author Ingemar Axelsson and Anders Fernstr�m
	 * \date 2005-11-29 (update)
	 *
	 * 2005-11-29 AF, addad call to updateScrollArea, so the scrollarea
	 * are updated when new cell is added.
	 */
	void NotebookWindow::inputCellsAction()
	{
		subject_->executeCommand(new CreateNewCellCommand("Input"));
		subject_->updateScrollArea();
	}
	
	








	// ***************************************************************



	

	

	


}
