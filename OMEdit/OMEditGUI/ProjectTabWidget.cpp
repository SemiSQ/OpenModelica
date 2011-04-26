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

/*
 * HopsanGUI
 * Fluid and Mechatronic Systems, Department of Management and Engineering, Linkoping University
 * Main Authors 2009-2010:  Robert Braun, Bjorn Eriksson, Peter Nordin
 * Contributors 2009-2010:  Mikael Axin, Alessandro Dell'Amico, Karl Pettersson, Ingo Staack
 */

#include <QtGui>
#include <QMap>

#include "ProjectTabWidget.h"
#include "LibraryWidget.h"
#include "mainwindow.h"

//! @class GraphicsView
//! @brief The GraphicsView class is a class which display the content of a scene of components.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsView::GraphicsView(int iconType, ProjectTab *parent)
    : QGraphicsView(parent), mIconType(iconType)
{
    mpParentProjectTab = parent;
    this->setFrameShape(QGraphicsView::NoFrame);
    this->setDragMode(QGraphicsView::RubberBandDrag);
    this->setInteractive(true);
    this->setEnabled(true);
    this->setAcceptDrops(true);
    this->mIsCreatingConnector = false;
    this->mIsMovingComponents = false;
    this->mIsCreatingLine = false;
    this->mIsCreatingPolygon = false;
    this->mIsCreatingRectangle = false;
    this->mIsCreatingEllipse = false;
    this->mIsCreatingText = false;    
    this->mIsCreatingBitmap = false;
    //this->setMinimumSize(Helper::viewWidth, Helper::viewHeight);
    this->setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
    this->setTransformationAnchor(QGraphicsView::AnchorUnderMouse);
    this->setSceneRect(-100.0, -100.0, 200.0, 200.0);
    this->centerOn(this->sceneRect().center());
    this->createActions();
    this->createMenus();

    // if user is viewing some readonly component then dont draw backgrounds.
    if (!mpParentProjectTab->isReadOnly())
    {
        this->scale(2.0, -2.0);
        if (mIconType == StringHandler::DIAGRAM)
        {
            this->setStyleSheet(QString("background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1")
                                         .append(", stop: 0 lightGray, stop: 1 gray);"));
        }
        // change the background shade if user is in Icon View
        else if (mIconType == StringHandler::ICON)
        {
            this->setStyleSheet(QString("background-color: qlineargradient(x1: 0, y1: 0, x2: 0, y2: 1")
                                         .append(", stop: 0 gray, stop: 1 lightGray);"));
        }
    }
    // if readonly view then don't scale the graphics view
    else
    {
        this->scale(1.0, -1.0);
    }

    connect(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->gridLinesAction,
            SIGNAL(toggled(bool)), this, SLOT(showGridLines(bool)));
}

void GraphicsView::drawBackground(QPainter *painter, const QRectF &rect)
{
    Q_UNUSED(rect);

    if (mpParentProjectTab->isReadOnly())
        return;

    // draw scene rectangle
    painter->setPen(Qt::black);
    painter->setBrush(QBrush(Qt::white, Qt::SolidPattern));
    painter->drawRect(this->sceneRect());
    //! @todo Grid Lines changes when resize the window. Update it.
    if (mpParentProjectTab->mpParentProjectTabWidget->mShowLines)
    {
        //painter->scale(1.0, -1.0);
        painter->setBrush(Qt::NoBrush);
        painter->setPen(Qt::gray);

        int xAxis = sceneRect().x();
        int yAxis = sceneRect().y();

        // Horizontal Lines
        while (yAxis < sceneRect().right())
        {
            yAxis += 20;
            painter->drawLine(xAxis, yAxis, sceneRect().right(), yAxis);
        }

        // Vertical Lines
        yAxis = sceneRect().y();
        while (xAxis < sceneRect().bottom())
        {
            xAxis += 20;
            painter->drawLine(xAxis, yAxis, xAxis, sceneRect().bottom());
        }
    }
    //draw scene rectangle again without brush
    painter->setPen(Qt::black);
    painter->setBrush(Qt::NoBrush);
    painter->drawRect(this->sceneRect());
}

//! Defines what happens when moving an object in a GraphicsView.
//! @param event contains information of the drag operation.
void GraphicsView::dragMoveEvent(QDragMoveEvent *event)
{
    // check if the view is readonly or not
    if (mpParentProjectTab->isReadOnly())
    {
        event->ignore();
        return;
    }

    if (event->mimeData()->hasFormat("image/modelica-component"))
    {
        event->setDropAction(Qt::CopyAction);
        event->accept();
    }
    else
    {
        event->ignore();
    }
}

//! Defines what happens when drop an object in a GraphicsView.
//! @param event contains information of the drop operation.
void GraphicsView::dropEvent(QDropEvent *event)
{
    this->setFocus();
    // check if the view is readonly or not
    if (mpParentProjectTab->isReadOnly())
    {
        event->ignore();
        return;
    }

    if (!event->mimeData()->hasFormat("image/modelica-component"))
    {
        event->ignore();
        return;
    }

    QByteArray itemData = event->mimeData()->data("image/modelica-component");
    QDataStream dataStream(&itemData, QIODevice::ReadOnly);

    QString name, classname;
    int type;
    QPointF point (mapToScene(event->pos()));
    dataStream >> name >> classname >> type;

    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    name = getUniqueComponentName(StringHandler::getLastWordAfterDot(name).toLower());
    // if dropping an item on the diagram layer
    if (mIconType == StringHandler::DIAGRAM)
    {
        // if item is a class, model, block, connector or record. then we can drop it to the graphicsview
        if ((type == StringHandler::CLASS) or (type == StringHandler::MODEL) or (type == StringHandler::BLOCK) or
            (type == StringHandler::CONNECTOR) or (type == StringHandler::RECORD))
        {
            if (type == StringHandler::CONNECTOR)
            {
                addComponentoView(name, classname, point, true, true, true);
                mpParentProjectTab->mpIconGraphicsView->addComponentoView(name, classname, point, true, false);
            }
            else
            {
                addComponentoView(name, classname, point);
            }
            event->accept();
        }
        else
        {
            pMainWindow->mpMessageWidget->printGUIInfoMessage(GUIMessages::getMessage(GUIMessages::DIAGRAM_VIEW_DROP_MSG)
                                                              .arg(classname)
                                                              .arg(StringHandler::getModelicaClassType(type)));
            event->ignore();
        }
    }
    // if dropping an item on the icon layer
    else if (mIconType == StringHandler::ICON)
    {
        // if item is a connector. then we can drop it to the graphicsview
        if (type == StringHandler::CONNECTOR)
        {
            addComponentoView(name, classname, point, true, false);
            mpParentProjectTab->mpDiagramGraphicsView->addComponentoView(name, classname, point, true,
                                                                         true, true);
            event->accept();
        }
        else
        {
            pMainWindow->mpMessageWidget->printGUIInfoMessage(GUIMessages::getMessage(GUIMessages::ICON_VIEW_DROP_MSG)
                                                              .arg(classname)
                                                              .arg(StringHandler::getModelicaClassType(type)));
            event->ignore();
        }
    }
}

void GraphicsView::addComponentoView(QString name, QString className, QPointF point, bool isConnector,
                                     bool addObject, bool diagram)
{
    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    // Check if the icon is already loaded.
    Component *oldComponent = pMainWindow->mpLibrary->getComponentObject(className);
    Component *newComponent;

    // if the item is a connector then we need to get the diagram annotation of it
    if (diagram)
    {
        QString result = pMainWindow->mpOMCProxy->getDiagramAnnotation(className);
        newComponent = new Component(result, name, className, point, StringHandler::ICON, isConnector,
                                     pMainWindow->mpOMCProxy, this);
    }
    else
    {
        if (!oldComponent)
        {
            QString result = pMainWindow->mpOMCProxy->getIconAnnotation(className);
            newComponent = new Component(result, name, className, point, StringHandler::ICON, isConnector,
                                         pMainWindow->mpOMCProxy, this);
        }
        else
        {
            newComponent = new Component(oldComponent, name, point, StringHandler::ICON, isConnector, this);
        }
    }
    if (addObject)
        addComponentObject(newComponent);
    else
        mComponentsList.append(newComponent);
}

void GraphicsView::addComponentObject(Component *component)
{
    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    // Add the component to model in OMC Global Scope.
    pMainWindow->mpOMCProxy->addComponent(component->getName(), component->getClassName(),
                                          mpParentProjectTab->mModelNameStructure);
    // add the annotations of icon
    component->updateAnnotationString(false);
    mComponentsList.append(component);
}

void GraphicsView::deleteComponentObject(Component *component)
{
    // First Remove the Connector associated to this icon
    int i = 0;
    while(i != mConnectorsVector.size())
    {
        if((mConnectorsVector[i]->getStartComponent()->getParentComponent()->getName() == component->getName()) or
           (mConnectorsVector[i]->getEndComponent()->getParentComponent()->getName() == component->getName()))
        {
            this->removeConnector(mConnectorsVector[i]);
            i = 0;   //Restart iteration if map has changed
        }
        else
        {
            ++i;
        }
    }
    // remove the icon now
    mComponentsList.removeOne(component);
    mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->deleteComponent(component->getName(), mpParentProjectTab->mModelNameStructure);
}

void GraphicsView::deleteAllComponentObjects()
{
    foreach (Component *component, mComponentsList)
    {
        component->deleteMe();
    }
}

Component* GraphicsView::getComponentObject(QString componentName)
{
    foreach (Component *component, mComponentsList)
    {
        if (component->getName() == componentName)
            return component;
    }
    return 0;
}

QString GraphicsView::getUniqueComponentName(QString iconName, int number)
{
    QString name;
    name = iconName + QString::number(number);

    foreach (Component *icon, mComponentsList)
    {
        if (icon->getName() == name)
        {
            name = getUniqueComponentName(iconName, ++number);
            break;
        }
    }
    return name;
}

bool GraphicsView::checkComponentName(QString iconName)
{
    foreach (Component *icon, mComponentsList)
    {
        if (icon->getName() == iconName)
        {
            return false;
        }
    }

    return true;
}

void GraphicsView::addShapeObject(ShapeAnnotation *shape)
{
    mShapesList.append(shape);
}

void GraphicsView::deleteShapeObject(ShapeAnnotation *shape)
{
    mShapesList.removeOne(shape);
}

void GraphicsView::deleteAllShapesObject()
{
    foreach (ShapeAnnotation *shape, mShapesList)
    {
        shape->deleteMe();
    }
}

void GraphicsView::removeAllConnectors()
{
    int i = 0;
    while(i != mConnectorsVector.size())
    {
        this->removeConnector(mConnectorsVector[i]);
        i = 0;   //Restart iteration if map has changed
    }
}

//! Defines what happens when the mouse is moving in a GraphicsView.
//! @param event contains information of the mouse moving operation.
void GraphicsView::mouseMoveEvent(QMouseEvent *event)
{
    // don't send mouse move events to items if we are creating something
    if (!mIsCreatingConnector and !mIsCreatingLine and !mIsCreatingPolygon and !mIsCreatingRectangle
        and !mIsCreatingEllipse and !mIsCreatingText and !mIsCreatingBitmap)
    {
        QGraphicsView::mouseMoveEvent(event);
    }

    //If creating connector, the end port shall be updated to the mouse position.
    if (this->mIsCreatingConnector)
    {
        mpConnector->updateEndPoint(this->mapToScene(event->pos()));
        mpConnector->drawConnector();
    }
    //If creating line shape, the end points shall be updated to the mouse position.
    else if (this->mIsCreatingLine)
    {
        mpLineShape->updateEndPoint(this->mapToScene(event->pos()));
        mpLineShape->update();
    }
    //If creating polygon shape, the end points shall be updated to the mouse position.
    else if (this->mIsCreatingPolygon)
    {
        mpPolygonShape->updateEndPoint(this->mapToScene(event->pos()));
        mpPolygonShape->update();
    }
    //If creating rectangle shape, the end points shall be updated to the mouse position.
    else if (this->mIsCreatingRectangle)
    {
        mpRectangleShape->updateEndPoint(this->mapToScene(event->pos()));
        mpRectangleShape->update();
    }
    //If creating ellipse shape, the end points shall be updated to the mouse position.
    else if (this->mIsCreatingEllipse)
    {
        mpEllipseShape->updateEndPoint(this->mapToScene(event->pos()));
        mpEllipseShape->update();
    }
    //If creating text shape, the end points shall be updated to the mouse position.
    else if (this->mIsCreatingText)
    {
        mpTextShape->updateEndPoint(this->mapToScene(event->pos()));
        mpTextShape->update();
    }
    //If creating bitmap shape, the end points shall be updated to the mouse position.
    else if (this->mIsCreatingBitmap)
    {
        mpBitmapShape->updateEndPoint(this->mapToScene(event->pos()));
        mpBitmapShape->update();
    }
}

