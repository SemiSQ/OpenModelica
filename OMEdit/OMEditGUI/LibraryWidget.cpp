/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linkoping University,
 * Department of Computer and Information Science,
 * SE-58183 Linkoping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 
 * AND THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S  
 * ACCEPTANCE OF THE OSMC PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Linkoping University, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main Authors 2010: Syed Adeel Asghar, Sonia Tariq
 *
 */

#include <QtGui>
#include <map>
#include <iostream>

#include "LibraryWidget.h"

//! Constructor.
//! @param parent defines a parent to the new instanced object.
LibraryWidget::LibraryWidget(MainWindow *parent)
    : QWidget(parent)
{
    mpParentMainWindow = parent;

    mpTree = new QTreeWidget(this);
    mpTree->setHeaderLabel(tr("Modelica Standard Library"));
    mpTree->setIndentation(15);
    mpTree->setDragEnabled(true);

    mpProjectsTree = new QTreeWidget(this);
    mpProjectsTree->setHeaderLabel(tr("Modelica Files"));
    mpProjectsTree->setColumnCount(1);
    mpProjectsTree->setIndentation(15);
    mpTree->setColumnCount(1);

    mpGrid = new QVBoxLayout(this);
    mpGrid->setContentsMargins(0, 0, 0, 0);
    mpGrid->addWidget(mpTree);
    mpGrid->addWidget(mpProjectsTree);

    setLayout(mpGrid);
    connect(mpTree, SIGNAL(itemClicked(QTreeWidgetItem*,int)), SLOT(showLib(QTreeWidgetItem*)));
    connect(mpTree, SIGNAL(itemExpanded(QTreeWidgetItem*)), SLOT(showLib(QTreeWidgetItem*)));
}

//! Let the user add the OM Standard Library to library widget.
void LibraryWidget::addModelicaStandardLibrary()
{
    // load Modelica Standard Library.
    this->mpParentMainWindow->mpOMCProxy->loadStandardLibrary();
    if (this->mpParentMainWindow->mpOMCProxy->isStandardLibraryLoaded())
    {
        QTreeWidgetItem *newTreePost = new QTreeWidgetItem((QTreeWidget*)0);
        newTreePost->setText(0, QString("Modelica"));
        newTreePost->setToolTip(0, QString("Modelica"));
        this->mpTree->insertTopLevelItem(0, newTreePost);
        // add temporary item to show open icon of tree.
        addClass("Temp", "Modelica.", "Modelica.", false);
        addClass("Ground", "", "Modelica.Electrical.Analog.Basic.", true);
        addClass("Resistor", "", "Modelica.Electrical.Analog.Basic.", true);
    }
}

//! Adds a whole tree structure hierarchy of OM Standard library to the library widget.
//! @param value is the name of the class.
//! @param prefixstr is the name of the parent hierarchy of the class.
void LibraryWidget::loadModelicaLibraryHierarchy(QString value, QString prefixStr)
{
    if (this->mpParentMainWindow->mpOMCProxy->isPackage(prefixStr + value))
    {
        //if value is Modelica then dont send it to addClass. Because we already added it statically.
        if (value != tr("Modelica"))
        {
            this->mpParentMainWindow->statusBar->showMessage(QString("Loading: ").append(prefixStr + value));
            addClass(value, StringHandler::getSubStringFromDots(prefixStr), prefixStr);
        }
        QStringList list = this->mpParentMainWindow->mpOMCProxy->getClassNames(prefixStr + value);
        prefixStr += value + ".";
        foreach (QString str, list)
        {
            loadModelicaLibraryHierarchy(str, prefixStr);
        }
    }
    else
    {
        addClass(value, StringHandler::getSubStringFromDots(prefixStr), prefixStr);
    }
}

