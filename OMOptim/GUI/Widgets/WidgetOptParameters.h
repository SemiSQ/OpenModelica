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

 	@file WidgetOptParameters.h
 	@brief Comments for file documentation.
 	@author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
 	Company : CEP - ARMINES (France)
 	http://www-cep.ensmp.fr/english/
 	@version 0.9 
*/

#ifndef WidgetOptParameters_H
#define WidgetOptParameters_H

#include <QtGui/QDialog>
#include <QtGui/QWidget>
#include<QtGui/QFileDialog>

#include "ui_WidgetOptParameters.h"
#include "MyDelegates.h"
#include "EAConfig.h"
#include "MyAlgoUtils.h"
#include "Optimization.h"
#include "MOTableView.h"
#include "GuiTools.h"
#include "Project.h"
#include "EAConfigDialog.h"

namespace Ui {
    class WidgetOptParametersClass;
}


class QErrorMessage;


class WidgetOptParameters : public QWidget {
    Q_OBJECT


public:
	explicit WidgetOptParameters(Project* project,Optimization* problem,QWidget *parent = NULL);
    virtual ~WidgetOptParameters();

	

public:
    Ui::WidgetOptParametersClass *_ui;


public slots :

	void launch();
	void changedAlgorithm();
	void onChangedCheckUseSartFile();
	void onAlgosConfigChanged();
	void openAlgoParameters();
	void restoreProblem();
	void pursueMoo();
	void selectStartFile();
	void onTextStartFileChanged(const QString &newText);
	void actualizeGui();

private :
	Project* _project;
	Optimization* _problem;

};

#endif 
