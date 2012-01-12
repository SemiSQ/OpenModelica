/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�pings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */

// REMADE LARGE PART OF THIS CLASS 2005-11-30 /AF

/*!
* \file xmlparser
.cpp
* \author Anders Fernstrom (and Ingemar Axelsson)
* \date 2005-11-30
*
* \brief Remake this class to work with the specified xml format that
* document are to be saved in. The old file have been renamed to
* 'xmlparser.cpp.old' /AF
*/


//STD Headers
#include <iostream>
#include <exception>
#include <stdexcept>
#include <string>
#include <typeinfo>

//QT Headers
#include <QtCore/QBuffer>
#include <QtCore/QFile>
#include <QtGui/QApplication>
#include <QtXml/QDomNode>
#include <QSettings>

//IAEX Headers
#include "xmlparser.h"
#include "factory.h"
#include "inputcell.h"
#include "textcell.h"
#include "celldocument.h"
#include "graphcell.h"
#include <QMessageBox>
#include <QPushButton>

using namespace std;

namespace IAEX
{
  /*!
  * \class XMLParser
  * \author Anders Fernstrom (and Ingemar Axelsson)
  *
  * \brief Open an XML file and read the content. The xmlparser support
  * two different read modes:
  * READMODE_NORMAL  : Read the xml file normaly
  * READMODE_OLD    : Read the xml file accordantly to the old xml
  *            format used by OMNotebook.
  */


  /*!
  * \author Anders Fernstrom (and Ingemar Axelsson)
  * \date 2005-11-30 (update)
  *
  * \brief The class constructor
  *
  * 2005-11-30 AF, This class was remade when another xml format
  * was used to save the cell structure.
  */
  XMLParser::XMLParser( const QString filename, Factory *factory,
    Document *document, int readmode )
    : filename_( filename ),
    factory_( factory ),
    doc_( document ),
    readmode_( readmode )
  {
  }

  /*!
  * \author Ingemar Axelsson
  *
  * \brief The class destructor
  */
  XMLParser::~XMLParser()
  {}

  /*!
  * \author Anders Fernstrom
  *
  * \brief Open the xml file and check what readmode to use
  */
  Cell *XMLParser::parse()
  {
    QDomDocument domdoc( "OMNotebook" );

    // open file and set content to the dom document
    QFile file( filename_ );
    if( !file.open( QIODevice::ReadOnly ))
    {
      string msg = "Could not open " + filename_.toStdString();
      throw runtime_error( msg.c_str() );
    }

    QByteArray ba = file.readAll();



    if(filename_.endsWith(".onbz", Qt::CaseInsensitive))
    {
      if(!(ba = qUncompress(ba)).size())
      {
        file.close();
        string msg = "The file " + filename_.toStdString() + " is not a valid onbz file.";
        throw runtime_error(msg.c_str());
      }
    }
    
    if(ba.indexOf("<InputCell") != -1)
    {
      /*
      QSettings s("PELAB", "OMNotebook");
      bool alwaysConvert = s.value("AlwaysConvert", true).toBool();
      QMessageBox m;
      int i;
      if(!alwaysConvert)
      {
        m.setWindowTitle("OMNotebook");
        m.setText("Do you want to convert this file to the current document version?");
        m.setIcon(QMessageBox::Question);
        m.setStandardButtons(QMessageBox::Yes | QMessageBox::No);
        QPushButton* always = m.addButton("Always convert old documents", QMessageBox::YesRole );

        i = m.exec();

        if(m.clickedButton() == always)
        {
          s.setValue("AlwaysConvert", true);
          alwaysConvert = true;
        }
      }

      if(alwaysConvert || i == QMessageBox::Yes)
      */
      ba = ba.replace("<InputCell", "<GraphCell").
        replace("/InputCell>", "/GraphCell>").
        replace("style=\"Input\"", "style=\"Graph\"");

    }

    if(!domdoc.setContent(ba))
    {
      file.close();
      string msg = "Could not understand content of " + filename_.toStdString();
      throw runtime_error( msg.c_str() );
    }

    file.close();

    // go to correct parse function
    try
    {
      switch( readmode_ )
      {
      case READMODE_OLD:
        return parseOld( domdoc );
      case READMODE_NORMAL:
      default:
        return parseNormal( domdoc );
      }
    }
    catch( exception &e )
    {
      throw e;
    }
  }

