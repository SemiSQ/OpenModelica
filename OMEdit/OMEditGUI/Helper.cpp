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

#include "Helper.h"

QString Helper::applicationName = "OMEdit";
QString Helper::applicationVersion = "0.0.1";
QString Helper::applicationIntroText = "Open Modelica Connection Editor";
QString Helper::OpenModelicaHome = getenv("OPENMODELICAHOME");
QString Helper::omcServerName = "OMEditor";
QString Helper::omFileTypes = "*.mo";
QString Helper::omFileOpenText = "Modelica Files (*.mo)";
qreal Helper::globalXScale = 0.15;
qreal Helper::globalYScale = 0.15;
int Helper::treeIndentation = 13;
QSize Helper::iconSize = QSize(20, 20);
int Helper::headingFontSize = 18;

QString Helper::ModelicaSimulationMethods = "DASSL,DASSL2,Euler,Runge-Kutta";

QString GUIMessages::getMessage(int type)
{
    if (type == SAME_COMPONENT_NAME)
        return "A Component with the same name already exists. Please choose another Name.";
    else if (type == SAME_PORT_CONNECT)
        return "You can not connect a port to itself.";
    else if (type == NO_OPEN_MODEL)
        return "There is no open Model to simulate.";
    else if (type == NO_SIMULATION_STARTTIME)
        return "Simulation Start Time is not defined. Default value (0) will be used.";
    else if (type == NO_SIMULATION_STOPTIME)
        return "Simulation Stop Time is not defined.";
    else if (type == SIMULATION_STARTTIME_LESSTHAN_STOPTIME)
        return "Simulation Start Time should be less than Stop Time.";
    else if (type == ENTER_NAME)
        return "Please enter %1 Name.";
    else if (type == MODEL_ALREADY_EXISTS)
        return "%1 %2 already exits %3.";
    else if (type == ITEM_ALREADY_EXISTS)
        return "An item with the same name alresady exists. Please try some other name.";
    else if (type == OPEN_MODELICA_HOME_NOT_FOUND)
        return "Could not find environment variable OPENMODELICAHOME. Please make sure OpenModelica is installed properly.";
    else if (type == ERROR_OCCURRED)
        return "Following Error has occurred. \n\n %1.";
    else if (type == ERROR_IN_MODELICA_TEXT)
        return "Following Errors are found in Modelica Text. \n\n %1.";
    else if (type == UNDO_OR_FIX_ERRORS)
        return "\n\nFor normal users it is recommended to choose 'Undo changes'. You can also choose 'Let me fix errors' if you want to fix them by your own.";
    else if (type == NO_OPEN_MODELICA_KEYWORDS)
        return "Please make sure you are not using any Open Modelica Keywords like (model, package, record, class etc.)";
    else if (type == INCOMPATIBLE_CONNECTORS)
        return "Incompatible types for the connectors.";
    else if (type == SAVE_CHANGES)
        return "Do you want to save your changes before closing?";
    else if (type == DELETE_FAIL)
        return "Unable to delete. Server error has occurred while trying to delete.";
    else if (type == ONLY_MODEL_ALLOWED)
        return "This item is not a model.";
}