//! Defines what happens when clicking in a GraphicsView.
//! @param event contains information of the mouse click operation.
void GraphicsView::mousePressEvent(QMouseEvent *event)
{
    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    // if left button presses and we are creating a connector
    if ((event->button() == Qt::LeftButton) && (this->mIsCreatingConnector))
    {
        mpConnector->addPoint(this->mapToScene(event->pos()));
    }
    // if left button presses and we are starting to create a Line
    else if ((event->button() == Qt::LeftButton) && pMainWindow->lineAction->isChecked())
    {
        // if we are starting to create a line then create line object and add to graphicsview
        createLineShape(this->mapToScene(event->pos()));
    }
    // if left button presses and we are starting to create a Polygon
    else if ((event->button() == Qt::LeftButton) && pMainWindow->polygonAction->isChecked())
    {
        // if we are starting to create a polygon then create line object and add to graphicsview
        createPolygonShape(this->mapToScene(event->pos()));
    }
    // if left button presses and we are starting to create a Rectangle
    else if ((event->button() == Qt::LeftButton) && pMainWindow->rectangleAction->isChecked())
    {
        // if we are starting to create a rectangle then create rectangle object and add to graphicsview
        createRectangleShape(this->mapToScene(event->pos()));
    }
    // if left button presses and we are starting to create an Ellipse
    else if ((event->button() == Qt::LeftButton) && pMainWindow->ellipseAction->isChecked())
    {
        // if we are starting to create a rectangle then create rectangle object and add to graphicsview
        createEllipseShape(this->mapToScene(event->pos()));
    }
    // if left button presses and we are starting to create a Text
    else if ((event->button() == Qt::LeftButton) && pMainWindow->textAction->isChecked())
    {
        // if we are starting to create a text then create text object and add to graphicsview
        createTextShape(this->mapToScene(event->pos()));
    }
    // if left button presses and we are starting to create a BITMAP
    else if ((event->button() == Qt::LeftButton) && pMainWindow->bitmapAction->isChecked())
    {
        // if we are starting to create a BITMAP then create BITMAP object and add to graphicsview
        createBitmapShape(this->mapToScene(event->pos()));
    }
    // if left button presses and we are not creating a connector
    else if ((event->button() == Qt::LeftButton))
    {
        // this flag is just used to have seperate identify for if statement in mouse release event of graphicsview
        this->mIsMovingComponents = true;
        // save the position of all components
        foreach (Component *component, mComponentsList)
        {
            component->mOldPosition = component->pos();
            component->isMousePressed = true;
        }
    }
    /* don't send mouse press events to items if we are creating something, only send them if creating a connector
       because for connector we need to select end port */
    if (!mIsCreatingLine and !mIsCreatingPolygon and !mIsCreatingRectangle and !mIsCreatingEllipse
        and !mIsCreatingText and !mIsCreatingBitmap)
    {
        QGraphicsView::mousePressEvent(event);
    }
}

void GraphicsView::mouseReleaseEvent(QMouseEvent *event)
{
    if ((event->button() == Qt::LeftButton) && (this->mIsMovingComponents))
    {
        this->mIsMovingComponents = false;
        // if component position is changed then update annotations
        foreach (Component *component, mComponentsList)
        {
            if (component->mOldPosition != component->pos())
            {
                component->updateAnnotationString();
                // if there are any connectors associated to component update their annotations as well.
                foreach (Connector *connector, mConnectorsVector)
                {
                    if ((connector->getStartComponent()->mpParentComponent == component) or
                        (connector->getEndComponent()->mpParentComponent == component))
                    {
                        connector->updateConnectionAnnotationString();
                    }
                }
            }
            component->isMousePressed = false;
        }
    }
    QGraphicsView::mouseReleaseEvent(event);
}

void GraphicsView::mouseDoubleClickEvent(QMouseEvent *event)
{
    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    if (this->mIsCreatingLine)
    {
        // finish creating the line
        this->mIsCreatingLine = false;
        // add the line to shapes list
        addShapeObject(mpLineShape);
        mpLineShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpLineShape->drawRectangleCornerItems();
        // make the toolbar button of line unchecked
        pMainWindow->lineAction->setChecked(false);
    }
    else if (this->mIsCreatingPolygon)
    {
        // finish creating the line
        this->mIsCreatingPolygon = false;
        // add the line to shapes list
        addShapeObject(mpPolygonShape);
        mpPolygonShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpPolygonShape->drawRectangleCornerItems();
        // make the toolbar button of line unchecked
        pMainWindow->polygonAction->setChecked(false);
    }
    QGraphicsView::mouseDoubleClickEvent(event);
}

void GraphicsView::keyPressEvent(QKeyEvent *event)
{
    if (event->key() == Qt::Key_Delete)
    {
        emit keyPressDelete();
        // once all selected items are deleted simply update the icon/diagram annotations.
        addClassAnnotation();
    }
    else if(event->key() == Qt::Key_Up)
    {
        emit keyPressUp();
    }
    else if(event->key() == Qt::Key_Down)
    {
        emit keyPressDown();
    }
    else if(event->key() == Qt::Key_Left)
    {
        emit keyPressLeft();
    }
    else if(event->key() == Qt::Key_Right)
    {
        emit keyPressRight();
    }
    else if (event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_A)
    {
        this->selectAll();
    }
    else if (!event->modifiers().testFlag(Qt::ShiftModifier) and event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_R)
    {
        emit keyPressRotateClockwise();
    }
    else if (event->modifiers().testFlag(Qt::ShiftModifier) and event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_R)
    {
        emit keyPressRotateAntiClockwise();
    }
    else
    {
        QGraphicsView::keyPressEvent(event);
    }
}

//! Defines what shall happen when a key is released.
//! @param event contains information about the keypress operation.
void GraphicsView::keyReleaseEvent(QKeyEvent *event)
{
    QGraphicsView::keyReleaseEvent(event);
}

void GraphicsView::createActions()
{
    // Connection Delete Action
    mpCancelConnectionAction = new QAction(QIcon(":/Resources/icons/delete.png"),
                                          tr("Cancel Connection"), this);
    mpCancelConnectionAction->setStatusTip(tr("Cancels the current connection"));
    connect(mpCancelConnectionAction, SIGNAL(triggered()), SLOT(removeConnector()));    
    // Icon Rotate ClockWise Action
    mpRotateIconAction = new QAction(QIcon(":/Resources/icons/rotateclockwise.png"),
                                    tr("Rotate Clockwise"), this);
    mpRotateIconAction->setStatusTip(tr("Rotate the item clockwise"));
    mpRotateIconAction->setShortcut(QKeySequence("Ctrl+r"));
    // Icon Rotate Anti-ClockWise Action
    mpRotateAntiIconAction = new QAction(QIcon(":/Resources/icons/rotateanticlockwise.png"),
                                        tr("Rotate Anticlockwise"), this);
    mpRotateAntiIconAction->setStatusTip(tr("Rotate the item anticlockwise"));
    mpRotateAntiIconAction->setShortcut(QKeySequence("Ctrl+Shift+r"));
    // Icon Reset Rotation Action
    mpResetRotation = new QAction(tr("Reset Rotation"), this);
    mpResetRotation->setStatusTip(tr("Reset the item rotation"));
    // Icon Delete Action
    mpDeleteIconAction = new QAction(QIcon(":/Resources/icons/delete.png"), tr("Delete"), this);
    mpDeleteIconAction->setStatusTip(tr("Delete the item"));
    mpDeleteIconAction->setShortcut(QKeySequence::Delete);
}

void GraphicsView::createMenus()
{

}

void GraphicsView::createLineShape(QPointF point)
{
    if (mpParentProjectTab->isReadOnly())
        return;

    if (!this->mIsCreatingLine)
    {
        this->mIsCreatingLine = true;
        mpLineShape = new LineAnnotation(this);
        mpLineShape->addPoint(point);
        mpLineShape->addPoint(point);
        this->scene()->addItem(mpLineShape);
    }
    // if we are already creating a line then only add one point.
    else
    {
        mpLineShape->addPoint(point);
    }
}

void GraphicsView::createPolygonShape(QPointF point)
{
    if (mpParentProjectTab->isReadOnly())
        return;

    if (!this->mIsCreatingPolygon)
    {
        this->mIsCreatingPolygon = true;
        mpPolygonShape = new PolygonAnnotation(this);
        mpPolygonShape->addPoint(point);
        mpPolygonShape->addPoint(point);
        mpPolygonShape->addPoint(point);
        this->scene()->addItem(mpPolygonShape);
    }
    // if we are already creating a polygon then only add one point.
    else
    {
        mpPolygonShape->addPoint(point);
    }
}

void GraphicsView::createRectangleShape(QPointF point)
{
    if (mpParentProjectTab->isReadOnly())
        return;

    if (!this->mIsCreatingRectangle)
    {
        this->mIsCreatingRectangle = true;
        mpRectangleShape = new RectangleAnnotation(this);
        mpRectangleShape->addPoint(point);
        mpRectangleShape->addPoint(point);
        this->scene()->addItem(mpRectangleShape);
    }
    // if we are already creating a rectangle then simply finish creating it.
    else
    {
        // finish creating the rectangle
        this->mIsCreatingRectangle = false;
        // add the line to shapes list
        addShapeObject(mpRectangleShape);
        mpRectangleShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpRectangleShape->drawRectangleCornerItems();
        // make the toolbar button of line unchecked
        mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->rectangleAction->setChecked(false);
    }
}

void GraphicsView::createEllipseShape(QPointF point)
{
    if (mpParentProjectTab->isReadOnly())
        return;

    if (!this->mIsCreatingEllipse)
    {
        this->mIsCreatingEllipse = true;
        mpEllipseShape = new EllipseAnnotation(this);
        mpEllipseShape->addPoint(point);
        mpEllipseShape->addPoint(point);
        this->scene()->addItem(mpEllipseShape);
    }
    // if we are already creating a rectangle then simply finish creating it.
    else
    {
        // finish creating the rectangle
        this->mIsCreatingEllipse = false;
        // add the line to shapes list
        addShapeObject(mpEllipseShape);
        mpEllipseShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpEllipseShape->drawRectangleCornerItems();
        // make the toolbar button of line unchecked
        mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->ellipseAction->setChecked(false);
    }
}

