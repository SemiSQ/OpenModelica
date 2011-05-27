// $Id$
        /**
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Link�pings universitet, Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
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

 	@file WidgetLaunchTarget.cpp
 	@brief Comments for file documentation.
 	@author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
 	Company : CEP - ARMINES (France)
 	http://www-cep.ensmp.fr/english/
 	@version 0.9 
*/

#include "WidgetLaunchTarget.h"
#include "ui_WidgetLaunchTarget.h"
#include <QtGui/QErrorMessage>
#include "QtGui/QListWidget"


        WidgetLaunchTarget::WidgetLaunchTarget(EITarget* problem,QWidget *parent) :
        QDialog(parent),
        _ui(new Ui::WidgetLaunchTargetClass)
{
    _ui->setupUi(this);


    _problem = problem;

    connect(_ui->pushMER,SIGNAL(clicked()),
            this,SLOT(launchMER()));

    connect(_ui->pushHEN1,SIGNAL(clicked()),
            this,SLOT(launchHEN()));

    connect(_ui->pushTarget,SIGNAL(clicked()),
            this,SLOT(launchTarget()));
}

WidgetLaunchTarget::~WidgetLaunchTarget()
{
    delete _ui;
}


void WidgetLaunchTarget::launchTarget()
{
    emit targetAsked();
}

void WidgetLaunchTarget::launchMER()
{
    emit MERAsked(_ui->checkUtilitiesMER->isChecked());
}

void WidgetLaunchTarget::launchHEN()
{
    emit HENAsked(_ui->checkUtilitiesMER->isChecked());
}
