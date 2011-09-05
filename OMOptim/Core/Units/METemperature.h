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

 	@file METemperature.h
 	@brief Comments for file documentation.
 	@author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
 	Company : CEP - ARMINES (France)
 	http://www-cep.ensmp.fr/english/
        @version

  */
#if !defined(_METEMPERATURE_H)
#define _METEMPERATURE_H

#include "InfoSender.h"
#include "MEDimValue.h"
#include <cmath>

class METemperature : public MEDimValue
{
public:
        METemperature(double value=-1,int unit=0);
        METemperature(const METemperature&);
	~METemperature();

	enum Units
	{
		K,
		C
	};

	QString unit(int iUnit)  const;
        QString unit() const;  //should'nt be (should be inherited) but error in compiler otherwise
	unsigned nbUnits() const;
	double convert(double value,int orgUnit,int dstUnit) const;


        double operator-(const METemperature& b) const; //temperature difference
        METemperature& operator+=(const double& diffTemp);
        METemperature& operator-=(const double& diffTemp);
        METemperature operator-(const double& diffTemp) const;
        METemperature operator+(const double& diffTemp) const;
        METemperature &operator=(const METemperature& b);
        METemperature operator+(const METemperature& b) const;
        bool operator==(const METemperature& b) const;
        bool operator!=(const METemperature& b) const;
        bool operator<(const METemperature& b) const;
        bool operator<=(const METemperature& b) const;
        bool operator>(const METemperature& b) const;
        bool operator>=(const METemperature& b) const;

        bool equals(const METemperature &b,double error=0) const;

        static bool TcolderThan(const METemperature T1, const METemperature T2){return T1<T2;};
        static bool ThoterThan(const METemperature T1, const METemperature T2){return T1>T2;};

};




#endif
