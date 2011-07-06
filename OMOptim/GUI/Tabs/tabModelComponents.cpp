﻿// $Id$
/**
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linköpings universitet, Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF GPL VERSION 3 LICENSE OR 
 * THIS OSMC PUBLIC LICENSE (OSMC-PL). 
 * ANY USE, REPRODUCTION OR DISTRIBUTION OF THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE
 * OF THE OSMC PUBLIC LICENSE OR THE GPL VERSION 3, ACCORDING TO RECIPIENTS CHOICE. 
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from OSMC, either from the above address,
 * from the URLs: http://www.ida.liu.se/projects/OpenModelica or  
 * http://www.openmodelica.org, and in the OpenModelica distribution. 
 * GNU version 3 is obtained from: http://www.gnu.org/copyleft/gpl.html.
 *
 * This program is distributed WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * Main contributor 2010, Hubert Thierot, CEP - ARMINES (France)
 * Main contributor 2010, Hubert Thierot, CEP - ARMINES (France)

 	@file tabModelComponents.cpp
 	@brief Comments for file documentation.
 	@author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
 	Company : CEP - ARMINES (France)
 	http://www-cep.ensmp.fr/english/
 	@version 0.9 
*/

#include "tabModelComponents.h"
#include <QtGui/QSortFilterProxyModel>
#include "MOOptPlot.h"


namespace Ui
{
	class TabModelComponents_Class;
}

TabModelComponents::TabModelComponents(Project *project, QWidget *parent) :
QWidget(parent), _ui(new Ui::TabModelComponents_Class)
{
	_project = project;

	_componentsTreeModel = NULL;

	_ui->setupUi(this);
	_ui->tableConnections->horizontalHeader()->setResizeMode(QHeaderView::Stretch);

	// connect
	connect(_ui->pushActualize,SIGNAL(clicked()),this,SLOT(actualizeGuiFromProject()));
	connect(_project,SIGNAL(curModModelChanged(ModClass*)),this,SLOT(actualizeGuiFromProject()));
}

TabModelComponents::~TabModelComponents()
{
	delete _ui;
}

void TabModelComponents::actualizeGuiFromProject()
{
	actualizeComponentTree();
	actualizeConnectionsTable();
}

void TabModelComponents::actualizeComponentTree()
{
	// File names
	if(_project->isDefined())
	{
		// Model components
		if(_project->curModModel())
		{
                    _ui->treeComponents->setModel(_project->modClassTree());
                        //GuiTools::ModClassToTreeView(_project->modReader(),_project->curModModel(),_ui->treeComponents,_componentsTreeModel);
		}
		else
		{
			_ui->treeComponents->reset();
		}
	}
}


void TabModelComponents::actualizeConnectionsTable()
{
	// File names
	if(_project->isDefined())
	{
		ModModelPlus* curModModelPlus = _project->curModModelPlus();
		if(curModModelPlus)
		{
			curModModelPlus->readConnections();
			_ui->tableConnections->setModel(curModModelPlus->connections());
			_ui->tableConnections->viewport()->update();
		}
		else
		{
			_ui->tableConnections->reset();
		}
	}
}