void GraphicsView::createTextShape(QPointF point)
{
    if (mpParentProjectTab->isReadOnly())
        return;

    if (!this->mIsCreatingText)
    {
        this->mIsCreatingText = true;
        mpTextShape = new TextAnnotation(this);
        mpTextShape->addPoint(point);
        mpTextShape->addPoint(point);
        this->scene()->addItem(mpTextShape);
    }
    // if we are already creating a text then simply finish creating it.
    else
    {
        // finish creating the text
        this->mIsCreatingText = false;
        // add the line to shapes list
        addShapeObject(mpTextShape);
        mpTextShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpTextShape->drawRectangleCornerItems();
        // make the toolbar button of line unchecked
        mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->textAction->setChecked(false);

        mpTextWidget = new TextWidget(mpTextShape, mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
        mpTextWidget -> show();
    }
}

void GraphicsView::createBitmapShape(QPointF point)
{       
    if (mpParentProjectTab->isReadOnly())
        return;

    if (!this->mIsCreatingBitmap)        
    {
        //If  model doesnt exist, then alert the user...
        if(mpParentProjectTab->mModelFileName.isEmpty())
        {
            QMessageBox *msgBox = new QMessageBox(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
            msgBox->setWindowTitle(QString(Helper::applicationName));
            msgBox->setIcon(QMessageBox::Warning);
            msgBox->setText(QString("The class needs to be saved before you can insert a bitmap"));
            msgBox->setStandardButtons(QMessageBox::Ok);
            msgBox->setDefaultButton(QMessageBox::Ok);
            int answer = msgBox->exec();
            mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->bitmapAction->setChecked(false);
            return;
        }

        this->mIsCreatingBitmap = true;
        mpBitmapShape = new BitmapAnnotation(this);
        mpBitmapShape->addPoint(point);
        mpBitmapShape->addPoint(point);
        this->scene()->addItem(mpBitmapShape);
    }
    else
    {
        // finish creating the bitmap
        this->mIsCreatingBitmap = false;
        // add the line to shapes list
        addShapeObject(mpBitmapShape);
        mpBitmapShape->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
        mpBitmapShape->drawRectangleCornerItems();
        // make the toolbar button of line unchecked
        mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->bitmapAction->setChecked(false);

        mpBitmapWidget = new BitmapWidget(mpBitmapShape, mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
        mpBitmapWidget->show();
    }
}

void GraphicsView::contextMenuEvent(QContextMenuEvent *event)
{
    if (mIsCreatingConnector)
    {
        QMenu menu(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
        mpCancelConnectionAction->setText("Cancel Connection");
        menu.addAction(mpCancelConnectionAction);
        menu.exec(event->globalPos());
        return;         // return from it because at a time we only want one context menu.
    }
    // if some item is right clicked then don't show graphics view context menu
    ShapeAnnotation *pShape = static_cast<ShapeAnnotation*>(itemAt(event->pos()));
    if (!pShape)
    {
        if (StringHandler::DIAGRAM == mIconType)
        {
            QMenu menu(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow);
            mpCancelConnectionAction->setText("Context Menu");
            menu.addAction(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->exportAsImage);
            menu.addAction(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->exportToOMNotebookAction);
            menu.exec(event->globalPos());
            return;         // return from it because at a time we only want one context menu.
        }
    }
    QGraphicsView::contextMenuEvent(event);
}

void GraphicsView::updateSceneRect(const QRectF &rect)
{
    //qDebug() << "in update scene rect :: " << rect;

}

//! Begins creation of connector or complete creation of connector depending on the mIsCreatingConnector flag.
//! @param pPort is a pointer to the clicked port, either start or end depending on the mIsCreatingConnector flag.
//! @param doNotRegisterUndo is true if the added connector shall not be registered in the undo stack, for example if this function is called by a redo function.
void GraphicsView::addConnector(Component *pComponent)
{
    //When clicking start port
    if (!mIsCreatingConnector)
    {
        QPointF startPos = pComponent->mapToScene(pComponent->boundingRect().center());

        this->mpConnector = new Connector(pComponent, this);

        this->scene()->addItem(mpConnector);
        this->mIsCreatingConnector = true;
        pComponent->getParentComponent()->addConnector(this->mpConnector);

        this->mpConnector->setStartComponent(pComponent);
        this->mpConnector->addPoint(startPos);
        this->mpConnector->addPoint(startPos);
        this->mpConnector->drawConnector();
    }
    // When clicking end port
    else
    {
        Component *pStartComponent = this->mpConnector->getStartComponent();
        // add the code to check if we can connect to component or not.
        MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
        QString startIconName = pStartComponent->getParentComponent()->getName();
        QString startIconCompName = pStartComponent->mpComponentProperties->getName();
        QString endIconName = pComponent->getParentComponent()->getName();
        QString endIconCompName = pComponent->mpComponentProperties->getName();
        // If both components are same
        if (pStartComponent == pComponent)
        {
            removeConnector();
            pMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(GUIMessages::SAME_PORT_CONNECT));
        }
        else
        {
            if (pMainWindow->mpOMCProxy->addConnection(startIconName + "." + startIconCompName,
                                                       endIconName + "." + endIconCompName,
                                                       mpParentProjectTab->mModelNameStructure))
            {
                // Check if both ports connected are compatible or not.
                if (pMainWindow->mpOMCProxy->instantiateModelSucceeds(mpParentProjectTab->mModelNameStructure))
                {
                    this->mIsCreatingConnector = false;
                    QPointF newPos = pComponent->mapToScene(pComponent->boundingRect().center());
                    this->mpConnector->updateEndPoint(newPos);
                    pComponent->getParentComponent()->addConnector(this->mpConnector);
                    this->mpConnector->setEndComponent(pComponent);
                    this->mConnectorsVector.append(mpConnector);
                    // add the connection annotation to OMC
                    mpConnector->updateConnectionAnnotationString();
                    pMainWindow->mpMessageWidget->printGUIInfoMessage("Connected: (" + startIconName + "." + startIconCompName +
                                                                      ", " + endIconName + "." + endIconCompName + ")");
                }
                else
                {
                    removeConnector();
                    //! @todo make the error message better
                    pMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(GUIMessages::INCOMPATIBLE_CONNECTORS));
                    pMainWindow->mpMessageWidget->printGUIErrorMessage(pMainWindow->mpOMCProxy->getErrorString());
                    // remove the connection from model
                    pMainWindow->mpOMCProxy->deleteConnection(startIconName + "." + startIconCompName,
                                                              endIconName + "." + endIconCompName,
                                                              mpParentProjectTab->mModelNameStructure);
                }
            }
        }
    }
}

//! Removes the current connecting connector from the model.
void GraphicsView::removeConnector()
{
    if (mIsCreatingConnector)
    {
        scene()->removeItem(mpConnector);
        delete mpConnector;
        mIsCreatingConnector = false;
    }
    else
    {
        int i = 0;
        while(i != mConnectorsVector.size())
        {
            if(mConnectorsVector[i]->isActive())
            {
                this->removeConnector(mConnectorsVector[i]);
                i = 0;   //Restart iteration if map has changed
            }
            else
            {
                ++i;
            }
        }
    }
}

//! Removes the connector from the model.
//! @param pConnector is a pointer to the connector to remove.
//! @param doNotRegisterUndo is true if the removal of the connector shall not be registered in the undo stack, for example if this function is called by a redo-function.
void GraphicsView::removeConnector(Connector* pConnector)
{
    bool doDelete = false;
    int i;

    for(i = 0; i != mConnectorsVector.size(); ++i)
    {
        if(mConnectorsVector[i] == pConnector)
        {
            scene()->removeItem(pConnector);
            doDelete = true;
            break;
        }
        if(mConnectorsVector.empty())
            break;
    }
    if(doDelete)
    {
        // If GUI delete is successful then remove the connection from omc as well.
        MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
        QString startComponentName = pConnector->getStartComponent()->getParentComponent()->getName();
        QString startIconCompName = pConnector->getStartComponent()->mpComponentProperties->getName();
        QString endComponentName = pConnector->getEndComponent()->getParentComponent()->getName();
        QString endIconCompName = pConnector->getEndComponent()->mpComponentProperties->getName();

        if (pMainWindow->mpOMCProxy->deleteConnection(startComponentName + "." + startIconCompName,
                                                       endComponentName + "." + endIconCompName,
                                                       mpParentProjectTab->mModelNameStructure))
        {
//            pMainWindow->mpMessageWidget->printGUIInfoMessage("Disconnected: (" + startComponentName + "." + startIconCompName +
//                                                              ", " + endComponentName + "." + endIconCompName + ")");
        }
        else
        {
            pMainWindow->mpMessageWidget->printGUIErrorMessage(pMainWindow->mpOMCProxy->getErrorString());
        }
        delete pConnector;
        mConnectorsVector.remove(i);
    }
}

//! Resets zoom factor to 100%.
//! @see zoomIn()
//! @see zoomOut()
void GraphicsView::resetZoom()
{
    this->resetMatrix();
    this->scale(2.0, -2.0);
}

//! Increases zoom factor by 15%.
//! @see resetZoom()
//! @see zoomOut()
void GraphicsView::zoomIn()
{
    //this->scale(1.15, 1.15);
    this->scale(1.12, 1.12);
}

//! Decreases zoom factor by 13.04% (1 - 1/1.15).
//! @see resetZoom()
//! @see zoomIn()
void GraphicsView::zoomOut()
{
    //if (transform().m11() != 2.0 and transform().m22() != -2.0)
    this->scale(1/1.12, 1/1.12);
}

void GraphicsView::showGridLines(bool showLines)
{
    this->mpParentProjectTab->mpParentProjectTabWidget->mShowLines = showLines;
    this->scene()->update();
}

//! Selects all objects and connectors.
void GraphicsView::selectAll()
{
    //Select all components
    foreach (Component *icon, mComponentsList)
    {
        icon->setSelected(true);
    }

    // Select all connectors
    foreach (Connector *connector, mConnectorsVector)
    {
        // just make one line of connector selected, it will make the whole connector selected
        foreach (ConnectorLine *connectorLine, connector->mpLines)
        {
            connectorLine->setSelected(true);
            break;
        }
    }

    // select all shapes like line, rectangle, polygon etc...
    foreach (ShapeAnnotation *pShape, mShapesList)
    {
        pShape->setSelected(true);
    }
}

void GraphicsView::addClassAnnotation()
{    
    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    int counter = 0;
    QString annotationString;

    annotationString.append("annotate=");
    if (mIconType == StringHandler::ICON)
    {
       annotationString.append("Icon(");
    }
    else if (mIconType == StringHandler::DIAGRAM)
    {
       annotationString.append("Diagram(");
    }
    if (mShapesList.size() > 0)
    {
       annotationString.append("graphics={");
       foreach (ShapeAnnotation *shape, mShapesList)
       {
           annotationString.append(shape->getShapeAnnotation());
           if (counter < mShapesList.size() - 1)
               annotationString.append(",");
           counter++;
       }
       annotationString.append("}");
    }
    annotationString.append(")");

    // add the class annotation to model through OMC
    if (!pMainWindow->mpOMCProxy->addClassAnnotation(mpParentProjectTab->mModelNameStructure, annotationString))
    {
       pMainWindow->mpMessageWidget->printGUIErrorMessage("Error in class annotation " +
                                                          pMainWindow->mpOMCProxy->getResult());
    }

    ModelicaTree *pModelicaTree = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpLibrary->mpModelicaTree;
    ModelicaTreeNode *pModelicaTreeNode = pModelicaTree->getNode(mpParentProjectTab->mModelNameStructure);

    LibraryLoader *libraryLoader = new LibraryLoader(pModelicaTreeNode, mpParentProjectTab->mModelNameStructure,
                                                     pModelicaTree);
    libraryLoader->start(QThread::HighestPriority);
    while (libraryLoader->isRunning())
        qApp->processEvents();
}

//! @class GraphicsScene
//! @brief The GraphicsScene class is a container for graphicsl components in a simulationmodel.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsScene::GraphicsScene(int iconType, ProjectTab *parent)
    : QGraphicsScene(parent), mIconType(iconType)
{
    mpParentProjectTab = parent;

    // only attach the haschanged slot if we are viewing the icon view.
    // if (mIconType == StringHandler::ICON)
    connect(this, SIGNAL(changed( const QList<QRectF> & )),mpParentProjectTab, SLOT(hasChanged()));
}

//GraphicsViewScroll::GraphicsViewScroll(GraphicsView *graphicsView, QWidget *parent)
//    : QScrollArea(parent)
//{
//    mpGraphicsView = graphicsView;
//}

//void GraphicsViewScroll::scrollContentsBy(int dx, int dy)
//{
//    QScrollArea::scrollContentsBy(dx, dy);
//    mpGraphicsView->update();
//}

//! @class ProjectTab
//! @brief The ProjectTab class is a Widget to contain a simulation model

//! ProjectTab contains a drawing space to create models.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
ProjectTab::ProjectTab(int modelicaType, int iconType, bool readOnly, bool isChild, ProjectTabWidget *parent)
    : QWidget(parent)
{
    mIsSaved = true;
    mModelFileName.clear();
    mpParentProjectTabWidget = parent;
    mModelicaType = modelicaType;
    mIconType = iconType;
    setReadOnly(readOnly);
    setIsChild(isChild);

    // icon graphics framework
    mpDiagramGraphicsScene = new GraphicsScene(StringHandler::DIAGRAM, this);
    mpDiagramGraphicsView = new GraphicsView(StringHandler::DIAGRAM, this);
    mpDiagramGraphicsView->setScene(mpDiagramGraphicsScene);

    // diagram graphics framework
    mpIconGraphicsScene = new GraphicsScene(StringHandler::ICON, this);
    mpIconGraphicsView = new GraphicsView(StringHandler::ICON, this);
    mpIconGraphicsView->setScene(mpIconGraphicsScene);

    // create a modelica text editor for modelica text
    mpModelicaEditor = new ModelicaEditor(this);
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    mpModelicaTextHighlighter = new ModelicaTextHighlighter(pMainWindow->mpOptionsWidget->mpModelicaTextSettings,
                                                            mpModelicaEditor->document());
    connect(pMainWindow->mpOptionsWidget, SIGNAL(modelicaTextSettingsChanged()), mpModelicaTextHighlighter,
            SLOT(settingsChanged()));

    // set Project Status Bar lables
    mpReadOnlyLabel = isReadOnly() ? new QLabel(Helper::readOnly) : new QLabel(Helper::writeAble);
    mpReadOnlyLabel->setTextInteractionFlags(Qt::TextSelectableByMouse);
    mpModelicaTypeLabel = new QLabel(StringHandler::getModelicaClassType(mModelicaType));
    mpModelicaTypeLabel->setTextInteractionFlags(Qt::TextSelectableByMouse);
    mpViewTypeLabel = new QLabel(StringHandler::getViewType(mIconType));
    mpViewTypeLabel->setTextInteractionFlags(Qt::TextSelectableByMouse);
    mpModelFilePathLabel = new QLabel(tr(""));
    mpModelFilePathLabel->setWordWrap(true);
    mpModelFilePathLabel->setTextInteractionFlags(Qt::TextSelectableByMouse);

    // frame to contain view buttons
    QFrame *viewsButtonsFrame = new QFrame;
    QHBoxLayout *viewsButtonsHorizontalLayout = new QHBoxLayout;
    viewsButtonsHorizontalLayout->setContentsMargins(0, 0, 0, 0);

    // icon view tool button
    mpDiagramToolButton = new QToolButton;
    mpDiagramToolButton->setText(Helper::iconView);
    mpDiagramToolButton->setIcon(QIcon(":/Resources/icons/model.png"));
    mpDiagramToolButton->setIconSize(Helper::buttonIconSize);
    mpDiagramToolButton->setToolTip(Helper::iconView);
    mpDiagramToolButton->setAutoRaise(true);
    mpDiagramToolButton->setCheckable(true);
    connect(mpDiagramToolButton, SIGNAL(clicked(bool)), SLOT(showIconView(bool)));
    viewsButtonsHorizontalLayout->addWidget(mpDiagramToolButton);

    // diagram view tool button
    mpIconToolButton = new QToolButton;
    mpIconToolButton->setText(Helper::diagramView);
    mpIconToolButton->setIcon(QIcon(":/Resources/icons/omeditor.png"));
    mpIconToolButton->setIconSize(Helper::buttonIconSize);
    mpIconToolButton->setToolTip(Helper::diagramView);
    mpIconToolButton->setAutoRaise(true);
    mpIconToolButton->setCheckable(true);
    connect(mpIconToolButton, SIGNAL(clicked(bool)), SLOT(showDiagramView(bool)));
    viewsButtonsHorizontalLayout->addWidget(mpIconToolButton);

    // modelica text view tool button
    mpModelicaTextToolButton = new QToolButton;
    mpModelicaTextToolButton->setText(Helper::modelicaTextView);
    mpModelicaTextToolButton->setIcon(QIcon(":/Resources/icons/modeltext.png"));
    mpModelicaTextToolButton->setIconSize(Helper::buttonIconSize);
    mpModelicaTextToolButton->setToolTip(Helper::modelicaTextView);
    mpModelicaTextToolButton->setAutoRaise(true);
    mpModelicaTextToolButton->setCheckable(true);
    connect(mpModelicaTextToolButton, SIGNAL(clicked(bool)), SLOT(showModelicaTextView(bool)));
    viewsButtonsHorizontalLayout->addWidget(mpModelicaTextToolButton);

    // documentation view tool button
    mpDocumentationViewToolButton = new QToolButton;
    mpDocumentationViewToolButton->setText(Helper::documentationView);
    mpDocumentationViewToolButton->setIcon(QIcon(":/Resources/icons/info-icon.png"));
    mpDocumentationViewToolButton->setIconSize(Helper::buttonIconSize);
    mpDocumentationViewToolButton->setToolTip(Helper::documentationView);
    mpDocumentationViewToolButton->setAutoRaise(true);
    connect(mpDocumentationViewToolButton, SIGNAL(pressed()), SLOT(showDocumentationView()));
    viewsButtonsHorizontalLayout->addWidget(mpDocumentationViewToolButton);

    viewsButtonsFrame->setLayout(viewsButtonsHorizontalLayout);

    // view buttons box
    mpViewsButtonGroup = new QButtonGroup;
    mpViewsButtonGroup->setExclusive(true);
    mpViewsButtonGroup->addButton(mpIconToolButton);
    mpViewsButtonGroup->addButton(mpDiagramToolButton);
    mpViewsButtonGroup->addButton(mpModelicaTextToolButton);

    // create project status bar
    mpProjectStatusBar = new QStatusBar;
    mpProjectStatusBar->setObjectName(tr("ProjectStatusBar"));
    mpProjectStatusBar->setSizeGripEnabled(false);
    mpProjectStatusBar->addPermanentWidget(viewsButtonsFrame, 5);
    mpProjectStatusBar->addPermanentWidget(mpReadOnlyLabel, 6);
    mpProjectStatusBar->addPermanentWidget(mpModelicaTypeLabel, 6);
    mpProjectStatusBar->addPermanentWidget(mpViewTypeLabel, 10);
    mpProjectStatusBar->addPermanentWidget(mpModelFilePathLabel, 73);

    // create the layout for Modelica Editor
    QHBoxLayout *modelicaEditorHorizontalLayout = new QHBoxLayout;
    modelicaEditorHorizontalLayout->setContentsMargins(0, 0, 0, 0);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpSearchLabelImage);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpSearchLabel);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpSearchTextBox);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpPreviuosButton);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpNextButton);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpMatchCaseCheckBox);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpMatchWholeWordCheckBox);
    modelicaEditorHorizontalLayout->addWidget(mpModelicaEditor->mpCloseButton);
    mpModelicaEditor->mpFindWidget->setLayout(modelicaEditorHorizontalLayout);
    QVBoxLayout *modelicaEditorVerticalLayout = new QVBoxLayout;
    modelicaEditorVerticalLayout->setContentsMargins(0, 0, 0, 0);
    modelicaEditorVerticalLayout->addWidget(mpModelicaEditor);
    modelicaEditorVerticalLayout->addWidget(mpModelicaEditor->mpFindWidget);
    mpModelicaEditorWidget = new QWidget;
    mpModelicaEditorWidget->setLayout(modelicaEditorVerticalLayout);

    QVBoxLayout *tabLayout = new QVBoxLayout;
    tabLayout->setContentsMargins(2, 2, 2, 2);
    tabLayout->addWidget(mpProjectStatusBar);
    tabLayout->addWidget(mpDiagramGraphicsView);
    tabLayout->addWidget(mpIconGraphicsView);
    tabLayout->addWidget(mpModelicaEditorWidget);
    setLayout(tabLayout);

    // Hide the modelica text view, icon view and show diagram view
    mpModelicaEditorWidget->hide();
    mpIconGraphicsView->hide();
    mpIconToolButton->setChecked(true);
}

