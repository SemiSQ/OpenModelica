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
#include <QSizePolicy>
#include <QMap>

#include "ProjectTabWidget.h"
#include "LibraryWidget.h"
#include "mainwindow.h"

//! @class GraphicsView
//! @brief The GraphicsView class is a class which display the content of a scene of components.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsView::GraphicsView(ProjectTab *parent)
    : QGraphicsView(parent)
{
    mpParentProjectTab = parent;
    this->setFrameShape(QGraphicsView::NoFrame);
    this->setDragMode(RubberBandDrag);
    this->setInteractive(true);
    this->setEnabled(true);
    this->setAcceptDrops(true);
    this->mIsCreatingConnector = false;
    this->setMinimumSize(2000,2000);
    this->setViewportUpdateMode(QGraphicsView::FullViewportUpdate);
    this->setTransformationAnchor(QGraphicsView::AnchorUnderMouse);
    this->setSceneRect(-100.0, -100.0, 200.0, 200.0);
    this->scale(2.0, -2.0);
    this->createActions();
    this->createMenus();

    connect(mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->gridLinesAction, SIGNAL(toggled(bool)), this, SLOT(showGridLines(bool)));
}

void GraphicsView::drawBackground(QPainter *painter, const QRectF &rect)
{
    // Draw Gradient Background
    Q_UNUSED(rect);
    QRectF rectangle (-500.0, -500.0, 1000.0, 1000.0);

    QLinearGradient gradient(rectangle.topLeft(), rectangle.bottomRight());
    gradient.setColorAt(0, Qt::lightGray);
    gradient.setColorAt(1, Qt::gray);
    painter->fillRect(rectangle, gradient);
    painter->setPen(Qt::NoPen);
    painter->setBrush(gradient);
    painter->drawRect(rectangle);

    // draw scene rectangle
    painter->setPen(Qt::black);
    painter->setBrush(QBrush(Qt::white, Qt::SolidPattern));
    painter->drawRect(this->sceneRect());

    //! @todo Grid Lines changes when resize the window. Update it.
    if (mpParentProjectTab->mpParentProjectTabWidget->mShowLines)
    {
        painter->scale(1.0, -1.0);
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
    // draw scene rectangle again without brush
    painter->setPen(Qt::black);
    painter->setBrush(Qt::NoBrush);
    painter->drawRect(this->sceneRect());
}

//! Defines what happens when moving an object in a GraphicsView.
//! @param event contains information of the drag operation.
void GraphicsView::dragMoveEvent(QDragMoveEvent *event)
{

}

//! Defines what happens when drop an object in a GraphicsView.
//! @param event contains information of the drop operation.
void GraphicsView::dropEvent(QDropEvent *event)
{
    QTreeWidget *tree = dynamic_cast<QTreeWidget *>(event->source());
    QTreeWidgetItem *item = tree->currentItem();

    if (item->text(0).isEmpty())
        event->ignore();

    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    if (!pMainWindow->mpOMCProxy->isWhat(StringHandler::PACKAGE, item->toolTip(0)))
    {
        // Check if the icon is already loaded.
        IconAnnotation *oldIcon = pMainWindow->mpLibrary->getGlobalIconObject(item->toolTip(0));
        IconAnnotation *newIcon;
        QString iconName = getUniqueIconName(item->text(0).toLower());

        if (oldIcon == NULL)
        {
            QString result = pMainWindow->mpOMCProxy->getIconAnnotation(item->toolTip(0));
            newIcon = new IconAnnotation(result, iconName, item->toolTip(0), mapToScene(event->pos()),
                                         pMainWindow->mpOMCProxy, this->mpParentProjectTab->mpGraphicsScene, this);
            addIconObject(newIcon);
        }
        else
        {
            newIcon = new IconAnnotation(oldIcon, iconName, mapToScene(event->pos()),
                                         this->mpParentProjectTab->mpGraphicsScene, this);
            addIconObject(newIcon);
        }
        event->accept();
    }
    else
        event->ignore();
}

Connector* GraphicsView::getConnector()
{
    return this->mpConnector;
}

void GraphicsView::addIconObject(IconAnnotation *icon)
{
    MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
    // Add the component to model in OMC Global Scope.
    pMainWindow->mpOMCProxy->addComponent(icon->getName(), icon->getClassName(),
                                          mpParentProjectTab->mModelNameStructure);
    // Add component annotation.
    pMainWindow->mpOMCProxy->updateComponent(icon->getName(), icon->getClassName(),
                                             mpParentProjectTab->mModelNameStructure, icon->getAnnotationString());
    // add the component to local list.
    mIconsList.append(icon);
}

void GraphicsView::deleteIconObject(IconAnnotation *icon)
{
    // First Remove the Connector associated to this icon
    int i = 0;
    while(i != mConnectorVector.size())
    {
        if((mConnectorVector[i]->getStartComponent()->getParentIcon()->getName() == icon->getName()) or
           (mConnectorVector[i]->getEndComponent()->getParentIcon()->getName() == icon->getName()))
        {
            this->removeConnector(mConnectorVector[i]);
            i = 0;   //Restart iteration if map has changed
        }
        else
        {
            ++i;
        }
    }
    // remove the icon now
    mIconsList.removeOne(icon);
    mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->deleteComponent(icon->getName(), mpParentProjectTab->mModelNameStructure);
}

QString GraphicsView::getUniqueIconName(QString iconName, int number)
{
    QString name;
    name = iconName + QString::number(number);

    foreach (IconAnnotation *icon, mIconsList)
    {
        if (icon->getName() == name)
        {
            name = getUniqueIconName(iconName, ++number);
            break;
        }
    }
    return name;
}

bool GraphicsView::checkIconName(QString iconName)
{
    foreach (IconAnnotation *icon, mIconsList)
    {
        if (icon->getName() == iconName)
        {
            return false;
        }
    }

    return true;
}

//! Defines what happens when the mouse is moving in a GraphicsView.
//! @param event contains information of the mouse moving operation.
void GraphicsView::mouseMoveEvent(QMouseEvent *event)
{
    QGraphicsView::mouseMoveEvent(event);

    //If creating connector, the end port shall be updated to the mouse position.
    if (this->mIsCreatingConnector)
    {
        mpConnector->updateEndPoint(this->mapToScene(event->pos()));
        mpConnector->drawConnector();
    }
}

//! Defines what happens when clicking in a GraphicsView.
//! @param event contains information of the mouse click operation.
void GraphicsView::mousePressEvent(QMouseEvent *event)
{
    if ((event->button() == Qt::LeftButton) && (this->mIsCreatingConnector))
    {
        mpConnector->addPoint(this->mapToScene(event->pos()));
    }
    QGraphicsView::mousePressEvent(event);
}

void GraphicsView::keyPressEvent(QKeyEvent *event)
{
    if (event->key() == Qt::Key_Delete)
    {
        emit keyPressDelete();
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
    connect(mpCancelConnectionAction, SIGNAL(triggered()), SLOT(removeConnector()));    
    // Icon Rotate ClockWise Action
    mpRotateIconAction = new QAction(QIcon(":/Resources/icons/rotateclockwise.png"),
                                    tr("Rotate Clockwise"), this);
    mpRotateIconAction->setShortcut(QKeySequence("Ctrl+r"));
    // Icon Rotate Anti-ClockWise Action
    mpRotateAntiIconAction = new QAction(QIcon(":/Resources/icons/rotateanticlockwise.png"),
                                        tr("Rotate Anticlockwise"), this);
    mpRotateAntiIconAction->setShortcut(QKeySequence("Ctrl+Shift+r"));
    // Icon Reset Rotation Action
    mpResetRotation = new QAction(tr("Reset Rotation"), this);
    // Icon Delete Action
    mpDeleteIconAction = new QAction(QIcon(":/Resources/icons/delete.png"), tr("Delete"), this);
    mpDeleteIconAction->setShortcut(QKeySequence::Delete);
}

void GraphicsView::createMenus()
{

}

void GraphicsView::contextMenuEvent(QContextMenuEvent *event)
{
    if (mIsCreatingConnector)
    {
        QMenu menu(this);
        mpCancelConnectionAction->setText("Cancel Connection");
        menu.addAction(mpCancelConnectionAction);
        menu.exec(event->globalPos());
    }
    QGraphicsView::contextMenuEvent(event);
}

//! Begins creation of connector or complete creation of connector depending on the mIsCreatingConnector flag.
//! @param pPort is a pointer to the clicked port, either start or end depending on the mIsCreatingConnector flag.
//! @param doNotRegisterUndo is true if the added connector shall not be registered in the undo stack, for example if this function is called by a redo function.
void GraphicsView::addConnector(ComponentAnnotation *pComponent)
{
    //When clicking start port
    if (!mIsCreatingConnector)
    {
        QPointF startPos = pComponent->mapToScene(pComponent->boundingRect().center());

        this->mpConnector = new Connector(pComponent, this);

        this->scene()->addItem(mpConnector);
        this->mIsCreatingConnector = true;
        pComponent->getParentIcon()->addConnector(this->mpConnector);

        this->mpConnector->setStartComponent(pComponent);
        this->mpConnector->addPoint(startPos);
        this->mpConnector->addPoint(startPos);
        this->mpConnector->drawConnector();
    }
    // When clicking end port
    else
    {
        ComponentAnnotation *pStartComponent = this->mpConnector->getStartComponent();
        // add the code to check if we can connect to component or not.
        MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
        QString startIconName = pStartComponent->getParentIcon()->getName();
        QString startIconCompName = pStartComponent->mpComponentProperties->getName();
        QString endIconName = pComponent->getParentIcon()->getName();
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
                if (pMainWindow->mpOMCProxy->instantiateModel(mpParentProjectTab->mModelNameStructure))
                {
                    this->mIsCreatingConnector = false;
                    QPointF newPos = pComponent->mapToScene(pComponent->boundingRect().center());
                    this->mpConnector->updateEndPoint(newPos);
                    pComponent->getParentIcon()->addConnector(this->mpConnector);
                    this->mpConnector->setEndComponent(pComponent);
                    this->mConnectorVector.append(mpConnector);
                    pMainWindow->mpMessageWidget->printGUIInfoMessage("Conncted: (" + startIconName + "." + startIconCompName +
                                                                      ", " + endIconName + "." + endIconCompName + ")");
                }
                else
                {
                    removeConnector();
                    pMainWindow->mpMessageWidget->printGUIErrorMessage(GUIMessages::getMessage(GUIMessages::INCOMPATIBLE_CONNECTORS));
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
        while(i != mConnectorVector.size())
        {
            if(mConnectorVector[i]->isActive())
            {
                this->removeConnector(mConnectorVector[i]);
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

    for(i = 0; i != mConnectorVector.size(); ++i)
    {
        if(mConnectorVector[i] == pConnector)
        {
            scene()->removeItem(pConnector);
            doDelete = true;
            break;
        }
        if(mConnectorVector.empty())
            break;
    }
    if(doDelete)
    {
        // If GUI delete is successful then remove the connection from omc as well.
        MainWindow *pMainWindow = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow;
        QString startIconName = pConnector->getStartComponent()->getParentIcon()->getName();
        QString startIconCompName = pConnector->getStartComponent()->mpComponentProperties->getName();
        QString endIconName = pConnector->getEndComponent()->getParentIcon()->getName();
        QString endIconCompName = pConnector->getEndComponent()->mpComponentProperties->getName();

        if (pMainWindow->mpOMCProxy->deleteConnection(startIconName + "." + startIconCompName,
                                                      endIconName + "." + endIconCompName,
                                                      mpParentProjectTab->mModelNameStructure))
        {
            pMainWindow->mpMessageWidget->printGUIInfoMessage("Disconncted: (" + startIconName + "." + startIconCompName +
                                                              ", " + endIconName + "." + endIconCompName + ")");
        }
        else
        {
            pMainWindow->mpMessageWidget->printGUIErrorMessage(pMainWindow->mpOMCProxy->getErrorString());
        }
        delete pConnector;
        mConnectorVector.remove(i);
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
    this->scale(2.0, 2.0);
}

//! Decreases zoom factor by 13.04% (1 - 1/1.15).
//! @see resetZoom()
//! @see zoomIn()
void GraphicsView::zoomOut()
{
    if (transform().m11() != 2.0 and transform().m22() != -2.0)
        this->scale(0.5, 0.5);
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
    foreach (IconAnnotation *icon, mIconsList)
    {
        icon->setSelected(true);
    }
}

void GraphicsView::saveModelAnnotation()
{
    // get the canvase positions
    int canvasXStart = -((int)sceneRect().width() / 2);
    int canvasYStart = -((int)sceneRect().height() / 2);
    int canvasXEnd = ((int)sceneRect().width() / 2);
    int canvasYEnd = ((int)sceneRect().height() / 2);

    // create the annotation string
    QString annotationString = "annotate=Diagram(";
    annotationString.append("coordinateSystem=CoordinateSystem(extent={{");
    annotationString.append(QString::number(canvasXStart)).append(", ");
    annotationString.append(QString::number(canvasYStart)).append("}, {");
    annotationString.append(QString::number(canvasXEnd)).append(", ");
    annotationString.append(QString::number(canvasYEnd)).append("}}))");

    // Send the annotation to OMC
    OMCProxy *pOMCProcy = mpParentProjectTab->mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy;
    pOMCProcy->addClassAnnotation(mpParentProjectTab->mModelNameStructure, annotationString);
}

//! @class GraphicsScene
//! @brief The GraphicsScene class is a container for graphicsl components in a simulationmodel.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
GraphicsScene::GraphicsScene(ProjectTab *parent)
        :   QGraphicsScene(parent)
{
    mpParentProjectTab = parent;
    setItemIndexMethod(NoIndex);
    connect(this, SIGNAL(changed( const QList<QRectF> & )),mpParentProjectTab, SLOT(hasChanged()));
}

GraphicsViewScroll::GraphicsViewScroll(GraphicsView *graphicsView, QWidget *parent)
    : QScrollArea(parent)
{
    mpGraphicsView = graphicsView;
}

void GraphicsViewScroll::scrollContentsBy(int dx, int dy)
{
    QScrollArea::scrollContentsBy(dx, dy);
    mpGraphicsView->update();
}

//! @class ProjectTab
//! @brief The ProjectTab class is a Widget to contain a simulation model

//! ProjectTab contains a drawing space to create models.

//! Constructor.
//! @param parent defines a parent to the new instanced object.
ProjectTab::ProjectTab(ProjectTabWidget *parent)
    : QWidget(parent)
{
    mIsSaved = true;
    mModelFileName.clear();
    mpParentProjectTabWidget = parent;

    mpGraphicsScene = new GraphicsScene(this);
    mpGraphicsView  = new GraphicsView(this);
    mpGraphicsView->setScene(mpGraphicsScene);

    mpModelicaModelButton = new QPushButton(QIcon(":/Resources/icons/model.png"), tr("Modeling"), this);
    mpModelicaModelButton->setIconSize(QSize(25, 25));
    mpModelicaModelButton->setObjectName(tr("ModelicaModelButton"));
    mpModelicaModelButton->setCheckable(true);
    mpModelicaModelButton->setChecked(true);
    connect(mpModelicaModelButton, SIGNAL(clicked()), this, SLOT(showModelicaModel()));

    mpModelicaTextButton = new QPushButton(QIcon(":/Resources/icons/modeltext.png") ,tr("Model Text"), this);
    mpModelicaTextButton->setIconSize(QSize(25, 25));
    mpModelicaTextButton->setCheckable(true);
    mpModelicaTextButton->setObjectName(tr("ModelicaTextButton"));
    connect(mpModelicaTextButton, SIGNAL(clicked()), this, SLOT(showModelicaText()));

    mpModelicaEditor = new ModelicaEditor(this);
    mpModelicaEditor->hide();

    mpViewScrollArea = new GraphicsViewScroll(mpGraphicsView);
    mpViewScrollArea->setWidget(mpGraphicsView);
    //mpViewScrollArea->ensureVisible(1050, 1220);
    mpViewScrollArea->ensureVisible(mpGraphicsView->rect().center().x(), mpGraphicsView->rect().center().y(), 100, 272);
    mpViewScrollArea->setWidgetResizable(true);

    QHBoxLayout *layout = new QHBoxLayout();
    layout->setContentsMargins(0, 0, 0, 0);
    layout->setAlignment(Qt::AlignRight);
    layout->addWidget(mpModelicaModelButton);
    layout->addWidget(mpModelicaTextButton);

    QVBoxLayout *tabLayout = new QVBoxLayout;
    tabLayout->setContentsMargins(2, 2, 2, 0);
    tabLayout->addWidget(mpViewScrollArea);
    tabLayout->addWidget(mpModelicaEditor);
    tabLayout->addItem(layout);
    setLayout(tabLayout);

    connect(this, SIGNAL(disableMainWindow(bool)),
            mpParentProjectTabWidget->mpParentMainWindow, SLOT(disableMainWindow(bool)));
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

void ProjectTab::addChildModel(ProjectTab *model)
{
    mChildModelsList.append(model);
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
    if (mIsSaved)
    {
        QString tabName = mpParentProjectTabWidget->tabText(mpParentProjectTabWidget->currentIndex());

        tabName.append("*");
        mpParentProjectTabWidget->setTabText(mpParentProjectTabWidget->currentIndex(), tabName);

        mIsSaved = false;
    }
}

void ProjectTab::showModelicaModel()
{
    // Enable the main window
    emit disableMainWindow(false);
    mpModelicaModelButton->setChecked(true);
    mpModelicaTextButton->setChecked(false);
    mpModelicaEditor->hide();
    mpViewScrollArea->show();
}

void ProjectTab::showModelicaText()
{
    // Disable the main window
    emit disableMainWindow(true);

    mpModelicaModelButton->setChecked(false);
    mpModelicaTextButton->setChecked(true);
    mpViewScrollArea->hide();
    // get the modelica text of the model
    mpModelicaEditor->setText(mpParentProjectTabWidget->mpParentMainWindow->mpOMCProxy->list(mModelNameStructure));
    mpModelicaEditor->mLastValidText = mpModelicaEditor->toPlainText();
    mpModelicaEditor->show();
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
    // if a model is a root model then
    else
    {
        modelNameStructure = modelName;
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

bool ProjectTab::loadRootModel(QString model)
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    // if model text is fine then
    if (pMainWindow->mpOMCProxy->saveModifiedModel(model))
    {
        updateModel(StringHandler::removeFirstLastCurlBrackets(pMainWindow->mpOMCProxy->getResult()));
        return true;
    }
    // if there is some error in model then dont accept it
    else
        return false;
}

bool ProjectTab::loadSubModel(QString model)
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    // if model text is fine then
//    if (pMainWindow->mpOMCProxy->updateSubClass(StringHandler::removeLastWordAfterDot(mModelNameStructure), model))
//    {
        updateModel(model);
        return true;
//    }
//    // if there is some error in model then dont accept it
//    else
//        return false;
}

bool ProjectTab::ModelicaEditorTextChanged()
{
    MainWindow *pMainWindow = mpParentProjectTabWidget->mpParentMainWindow;
    QString modelName = mpModelicaEditor->getModelName();
    if (!modelName.isEmpty())
    {
        if (loadModelFromText(modelName))
            return true;
        else
            return false;
    }
    else
    {
        pMainWindow->mpOMCProxy->setResult("Unknown error occurred.");
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

    connect(mpParentMainWindow->saveAction, SIGNAL(triggered()), this,SLOT(saveProjectTab()));
    connect(mpParentMainWindow->saveAsAction, SIGNAL(triggered()), this,SLOT(saveProjectTabAs()));
    connect(this,SIGNAL(tabCloseRequested(int)),SLOT(closeProjectTab(int)));
    connect(this, SIGNAL(tabAdded()), SLOT(enableViewToolbar()));
    connect(this, SIGNAL(tabRemoved()), SLOT(disableViewToolbar()));
    emit tabRemoved();
    connect(mpParentMainWindow->resetZoomAction, SIGNAL(triggered()),this,SLOT(resetZoom()));
    connect(mpParentMainWindow->zoomInAction, SIGNAL(triggered()),this,SLOT(zoomIn()));
    connect(mpParentMainWindow->zoomOutAction, SIGNAL(triggered()),this,SLOT(zoomOut()));
    connect(mpParentMainWindow->mpLibrary->mpModelicaTree, SIGNAL(nodeDeleted()), SLOT(updateTabIndexes()));
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

//! Reimplemented function to add the Tab.
int ProjectTabWidget::addTab(ProjectTab *tab, QString tabName)
{
    int position = QTabWidget::addTab(tab, tabName);
    tab->mpGraphicsView->saveModelAnnotation();
    emit tabAdded();
    return position;
}

//! Reimplemented function to remove the Tab.
void ProjectTabWidget::removeTab(int index)
{
    QTabWidget::removeTab(index);
    emit tabRemoved();
    mpParentMainWindow->disableMainWindow(false);
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

//! Adds an existing ProjectTab object to itself.
//! @see closeProjectTab(int index)
void ProjectTabWidget::addProjectTab(ProjectTab *projectTab, QString modelName, int type)
{
    /*projectTab->setParent(this);*/
    projectTab->mIsSaved = false;
    projectTab->mModelName = modelName;
    projectTab->mModelNameStructure = modelName;
    projectTab->mType = type;
    projectTab->mTabPosition = addTab(projectTab, modelName);
    setCurrentWidget(projectTab);
}

//! Adds a ProjectTab object (a new tab) to itself.
//! @see closeProjectTab(int index)
void ProjectTabWidget::addNewProjectTab(QString modelName, QString modelStructure, int type)
{
    ProjectTab *newTab = new ProjectTab(this);
    if (getTabByName(StringHandler::removeLastWordAfterDot(modelStructure)))
    {
        newTab->mpParentModel = getTabByName(StringHandler::removeLastWordAfterDot(modelStructure));
        newTab->mpParentModel->addChildModel(newTab);
    }
    else
    {
        newTab->mpParentModel = 0;
    }
    newTab->mIsSaved = false;
    newTab->mModelName = modelName;
    newTab->mModelNameStructure = modelStructure + modelName;
    newTab->mType = type;
    newTab->mTabPosition = addTab(newTab, modelName.append(QString("*")));
    setCurrentWidget(newTab);
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
    QString tabName = tabText(index);

    if (saveAs)
    {
        saveModel(saveAs);
    }
    // if not saveAs then
    else
    {
        // if user presses ctrl + s and model is already saved
        if (pCurrentTab->mIsSaved)
        {
            //Nothing to do
        }
        // if model is not saved then save it
        else
        {
            if (saveModel(saveAs))
            {
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
        modelFileName = QFileDialog::getSaveFileName(this, tr("Save File"),
                                                             fileDialogSaveDir.currentPath(),
                                                             Helper::omFileOpenText);
        if (modelFileName.isEmpty())
        {
            return false;
        }
        else
        {
            if (pMainWindow->mpOMCProxy->setSourceFile(pCurrentTab->mModelNameStructure, modelFileName))
            {
                if (pMainWindow->mpOMCProxy->save(pCurrentTab->mModelNameStructure))
                {
                    pCurrentTab->mModelFileName = modelFileName;
                    return true;
                }
                // if OMC is unable to save the file
                else
                {
                    QMessageBox::critical(this, Helper::applicationName + " - Error",
                                         GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).
                                         arg(pMainWindow->mpOMCProxy->getResult()), tr("OK"));
                    return false;
                }
            }
            // if unable to set source file in OMC
            else
            {
                QMessageBox::critical(this, Helper::applicationName + " - Error",
                                     GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).
                                     arg(pMainWindow->mpOMCProxy->getResult()), tr("OK"));
                return false;
            }
        }
    }
    // if saving the file second time
    else
    {
        if (pMainWindow->mpOMCProxy->save(pCurrentTab->mModelNameStructure))
        {
            return true;
        }
        else
        {
            QMessageBox::critical(this, Helper::applicationName + " - Error",
                                 GUIMessages::getMessage(GUIMessages::ERROR_OCCURRED).
                                 arg(pMainWindow->mpOMCProxy->getResult()), tr("OK"));
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
        msgBox->setText(QString("The model '").append(modelName).append("'").append(QString(" is not saved.")));
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
            if (pTree->deleteNodeTriggered(pTree->getNode(pCurrentTab->mModelNameStructure)))
                removeTab(index);
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
    while(count() > 0)
    {
        setCurrentIndex(count()-1);
        if (!getCurrentTab()->mIsSaved)
        {
            QMessageBox *msgBox = new QMessageBox(mpParentMainWindow);
            msgBox->setWindowTitle(QString(Helper::applicationName).append(" - Question"));
            msgBox->setIcon(QMessageBox::Question);
            msgBox->setText(QString("There are unsaved models opened. Do you still want to quit?"));
            msgBox->setStandardButtons(QMessageBox::Yes | QMessageBox::No);
            msgBox->setDefaultButton(QMessageBox::No);

            int answer = msgBox->exec();

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
void ProjectTabWidget::loadModel()
{
    QString fileName = QFileDialog::getOpenFileName(this, tr("Choose File"),
                                                    QDir::currentPath() + QString("/../.."),
                                                    Helper::omFileOpenText);
    if (fileName.isEmpty())
        return;

    this->mpParentMainWindow->mpLibrary->loadModel(fileName);
}

//! Tells the current tab to reset zoom to 100%.
//! @see zoomIn()
//! @see zoomOut()
void ProjectTabWidget::resetZoom()
{
    this->getCurrentTab()->mpGraphicsView->resetZoom();
}

//! Tells the current tab to increase its zoom factor.
//! @see resetZoom()
//! @see zoomOut()
void ProjectTabWidget::zoomIn()
{
    this->getCurrentTab()->mpGraphicsView->zoomIn();
}

//! Tells the current tab to decrease its zoom factor.
//! @see resetZoom()
//! @see zoomIn()
void ProjectTabWidget::zoomOut()
{
    this->getCurrentTab()->mpGraphicsView->zoomOut();
}

void ProjectTabWidget::updateTabIndexes()
{
    for (int i = 0 ; i < count() ; i++)
    {
        (dynamic_cast<ProjectTab*>(widget(i)))->mTabPosition = i;
    }
}

void ProjectTabWidget::enableViewToolbar()
{
    if (!mToolBarEnabled)
    {
        mpParentMainWindow->gridLinesAction->setEnabled(true);
        mpParentMainWindow->resetZoomAction->setEnabled(true);
        mpParentMainWindow->zoomInAction->setEnabled(true);
        mpParentMainWindow->zoomOutAction->setEnabled(true);
        mToolBarEnabled = true;
    }
}

void ProjectTabWidget::disableViewToolbar()
{
    if (mToolBarEnabled and (count() == 0))
    {
        mpParentMainWindow->gridLinesAction->setEnabled(false);
        mpParentMainWindow->resetZoomAction->setEnabled(false);
        mpParentMainWindow->zoomInAction->setEnabled(false);
        mpParentMainWindow->zoomOutAction->setEnabled(false);
        mToolBarEnabled = false;
    }
}
