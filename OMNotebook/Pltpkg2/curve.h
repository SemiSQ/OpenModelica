/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-2010, Link�pings University,
 * Department of Computer and Information Science,
 * SE-58183 Link�ping, Sweden.
 *
 * All rights reserved.
 *
 * THIS PROGRAM IS PROVIDED UNDER THE TERMS OF THIS OSMC PUBLIC
 * LICENSE (OSMC-PL). ANY USE, REPRODUCTION OR DISTRIBUTION OF
 * THIS PROGRAM CONSTITUTES RECIPIENT'S ACCEPTANCE OF THE OSMC
 * PUBLIC LICENSE.
 *
 * The OpenModelica software and the Open Source Modelica
 * Consortium (OSMC) Public License (OSMC-PL) are obtained
 * from Link�pings University, either from the above address,
 * from the URL: http://www.ida.liu.se/projects/OpenModelica
 * and in the OpenModelica distribution.
 *
 * This program is distributed  WITHOUT ANY WARRANTY; without
 * even the implied warranty of  MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE, EXCEPT AS EXPRESSLY SET FORTH
 * IN THE BY RECIPIENT SELECTED SUBSIDIARY LICENSE CONDITIONS
 * OF OSMC-PL.
 *
 * See the full OSMC Public License conditions for more details.
 *
 * For more information about the Qt-library visit TrollTech's webpage 
 * regarding the Qt licence: http://www.trolltech.com/products/qt/licensing.html
 */

#ifndef CURVE_H
#define CURVE_H

//Qt headers
#include <QColor>
#include <QGraphicsItemGroup>

//IAEX headers
#include "variableData.h"

class LegendLabel;
class VariableData;
class Point;

class Curve
{

public:
	Curve(VariableData* x_, VariableData* y_, QColor& color, LegendLabel* ll);
	~Curve();

public slots:
	void showLine(bool b);
	void showPoints(bool b);
	void setColor(QColor c);

public:
	QGraphicsItemGroup *line;
	QList<Point*> dataPoints;
	LegendLabel* label;
	bool visible;
	bool drawPoints;
	int interpolation;
	QColor color_;

	VariableData* x, *y;
};

#endif