ProjectTab::~ProjectTab()
{
    delete mpProjectStatusBar;
}

void ProjectTab::updateTabName(QString name, QString nameStructure)
{
    mModelName = name;
    mModelNameStructure = nameStructure;

    if (mIsSaved)
        mpParentProjectTabWidget->setTabText(mTabPosition, mModelName);
    else
        mpParentProjectTabWidget->setTabText(mTabPosition, QString(mModelName).append("*"));
}

void ProjectTab::updateModel(QString name)
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    QString newNameStructure;
    QString oldModelName = mModelName;
    // rename the model, if user has changed the name
    if (pMainWindow->mpOMCProxy->renameClass(mModelNameStructure, name))
    {
        newNameStructure = StringHandler::removeFirstLastCurlBrackets(pMainWindow->mpOMCProxy->getResult());
        // Change the name in tree
        ModelicaTreeNode *node = pMainWindow->mpLibrary->mpModelicaTree->getNode(mModelNameStructure);
        pMainWindow->mpLibrary->updateNodeText(name, newNameStructure, node);
        pMainWindow->mpMessageWidget->printGUIInfoMessage("Renamed '"+oldModelName+"' to '"+name+"'");
    }
}

//! Should be called when a model has changed in some sense,
//! e.g. a component added or a connection has changed.
void ProjectTab::hasChanged()
{
    // if the model is readonly then simply return.........e.g Ground, Inertia, EMF etc.
    // if model is a child then simply return.....
    if (isReadOnly() or isChild())
        return;

    if (mIsSaved)
    {
        QString tabName = mpParentProjectTabWidget->tabText(mpParentProjectTabWidget->currentIndex());
        tabName.append("*");
        mpParentProjectTabWidget->setTabText(mpParentProjectTabWidget->currentIndex(), tabName);
        mIsSaved = false;
    }

//    qreal left = fabs(mpDiagramGraphicsView->sceneRect().left()) + 10;
//    if (mpDiagramGraphicsView->sceneRect().left() < 0)
//        left = -left;
//    qreal top = fabs(mpDiagramGraphicsView->sceneRect().top()) + 20;
//    if (mpDiagramGraphicsView->sceneRect().top() < 0)
//        top = -top;
//    qreal width = mpDiagramGraphicsView->sceneRect().width() + 30;
//    qreal height = mpDiagramGraphicsView->sceneRect().height() + 20;

//    QRectF mSourceRectangle(left, top, width, height);
//    QRectF mTargetRectangle = mpDiagramGraphicsView->sceneRect();
//    QPixmap pixmap(Helper::iconSize);
//    pixmap.fill(QColor(Qt::transparent));
//    QPainter painter(&pixmap);
//    painter.setWindow(mTargetRectangle.toRect());
//    painter.scale(1.0, -1.0);
//    mpDiagramGraphicsView->scene()->render(&painter, mTargetRectangle, mSourceRectangle);
//    painter.end();

//    ModelicaTree *pModelicaTree = mpParentProjectTabWidget->mpParentMainWindow->mpLibrary->mpModelicaTree;
//    ModelicaTreeNode *pModelicaTreeNode = pModelicaTree->getNode(mModelNameStructure);
//    pModelicaTreeNode->setIcon(0, QIcon(pixmap));
}

void ProjectTab::showIconView(bool checked)
{
    // validate the modelica text before switching to diagram view
    if (!mpModelicaEditor->validateText())
    {
        mpModelicaTextToolButton->setChecked(true);
        return;
    }

    mpIconGraphicsView->setFocus();
    if (!checked or (checked and mpIconGraphicsView->isVisible()))
        return;

    mpModelicaEditorWidget->hide();
    mpDiagramGraphicsView->hide();
    mpIconGraphicsView->show();
    mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::ICON));
}

void ProjectTab::showDiagramView(bool checked)
{
    // validate the modelica text before switching to icon view
    if (!mpModelicaEditor->validateText())
    {
        mpModelicaTextToolButton->setChecked(true);
        return;
    }

    mpDiagramGraphicsView->setFocus();
    if (!checked or (checked and mpDiagramGraphicsView->isVisible()))
        return;

    mpModelicaEditorWidget->hide();
    mpIconGraphicsView->hide();
    mpDiagramGraphicsView->show();
    mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::DIAGRAM));
}

void ProjectTab::showModelicaTextView(bool checked)
{
    if (!checked or (checked and mpModelicaEditorWidget->isVisible()))
        return;

    mpDiagramGraphicsView->hide();
    mpIconGraphicsView->hide();
    mpViewTypeLabel->setText(StringHandler::getViewType(StringHandler::MODELICATEXT));
    // get the modelica text of the model
    mpModelicaEditor->setText(mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->list(mModelNameStructure));
    mpModelicaEditor->mLastValidText = mpModelicaEditor->toPlainText();
    mpModelicaEditor->setFocus();
    mpModelicaEditorWidget->show();
}

void ProjectTab::showDocumentationView()
{
    mpParentProjectTabWidget->mpParentMainWindow->documentationdock->show();
    mpParentProjectTabWidget->mpParentMainWindow->mpDocumentationWidget->show(mModelNameStructure);
}

