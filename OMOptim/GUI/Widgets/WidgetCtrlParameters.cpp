// $Id: WidgetCtrlParameters.cpp 9677 2011-08-24 13:09:00Z hubert.thieriot $
/**
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Open Source Modelica Consortium (OSMC),
 * c/o Linkpings universitet, Department of Computer and Information Science,
 * SE-58183 Linkping, Sweden.
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
 * Main contributor 2010, Hubert Thierot, CEP - ARMINES (France)

  @file WidgetCtrlParameters.cpp
  @brief Comments for file documentation.
  @author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
  Company : CEP - ARMINES (France)
  http://www-cep.ensmp.fr/english/
  @version
*/

#include "WidgetCtrlParameters.h"
#include <QtGui/QErrorMessage>


WidgetCtrlParameters::WidgetCtrlParameters(Project* project,ModModelPlus* model,ModPlusCtrls * ctrls,bool isResult,QWidget *parent)
    : QWidget(parent)
{

    _layout = new QGridLayout(this);
    _project = project;
    _isResult = isResult;

    QMap<ModModelPlus*,ModPlusCtrls *> tmpCtrls;
    tmpCtrls.insert(model,ctrls);

    update(tmpCtrls);
}

WidgetCtrlParameters::WidgetCtrlParameters(Project* project,QMap<ModModelPlus*,ModPlusCtrls *> ctrls,bool isResult,QWidget *parent)
    : QWidget(parent)
{
    _layout = new QGridLayout(this);
    _project = project;
    _isResult = isResult;
    update(ctrls);
}

void WidgetCtrlParameters::update(QMap<ModModelPlus*,ModPlusCtrls *> ctrlsMap)
{
    QList<ModModelPlus*> models = ctrlsMap.keys();


    // delete old widgets
    for(int i=0;i<_widgetsCreated.size();i++)
        delete _widgetsCreated.at(i);

    _widgetsCreated.clear();

    // clear layout
    delete _layout;
    _layout = new QGridLayout(this);
    this->setLayout(_layout);



    // empty maps
    _ctrls.clear();
    _comboBoxs.clear();
    _parametersPbs.clear();
    _compilePbs.clear();

    ModModelPlus* curmodel;
    ModPlusCtrls *curCtrls;
    int iRow;
    for(int i=0;i<models.size();i++)
    {
        curmodel = models.at(i);
        curCtrls = ctrlsMap.value(curmodel);

        // insert in _ctrls
        _ctrls.insert(curmodel,curCtrls);

        // add model combobox
        QComboBox *newCb = new QComboBox(this);
        //Ctrl box
        ModPlusCtrl::Type curCtrlType;
        ModPlusCtrl *curCtrl;

        for(int i=0;i< curCtrls->keys().size();i++)
        {
            curCtrlType = curCtrls->keys().at(i);
            curCtrl = curCtrls->value(curCtrlType);

            newCb->addItem(curCtrl->name(),curCtrlType);

            if(curCtrlType == curCtrls->currentCtrlType())
            {
                newCb->setCurrentIndex(i);
            }
        }

        newCb->setEnabled(!_isResult);
        _comboBoxs.insert(curmodel,newCb);
        iRow = _layout->rowCount()+1;
        QLabel *newLabel = new QLabel(curmodel->modModelName(),this);
        _layout->addWidget(newLabel,iRow,0);
        _layout->addWidget(newCb,iRow,1);

        // add push buttons
        QPushButton* newParamPb = new QPushButton("Parameters ...",this);
        _layout->addWidget(newParamPb,iRow,2);
        _parametersPbs.insert(curmodel,newParamPb);

        QPushButton* newCompilePb = new QPushButton("Compile",this);
        _layout->addWidget(newCompilePb,iRow,3);
        _compilePbs.insert(curmodel,newCompilePb);

        connect(newCb, SIGNAL(currentIndexChanged(int)),this, SLOT(changedCtrl()));
        connect(newParamPb, SIGNAL(clicked()),this,SLOT(openCtrlParameters()));
        connect(newCompilePb, SIGNAL(clicked()),this,SLOT(compile()));

        // horizontal spacer
        //        QSpacerItem* spacer = new QSpacerItem(10,10,QSizePolicy::Expanding,QSizePolicy::Ignored);
        //        _layout->addItem(spacer,iRow,4);
        _layout->setColumnStretch(4,10);
        _widgetsCreated.push_back(newLabel);
        _widgetsCreated.push_back(newCb);
        _widgetsCreated.push_back(newParamPb);
        _widgetsCreated.push_back(newCompilePb);
        //_widgetsCreated.push_back(spacer);
    }
}


WidgetCtrlParameters::~WidgetCtrlParameters()
{
    QString msg = "delete WidgetCtrlParameters";
    qDebug(msg.toLatin1().data());
}


void WidgetCtrlParameters::changedCtrl()
{
    // get combobox where it's coming from
    QComboBox* cb = dynamic_cast<QComboBox*>(sender());

    if(cb)
    {

        ModModelPlus* model = _comboBoxs.key(cb);
        ModPlusCtrls *modelCtrls = _ctrls.value(model,NULL);

        if(modelCtrls)
        {
            int selectedType = cb->itemData(cb->currentIndex()).toInt();
            modelCtrls->setCurrentCtrlType((ModPlusCtrl::Type)selectedType);
        }
    }
}


void WidgetCtrlParameters::openCtrlParameters()
{
    // get combobox where it's coming from
    QPushButton* pb = dynamic_cast<QPushButton*>(sender());

    if(pb)
    {

        ModModelPlus* model = _parametersPbs.key(pb);
        ModPlusCtrls *modelCtrls = _ctrls.value(model,NULL);

        if(modelCtrls)
        {
            MOParametersDlg dlg(modelCtrls->currentCtrl()->parameters(),!_isResult);
            dlg.exec();
        }
    }
}


void WidgetCtrlParameters::compile()
{
    // get combobox where it's coming from
    QPushButton* pb = dynamic_cast<QPushButton*>(sender());

    if(pb)
    {

        ModModelPlus* modelPlus = _compilePbs.key(pb);
        ModPlusCtrls *modelCtrls = _ctrls.value(modelPlus,NULL);

        if(modelCtrls)
        {
            bool compileOk = modelPlus->compile(modelCtrls->currentCtrl());

            // if compiled success, read variables
            if(compileOk)
                modelPlus->readVariables(modelCtrls->currentCtrl());
        }
    }
}


