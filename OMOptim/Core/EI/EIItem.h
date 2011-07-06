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

 	@file EIItem.h
 	@brief Comments for file documentation.
 	@author Hubert Thieriot, hubert.thieriot@mines-paristech.fr
 	Company : CEP - ARMINES (France)
 	http://www-cep.ensmp.fr/english/
 	@version 0.9 

  */
#ifndef _EIItem_H
#define _EIItem_H

#include "MOItem.h"
#include "MOVector.h"
#include "Variable.h"


#include "QtCore/QDir"
#include "LowTools.h"

#include <QtGui/QStandardItem>

namespace EI
{
	enum Type{
		GROUP,
		STREAM,
            MODELCONTAINER,
		GENERIC
	};

	enum NameFormat{
		SHORT,
		FULL
	};
};

//class EITree;

class EIItem : public MOItem
{
	Q_OBJECT

    /**
    * \brief EIItem is a class corresponding to a Energy Integration item (like a group or a stream)
    *
    * A EIItem can correspond to any energy integration item. It is inherited by specific classes (currently EIGroup or EIStream).
    * This class provides basic structure and functions of Energy Integration items.
    */

  //  friend class EITree;
protected:
        EIItem *_parent; /** if has no parent, set to NULL*/
        QList<EIItem*> _children; /** list of children */
        bool _checked; /** is this item enabled or not */
	



	//***********************
	// Functions
	//***********************
public:
	EIItem();
        EIItem(EIItem* parent,QString name);
	EIItem(const EIItem &);
        EIItem(QDomElement & domEl);
	virtual ~EIItem(void);
	virtual EI::Type getEIType(){return EI::GENERIC;};	
	virtual QString getClassName(){return "EIItem";};
	
	virtual EIItem* clone();
	QString name(EI::NameFormat = EI::FULL);


	enum Field
	{
		//Modelica fields
		NAME,
                CHECKED
	};



public:
        static const int nbFields = 2;
	virtual unsigned getNbFields(){return nbFields;};


	
	// General functions
	virtual QVariant getFieldValue(int iField, int role = Qt::UserRole) const;
	virtual bool setFieldValue(int iField, QVariant value);
	static QString sFieldName(int field, int role);
	virtual QString getFieldName(int i, int role = Qt::DisplayRole){return EIItem::sFieldName(i,role);};

	void emitModified();

	// Parent
        EIItem* parent();
	void setParent(EIItem *);

	// Tree functions
	int depth();
		
	//Checked
	bool isChecked();
	void setChecked(bool);

        //References
        virtual QStringList references();
        virtual bool numerize(MOOptVector* variables);
        virtual bool isValid(MOOptVector* variables, QString &errMsg);
        virtual QString model(); /** returns a QString if item is included in a model container*/

	//*****************************
	//Children
	//*****************************
	bool addChild(EIItem*);
	void clearDescendants();
	virtual void clear();
	int streamChildCount();
	int groupChildCount();
	int childCount() const;
        bool removeChild(int i);
        bool removeChild(EIItem *);
        bool removeDescendant(EIItem*);
        void removeUncheckedDescendants();
        int findChild(QVariant itemFieldValue, int iField);

	EIItem* child(int row) const;
	EIItem* streamChild(int row);
	EIItem* groupChild(int row);	

        int indexInParent();



	//******************************
	// GUI
	//******************************
	virtual QString getStrToolTip();

	//******************************
	// XML
	//******************************
	virtual QDomElement toXmlData(QDomDocument & doc);


signals:
	//void connectionsUpdated();
	void addedChild(EIItem*);
	void modified();
	void cleared();
        //void deleted();
};

#endif
