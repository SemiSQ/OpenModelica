// $Id$
/**
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linkpings universitet, Department of Computer and Information Science,
 * SE-58183 Linkping, Sweden.
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

 	@file MOMainTab.h
 	@brief Comments for file documentation.
 	@author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
 	Company : CEP - ARMINES (France)
 	http://www-cep.ensmp.fr/english/
 	@version 
*/

#ifndef MOMAINTAB_H
#define MOMAINTAB_H

#include <QtGui/QTabWidget>
#include <QContextMenuEvent>
#include "TabOneSim.h"
#include "TabOptimization.h"
#include "TabResOneSim.h"
#include "TabResOptimization.h"
#include "TabResOneSim.h"
#include "MOTab.h"
#include "Project.h"

class MainWindow;

class MOMainTab : public QTabWidget
{
	Q_OBJECT

public:
	MOMainTab(QWidget *_mainWindow,Project* _project);
        virtual ~MOMainTab(void);

        void addProblemTab(Problem*,QWidget*);
        void addResultTab(Result*,QWidget*);

        void removeTab(Problem*);
        void removeTab(Result*);

	void removeTab(MOTabBase::TabType,QString name);
	void removeTab(int);
        void enableCaseTab(OMCase*);
	

public slots:
	void contextMenuEvent(QContextMenuEvent* pEvent);
        void onOMCaseRenamed(QString);

private :
	Project* project;
	QWidget* mainWindow;
        QMap<Problem*,QWidget*> _problemTabs;
        QMap<Result*,QWidget*> _resultTabs;
};

#endif
