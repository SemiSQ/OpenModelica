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

#include <QtSvg/QSvgGenerator>
#include "PlotWindow.h"
#include "iostream"

using namespace OMPlot;

PlotWindow::PlotWindow(QStringList arguments, QWidget *parent)
    : QMainWindow(parent)
{
    // setup the main window widget
    setUpWidget();
    // initialize plot by reading all parameters passed to it
    if (arguments.size() > 1)
        initializePlot(arguments);
    // set qwtplot the central widget
    mpPlot->getPlotZoomer()->setZoomBase(false);
    setCentralWidget(getPlot());
}

PlotWindow::~PlotWindow()
{

}

void PlotWindow::setUpWidget()
{
    // create an instance of qwt plot
    mpPlot = new Plot(this);
    // set up the toolbar
    setupToolbar();
    // enable the zoom mode by default
    mpZoomButton->setChecked(true);
    // set the default values
    // set the plot title
    setTitle(tr("Plot by OpenModelica"));
    // set the plot legend
    setLegend(true);
    // set the plot grid
    setGrid(true);
    setXLabel(tr("time"));
    setMinimumHeight(250);
    setMinimumWidth(250);
}

void PlotWindow::initializePlot(QStringList arguments)
{
    // open the file
    openFile(QString(arguments[1]));

    //Set up arguments
    setTitle(QString(arguments[2]));
    if(QString(arguments[3]) == "true")
        setLegend(true);
    else if(QString(arguments[3]) == "false")
        setLegend(false);
    else
        throw PlotException("Invalid input");
    if(QString(arguments[4]) == "true")
        setGrid(true);
    else if(QString(arguments[4]) == "false")
        setGrid(false);
    else
        throw PlotException("Invalid input");
    QString plotType = arguments[5];
    if(QString(arguments[6]) == "true")
        setLogX(true);
    else if(QString(arguments[6]) == "false")
        setLogX(false);
    else
        throw PlotException("Invalid input");
    if(QString(arguments[7]) == "true")
        setLogY(true);
    else if(QString(arguments[7]) == "false")
        setLogY(false);
    else
        throw PlotException("Invalid input");
    setXLabel(QString(arguments[8]));
    setYLabel(QString(arguments[9]));
    setXRange(QString(arguments[10]).toDouble(), QString(arguments[11]).toDouble());
    setYRange(QString(arguments[12]).toDouble(), QString(arguments[13]).toDouble());
    QStringList variablesToRead;
    for(int i = 14; i < arguments.length(); i++)
        variablesToRead.append(QString(arguments[i]));

    setVariablesList(variablesToRead);

    //Plot
    if(plotType.toLower().compare("plot") == 0)
    {
        setPlotType(PlotWindow::PLOT);
        plot();
    }
    else if(plotType.toLower().compare("plotall") == 0)
    {
        setPlotType(PlotWindow::PLOTALL);
        plot();
    }
    else if(plotType.toLower().compare("plotparametric") == 0)
    {
        setPlotType(PlotWindow::PLOTPARAMETRIC);
        plotParametric();
    }
}

void PlotWindow::setVariablesList(QStringList variables)
{
    mVariablesList = variables;
}

void PlotWindow::setPlotType(PlotType type)
{
    mPlotType = type;
}

PlotWindow::PlotType PlotWindow::getPlotType()
{
    return mPlotType;
}

void PlotWindow::openFile(QString file)
{    
    //Open file to a textstream
    mFile.setFileName(file);
    if(!mFile.exists())
        throw NoFileException(QString("File not found : ").append(file).toStdString().c_str());
    mFile.open(QIODevice::ReadOnly);
    mpTextStream = new QTextStream(&mFile);
}

