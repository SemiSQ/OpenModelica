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

#ifndef COMPONENTANNOTATION_H
#define COMPONENTANNOTATION_H

#include "ShapeAnnotation.h"
#include "IconAnnotation.h"
#include "ComponentsProperties.h"

class IconAnnotation;
class LineAnnotation;
class PolygonAnnotation;
class RectangleAnnotation;
class EllipseAnnotation;
class TextAnnotation;

class ComponentAnnotation : public ShapeAnnotation
{
    Q_OBJECT
private:
    QLineF line;
    IconAnnotation *mpParentIcon;
    bool mVisible;    
    qreal mScale;
    qreal mAspectRatio;
    bool mFlipHorizontal;
    bool mFlipVertical;
    qreal mRotateAngle;
public:
    ComponentAnnotation(QString value, QString className, QString transformationStr,
                        ComponentsProperties *pComponentProperties, IconAnnotation *pParent);
    ComponentAnnotation(QString value, QString className, QString transformationStr,
                        ComponentsProperties *pComponentProperties, IconAnnotation *pParent, bool libraryIcon);
    void setDefaultValues();
    void parseTransformationString(QString value);
    QRectF boundingRect() const;
    void paint(QPainter *painter, const QStyleOptionGraphicsItem *option, QWidget *widget = 0);
    qreal getRotateAngle();
    IconAnnotation* getParentIcon();

    QString mClassName;
    QString mIconAnnotationString;
    QString mTransformationString;
    QRectF mRectangle;    // stores the extent points
    bool mPreserveAspectRatio;
    qreal mInitialScale;
    QList<qreal> mGrid;
    qreal mPositionX;
    qreal mPositionY;
    ComponentsProperties *mpComponentProperties;
    QList<LineAnnotation*> mpLinesList;
    QList<PolygonAnnotation*> mpPolygonsList;
    QList<RectangleAnnotation*> mpRectanglesList;
    QList<EllipseAnnotation*> mpEllipsesList;
    QList<TextAnnotation*> mpTextsList;
protected:
    virtual void mousePressEvent(QGraphicsSceneMouseEvent *event);
signals:
    void componentClicked(ComponentAnnotation*);
};

#endif // COMPONENTANNOTATION_H
