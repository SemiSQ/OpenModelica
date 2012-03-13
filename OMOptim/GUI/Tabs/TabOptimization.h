// $Id$
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

     @file tabOptimization.h
     @brief Comments for file documentation.
     @author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
     Company : CEP - ARMINES (France)
     http://www-cep.ensmp.fr/english/
     @version 
*/

#ifndef TABOPTIMIZATIONCLASS_H
#define TABOPTIMIZATIONCLASS_H

#include "Optimization.h"
#include "Project.h"
#include "Tabs/MO2ColTab.h"

#include "Widgets/WidgetOptParameters.h"
#include "Widgets/WidgetSelectOptVars.h"
#include "Widgets/WidgetSelectComponents.h"
#include "Widgets/WidgetFilesList.h"
#include "Widgets/WidgetOptimActions.h"
#include "Widgets/WidgetCtrlParameters.h"


class TabOptimization : public MO2ColTab {
    Q_OBJECT

public:
        TabOptimization(Optimization *problem, QWidget *parent);
    ~TabOptimization();
    TabType tabType(){return TABPROBLEM;};

        Project *_project;
        Optimization *_problem;


        WidgetOptParameters *_widgetOptParameters;
        WidgetSelectOptVars *_widgetSelectOptVars;
        WidgetSelectComponents *_widgetSelectComponents;
        WidgetFilesList *_widgetFilesList;
        WidgetOptimActions *_widgetOptimActions;
        WidgetCtrlParameters *_widgetCtrl;


    void actualizeGui();
 
};


#endif // TABOPTIMIZATIONCLASS_H
