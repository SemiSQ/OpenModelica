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
 */

/*
 * tables-h
 * Author : PA
 *
 * This file contain declarations for table interpolation functions used by
 * Modelica.Blocks.Source.CombiTable. The are the equivalent implementation of Dymolas
 * functions dymTableTimeIni2, etc.
 *
 */

#ifndef _OMC_TAPLES_H
#define _OMC_TAPLES_H

#ifdef __cplusplus
extern "C"
{
#endif

extern char *model_dir; /*Model directory defined in modelname.cpp */

int omcTableTimeIni(double timeIn, double startTime,int ipoType,int expoType,
	char *tableName,char* fileName, double *table,int tableDim1,int tableDim2,int colWise);

double omcTableTimeIpo(int tableID,int icol,double timeIn);

double omcTableTimeTmax(int tableID);

double omcTableTimeTmin(int tableID);

int omcTable2DIni(int ipoType,char *tableName,char* fileName, double *table,int tableDim1,int tableDim2,int colWise);

double omcTable2DIpo(int tableID,double u1_, double u2_);


#ifdef __cplusplus
} //end extern "C"

#include <string>

class InterpolationTable {

public:
	InterpolationTable(double time,double startTime, int ipoType, int expoType,
			char* tableName, char* fileName, double *table, int tableDim1, int tableDim2,int colWise);
	InterpolationTable();
	~InterpolationTable();
	double Interpolate(double time, int col);
	double MaxTime();
	double MinTime();
	char* getTableName() {return tableName_;};
	char* getFileName() {return fileName_;};
	double* getData() {return data_;};
protected:
    void readMatFile(std::string& fileName, std::string& columnName);
    void readTextFile(std::string& fileName, std::string& columnName);
    void readCSVFile(std::string& fileName, std::string& columnName);

    bool isTableHeaderNamed(std::string line,std::string& columnName);
    bool readTableHeader(std::string line);
    double getElt(int row, int col);
    double extrapolate(double time,int col,bool beforeData);

	char* fileName_;
	char* tableName_;
	double time_;
	double startTime_;
	int ipoType_;
	int expoType_;
	int colWise_;

    double *data_;
    int nRows_;
    int nCols_;
};

class InterpolationTable2D {

public:
	InterpolationTable2D(int ipoType,
			char *tableName,char* fileName, double *table,int tableDim1,int tableDim2,int colWise);
	InterpolationTable2D();
	~InterpolationTable2D();

	double Interpolate(double u1_, double u2_);
	char* getTableName() {return tableName_;};
	char* getFileName() {return fileName_;};
	double* getData() {return data_;};
protected:
    void readMatFile(string& fileName, string& columnName);
    void readTextFile(string& fileName, string& columnName);
    void readCSVFile(string& fileName, string& columnName);

	bool isTableHeaderNamed(string line,string& columnName);
    bool readTableHeader(string line);
    double getElt(unsigned int row,unsigned int col);
	bool check_data(double u1_, double u2_);

	double min_row();
	double max_row();
	double min_col();
	double max_col();

	char* fileName_;
	char* tableName_;
	int ipoType_;

	int colWise_;

    double *data_;
    unsigned int nRows_;
    unsigned int nCols_;
};

#endif

#endif