  /*!
  * \author Anders Fernstrom
  * \date 2005-11-30
  *
  * \brief Parse the xml file using NORMAL readmode
  *
  * \param domdoc The QDomDocument that should be parsed.
  */
  Cell *XMLParser::parseNormal( QDomDocument &domdoc )
  {
    // Create a root element
    QDomElement root = domdoc.documentElement();

    // Check if correct root, otherwise throw exception
    if( root.toElement().tagName() != XML_NOTEBOOK )
    {
      string msg = "Wrong root node (" + root.toElement().tagName().toStdString() +
        ") in file " + filename_.toStdString();
      throw runtime_error( msg.c_str() );
    }

    // Remove first cellgroup.
    QDomNode node = root.firstChild();
    if( !node.isNull() )
    {
      QDomElement element = node.toElement();
      if( !element.isNull() )
        if( element.tagName() == XML_GROUPCELL )
          node = element.firstChild();
    }

    // Create the grouppcell that will be the root parent.
    Cell *rootcell = factory_->createCell( "cellgroup", 0 );

    try
    {
      if( !node.isNull() )
        traverseCells( rootcell, node );
    }
    catch( exception &e )
    {
      throw e;
    }

    // check if root cell is empty
    if( !rootcell->hasChilds() )
    {
      string msg = "File " + filename_.toStdString() + " is empty";
      throw runtime_error( msg.c_str() );
    }

    return rootcell;
  }

  /*!
  * \author Anders Fernstrom
  * \date 2005-11-30
  *
  * \brief Parse the xml file using OLD readmode
  *
  * \param domdoc The QDomDocument that should be parsed.
  */
  Cell *XMLParser::parseOld( QDomDocument &domdoc )
  {
    // Create a root element
    QDomElement root = domdoc.documentElement();

    // Check if correct root, otherwise throw exception
    if( root.toElement().tagName() != "Notebook" )
    {
      string msg = "Wrong root node (" + root.toElement().tagName().toStdString() +
        ") in file " + filename_.toStdString() + " (Old File)";
      throw runtime_error( msg.c_str() );
    }

    // Remove first cellgroup.
    QDomNode node = root.firstChild();
    if( !node.isNull() )
    {
      QDomElement element = node.toElement();
      if( !element.isNull() )
        if( element.tagName() == "CellGroupData" )
          node = element.firstChild();
    }

    // Create the grouppcell that will be the root parent.
    Cell *rootcell = factory_->createCell( "cellgroup", 0 );
    xmltraverse( rootcell, node );
    return rootcell;
  }


  // READMODE_NORMAL
  // ***************************************************************

  /*!
  * \author Anders Fernstrom
  * \date 2005-11-30
  * \date 2005-12-01 (update)
  *
  * \brief Parse the xml file, check which cell and then call the
  * correct traverse function; traverseGroupCell(), traverseTextCell(),
  * traverseInputCell().
  *
  * 2005-12-01 AF, Implement function
  *
  * \param parent The parent cell
  * \param element The current QDomElement being parsed
  */
  void XMLParser::traverseCells( Cell *parent, QDomNode &node )
  {
    try
    {
      while( !node.isNull() )
      {
        QDomElement element = node.toElement();
        if( !element.isNull() )
        {
          if( element.tagName() == XML_GROUPCELL )
            traverseGroupCell( parent, element );
          else if( element.tagName() == XML_TEXTCELL )
            traverseTextCell( parent, element );
          else if( element.tagName() == XML_INPUTCELL )
            traverseInputCell( parent, element );
          else if( element.tagName() == XML_GRAPHCELL )
            traverseGraphCell( parent, element );
          else
          {
            string msg = "Unknow tag name: " + element.tagName().toStdString() + ", in file " + filename_.toStdString();
            throw runtime_error( msg.c_str() );
          }
        }

        node = node.nextSibling();
      }
    }
    catch( exception &e )
    {
      throw e;
    }
  }