bool ProjectTab::loadModelFromText(QString modelName)
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    QString modelNameStructure;
    // if a model is a sub model then
    if (mModelNameStructure.contains("."))
    {
        modelNameStructure = StringHandler::removeLastWordAfterDot(mModelNameStructure)
                             .append(".").append(modelName);
        // if model with this name already exists
        if (mModelNameStructure.compare(modelNameStructure) != 0)
        {
            if (!pMainWindow->mpOMCProxy->existClass(modelNameStructure))
            {
                return loadSubModel(modelName);
            }
            else
            {
                pMainWindow->mpOMCProxy->setResult(GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS));
                return false;
            }
        }
    }
    // if a model is a root model then
    else
    {
        modelNameStructure = modelName;
        if (mModelNameStructure.compare(modelNameStructure) != 0)
        {
            if (!pMainWindow->mpOMCProxy->existClass(modelNameStructure))
            {
                return loadRootModel(mpModelicaEditor->toPlainText());
            }
            else
            {
                pMainWindow->mpOMCProxy->setResult(GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS));
                return false;
            }
        }
    }
}

bool ProjectTab::loadRootModel(QString model)
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    // if model text is fine then
//    if (pMainWindow->mpOMCProxy->saveModifiedModel(model))
//    {
        updateModel(model);
        return true;
//    }
//    // if there is some error in model then dont accept it
//    else
//        return false;
}

bool ProjectTab::loadSubModel(QString model)
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    // if model text is fine then
    if (pMainWindow->mpOMCProxy->updateSubClass(StringHandler::removeLastWordAfterDot(mModelNameStructure), model))
    {
        QString modelName = StringHandler::getFirstWordBeforeDot(StringHandler::removeFirstLastCurlBrackets(pMainWindow->mpOMCProxy->getResult()));
        updateModel(modelName);
        //! @todo since we have created an extra model with the same name so delete it. Fix this ugly thing.
        pMainWindow->mpOMCProxy->deleteClass(mModelNameStructure);
        return true;
    }
    // if there is some error in model then dont accept it
    else
        return false;
}

//! Gets the components of the model and place them in the GraphicsView.
void ProjectTab::getModelComponents()
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    QList<ComponentsProperties*> components = pMainWindow->mpOMCProxy->getComponents(mModelNameStructure);
    QStringList componentsAnnotationsList = pMainWindow->mpOMCProxy->getComponentAnnotations(mModelNameStructure);

    int i = 0;
    foreach (ComponentsProperties *componentProperties, components)
    {
//        //! @todo add the code to check if components are of types Real, so that we dont check annotation for them.
//        Component *oldComponent = pMainWindow->mpLibrary->getComponentObject(componentProperties->getClassName());
//        Component *newComponent;
//        // create a component
//        if (!pMainWindow->mpOMCProxy->isWhat(StringHandler::PACKAGE, componentProperties->getClassName()))
//        {
//            // Check if the icon is already loaded.
//            QString iconName;
//            iconName = componentProperties->getName();

//            if (!oldComponent)
//            {
//                LibraryComponent *libComponent;
//                QString result = pMainWindow->mpOMCProxy->getIconAnnotation(componentProperties->getClassName());
//                libComponent = new LibraryComponent(result, componentProperties->getClassName(),
//                                                    mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy);
//                // add the component to library widget components lists
//                mpParentProjectTabWidget->mpParentMainWindow->mpLibrary->addComponentObject(libComponent);
//                // create a new copy component here
//                newComponent = new Component(libComponent->mpComponent, iconName, QPointF(0.0, 0.0),
//                                             StringHandler::ICON, false, mpDiagramGraphicsView);
////                newComponent = new Component(result, iconName, componentProperties->getClassName(), QPointF(0.0, 0.0),
////                                             StringHandler::ICON, false, pMainWindow->mpOMCProxy, mpGraphicsView);
//            }
//            else
//            {
//                // create a new copy component here
//                newComponent = new Component(oldComponent, iconName, QPointF(0.0, 0.0), StringHandler::ICON,
//                                             false, mpDiagramGraphicsView);
//            }
//            //mpGraphicsView->addComponentObject(newComponent);
//            mpDiagramGraphicsView->mComponentsList.append(newComponent);
//        }

        if (pMainWindow->mpOMCProxy->isWhat(StringHandler::CONNECTOR, componentProperties->getClassName()))
        {
            mpDiagramGraphicsView->addComponentoView(componentProperties->getName(),
                                                     componentProperties->getClassName(), QPointF(0.0, 0.0), true,
                                                     false, true);
            mpIconGraphicsView->addComponentoView(componentProperties->getName(),
                                                  componentProperties->getClassName(), QPointF(0.0, 0.0), true,
                                                  false);

            if (!static_cast<QString>(componentsAnnotationsList.at(i)).toLower().contains("error"))
            {
                // get the diagram component object we just created
                Component *pDiagramComponent = mpDiagramGraphicsView->getComponentObject(componentProperties->getName());
                // get the icon component object we just created
                Component *pIconComponent = mpIconGraphicsView->getComponentObject(componentProperties->getName());
                // if component annotation is found then place it according to annotation
                if (StringHandler::removeFirstLastCurlBrackets(componentsAnnotationsList.at(i)).length() > 0)
                {
                    Transformation *transformation;
                    if (pDiagramComponent)
                    {
                        pDiagramComponent->mTransformationString = componentsAnnotationsList.at(i);
                        transformation = new Transformation(pDiagramComponent);
                        // We need to reset the matrix before applying tranformations.
                        pDiagramComponent->resetTransform();
                        pDiagramComponent->scale(transformation->getScale(), transformation->getScale());
                        pDiagramComponent->setPos(transformation->getPositionX(), transformation->getPositionY());
                        pDiagramComponent->setRotation(transformation->getRotateAngle());
                    }
                    if (pIconComponent)
                    {
                        pIconComponent->mTransformationString = componentsAnnotationsList.at(i);
                        // We need to reset the matrix before applying tranformations.
                        pIconComponent->resetTransform();
                        pIconComponent->scale(transformation->getScaleIcon(), transformation->getScaleIcon());
                        pIconComponent->setPos(transformation->getPositionXIcon(), transformation->getPositionYIcon());
                        pIconComponent->setRotation(transformation->getRotateAngleIcon());
                    }
                }
            }
        }
        else
        {
            mpDiagramGraphicsView->addComponentoView(componentProperties->getName(),
                                                     componentProperties->getClassName(), QPointF(0.0, 0.0), true,
                                                     false, false);
            if (!static_cast<QString>(componentsAnnotationsList.at(i)).toLower().contains("error"))
            {
                // get the diagram component object we just created
                Component *pDiagramComponent = mpDiagramGraphicsView->getComponentObject(componentProperties->getName());
                if (pDiagramComponent)
                {
                    // if component annotation is found then place it according to annotation
                    if (StringHandler::removeFirstLastCurlBrackets(componentsAnnotationsList.at(i)).length() > 0)
                    {
                        pDiagramComponent->mTransformationString = componentsAnnotationsList.at(i);
                        Transformation *transformation = new Transformation(pDiagramComponent);
                        //newComponent->setTransform(transformation->getTransformationMatrix());
                        //! @todo We need to reset the matrix before applying tranformations.
                        pDiagramComponent->resetTransform();
                        pDiagramComponent->scale(transformation->getScale(), transformation->getScale());
                        pDiagramComponent->setPos(transformation->getPositionX(), transformation->getPositionY());
                        pDiagramComponent->setRotation(transformation->getRotateAngle());
                    }
                }
            }
        }
        i++;
    }
}

//! Gets the connections of the model and place them in the GraphicsView.
void ProjectTab::getModelConnections()
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    int connectionsCount = pMainWindow->mpOMCProxy->getConnectionCount(mModelNameStructure);

    for (int i = 1 ; i <= connectionsCount ; i++)
    {
        // get the connection from OMC
        QString connectionString;
        QStringList connectionList;
        connectionString = pMainWindow->mpOMCProxy->getNthConnection(mModelNameStructure, i);
        connectionList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionString));
        // if the connectionString only contains two items then continue the loop,
        // because connection is not valid then
        if (connectionList.size() < 3)
            continue;

        // get start and end components
        QStringList startComponentList = static_cast<QString>(connectionList.at(0)).split(".");
        QStringList endComponentList = static_cast<QString>(connectionList.at(1)).split(".");

        Component *pStartComponent = mpDiagramGraphicsView->getComponentObject(startComponentList.at(0));
        Component *pEndComponent = mpDiagramGraphicsView->getComponentObject(endComponentList.at(0));

        // if Start component and end component not found then continue the loop
        if (!pStartComponent or !pEndComponent)
            continue;

        // get start and end ports
        Component *pStartPort = 0;
        Component *pEndPort = 0;
        foreach (Component *component, pStartComponent->mpComponentsList)
        {
            if (component->mpComponentProperties->getName() == startComponentList.at(1))
                pStartPort = component;
        }

        foreach (Component *component, pEndComponent->mpComponentsList)
        {
            if (component->mpComponentProperties->getName() == endComponentList.at(1))
                pEndPort = component;
        }

        // if Start port and end port not found then continue the loop
        if (!pStartPort or !pEndPort)
            continue;

        // get the connector annotations from OMC
        QString connectionAnnotationString;
        QStringList connectionAnnotationList;
        connectionAnnotationString = pMainWindow->mpOMCProxy->getNthConnectionAnnotation(mModelNameStructure, i);

        connectionAnnotationString = connectionAnnotationString.mid(QString("Line").length());
        connectionAnnotationString = StringHandler::removeFirstLastBrackets(connectionAnnotationString);

        connectionAnnotationList = StringHandler::getStrings(connectionAnnotationString);
        // if the connectionAnnotationString is empty then continue the loop,
        // because connection is not valid then
        if (connectionAnnotationList.size() < 8)
            continue;

        // create a QVector<QPointF> of annotation string to pass to connector
        QStringList pointsList;
        QVector<QPointF> points;
        pointsList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(connectionAnnotationList.at(3)));

        foreach (QString point, pointsList)
        {
            QStringList linePoints = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(point));
            if (linePoints.size() < 2)
                continue;

            qreal x = static_cast<QString>(linePoints.at(0)).toFloat();
            qreal y = static_cast<QString>(linePoints.at(1)).toFloat();
            QPointF p (x, y);
            points.append(p);
        }
        // create a connector now
        Connector *pConnector = new Connector(pStartPort, pEndPort, mpDiagramGraphicsView, points);
        mpDiagramGraphicsView->mConnectorsVector.append(pConnector);
        mpDiagramGraphicsView->scene()->addItem(pConnector);
    }
}