void PlotWindow::setupToolbar()
{
    QToolBar *toolBar = new QToolBar(this);
    setContextMenuPolicy(Qt::NoContextMenu);
    //ZOOM
    mpZoomButton = new QToolButton(toolBar);
    mpZoomButton->setText("Zoom");
    mpZoomButton->setCheckable(true);
    connect(mpZoomButton, SIGNAL(toggled(bool)), SLOT(enableZoomMode(bool)));
    toolBar->addWidget(mpZoomButton);
    toolBar->addSeparator();
    //PAN
    mpPanButton = new QToolButton(toolBar);
    mpPanButton->setText("Pan");
    mpPanButton->setCheckable(true);
    connect(mpPanButton, SIGNAL(toggled(bool)), SLOT(enablePanMode(bool)));
    toolBar->addWidget(mpPanButton);
    toolBar->addSeparator();
    //ORIGINAL SIZE
    QToolButton *originalButton = new QToolButton(toolBar);
    originalButton->setText("Original");
    connect(originalButton, SIGNAL(clicked()), SLOT(setOriginal()));
    toolBar->addWidget(originalButton);
    toolBar->addSeparator();
    //Fit in View
    QToolButton *fitInViewButton = new QToolButton(toolBar);
    fitInViewButton->setText("Fit in View");
    connect(fitInViewButton, SIGNAL(clicked()), SLOT(fitInView()));
    toolBar->addWidget(fitInViewButton);
    toolBar->addSeparator();
    // make the buttons exclusive
    QButtonGroup *pViewsButtonGroup = new QButtonGroup;
    pViewsButtonGroup->setExclusive(true);
    pViewsButtonGroup->addButton(mpZoomButton);
    pViewsButtonGroup->addButton(mpPanButton);
    //EXPORT
    QToolButton *btnExport = new QToolButton(toolBar);
    btnExport->setText("Save");
    //btnExport->setToolButtonStyle(Qt::ToolButtonTextUnderIcon);
    connect(btnExport, SIGNAL(clicked()), SLOT(exportDocument()));
    toolBar->addWidget(btnExport);
    toolBar->addSeparator();
    //PRINT
    QToolButton *btnPrint = new QToolButton(toolBar);
    btnPrint->setText("Print");
    connect(btnPrint, SIGNAL(clicked()), SLOT(printPlot()));
    toolBar->addWidget(btnPrint);
    toolBar->addSeparator();
    //GRID
    mpGridButton = new QToolButton(toolBar);
    mpGridButton->setText("Grid");
    mpGridButton->setCheckable(true);
    mpGridButton->setChecked(true);
    connect(mpGridButton, SIGNAL(toggled(bool)), SLOT(setGrid(bool)));
    toolBar->addWidget(mpGridButton);
    toolBar->addSeparator();
    //LOG x LOG y
    mpXCheckBox = new QCheckBox("Log X", this);
    connect(mpXCheckBox, SIGNAL(toggled(bool)), SLOT(setLogX(bool)));
    toolBar->addWidget(mpXCheckBox);
    toolBar->addSeparator();
    mpYCheckBox = new QCheckBox("Log Y", this);
    connect(mpYCheckBox, SIGNAL(toggled(bool)), SLOT(setLogY(bool)));
    toolBar->addWidget(mpYCheckBox);
    // finally add the tool bar to the mainwindow
    addToolBar(toolBar);
}