  /*!
  * \author Anders Fernstrom
  * \date 2005-11-30
  * \date 2005-12-01 (update)
  *
  * \brief Parse a group cell in the xml file.
  *
  * 2005-12-01 AF, Implement function
  *
  * \param parent The parent cell to the group cell
  * \param element The current QDomElement being parsed
  */
  void XMLParser::traverseGroupCell( Cell *parent, QDomElement &element )
  {
    Cell *groupcell = factory_->createCell( "cellgroup", parent );

    QDomNode node = element.firstChild();
    if( !node.isNull() )
    {
      QDomElement e = node.toElement();
      traverseCells( groupcell, e );
    }

    // check if the groupcell is open or closed
    QString closed = element.attribute( XML_CLOSED, XML_FALSE );
    if( closed == XML_TRUE )
      groupcell->setClosed( true );
    else if( closed == XML_FALSE )
      groupcell->setClosed( false );
    else
      throw runtime_error( "Unknown closed value in group cell" );

    parent->addChild( groupcell );
  }

  /*!
  * \author Anders Fernstrom
  * \date 2005-11-30
  * \date 2005-12-01 (update)
  *
  * \brief Parse a text cell in the xml file.
  *
  * 2005-12-01 AF, Implement function
  *
  * \param parent The parent cell to the text cell
  * \param element The current QDomElement being parsed
  */
  void XMLParser::traverseTextCell( Cell *parent, QDomElement &element )
  {
    // Get the style value
    QString style = element.attribute( XML_STYLE, "Text" );

    // create textcell with the saved style
    Cell *textcell = factory_->createCell( style, parent );


    // go through all children in text cell/element
    QDomNode node = element.firstChild();
    while( !node.isNull() )
    {
      QDomElement e = node.toElement();
      if( !e.isNull() )
      {
        if( e.tagName() == XML_TEXT )
        {
          
          // adrpo --> add URL conversion because Qt 4.4.2 doesn't accept \ in the URL!
          QString text = e.text();
          // replace all href="...\..." with href=".../..."
          QString pattern("(href[^=]*=[^\"]*\"[^\"\\\\]*)\\\\([^\"]*\")");
          QRegExp rx(pattern);
          rx.setCaseSensitivity(Qt::CaseInsensitive);
          rx.setMinimal(true);
          rx.setPatternSyntax(QRegExp::RegExp);
          if (!rx.isValid())
          {
            fprintf(stderr, "Invalid QRegExp(%s)\n", rx.pattern().toStdString().c_str());
          }
          int done = rx.indexIn(text);
          if (done > -1)
          {
            while (done > -1)
            {
              // int numX = rx.numCaptures(); QString s1 = rx.cap(1),s2 = rx.cap(2); 
              // cout << numX << " " << s1.toStdString() << "-" << s2.toStdString() << endl;
              text = text.replace(rx, rx.cap(1) + QString::fromAscii("/") + rx.cap(2));
              done = rx.indexIn(text);
            }
            textcell->setTextHtml( text );
            // fprintf(stderr, "str->%s %d\n", text.toStdString().c_str());
          }
          else // we haven't found any "\"
          {
            textcell->setTextHtml( text );
          }
        }
        else if( e.tagName() == XML_RULE )
        {
          textcell->addRule(
            new Rule( e.attribute( XML_NAME, "" ), e.text() ));
        }
        else if( e.tagName() == XML_IMAGE )
        {
          addImage( textcell, e );
        }
        else
        {
          string msg = "Unknown tagname " + e.tagName().toStdString() + ", in text cell";
          throw runtime_error( msg.c_str() );
        }
      }

      node = node.nextSibling();
    }

    // set style, before set text, so all rules are applied to the style
    QString html = textcell->textHtml();
    textcell->setStyle( *textcell->style() );
    textcell->setTextHtml( html );

    parent->addChild( textcell );
  }