//! Gets the shapes contained in the annotation string.
void ProjectTab::getModelShapes(QString annotationString, int type)
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    annotationString = StringHandler::removeFirstLastCurlBrackets(annotationString);
    if (annotationString.isEmpty())
    {
        return;
    }
    QStringList list = StringHandler::getStrings(annotationString);
    QStringList shapesList;

    if (pMainWindow->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION3X)
    {
        if (list.size() < 9)
            return;

        shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(8)), '(', ')');
    }
    else if (pMainWindow->mpOMCProxy->mAnnotationVersion == OMCProxy::ANNOTATION_VERSION2X)
    {
        if (list.size() < 4)
            return;

        shapesList = StringHandler::getStrings(StringHandler::removeFirstLastCurlBrackets(list.at(4)), '(', ')');
    }

    // Now parse the shapes available in list
    foreach (QString shape, shapesList)
    {
        shape = StringHandler::removeFirstLastCurlBrackets(shape);
        if (shape.startsWith("Line"))
        {
            shape = shape.mid(QString("Line").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            LineAnnotation *lineAnnotation;
            // add the shapeannotation item to shapes list
            if (type == StringHandler::ICON)
            {
                lineAnnotation = new LineAnnotation(shape, mpIconGraphicsView);
                lineAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpIconGraphicsView->addShapeObject(lineAnnotation);
                mpIconGraphicsView->scene()->addItem(lineAnnotation);
            }
            else if (type == StringHandler::DIAGRAM)
            {
                lineAnnotation = new LineAnnotation(shape, mpDiagramGraphicsView);
                lineAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpDiagramGraphicsView->addShapeObject(lineAnnotation);
                mpDiagramGraphicsView->scene()->addItem(lineAnnotation);
            }
            /*
                before drawing the rectangle corner items add one point to line since drawrectanglecorneritems
                deletes the one point. Why? because we end the line shape with double click which adds an extra
                point to it. so we need to delete this point.
            */
            lineAnnotation->addPoint(QPoint(0, 0));
            lineAnnotation->drawRectangleCornerItems();
            lineAnnotation->setSelectionBoxPassive();
        }
        if (shape.startsWith("Polygon"))
        {
            shape = shape.mid(QString("Polygon").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            PolygonAnnotation *polygonAnnotation;
            // add the shapeannotation item to shapes list
            if (type == StringHandler::ICON)
            {
                polygonAnnotation = new PolygonAnnotation(shape, mpIconGraphicsView);
                polygonAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpIconGraphicsView->addShapeObject(polygonAnnotation);
                mpIconGraphicsView->scene()->addItem(polygonAnnotation);
            }
            else if (type == StringHandler::DIAGRAM)
            {
                polygonAnnotation = new PolygonAnnotation(shape, mpDiagramGraphicsView);
                polygonAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpDiagramGraphicsView->addShapeObject(polygonAnnotation);
                mpDiagramGraphicsView->scene()->addItem(polygonAnnotation);
            }
            /*
                before drawing the rectangle corner items add one point to polygon since drawrectanglecorneritems
                deletes the one point. Why? because we end the polygon shape with double click which adds an extra
                point to it. so we need to delete this point.
            */
            polygonAnnotation->addPoint(QPoint(0, 0));
            polygonAnnotation->drawRectangleCornerItems();
            polygonAnnotation->setSelectionBoxPassive();
        }
        if (shape.startsWith("Rectangle"))
        {
            shape = shape.mid(QString("Rectangle").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            RectangleAnnotation *rectangleAnnotation;
            // add the shapeannotation item to shapes list
            if (type == StringHandler::ICON)
            {
                rectangleAnnotation = new RectangleAnnotation(shape, mpIconGraphicsView);
                rectangleAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpIconGraphicsView->addShapeObject(rectangleAnnotation);
                mpIconGraphicsView->scene()->addItem(rectangleAnnotation);
            }
            else if (type == StringHandler::DIAGRAM)
            {
                rectangleAnnotation = new RectangleAnnotation(shape, mpDiagramGraphicsView);
                rectangleAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpDiagramGraphicsView->addShapeObject(rectangleAnnotation);
                mpDiagramGraphicsView->scene()->addItem(rectangleAnnotation);
            }
            rectangleAnnotation->drawRectangleCornerItems();
            rectangleAnnotation->setSelectionBoxPassive();
        }
        if (shape.startsWith("Ellipse"))
        {
            shape = shape.mid(QString("Ellipse").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            EllipseAnnotation *ellipseAnnotation;
            // add the shapeannotation item to shapes list
            if (type == StringHandler::ICON)
            {
                ellipseAnnotation = new EllipseAnnotation(shape, mpIconGraphicsView);
                ellipseAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpIconGraphicsView->addShapeObject(ellipseAnnotation);
                mpIconGraphicsView->scene()->addItem(ellipseAnnotation);
            }
            else if (type == StringHandler::DIAGRAM)
            {
                ellipseAnnotation = new EllipseAnnotation(shape, mpDiagramGraphicsView);
                ellipseAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpDiagramGraphicsView->addShapeObject(ellipseAnnotation);
                mpDiagramGraphicsView->scene()->addItem(ellipseAnnotation);
            }
            ellipseAnnotation->drawRectangleCornerItems();
            ellipseAnnotation->setSelectionBoxPassive();
        }
        if (shape.startsWith("Text"))
        {            
            shape = shape.mid(QString("Text").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            TextAnnotation *textAnnotation;
            // add the shapeannotation item to shapes list
            if (type == StringHandler::ICON)
            {
                textAnnotation = new TextAnnotation(shape, mpIconGraphicsView);
                textAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpIconGraphicsView->addShapeObject(textAnnotation);
                mpIconGraphicsView->scene()->addItem(textAnnotation);
            }
            else if (type == StringHandler::DIAGRAM)
            {
                textAnnotation = new TextAnnotation(shape, mpDiagramGraphicsView);
                textAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpDiagramGraphicsView->addShapeObject(textAnnotation);
                mpDiagramGraphicsView->scene()->addItem(textAnnotation);
            }
            textAnnotation->drawRectangleCornerItems();
            textAnnotation->setSelectionBoxPassive();
        }
        if (shape.startsWith("Bitmap"))
        {            
            shape = shape.mid(QString("Bitmap").length());
            shape = StringHandler::removeFirstLastBrackets(shape);
            BitmapAnnotation *bitmapAnnotation;
            // add the shapeannotation item to shapes list
            if (type == StringHandler::ICON)
            {
                bitmapAnnotation = new BitmapAnnotation(shape, mpIconGraphicsView);
                bitmapAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpIconGraphicsView->addShapeObject(bitmapAnnotation);
                mpIconGraphicsView->scene()->addItem(bitmapAnnotation);
            }
            else if (type == StringHandler::DIAGRAM)
            {
                bitmapAnnotation = new BitmapAnnotation(shape, mpDiagramGraphicsView);
                bitmapAnnotation->setFlags(QGraphicsItem::ItemIsMovable | QGraphicsItem::ItemIsSelectable);
                mpDiagramGraphicsView->addShapeObject(bitmapAnnotation);
                mpDiagramGraphicsView->scene()->addItem(bitmapAnnotation);
            }
            bitmapAnnotation->drawRectangleCornerItems();
            bitmapAnnotation->setSelectionBoxPassive();
        }
    }
}

//! Gets the Icon and Diagram Annotation of the model and place them in the GraphicsView (Icon View).
void ProjectTab::getModelIconDiagram()
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    QString iconAnnotationString = pMainWindow->mpOMCProxy->getIconAnnotation(mModelNameStructure);
    QString diagramAnnotationString = pMainWindow->mpOMCProxy->getDiagramAnnotation(mModelNameStructure);
    getModelShapes(iconAnnotationString, StringHandler::ICON);
    getModelShapes(diagramAnnotationString, StringHandler::DIAGRAM);
}

void ProjectTab::setReadOnly(bool readOnly)
{
    mReadOnly = readOnly;
}

bool ProjectTab::isReadOnly()
{
    return mReadOnly;
}

void ProjectTab::setIsChild(bool isChild)
{
    mIsChild = isChild;
}

bool ProjectTab::isChild()
{
    return mIsChild;
}

void ProjectTab::setModelFilePathLabel(QString filePath)
{
    mpModelFilePathLabel->setText(filePath);
}

QString ProjectTab::getModelicaTypeLabel()
{
    return mpModelicaTypeLabel->text();
}

QToolButton* ProjectTab::getModelicaTextToolButton()
{
    return mpModelicaTextToolButton;
}

//! Notifies the model that its corresponding text has changed.
//! @see loadRootModel(QString model)
//! @see loadSubModel(QString model)
//! @see updateModel(QString name)
bool ProjectTab::modelicaEditorTextChanged()
{
    // make mIsSaved to false inorder to save the changes to file as well.
    mIsSaved = false;
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    QString modelName = mpModelicaEditor->getModelName();
    if (!modelName.isEmpty())
    {
        QString modelNameStructure;
        // if a model is a sub model then
        if (mModelNameStructure.contains("."))
        {
            modelNameStructure = StringHandler::removeLastWordAfterDot(mModelNameStructure)
                                 .append(".").append(modelName);
            // if model with this name already exists
            if (mModelNameStructure.compare(modelNameStructure) != 0)
            {
                if (!pMainWindow->mpOMCProxy->existClass(modelNameStructure))
                {
                    if (!loadSubModel(mpModelicaEditor->toPlainText()))
                        return false;
                }
                else
                {
                    pMainWindow->mpOMCProxy->setResult(GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS));
                    return false;
                }
            }
            if (pMainWindow->mpOMCProxy->updateSubClass(StringHandler::removeLastWordAfterDot(mModelNameStructure),
                                                        mpModelicaEditor->toPlainText()))
            {
                // clear the complete view before loading the models again
                mpIconGraphicsView->removeAllConnectors();
                mpIconGraphicsView->deleteAllComponentObjects();
                mpIconGraphicsView->deleteAllShapesObject();
                mpDiagramGraphicsView->removeAllConnectors();
                mpDiagramGraphicsView->deleteAllComponentObjects();
                mpDiagramGraphicsView->deleteAllShapesObject();
                // load model again so that we have models and connectors correctly.
                pMainWindow->mpOMCProxy->updateSubClass(StringHandler::removeLastWordAfterDot(mModelNameStructure),
                                                        mpModelicaEditor->toPlainText());
                // get the model components and connectors now
                getModelComponents();
                getModelConnections();
                getModelIconDiagram();
                // change the modelica tree node type accordingly
                ModelicaTreeNode *node = pMainWindow->mpLibrary->mpModelicaTree->getNode(mModelNameStructure);
                node->mType = pMainWindow->mpOMCProxy->getClassRestriction(mModelNameStructure);
                node->setIcon(0, node->getModelicaNodeIcon(node->mType));
                // if mType is package then check the child models
                if (node->mType == StringHandler::PACKAGE)
                {
                    pMainWindow->mpLibrary->mpModelicaTree->removeChildNodes(node);
                    QStringList modelsList = pMainWindow->mpOMCProxy->getClassNames(mModelNameStructure);
                    foreach (QString model, modelsList)
                    {
                        pMainWindow->mpLibrary->addModelFiles(model, mModelNameStructure,
                                                              mModelNameStructure + tr(".") + model);
                    }/*
                    QStringList modelsList = pMainWindow->mpOMCProxy->getClassNames(mModelNameStructure);
                    foreach (QString model, modelsList)
                    {
                        pMainWindow->mpLibrary->addModelFiles(model,
                                                          StringHandler::removeLastWordAfterDot(mModelNameStructure),
                                                          StringHandler::removeLastWordAfterDot(mModelNameStructure));
                    }*/

                }
                return true;
            }
            else
            {
                return false;
            }
        }
        // if a model is a root model then
        else
        {
            modelNameStructure = modelName;
            if (mModelNameStructure.compare(modelNameStructure) != 0)
            {
                if (!pMainWindow->mpOMCProxy->existClass(modelNameStructure))
                {
                    if (!loadRootModel(modelNameStructure))
                        return false;
                }
                else
                {
                    pMainWindow->mpOMCProxy->setResult(GUIMessages::getMessage(GUIMessages::ITEM_ALREADY_EXISTS));
                    return false;
                }
            }
            if (pMainWindow->mpOMCProxy->saveModifiedModel(mpModelicaEditor->toPlainText()))
            {
                // clear the complete view before loading the models again
                mpIconGraphicsView->removeAllConnectors();
                mpIconGraphicsView->deleteAllComponentObjects();
                mpIconGraphicsView->deleteAllShapesObject();
                mpDiagramGraphicsView->removeAllConnectors();
                mpDiagramGraphicsView->deleteAllComponentObjects();
                mpDiagramGraphicsView->deleteAllShapesObject();
                // load model again so that we have models and connectors correctly.
                pMainWindow->mpOMCProxy->saveModifiedModel(mpModelicaEditor->toPlainText());
                // get the model components and connectors now
                getModelComponents();
                getModelConnections();
                getModelIconDiagram();
                // change the modelica tree node type accordingly
                ModelicaTreeNode *node = pMainWindow->mpLibrary->mpModelicaTree->getNode(mModelNameStructure);
                node->mType = pMainWindow->mpOMCProxy->getClassRestriction(mModelNameStructure);
                node->setIcon(0, node->getModelicaNodeIcon(node->mType));
                // if mType is package then check the child models
                if (node->mType == StringHandler::PACKAGE)
                {
                    pMainWindow->mpLibrary->mpModelicaTree->removeChildNodes(node);
                    QStringList modelsList = pMainWindow->mpOMCProxy->getClassNames(mModelNameStructure);
                    foreach (QString model, modelsList)
                    {
                        pMainWindow->mpLibrary->addModelFiles(model,
                                                          StringHandler::removeLastWordAfterDot(mModelNameStructure),
                                                          StringHandler::removeLastWordAfterDot(mModelNameStructure)
                                                          + tr(".") + model);
                    }
                }
                return true;
            }
            else
            {
                return false;
            }
        }
    }
    else
    {
        pMainWindow->mpOMCProxy->setResult(mpModelicaEditor->mErrorString);
        return false;
    }
}

//! @class ProjectTabWidget
//! @brief The ProjectTabWidget class is a container class for ProjectTab class

//! ProjectTabWidget contains ProjectTabWidget widgets.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
ProjectTabWidget::ProjectTabWidget(MainWindow *parent)
    : QTabWidget(parent)
{
    mpParentMainWindow = parent;
    setTabsClosable(true);
    setContentsMargins(0, 0, 0, 0);
    mShowLines = false;
    mToolBarEnabled = true;

    connect(mpParentMainWindow->openAction, SIGNAL(triggered()), this,SLOT(openFile()));
    connect(mpParentMainWindow->saveAction, SIGNAL(triggered()), this,SLOT(saveProjectTab()));
    connect(mpParentMainWindow->saveAsAction, SIGNAL(triggered()), this,SLOT(saveProjectTabAs()));
    connect(this,SIGNAL(tabCloseRequested(int)),SLOT(closeProjectTab(int)));
    connect(this, SIGNAL(tabAdded()), SLOT(enableProjectToolbar()));
    connect(this, SIGNAL(tabRemoved()), SLOT(disableProjectToolbar()));
    emit tabRemoved();
    connect(mpParentMainWindow->resetZoomAction, SIGNAL(triggered()),this,SLOT(resetZoom()));
    connect(mpParentMainWindow->zoomInAction, SIGNAL(triggered()),this,SLOT(zoomIn()));
    connect(mpParentMainWindow->zoomOutAction, SIGNAL(triggered()),this,SLOT(zoomOut()));
    connect(mpParentMainWindow->mpLibrary->mpModelicaTree, SIGNAL(nodeDeleted()), SLOT(updateTabIndexes()));
    connect(this, SIGNAL(modelSaved(QString,QString)), mpParentMainWindow->mpLibrary->mpModelicaTree,
            SLOT(saveChildModels(QString,QString)));
}

ProjectTabWidget::~ProjectTabWidget()
{
    // delete all the tabs opened currently
    while(count() > 0)
    {
        delete dynamic_cast<ProjectTab*>(this->widget(count() - 1));
    }

    // delete all the removed tabs as well.
    foreach (ProjectTab *pCurrentTab, mRemovedTabsList)
    {
        delete pCurrentTab;
    }
}

//! Returns a pointer to the currently active project tab
ProjectTab* ProjectTabWidget::getCurrentTab()
{
    return qobject_cast<ProjectTab *>(currentWidget());
}

ProjectTab* ProjectTabWidget::getTabByName(QString name)
{
    for (int i = 0; i < this->count() ; i++)
    {
        ProjectTab *pCurrentTab = dynamic_cast<ProjectTab*>(this->widget(i));
        if (pCurrentTab->mModelNameStructure == name)
        {
            return pCurrentTab;
        }
    }
    return 0;
}

ProjectTab* ProjectTabWidget::getRemovedTabByName(QString name)
{
    foreach (ProjectTab *pCurrentTab, mRemovedTabsList)
    {
        if (pCurrentTab->mModelNameStructure == name)
        {
            return pCurrentTab;
        }
    }
    return 0;
}

//! Reimplemented function to add the Tab.
int ProjectTabWidget::addTab(ProjectTab *tab, QString tabName)
{
    int position = QTabWidget::addTab(tab, tabName);
    emit tabAdded();
    return position;
}

//! Reimplemented function to remove the Tab.
void ProjectTabWidget::removeTab(int index)
{
    // if tab is saved and user is just closing it then save it to mRemovedTabsList, so that we can open it later on
    ProjectTab *pCurrentTab = qobject_cast<ProjectTab *>(widget(index));
    QTabWidget::removeTab(index);
    if (pCurrentTab->mIsSaved)
    {
        mRemovedTabsList.append(pCurrentTab);
    }
    else
    {
        // delete the tab if user dont save it, becasue removetab only removes the widget don't delete it
        delete pCurrentTab;
    }
    emit tabRemoved();
}

void ProjectTabWidget::disableTabs(bool disable)
{
    int i = count();
    while(i > 0)
    {
        i = i - 1;
        if (i != currentIndex())
            setTabEnabled(i, !disable);
    }
}

void ProjectTabWidget::setSourceFile(QString modelName, QString modelFileName)
{
    if (mpParentMainWindow->mpOMCProxy->isPackage(modelName))
    {
        // set the source file name
        mpParentMainWindow->mpOMCProxy->setSourceFile(modelName, modelFileName);
        // get the class names of this package
        QStringList modelsList = mpParentMainWindow->mpOMCProxy->getClassNames(modelName);

        foreach (QString model, modelsList)
            setSourceFile(modelName + "." + model, modelFileName);
    }
    else
    {
        // set the source file name
        mpParentMainWindow->mpOMCProxy->setSourceFile(modelName, modelFileName);
    }
}

//! Adds an existing ProjectTab object to itself.
//! @see closeProjectTab(int index)
void ProjectTabWidget::addProjectTab(ProjectTab *projectTab, QString modelName, QString modelStructure)
{
    projectTab->mIsSaved = true;
    projectTab->mModelName = modelName;
    projectTab->mModelNameStructure = modelStructure;
    projectTab->mModelFileName = mpParentMainWindow->mpOMCProxy->getSourceFile(modelStructure);
    projectTab->setModelFilePathLabel(projectTab->mModelFileName);
    projectTab->mTabPosition = addTab(projectTab, modelName);
    projectTab->getModelComponents();
    projectTab->getModelConnections();
    projectTab->getModelIconDiagram();
    setCurrentWidget(projectTab);
    /* when we add the models and connections to the model, GraphicsView hasChanged will be called
       which mark the model as not saved, so just make it save again manually. */
//    QString tabName = tabText(currentIndex());
//    tabName.chop(1);
//    setTabText(currentIndex(), tabName);
}

//! Adds a ProjectTab object (a new tab) to itself.
//! @see closeProjectTab(int index)
void ProjectTabWidget::addNewProjectTab(QString modelName, QString modelStructure, int modelicaType)
{
    ProjectTab *newTab;
    if (modelStructure.isEmpty())
    {
        newTab = new ProjectTab(modelicaType, StringHandler::ICON, false, false, this);
        newTab->mIsSaved = false;
    }
    else
    {
        newTab = new ProjectTab(modelicaType, StringHandler::ICON, false, true, this);
        ProjectTab *pParentTab = getTabByName(StringHandler::removeLastDot(modelStructure));
        if (pParentTab)
        {
            // set the text of the model and make it unsaved.
            pParentTab->mpModelicaEditor->setText(mpParentMainWindow->mpOMCProxy->list
                                                 (StringHandler::removeLastDot(modelStructure)));
            pParentTab->mIsSaved = true;
            pParentTab->hasChanged();
        }
    }
    newTab->mModelName = modelName;
    newTab->mModelNameStructure = modelStructure + modelName;
    newTab->mTabPosition = addTab(newTab, newTab->isChild() ? modelName : modelName.append(QString("*")));
    setCurrentWidget(newTab);
    // make the icon view visible and focused for key press events
    newTab->showDiagramView(true);
}

void ProjectTabWidget::addDiagramViewTab(QTreeWidgetItem *item, int column)
{
    Q_UNUSED(column);
    LibraryTreeNode *treeNode = dynamic_cast<LibraryTreeNode*>(item);
    ProjectTab *newTab = new ProjectTab(mpParentMainWindow->mpOMCProxy->getClassRestriction(treeNode->mNameStructure),
                                        StringHandler::DIAGRAM, true, false, this);
    newTab->mModelName = treeNode->mName;
    newTab->mModelNameStructure = treeNode->mNameStructure;
    newTab->mTabPosition = addTab(newTab, StringHandler::getLastWordAfterDot(treeNode->mNameStructure));

    Component *diagram;
    QString result = mpParentMainWindow->mpOMCProxy->getDiagramAnnotation(treeNode->toolTip(0));
    diagram = new Component(result, newTab->mModelName, newTab->mModelNameStructure, QPointF (0,0),
                            StringHandler::DIAGRAM, false, mpParentMainWindow->mpOMCProxy,
                            newTab->mpDiagramGraphicsView);

    Component *oldIconComponent = mpParentMainWindow->mpLibrary->getComponentObject(newTab->mModelNameStructure);
    Component *newIconComponent;

    if (!oldIconComponent)
    {
        QString result = mpParentMainWindow->mpOMCProxy->getIconAnnotation(newTab->mModelNameStructure);
        newIconComponent = new Component(result, newTab->mModelName, newTab->mModelNameStructure, QPointF (0,0),
                                         StringHandler::ICON, false, mpParentMainWindow->mpOMCProxy,
                                         newTab->mpIconGraphicsView);
    }
    else
    {
        newIconComponent = new Component(oldIconComponent, newTab->mModelName, QPointF (0,0), StringHandler::ICON,
                                        false, newTab->mpIconGraphicsView);
    }
    setCurrentWidget(newTab);
    // make the icon view visible and focused for key press events
    newTab->showDiagramView(true);
}

//! Saves current project.
//! @see saveProjectTab(int index)
void ProjectTabWidget::saveProjectTab()
{
    saveProjectTab(currentIndex(), false);
}

//! Saves current project to a new model file.
//! @see saveProjectTab(int index)
void ProjectTabWidget::saveProjectTabAs()
{
    saveProjectTab(currentIndex(), true);
}

//! Saves project at index.
//! @param index defines which project to save.
//! @see saveProjectTab()
void ProjectTabWidget::saveProjectTab(int index, bool saveAs)
{
    ProjectTab *pCurrentTab = qobject_cast<ProjectTab *>(widget(index));
    if (!pCurrentTab)
        return;
    // if the model is readonly then simply return.........e.g Ground, Inertia, EMF etc.
    if (pCurrentTab->isReadOnly())
        return;

    // validate the modelica text before saving the model
    if (!pCurrentTab->mpModelicaEditor->validateText())
        return;

    // if model is a child model then give user a message and return
    if (pCurrentTab->isChild())
    {
        MessageWidget *pMessageWidget = pCurrentTab->mpParentProjectTabWidget->mpParentMainWindow->mpMessageWidget;
        pMessageWidget->printGUIInfoMessage(QString(GUIMessages::getMessage(GUIMessages::CHILD_MODEL_SAVE))
                                            .arg(pCurrentTab->getModelicaTypeLabel()).arg(pCurrentTab->mModelName));
        return;
    }

    QString tabName = tabText(index);

    if (saveAs)
    {
        if (saveModel(saveAs))
        {
            // make sure we only trim * and not any letter of model name.
            if (tabName.endsWith('*'))
                tabName.chop(1);

            setTabText(index, tabName);
            pCurrentTab->mIsSaved = true;
        }
    }
    // if not saveAs then
    else
    {
        // if user presses ctrl + s and model is already saved
        if (pCurrentTab->mIsSaved)
        {
            //Nothing to do except for package
            if (pCurrentTab->mModelicaType == StringHandler::PACKAGE)
            {
                if (saveModel(saveAs))
                {
                    // make sure we only trim * and not any letter of model name.
                    if (tabName.endsWith('*'))
                        tabName.chop(1);

                    setTabText(index, tabName);
                    pCurrentTab->mIsSaved = true;
                }
            }
        }
        // if model is not saved then save it
        else
        {
            if (saveModel(saveAs))
            {
                // make sure we only trim * and not any letter of model name.
                if (tabName.endsWith('*'))
                    tabName.chop(1);

                setTabText(index, tabName);
                pCurrentTab->mIsSaved = true;
            }
        }
    }
}

//! Saves the model in the active project tab to a model file.
//! @param saveAs tells whether or not an already existing file name shall be used
//! @see saveProjectTab()
//! @see loadModel()
bool ProjectTabWidget::saveModel(bool saveAs)
{
    ProjectTab *pCurrentTab = qobject_cast<ProjectTab *>(currentWidget());
    MainWindow *pMainWindow = pCurrentTab->mpParentProjectTabWidget->mpParentMainWindow;

    QString modelFileName;
    // if first time save or doing a saveas
    if(pCurrentTab->mModelFileName.isEmpty() | saveAs)
    {
        QDir fileDialogSaveDir;

        modelFileName = StringHandler::getSaveFileName(this, tr(saveAs ? "Save File As" : "Save File"),
                                                       fileDialogSaveDir.currentPath(),
                                                       Helper::omFileTypes, NULL, "mo");

        if (modelFileName.isEmpty())
        {
            return false;
        } else {
            // set the source file in OMC
            pMainWindow->mpOMCProxy->setSourceFile(pCurrentTab->mModelNameStructure, modelFileName);
            // if opened tab is a package save all of its child models
            if (pCurrentTab->mModelicaType == StringHandler::PACKAGE)
                emit modelSaved(pCurrentTab->mModelNameStructure, modelFileName);
            // finally save the model through OMC
            if (pMainWindow->mpOMCProxy->save(pCurrentTab->mModelNameStructure))
            {
                pCurrentTab->mModelFileName = modelFileName;
                pCurrentTab->setModelFilePathLabel(modelFileName);
                return true;
            }
            // if OMC is unable to save the file
            else
            {
                QMessageBox::critical(this, Helper::applicationName + " - Error",
                                     GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).
                                     arg(pMainWindow->mpOMCProxy->getErrorString()), tr("OK"));
                return false;
            }
        }
    }
    // if saving the file second time
    else
    {
        // set the source file in OMC
        pMainWindow->mpOMCProxy->setSourceFile(pCurrentTab->mModelNameStructure, pCurrentTab->mModelFileName);
        // if opened tab is a package save all of its child models
        if (pCurrentTab->mModelicaType == StringHandler::PACKAGE)
            emit modelSaved(pCurrentTab->mModelNameStructure, pCurrentTab->mModelFileName);
        // finally save the model through OMC
        if (pMainWindow->mpOMCProxy->save(pCurrentTab->mModelNameStructure))
        {
            return true;
        }
        // if OMC is unable to save the file
        else
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error",
                                 GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).
                                 arg(pMainWindow->mpOMCProxy->getErrorString()), tr("OK"));
            return false;
        }
    }
}

