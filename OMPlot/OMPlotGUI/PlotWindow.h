/*
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

//! @file   plotwindow.h
//! @author harka011
//! @date   2011-02-03

//! @brief Tool drawing 2D plot graph, supports .plt .mat .csv and plot plotParametric plotAll

#ifndef PLOTWINDOW_H
#define PLOTWINDOW_H

#include <QtGui>
#include <QtCore>

#include <qwt_plot.h>
#include <qwt_text.h>
#include <qwt_plot_curve.h>
#include <qwt_plot_picker.h>
#include <qwt_picker_machine.h>
#include <qwt_plot_grid.h>
#include <qwt_curve_fitter.h>
#include <qwt_legend.h>
#include <qwt_plot_zoomer.h>
#include <qwt_plot_panner.h>
#include <qwt_scale_engine.h>
#include <stdexcept>
#include "../../c_runtime/read_matlab4.h"
#include "Plot.h"

namespace OMPlot
{
class Plot;
class PlotCurve;

class PlotWindow : public QMainWindow
{
    Q_OBJECT
public:
    enum PlotType {PLOT, PLOTALL, PLOTPARAMETRIC};
private:
    Plot *mpPlot;
    QCheckBox *mpXCheckBox;
    QCheckBox *mpYCheckBox;
    QToolButton *mpGridButton;
    QToolButton *mpZoomButton;
    QToolButton *mpPanButton;
    QTextStream *mpTextStream;
    QFile mFile;
    QStringList mVariablesList;
    PlotType mPlotType;
public:
    PlotWindow(QStringList arguments = QStringList(), QWidget *parent = 0);
    ~PlotWindow();

    void setUpWidget();
    void initializePlot(QStringList arguments);
    void setVariablesList(QStringList variables);
    void setPlotType(PlotType type);
    PlotType getPlotType();
    void openFile(QString file);
    void setupToolbar();
    void plot();
    void plotParametric();
    void setTitle(QString title);
    void setLegend(bool on);
    void setXLabel(QString label);
    void setYLabel(QString label);
    void setXRange(double min, double max);
    void setYRange(double min, double max);
    void checkForErrors(QStringList variables, QStringList variablesPlotted);
    Plot* getPlot();
    QToolButton* getPanButton();
    void receiveMessage(QStringList arguments);
    void closeEvent(QCloseEvent *event);
signals:
    void closingDown();
public slots:
    void enableZoomMode(bool on);
    void enablePanMode(bool on);
    void exportDocument();
    void printPlot();
    void setGrid(bool on);
    void fitInView();
    void setLogX(bool on);
    void setLogY(bool on);
};

//Exception classes
class PlotException : public std::runtime_error
{
public:
    PlotException(const char *e) : std::runtime_error(e) {}
};

class NoFileException : public PlotException
{
public:
    NoFileException(const char *fileName) : PlotException(fileName) {}
private:
    const char *temp;
};

class NoVariableException : public PlotException
{
public:
    NoVariableException(const char *varName) : PlotException(varName) {}
};

//Options Class
//class Options : public QDialog
//{
//    Q_OBJECT
//public:
//    Options(PlotWindow *pPlotWindow);

//    void setUpForm();
//    void show();

//    //MainWindow *mpParentMainWindow;
//private:
//   QLineEdit *mpTitle;
//   QLineEdit *mpXLabel;
//   QLineEdit *mpYLabel;

//   QLineEdit *mpXRangeMin;
//   QLineEdit *mpXRangeMax;
//   QLineEdit *mpYRangeMin;
//   QLineEdit *mpYRangeMax;

//   QLabel *mpTitleLabel;

//   QGroupBox *mpLabelGroup;

//   QPushButton *mpOkButton;
//   QPushButton *mpCancelButton;

//   PlotWindow *mpPlotWindow;
//public slots:
//    void edit();
//};
}

#endif // PLOTWINDOW_H