  /*!
  * \author Anders Fernstrom
  * \date 2005-11-30
  * \date 2006-01-17 (update)
  *
  * \brief Parse an input cell in the xml file.
  *
  * 2005-12-01 AF, Implement function
  * 2006-01-17 AF, Added support for closed value in the inputcell
  *
  * \param parent The parent cell to the input cell
  * \param element The current QDomElement being parsed
  */
  void XMLParser::traverseInputCell( Cell *parent, QDomElement &element )
  {
    // Get the style value
    QString style = element.attribute( XML_STYLE, "Input" );

    // create inputcell with the saved style
    Cell *inputcell = factory_->createCell( style, parent );

    // go through all children in input cell/element
    QString text;
    QDomNode node = element.firstChild();
    while( !node.isNull() )
    {
      QDomElement e = node.toElement();
      if( !e.isNull() )
      {
        if( e.tagName() == XML_INPUTPART )
        {
          text = e.text();
          inputcell->setText( text );
        }
        else if( e.tagName() == XML_OUTPUTPART )
        {
          InputCell *iCell = dynamic_cast<InputCell*>(inputcell);
          iCell->setTextOutput( e.text() );
        }
        else if( e.tagName() == XML_RULE )
        {
          inputcell->addRule(
            new Rule( e.attribute( XML_NAME, "" ), e.text() ));
        }
        else if( e.tagName() == XML_IMAGE )
        {
          addImage( inputcell, e );
        }
        else
        {
          string msg = "Unknown tagname " + e.tagName().toStdString() + ", in input cell";
          throw runtime_error( msg.c_str() );
        }
      }

      node = node.nextSibling();
    }

    // set style, before set text, so all rules are applied to the style
    inputcell->setStyle( *inputcell->style() );
    inputcell->setText( text );

    // 2006-01-17 AF, check if the inputcell is open or closed
    QString closed = element.attribute( XML_CLOSED, XML_FALSE );
    if( closed == XML_TRUE )
      inputcell->setClosed( true );
    else if( closed == XML_FALSE )
      inputcell->setClosed( false );
    else
      throw runtime_error( "Unknown closed value in inputcell" );

    parent->addChild( inputcell );
  }


  void XMLParser::traverseGraphCell( Cell *parent, QDomElement &element )
  {

    // Get the style value
    QString style = element.attribute( XML_STYLE, "Graph" );


    // create inputcell with the saved style
    Cell *graphcell = factory_->createCell( style, parent );

    graphcell->setStyle(QString("Input"));
    //    graphcell->setStyle(style);


    // go through all children in input cell/element
    QString text;
    QDomNode node = element.firstChild();
    while( !node.isNull() )
    {
      QDomElement e = node.toElement();
      if( !e.isNull() )
      {
        if( e.tagName() == XML_INPUTPART )
        {
          text = e.text();
          GraphCell *gCell = dynamic_cast<GraphCell*>(graphcell);
          gCell->setText(text);
        }
        else if( e.tagName() == XML_OUTPUTPART )
        {
          GraphCell *iCell = dynamic_cast<GraphCell*>(graphcell);

          if( iCell->isQtPlot() )
            iCell->setTextOutputHtml( e.text() );
          else
            iCell->setTextOutput( e.text() );
        }
        else if( e.tagName() == XML_IMAGE )
        {
          addImage( graphcell, e );
        }
        else if( e.tagName() == XML_RULE )
        {
          graphcell->addRule(
            new Rule( e.attribute( XML_NAME, "" ), e.text() ));
        }
        else if( e.tagName() == XML_GRAPHCELL_DATA ) {}
        else if( e.tagName() == XML_GRAPHCELL_GRAPH ) {}
        else if( e.tagName() == XML_GRAPHCELL_SHAPE ) {}
        else
        {
          string msg = "Unknown tagname " + e.tagName().toStdString() + ", in input cell";
          throw runtime_error( msg.c_str() );
        }
      }

      node = node.nextSibling();
    }

    // set style, before set text, so all rules are applied to the style

    //    graphcell->setStyle(QString("Graph"));

    //    graphcell->setText( text ); //fjass

    GraphCell *gCell = dynamic_cast<GraphCell*>(graphcell);

    QByteArray ba = QByteArray::fromBase64( element.attribute(XML_GRAPHCELL_AREA).toLatin1());
    QBuffer b(&ba);
    b.open(QBuffer::ReadOnly);
    QDataStream ds(&b);

    QRectF r;
    ds >> r;
    b.close();

    // 2006-01-17 AF, check if the inputcell is open or closed
    QString closed = element.attribute( XML_CLOSED, XML_FALSE );
    if( closed == XML_TRUE )
      gCell->setClosed( true,true );
    else if( closed == XML_FALSE )
      gCell->setClosed( false,true );
    else
      throw runtime_error( "Unknown closed value in inputcell" );

    parent->addChild( graphcell );
  }