//! Closes current project.
//! @param index defines which project to close.
//! @return true if closing went ok. false if the user canceled the operation.
//! @see closeAllProjectTabs()
bool ProjectTabWidget::closeProjectTab(int index)
{
    ModelicaTree *pTree = mpParentMainWindow->mpLibrary->mpModelicaTree;
    ProjectTab *pCurrentTab = dynamic_cast<ProjectTab*>(widget(index));
    if (!(pCurrentTab->mIsSaved))
    {
        QString modelName;
        modelName = tabText(index);
        modelName.chop(1);
        QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
        msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Question"));
        msgBox->setIcon(QMessageBox::Question);
        msgBox->setText(QString(GUIMessages::getMessage(GUIMessages::SAVED_MODEL))
                        .arg(pCurrentTab->getModelicaTypeLabel()).arg(pCurrentTab->mModelName));
        msgBox->setInformativeText(GUIMessages::getMessage(GUIMessages::SAVE_CHANGES));
        msgBox->setStandardButtons(QMessageBox::Save | QMessageBox::Discard | QMessageBox::Cancel);
        msgBox->setDefaultButton(QMessageBox::Save);

        int answer = msgBox->exec();

        switch (answer)
        {
        case QMessageBox::Save:
            // Save was clicked
            saveProjectTab(index, false);
            removeTab(index);
            return true;
        case QMessageBox::Discard:
            // Don't Save was clicked
            //if (pTree->deleteNodeTriggered(pTree->getNode(pCurrentTab->mModelNameStructure)))
                //removeTab(index);
            pTree->deleteNodeTriggered(pTree->getNode(pCurrentTab->mModelNameStructure), false);
            return true;
        case QMessageBox::Cancel:
            // Cancel was clicked
            return false;
        default:
            // should never be reached
            return false;
        }
    }
    else
    {
        removeTab(index);
        return true;
    }
}

