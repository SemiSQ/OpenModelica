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

 	@file EABase.h
 	@brief Comments for file documentation.
 	@author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
 	Company : CEP - ARMINES (France)
 	http://www-cep.ensmp.fr/english/
 	@version 0.9 

  */
#if !defined(_EABASE_H)
#define _EABASE_H

#include <QtCore/QObject>
#include "EAConfig.h"
#include "ProblemConfig.h"
#include "MyAlgorithm.h"
#include "ModReader.h"
#include "ModPlusCtrl.h"
#include "ModClass.h"

class Project;
class Problem;

class Result;
class BlockSubstitutions;
class ModModelPlus;

class EABase : public MyAlgorithm
{
	Q_OBJECT

public:
	EABase(void);
	EABase(Project* project,Problem* problem,ModReader*,ModPlusCtrl*,ModClass*);
	EABase(const EABase &);
	
	~EABase(void);

	virtual EABase* clone() = 0;
	virtual Result* launch(QString tempDir) = 0;
	virtual void setDefaultParameters() = 0;
	
	// subModels (for Optimization problems)
	bool _useSubModels;
	void setSubModels(QList<ModModelPlus*>,QList<BlockSubstitutions*>);

protected:

	ModReader* _modReader;
	ModPlusCtrl* _modPlusReader;
	ModClass* _rootModClass;

	// for Optimization problems
	QList<ModModelPlus*> _subModels;
	QList<BlockSubstitutions*> _subBlocks;
	
	// solve mixing pointdep-pointindep in bounds
	QVector<QVector<int> > _index;
	bool _stop;
	
	public slots:
		void onStopAsked();

};

#endif