void PlotWindow::plot()
{
    QString currentLine;
    if (mVariablesList.isEmpty() and getPlotType() == PlotWindow::PLOT)
        throw NoVariableException(QString("No variables specified!").toStdString().c_str());

    //PLOT PLT
    if (mFile.fileName().endsWith("plt"))
    {
        // read the interval size from the file
        int intervalSize;
        while (!mpTextStream->atEnd())
        {
            currentLine = mpTextStream->readLine();
            if (currentLine.startsWith("#IntervalSize"))
            {
                intervalSize = static_cast<QString>(currentLine.split("=").last()).toInt();
                break;
            }
        }

        QStringList variablesPlotted;
        // Read variable values and plot them
        while (!mpTextStream->atEnd())
        {
            currentLine = mpTextStream->readLine();
            QString currentVariable;
            if (currentLine.contains("DataSet:"))
            {
                currentVariable = currentLine.remove("DataSet: ");
                if (mVariablesList.contains(currentVariable) or getPlotType() == PlotWindow::PLOTALL)
                {
                    variablesPlotted.append(currentVariable);
                    PlotCurve *pPlotCurve = new PlotCurve(mpPlot);
                    pPlotCurve->setFileName(QFileInfo(mFile).fileName());
                    mpPlot->addPlotCurve(pPlotCurve);
                    // read the variable values now
                    currentLine = mpTextStream->readLine();
                    for(int j = 0; j < intervalSize; j++)
                    {
                        QStringList values = currentLine.split(",");
                        pPlotCurve->addXAxisValue(QString(values[0]).toDouble());
                        pPlotCurve->addYAxisValue(QString(values[1]).toDouble());
                        currentLine = mpTextStream->readLine();
                    }
                    pPlotCurve->setTitle(currentVariable);
                    pPlotCurve->setRawData(pPlotCurve->getXAxisVector(), pPlotCurve->getYAxisVector(),
                                           pPlotCurve->getSize());
                    pPlotCurve->attach(mpPlot);
                    mpPlot->replot();
                }
                // if plottype is PLOT and we have read all the variable we need to plot then simply break the loop
                if (getPlotType() == PlotWindow::PLOT)
                    if (mVariablesList.size() == variablesPlotted.size())
                        break;
            }
        }
        // if plottype is PLOT then check which requested variables are not found in the file
        if (getPlotType() == PlotWindow::PLOT)
            checkForErrors(mVariablesList, variablesPlotted);
    }
    //PLOT CSV
    else if (mFile.fileName().endsWith("csv"))
    {
        currentLine = mpTextStream->readLine();
        currentLine.remove(QChar('"'));
        QStringList allVariablesInFile = currentLine.split(",");
        allVariablesInFile.removeLast();

        QStringList variablesPlotted;
        QVector<int> variablesToPlotIndex;
        for (int j = 0; j < allVariablesInFile.length(); j++)
        {
            if ((mVariablesList.contains(allVariablesInFile[j])) or (getPlotType() == PlotWindow::PLOTALL))
            {
                variablesToPlotIndex.push_back(j);
                variablesPlotted.append(allVariablesInFile[j]);
            }
        }

        // create plot curves
        PlotCurve *pPlotCurve[variablesToPlotIndex.size()];
        for(int i = 0; i < variablesToPlotIndex.size(); i++)
        {
            pPlotCurve[i] = new PlotCurve(mpPlot);
            pPlotCurve[i]->setFileName(QFileInfo(mFile).fileName());
            mpPlot->addPlotCurve(pPlotCurve[i]);
            pPlotCurve[i]->setTitle(allVariablesInFile.at(i));
        }

        //Assign Values
        while(!mpTextStream->atEnd())
        {
            currentLine = mpTextStream->readLine();
            QStringList values = currentLine.split(",");
            values.removeLast();

            for(int i = 0; i < variablesToPlotIndex.size(); i++)
            {
                QString valuesString = values[0];
                pPlotCurve[i]->addXAxisValue(valuesString.toDouble());
                QString valuesString2 = values[variablesToPlotIndex[i]];
                pPlotCurve[i]->addYAxisValue(valuesString2.toDouble());
            }
        }

        // plot the curves
        for(int i = 0; i < variablesToPlotIndex.size(); i++)
        {
            pPlotCurve[i]->setRawData(pPlotCurve[i]->getXAxisVector(), pPlotCurve[i]->getYAxisVector(),
                                      pPlotCurve[i]->getSize());
            pPlotCurve[i]->attach(mpPlot);
            mpPlot->replot();
        }

        // if plottype is PLOT then check which requested variables are not found in the file
        if (getPlotType() == PlotWindow::PLOT)
            checkForErrors(mVariablesList, variablesPlotted);
    }
    //PLOT MAT
    else if(mFile.fileName().endsWith("mat"))
    {
        ModelicaMatReader reader;
        ModelicaMatVariable_t *var;
        const char *msg = new char[20];
        QStringList variablesPlotted;

        //Read in mat file
        if(0 != (msg = omc_new_matlab4_reader(mFile.fileName().toStdString().c_str(), &reader)))
            return;

        //Read in timevector
        double startTime = omc_matlab4_startTime(&reader);
        double stopTime =  omc_matlab4_stopTime(&reader);
        if (reader.nvar < 1)
          throw NoVariableException("Variable doesnt exist: time");
        double *timeVals = omc_matlab4_read_vals(&reader,0);

        // read in all values
        int counter = 0;
        for (int i = 0; i < reader.nall; i++)
        {
            if (mVariablesList.contains(reader.allInfo[i].name) or getPlotType() == PlotWindow::PLOTALL)
            {
                variablesPlotted.append(reader.allInfo[i].name);
                // create the plot curve for variable
                PlotCurve *pPlotCurve = new PlotCurve(mpPlot);
                pPlotCurve->setFileName(QFileInfo(mFile).fileName());
                mpPlot->addPlotCurve(pPlotCurve);
                pPlotCurve->setTitle(reader.allInfo[i].name);
                counter++;
                // read the variable values
                var = omc_matlab4_find_var(&reader, reader.allInfo[i].name);
                // if variable is not a parameter then
                if (!var->isParam)
                {
                    double *vals = omc_matlab4_read_vals(&reader, var->index);
                    // set plot curve data and attach it to plot
                    pPlotCurve->setRawData(timeVals, vals, reader.nrows);
                    pPlotCurve->attach(mpPlot);
                    mpPlot->replot();
                }
                // if variable is a parameter then
                else
                {
                    double val;
                    if (omc_matlab4_val(&val,&reader,var,0.0))
                      throw NoVariableException(QString("Parameter doesn't have a value : ").append(reader.allInfo[i].name).toStdString().c_str());

                    pPlotCurve->addXAxisValue(startTime);
                    pPlotCurve->addYAxisValue(val);
                    pPlotCurve->addXAxisValue(stopTime);
                    pPlotCurve->addYAxisValue(val);
                    pPlotCurve->setRawData(pPlotCurve->getXAxisVector(), pPlotCurve->getYAxisVector(),
                                           pPlotCurve->getSize());
                    pPlotCurve->attach(mpPlot);
                    mpPlot->replot();
                }
            }
        }
        // if plottype is PLOT then check which requested variables are not found in the file
        if (getPlotType() == PlotWindow::PLOT)
            checkForErrors(mVariablesList, variablesPlotted);
    }
    // close the file
    mFile.close();
}

