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

 	@file EIMERResult.h
 	@brief Comments for file documentation.
 	@author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
 	Company : CEP - ARMINES (France)
 	http://www-cep.ensmp.fr/english/
 	@version 0.9 

  */
#ifndef MERRESULT_H
#define MERRESULT_H

#include "Result.h"
#include "MOCCCurve.h"
#include "EIReader.h"
#include "MOOptVector.h"
#include "EIProblem.h"

class EIMERResult : public Result
{
	Q_OBJECT

public:
	EIMERResult();
	EIMERResult(const EIMERResult &);
        EIMERResult(Project*, EIProblem *);
	~EIMERResult(void);
	QString getClassName(){return "EIMERResult";};

	int problemType();
	QDomElement toXmlData(QDomDocument &);



public :

	//Results
        METemperature TPinch;
        MEQflow MER;
        MEQflow MERCold;

	//MOOptVector* resultVars;

	MOCCCurve *curveHot;
	MOCCCurve *curveCold;
	MOCCCurve *curveGcc;

//	QList<double>  xDataHot;
//	QList<double>  yDataHot;
//	QList<double>  xDataCold;
//	QList<double>  yDataCold;

	void emitUpdated();

signals :
	void updated();
};

#endif
