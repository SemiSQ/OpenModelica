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

 	@file EITools.h
 	@brief Comments for file documentation.
 	@author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
 	Company : CEP - ARMINES (France)
 	http://www-cep.ensmp.fr/english/
 	@version 0.9 

  */
#ifndef EITOOLS_H
#define EITOOLS_H

#include "EIItem.h"
#include "EIStream.h"
#include "EIGroupFact.h"
#include "EIGroup.h"
#include "EIReader.h"
#include "assert.h"

class EITools
{
public:
	EITools(void);
	~EITools(void);


        static void getTkQik(MOOptVector *variables,
		EIItem* rootEI,QList<METemperature> & Tk,
                QList<EIStream*> & eiStreams, QList<QList<MEQflow> > & Qik, bool onlyProcess, bool useCorrectedT);

        static void getTkQpkQuk(MOOptVector *variables,
		EIItem* rootEI,QList<METemperature> & Tk,
		QList<EIStream*> & eiProcessStreams, QList<QList<MEQflow> > & Qpk,
		QList<EIStream*> & eiUtilityStreams, QList<QList<MEQflow> > & Quk,
		QMultiMap<EIGroupFact*,EIStream*> &factStreamMap, // multimap <unit multiplier, Streams concerned>,
		QMap<EIGroupFact*,EIGroupFact*> &factsRelation, // map<child unit multiplier, parent unit multiplier> for constraint (e.g. fchild <= fparent * fchildmax)
                QMap<EIGroupFact*,EIGroup*> &factGroupMap,
                                 bool useCorrectedT

		);

        static double DTlm(METemperature T1in,METemperature T1out,METemperature T2in,METemperature T2out);
        static double DTlm(double dT1,double dT2);

	
};


#endif