//! Closes all opened projects.
//! @return true if closing went ok. false if the user canceled the operation.
//! @see closeProjectTab(int index)
//! @see saveProjectTab()
bool ProjectTabWidget::closeAllProjectTabs()
{
    for (int i = 0 ; i < count() ; i++)
    {
        if (!(dynamic_cast<ProjectTab*>(widget(i)))->mIsSaved)
        {
            QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
            msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Question"));
            msgBox->setIcon(QMessageBox::Question);
            msgBox->setText(QString("There are unsaved models opened. Do you still want to quit?"));
            msgBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
            msgBox->setDefaultButton(QMessageBox::No);

            int answer = msgBox->exec();
            msgBox->raise();

            switch (answer)
            {
            case QMessageBox::Yes:
                return true;
            case QMessageBox::No:
                return false;
            default:
                // should never be reached
                return false;
            }
        }
    }
    return true;
}

//! Loads a model from a file and opens it in a new project tab.
//! @see saveModel(bool saveAs)
void ProjectTabWidget::openFile(QString fileName)
{
    if (fileName.isEmpty())
    {
        QString name = QFileDialog::getOpenFileName(this, tr("Choose File"),
                                                        QDir::currentPath() + QString("/../.."),
                                                        Helper::omFileTypes);
        if (name.isEmpty())
            return;
        else
            fileName = name;
    }
    // get the class names now to check if they are already loaded or not
    QStringList existingmodelsList;
    if (!mpParentMainWindow->mpOMCProxy->parseFile(fileName))
    {
        QString message = QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).append(" ").arg(fileName))
                          .append("\n").append(mpParentMainWindow->mpOMCProxy->getErrorString());
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(message);
        return;
    }
    QString result = StringHandler::removeFirstLastCurlBrackets(mpParentMainWindow->mpOMCProxy->getResult());
    QStringList modelsList = result.split(",", QString::SkipEmptyParts);
    bool existModel = false;
    // check if the model already exists
    foreach(QString model, modelsList)
    {
        if (mpParentMainWindow->mpOMCProxy->existClass(model))
        {
            existingmodelsList.append(model);
            existModel = true;
        }
    }

    // check if existModel is true
    if (existModel)
    {
        QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
        msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Information"));
        msgBox->setIcon(QMessageBox::Information);
        msgBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_FILE).arg("")));
        msgBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFING_EXISTING_MODELS))
                                   .arg(existingmodelsList.join(",")).append("\n")
                                   .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD)));
        msgBox->setStandardButtons(QMessageBox::Ok);
        msgBox->exec();
    }
    // if no conflicting model found then just load the file simply
    else
    {
        mpParentMainWindow->mpLibrary->loadFile(fileName, modelsList);
    }
}

//! Loads a model and opens it in a new project tab.
//! @see saveModel(bool saveAs)
void ProjectTabWidget::openModel(QString modelText)
{
    QStringList modelsList = mpParentMainWindow->mpOMCProxy->parseString(modelText);
    if (modelsList.size() == 0)
    {
        QString message = QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_MODEL).append(" ").arg(modelText))
                          .append("\n").append(mpParentMainWindow->mpOMCProxy->getErrorString());
        mpParentMainWindow->mpMessageWidget->printGUIErrorMessage(message);
        return;
    }

    QStringList existingmodelsList;
    bool existModel = false;
    // check if the model already exists
    foreach(QString model, modelsList)
    {
        if (mpParentMainWindow->mpOMCProxy->existClass(model))
        {
            existingmodelsList.append(model);
            existModel = true;
        }
    }

    // check if existModel is true
    if (existModel)
    {
        QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
        msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Information"));
        msgBox->setIcon(QMessageBox::Information);
        msgBox->setText(QString(GUIMessages::getMessage(GUIMessages::UNABLE_TO_LOAD_MODEL).arg("")));
        msgBox->setInformativeText(QString(GUIMessages::getMessage(GUIMessages::REDEFING_EXISTING_MODELS))
                                   .arg(existingmodelsList.join(",")).append("\n")
                                   .append(GUIMessages::getMessage(GUIMessages::DELETE_AND_LOAD)));
        msgBox->setStandardButtons(QMessageBox::Ok);
        msgBox->exec();
    }
    // if no conflicting model found then just load the file simply
    else
    {
        mpParentMainWindow->mpLibrary->loadModel(modelText, modelsList);
    }
}

//! Tells the current tab to reset zoom to 100%.
//! @see zoomIn()
//! @see zoomOut()
void ProjectTabWidget::resetZoom()
{
    ProjectTab *pCurrentTab = getCurrentTab();
    if (pCurrentTab)
    {
        if (pCurrentTab->mpDiagramGraphicsView->isVisible())
            pCurrentTab->mpDiagramGraphicsView->resetZoom();
        else if (pCurrentTab->mpIconGraphicsView->isVisible())
            pCurrentTab->mpIconGraphicsView->resetZoom();
    }
}

//! Tells the current tab to increase its zoom factor.
//! @see resetZoom()
//! @see zoomOut()
void ProjectTabWidget::zoomIn()
{
    ProjectTab *pCurrentTab = getCurrentTab();
    if (pCurrentTab)
    {
        if (pCurrentTab->mpDiagramGraphicsView->isVisible())
            pCurrentTab->mpDiagramGraphicsView->zoomIn();
        else if (pCurrentTab->mpIconGraphicsView->isVisible())
            pCurrentTab->mpIconGraphicsView->zoomIn();
    }
}

//! Tells the current tab to decrease its zoom factor.
//! @see resetZoom()
//! @see zoomIn()
void ProjectTabWidget::zoomOut()
{
    ProjectTab *pCurrentTab = getCurrentTab();
    if (pCurrentTab)
    {
        if (pCurrentTab->mpDiagramGraphicsView->isVisible())
            pCurrentTab->mpDiagramGraphicsView->zoomOut();
        else if (pCurrentTab->mpIconGraphicsView->isVisible())
            pCurrentTab->mpIconGraphicsView->zoomOut();
    }
}

void ProjectTabWidget::updateTabIndexes()
{
    for (int i = 0 ; i < count() ; i++)
    {
        (dynamic_cast<ProjectTab*>(widget(i)))->mTabPosition = i;
    }
}

void ProjectTabWidget::enableProjectToolbar()
{
    if (!mToolBarEnabled)
    {
        mpParentMainWindow->gridLinesAction->setEnabled(true);
        mpParentMainWindow->resetZoomAction->setEnabled(true);
        mpParentMainWindow->zoomInAction->setEnabled(true);
        mpParentMainWindow->zoomOutAction->setEnabled(true);
        mpParentMainWindow->flatModelAction->setEnabled(true);
        mpParentMainWindow->checkModelAction->setEnabled(true);
        // enable the shapes tool bar
        mpParentMainWindow->shapesToolBar->setEnabled(true);
        // enable the export as image action
        mpParentMainWindow->exportAsImage->setEnabled(true);
        // enable the export to omnotebook action
        mpParentMainWindow->exportToOMNotebookAction->setEnabled(true);
        mToolBarEnabled = true;
    }
}

void ProjectTabWidget::disableProjectToolbar()
{
    if (mToolBarEnabled and (count() == 0))
    {
        mpParentMainWindow->gridLinesAction->setEnabled(false);
        mpParentMainWindow->resetZoomAction->setEnabled(false);
        mpParentMainWindow->zoomInAction->setEnabled(false);
        mpParentMainWindow->zoomOutAction->setEnabled(false);
        mpParentMainWindow->flatModelAction->setEnabled(false);
        mpParentMainWindow->checkModelAction->setEnabled(false);
        // disable the shapes tool bar
        mpParentMainWindow->shapesToolBar->setEnabled(false);
        // disable the export as image action
        mpParentMainWindow->exportAsImage->setEnabled(false);
        // enable the export to omnotebook action
        mpParentMainWindow->exportToOMNotebookAction->setEnabled(false);
        mToolBarEnabled = false;
    }
}

void ProjectTabWidget::keyPressEvent(QKeyEvent *event)
{
    ProjectTab *pCurrentTab = getCurrentTab();
    if (!pCurrentTab)
        return;

    if (pCurrentTab->mpModelicaEditorWidget->isVisible())
    {
        if (event->modifiers().testFlag(Qt::ControlModifier) and event->key() == Qt::Key_F)
        {
            pCurrentTab->mpModelicaEditor->mpFindWidget->show();
            pCurrentTab->mpModelicaEditor->mpSearchTextBox->setFocus();
        }
        else if (event->key() == Qt::Key_Escape)
        {
            pCurrentTab->mpModelicaEditor->mpFindWidget->hide();
        }
    }

    QTabWidget::keyPressEvent(event);
}