void PlotWindow::plotParametric()
{
    QString currentLine, xVariable, yVariable;
    if (mVariablesList.isEmpty())
        throw NoVariableException(QString("No variables specified!").toStdString().c_str());
    else if (mVariablesList.size() != 2)
        throw NoVariableException(QString("Please specify two variables for plotParametric.").toStdString().c_str());

    xVariable = mVariablesList.at(0);
    yVariable = mVariablesList.at(1);
    setXLabel(xVariable);
    setYLabel(yVariable);

    //PLOT PLT
    if (mFile.fileName().endsWith("plt"))
    {
        // read the interval size from the file
        int intervalSize;
        while (!mpTextStream->atEnd())
        {
            currentLine = mpTextStream->readLine();
            if (currentLine.startsWith("#IntervalSize"))
            {
                intervalSize = static_cast<QString>(currentLine.split("=").last()).toInt();
                break;
            }
        }

        QStringList variablesPlotted;
        // Read variable values and plot them
        while (!mpTextStream->atEnd())
        {
            currentLine = mpTextStream->readLine();
            QString currentVariable;
            if (currentLine.contains("DataSet:"))
            {
                currentVariable = currentLine.remove("DataSet: ");
                if (mVariablesList.contains(currentVariable))
                {
                    variablesPlotted.append(currentVariable);
                    // create plot object if first variable is found
                    PlotCurve *pPlotCurve;
                    if (variablesPlotted.size() == 1)
                    {
                        pPlotCurve = new PlotCurve(mpPlot);
                        pPlotCurve->setFileName(QFileInfo(mFile).fileName());
                        pPlotCurve->setXVariable(xVariable);
                        pPlotCurve->setYVariable(yVariable);
                        mpPlot->addPlotCurve(pPlotCurve);
                    }
                    // read the variable values now
                    currentLine = mpTextStream->readLine();
                    for(int j = 0; j < intervalSize; j++)
                    {
                        // add first variable to the xaxis vector and 2nd to yaxis vector
                        QStringList values = currentLine.split(",");
                        if (variablesPlotted.size() == 1)
                            pPlotCurve->addXAxisValue(QString(values[1]).toDouble());
                        else if (variablesPlotted.size() == 2)
                            pPlotCurve->addYAxisValue(QString(values[1]).toDouble());
                        currentLine = mpTextStream->readLine();
                    }
                    // when two variables are found plot then plot them
                    if (variablesPlotted.size() == 2)
                    {
                        pPlotCurve->setTitle(yVariable + "(" + xVariable + ")");
                        pPlotCurve->setRawData(pPlotCurve->getXAxisVector(), pPlotCurve->getYAxisVector(),
                                               pPlotCurve->getSize());
                        pPlotCurve->attach(mpPlot);
                        mpPlot->replot();
                    }
                }
                // if we have read all the variable we need to plot then simply break the loop
                if (mVariablesList.size() == variablesPlotted.size())
                    break;
            }
        }
        // check which requested variables are not found in the file
        checkForErrors(mVariablesList, variablesPlotted);
    }
    //PLOT CSV
    else if (mFile.fileName().endsWith("csv"))
    {
        currentLine = mpTextStream->readLine();
        currentLine.remove(QChar('"'));

        int xVariableIndex = 0;
        int yVariableIndex = 0;
        QStringList allVariables = currentLine.split(",");
        allVariables.removeLast();

        QStringList variablesPlotted;
        for(int j = 0; j < allVariables.length(); j++)
        {
            if(allVariables[j] == xVariable)
            {
                xVariableIndex = j;
                variablesPlotted.append(allVariables[j]);
            }
            if(allVariables[j] == yVariable)
            {
                yVariableIndex = j;
                variablesPlotted.append(allVariables[j]);
            }
        }

        // create plot curves
        PlotCurve *pPlotCurve = new PlotCurve(mpPlot);
        pPlotCurve->setFileName(QFileInfo(mFile).fileName());
        pPlotCurve->setXVariable(xVariable);
        pPlotCurve->setYVariable(yVariable);
        mpPlot->addPlotCurve(pPlotCurve);
        pPlotCurve->setTitle(yVariable + "(" + xVariable + ")");

        //Assign Values
        while(!mpTextStream->atEnd())
        {
            currentLine = mpTextStream->readLine();
            QStringList values = currentLine.split(",");
            values.removeLast();

            pPlotCurve->addXAxisValue(QString(values[xVariableIndex]).toDouble());
            pPlotCurve->addYAxisValue(QString(values[yVariableIndex]).toDouble());
        }

        pPlotCurve->setRawData(pPlotCurve->getXAxisVector(), pPlotCurve->getYAxisVector(),
                               pPlotCurve->getSize());
        pPlotCurve->attach(mpPlot);
        mpPlot->replot();
        // check which requested variables are not found in the file
        checkForErrors(mVariablesList, variablesPlotted);
    }
    //PLOT MAT
    else if(mFile.fileName().endsWith("mat"))
    {
        //Declare variables
        ModelicaMatReader reader;        
        ModelicaMatVariable_t *var;
        const char *msg = new char[20];

        //Read the .mat file
        if(0 != (msg = omc_new_matlab4_reader(mFile.fileName().toStdString().c_str(), &reader)))
            return;

        PlotCurve *pPlotCurve = new PlotCurve(mpPlot);
        pPlotCurve->setFileName(QFileInfo(mFile).fileName());
        pPlotCurve->setXVariable(xVariable);
        pPlotCurve->setYVariable(yVariable);
        mpPlot->addPlotCurve(pPlotCurve);
        //Fill variable x with data
        var = omc_matlab4_find_var(&reader, xVariable.toStdString().c_str());
        if(!var)
            throw NoVariableException(QString("Variable doesn't exist : ").append(xVariable).toStdString().c_str());
        double *xVals = omc_matlab4_read_vals(&reader,var->index);
        //Fill variable y with data
        var = omc_matlab4_find_var(&reader, yVariable.toStdString().c_str());
        if(!var)
            throw NoVariableException(QString("Variable doesn't exist : ").append(yVariable).toStdString().c_str());
        double *yVals = omc_matlab4_read_vals(&reader,var->index);
        pPlotCurve->setRawData(xVals, yVals, reader.nrows);
        pPlotCurve->setTitle(yVariable + "(" + xVariable + ")");
        pPlotCurve->attach(mpPlot);
        mpPlot->replot();
    }
    // close the file
    mFile.close();
}