//! Let the user to point out a OM Class and adds it to the library widget.
//! @param className is the name of the OM Class.
//! @param parentClassName is the name of the parent OM Class where the OM Class should be added.
//! @param parentStructure is the name of the parent hierarchy of the OM Class where, used as a tooltip.
//! @param hasIcon is the boolean value indicating whether the class has IconAnnotation or not.
void LibraryWidget::addClass(QString className, QString parentClassName, QString parentStructure, bool hasIcon)
{
    QTreeWidgetItem *newTreePost = new QTreeWidgetItem((QTreeWidget*)0);
    newTreePost->setText(0, QString(className));
    newTreePost->setToolTip(0, QString(parentStructure + className));
    /*if (hasIcon)
    {
        OMCProxy *omcproxy = OMCProxy::getInstance();
        QString result = omcproxy->getIconAnnotation(parentStructure + className);
        qDebug() << parentStructure + className;
        //QGraphicsScene scene;
        IconAnnotation *iconAnnotation = new IconAnnotation(result, parentStructure + className);

        newTreePost->setIcon(0, QIcon(iconAnnotation->getIcon()));
        //newTreePost->setIcon(0, QIcon("../../HopsanGUI/icons/hopsan.png"));
    }*/

    if (parentClassName.isEmpty())
    {
        mpTree->insertTopLevelItem(0, newTreePost);
    }
    else
    {
        QTreeWidgetItemIterator it(mpTree);
        while (*it)
        {
            if ((*it)->toolTip(0) == StringHandler::removeLastDot(parentStructure))
            {
                (*it)->addChild(newTreePost);
            }
            ++it;
        }
    }
}

void LibraryWidget::loadModel(QString fileName)
{
    // load the file in OMC
    this->mpParentMainWindow->mpOMCProxy->loadFile(fileName);

    QStringList classesList = this->mpParentMainWindow->mpOMCProxy->getClassNames(tr(""));

    foreach (QString model, classesList)
    {
        // if model is Modelica skip it.
        if (model != tr("Modelica"))
        {
            this->addModelFiles(model, tr(""), tr(""));
        }
    }
}

void LibraryWidget::addModelNode(QString name, QString parentName, QString parentStructure)
{
    QTreeWidgetItem *newTreePost = new QTreeWidgetItem((QTreeWidget*)0);
    newTreePost->setText(0, QString(name));
    newTreePost->setToolTip(0, QString(parentStructure + name));

    if (parentName.isEmpty())
    {
        this->mpProjectsTree->insertTopLevelItem(0, newTreePost);
    }
    else
    {
        QTreeWidgetItemIterator it(mpProjectsTree);
        while (*it)
        {
            if ((*it)->toolTip(0) == StringHandler::removeLastDot(parentStructure))
            {
                (*it)->addChild(newTreePost);
            }
            ++it;
        }
    }
}

void LibraryWidget::addModelFiles(QString fileName, QString parentFileName, QString parentStructure)
{
    if (parentFileName.isEmpty())
        this->addModelNode(fileName, parentFileName, parentStructure);
    else
    {
        this->addModelNode(fileName, parentFileName, parentStructure + tr("."));
        fileName = parentFileName + tr(".") + fileName;
    }

    if (this->mpParentMainWindow->mpOMCProxy->isPackage(fileName))
    {
        QStringList classesList = this->mpParentMainWindow->mpOMCProxy->getClassNames(fileName);
        foreach (QString file, classesList)
        {
            addModelFiles(file, fileName, fileName);
        }
    }
}

void LibraryWidget::removeProject()
{
    QTreeWidgetItem *newTreePost = mpProjectsTree->topLevelItem(0);
    //mpProjectsTree->removeItemWidget(newTreePost, 0);
    // delete the tree widget item because removeItemWidget will only remove it dont delete it.
    delete newTreePost;
}

//! Makes a library visible.
//! @param item is the library to show.
//! @param column is the position of the library name in the tree.
//! @see hideAllLib()
void LibraryWidget::showLib(QTreeWidgetItem *item)
{
    // disconnect the mpTree itemClicked and itemExpanded signals
    disconnect(mpTree, SIGNAL(itemClicked(QTreeWidgetItem*,int)), this, SLOT(showLib(QTreeWidgetItem*)));
    disconnect(mpTree, SIGNAL(itemExpanded(QTreeWidgetItem*)), this, SLOT(showLib(QTreeWidgetItem*)));

    // Set the cursor to wait.
    setCursor(Qt::WaitCursor);
    // Delete the temp entry now
    item->removeChild(item->child(0));
//    loadModelicaLibraryHierarchy(tr("Modelica"));
//    this->mpParentMainWindow->statusBar->clearMessage();
    //mpTree->sortItems(0, Qt::AscendingOrder);
    // Remove the wait cursor
    unsetCursor();
}