  /*!
  * \author Anders Fernstrom
  * \date 2005-11-30
  * \date 2005-12-01 (update)
  *
  * \brief Parse an image element in the xml file.
  *
  * 2005-12-01 AF, Implement function
  *
  * \param parent The cell that the image should be added to
  * \param element The current QDomElement containing the image
  */
  void XMLParser::addImage( Cell *parent, QDomElement &element )
  {
    // Create a new image
    QImage *image = new QImage();

    // Get saved image name
    QString imagename = element.attribute( XML_NAME, "" );
    if( imagename.isEmpty() || imagename.isNull() )
      throw runtime_error( "No name in image tag" );


    // Get saved image data
    QByteArray imagedata = QByteArray::fromBase64( element.text().toLatin1() );

    // Create image of image data
    QBuffer imagebuffer( &imagedata );
    imagebuffer.open( QBuffer::ReadOnly );
    QDataStream imagestream( &imagebuffer );
    imagestream >> *image;
    imagebuffer.close();

    if( !image->isNull() )
    {
      QString newname = doc_->addImage( image );

      // replace old imagename with the new name
      if( typeid(TextCell) == typeid(*parent) )
      {
        QString html = parent->textHtml();
        html.replace( imagename, newname );
        parent->setTextHtml( html );
      }
      else if( typeid(InputCell) == typeid(*parent) )
      {
        InputCell *inputcell = dynamic_cast<InputCell*>(parent);

        QString html = inputcell->textOutputHtml();

        html.replace( imagename, newname );
        inputcell->setTextOutputHtml( html );
      }
      else if( typeid(GraphCell) == typeid(*parent) )
      {
        GraphCell *graphcell = dynamic_cast<GraphCell*>(parent);

        QString html = graphcell->textOutputHtml();
        html.replace( imagename, newname );

        graphcell->setTextOutputHtml( html );
      }
      else
      {
        string msg = "Unknown typeid of parent cell";
        throw runtime_error( msg.c_str() );
      }
    }
    else
    {
      string msg = "Error creating image: <"+ imagename.toStdString() +">";
      throw runtime_error( msg.c_str() );
    }
  }


  // READMODE_OLD
  // ***************************************************************

  /*!
  * \author Ingemar Axelsson and Anders Fernstrom
  * \date 2005-12-01 (update)
  *
  * \brief Method for tracersing through the xmlfile (old format)
  *
  * 2005-12-01 AF, Changed some small things to fit the new xmlparser,
  * but most of the function is taken from the old xmlparser class
  */
  void XMLParser::xmltraverse( Cell *parent, QDomNode &node )
  {
    while( !node.isNull())
    {
      QDomElement e = node.toElement();
      if(!e.isNull())
      {
        if(e.tagName() == "CellGroupData")
        {
          Cell *aGroup = factory_->createCell("cellgroup", parent);

          QDomNode p = e.firstChild();
          xmltraverse( aGroup, p );

          QString qbool = e.attribute("closed");
          if( qbool.toLower() == "0" )
            aGroup->setClosed( false );
          else
            aGroup->setClosed( true );

          parent->addChild(aGroup);
        }
        else if(e.tagName() == "Cell")
        {
          // ignore imagecells
          if( e.attribute("style") != "Image" )
          {
            Cell *aCell = factory_->createCell(e.attribute("style"), parent);
            aCell->setText(e.text());
            aCell->setStyle( e.attribute("style") );

            parent->addChild( aCell );
          }
        }
        else
        {
          string msg = "Unknown tag: <"+ e.tagName().toStdString() +">";
          throw runtime_error( msg.c_str() );
        }
      }
      node = node.nextSibling();
    }


  }


};