void PlotWindow::setTitle(QString title)
{
    mpPlot->setTitle(title);
}

void PlotWindow::setLegend(bool on)
{
    mpPlot->getLegend()->setVisible(on);
}

void PlotWindow::setXLabel(QString label)
{
    mpPlot->setAxisTitle(QwtPlot::xBottom, label);
}

void PlotWindow::setYLabel(QString label)
{
    mpPlot->setAxisTitle(QwtPlot::yLeft, label);
}

void PlotWindow::setXRange(double min, double max)
{
    if(!(max == 0 && min == 0))
        mpPlot->setAxisScale(QwtPlot::xBottom, min, max);
}

void PlotWindow::setYRange(double min, double max)
{
    if(!(max == 0 && min == 0))
        mpPlot->setAxisScale(QwtPlot::yLeft, min, max);
}

void PlotWindow::checkForErrors(QStringList variables, QStringList variablesPlotted)
{
    QStringList nonExistingVariables;
    foreach (QString variable, variables)
    {
        if (!variablesPlotted.contains(variable))
            nonExistingVariables.append(variable);
    }
    if (!nonExistingVariables.isEmpty())
    {
        throw NoVariableException(QString("Following variable(s) are not found : ")
                                  .append(nonExistingVariables.join(",")).toStdString().c_str());
    }
}

Plot* PlotWindow::getPlot()
{
    return mpPlot;
}

QToolButton* PlotWindow::getPanButton()
{
    return mpPanButton;
}

void PlotWindow::receiveMessage(QStringList arguments)
{
    foreach (PlotCurve *pCurve, mpPlot->getPlotCurvesList())
    {
        pCurve->detach();
        mpPlot->removeCurve(pCurve);
    }
    initializePlot(arguments);
}

void PlotWindow::closeEvent(QCloseEvent *event)
{
    emit closingDown();
    event->accept();
}

void PlotWindow::enableZoomMode(bool on)
{
    mpPlot->getPlotZoomer()->setEnabled(on);
    if(on)
    {
        mpPlot->canvas()->setCursor(Qt::CrossCursor);
    }
}

void PlotWindow::enablePanMode(bool on)
{
    mpPlot->getPlotPanner()->setEnabled(on);
    if(on)

    {
        mpPlot->canvas()->setCursor(Qt::OpenHandCursor);
    }
}

void PlotWindow::exportDocument()
{
    QString fileName = QFileDialog::getSaveFileName(this, tr("Save File As"), QDir::currentPath(), tr("Image Files (*.png *.svg *.bmp *.jpg)"));

    if ( !fileName.isEmpty() )
    {
        // export svg
        if (fileName.endsWith(".svg"))
        {
            QSvgGenerator generator;
            generator.setFileName(fileName);
            generator.setSize(getPlot()->rect().size());
            getPlot()->print(generator);
        }
        // export png, bmp, jpg
        else
        {
            QPixmap pixmap(mpPlot->size());
            mpPlot->render(&pixmap);
            if (!pixmap.save(fileName)) {
              QMessageBox::critical(this, "Error", "Failed to save image " + fileName);
            }
        }
    }
}

void PlotWindow::printPlot()
{
    #if 1
        QPrinter printer;
    #else
        QPrinter printer(QPrinter::HighResolution);
        printer.setOutputFileName("OMPlot.ps");
    #endif

    printer.setDocName("OMPlot");
    printer.setCreator("Plot Window");
    printer.setOrientation(QPrinter::Landscape);

    QPrintDialog dialog(&printer);
    if ( dialog.exec() )
    {
        QwtPlotPrintFilter filter;
        if ( printer.colorMode() == QPrinter::GrayScale )
        {
            int options = QwtPlotPrintFilter::PrintAll;
            options &= ~QwtPlotPrintFilter::PrintBackground;
            options |= QwtPlotPrintFilter::PrintFrameWithScales;
            filter.setOptions(options);
        }
        mpPlot->print(printer, filter);
    }
}

void PlotWindow::setGrid(bool on)
{
    if (!on)
    {
        mpPlot->getPlotGrid()->detach();
        mpGridButton->setChecked(false);
    }
    else
    {
        mpPlot->getPlotGrid()->attach(mpPlot);
        mpGridButton->setChecked(true);
    }
    mpPlot->replot();
}

void PlotWindow::setOriginal()
{
    mpPlot->getPlotZoomer()->zoom(0);
    mpPlot->replot();
}

void PlotWindow::fitInView()
{
    mpPlot->getPlotZoomer()->zoom(0);
    mpPlot->setAxisAutoScale(QwtPlot::yLeft);
    mpPlot->setAxisAutoScale(QwtPlot::xBottom);
    mpPlot->replot();
}

void PlotWindow::setLogX(bool on)
{
    if(on)
    {
        mpPlot->setAxisScaleEngine(QwtPlot::xBottom, new QwtLog10ScaleEngine);
        mpPlot->setAxisAutoScale(QwtPlot::xBottom);
        if(!mpXCheckBox->isChecked())
            mpXCheckBox->setChecked(true);
    }
    else
    {
        mpPlot->setAxisScaleEngine(QwtPlot::xBottom, new QwtLinearScaleEngine);
        mpPlot->setAxisAutoScale(QwtPlot::xBottom);
    }
    mpPlot->replot();
}

void PlotWindow::setLogY(bool on)
{
    if(on)
    {
        mpPlot->setAxisScaleEngine(QwtPlot::yLeft, new QwtLog10ScaleEngine);
        mpPlot->setAxisAutoScale(QwtPlot::yLeft);
        if(!mpYCheckBox->isChecked())
            mpYCheckBox->setChecked(true);
    }
    else
    {
        mpPlot->setAxisScaleEngine(QwtPlot::yLeft, new QwtLinearScaleEngine);
        mpPlot->setAxisAutoScale(QwtPlot::yLeft);
    }
    mpPlot->replot();
}
