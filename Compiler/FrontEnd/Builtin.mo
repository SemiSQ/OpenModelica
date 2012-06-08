/*
 * This file is part of OpenModelica.
 *
 * Copyright (c) 1998-CurrentYear, Linköping University,
 * Department of Computer and Information Science,
 * SE-58183 Linköping, Sweden.
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
 * from Linköping University, either from the above address,
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
 */

encapsulated package Builtin
" file:        Builtin.mo
  package:     Builtin
  description: Builting tyepes and variables

  RCS: $Id$

  This module defines the builtin types, variables and functions in
  Modelica.  The only exported functions are Builtin.initialEnv and
  Builtin.simpleInitialEnv.

  There are several builtin attributes defined in the builtin types, 
  such as unit, start, etc."

public import Absyn;
public import DAE;
public import Env;
public import Error;
public import SCode;

// protected imports
protected import ClassInf;
protected import Config;
protected import Debug;
protected import Flags;
protected import Global;
protected import List;
protected import Parser;
protected import SCodeUtil;
protected import Settings;
protected import System;
protected import Types;
protected import Util;

/* These imports were used in e.g. MSL 1.6. They should not be here anymore...
   If you need them, add them to the initial environment and recompile; they are not standard Modelica.
  import arcsin = asin;
  import arccos = acos;
  import arctan = atan;
  import ln = log;
*/

// Predefined DAE.Types
// Real arrays
protected constant DAE.Type T_REAL_ARRAY_DEFAULT   = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_UNKNOWN()},   DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_1_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_2_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_3_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(3)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_4_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(4)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_5_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(5)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_6_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(6)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_7_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(7)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_8_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(8)}, DAE.emptyTypeSource);
protected constant DAE.Type T_REAL_ARRAY_9_DEFAULT = DAE.T_ARRAY(DAE.T_REAL_DEFAULT, {DAE.DIM_INTEGER(9)}, DAE.emptyTypeSource);

// Integer arrays
protected constant DAE.Type T_INT_ARRAY_1_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);  
protected constant DAE.Type T_INT_ARRAY_2_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_3_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(3)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_4_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(4)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_5_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(5)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_6_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(6)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_7_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(7)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_8_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(8)}, DAE.emptyTypeSource);
protected constant DAE.Type T_INT_ARRAY_9_DEFAULT = DAE.T_ARRAY(DAE.T_INTEGER_DEFAULT, {DAE.DIM_INTEGER(9)}, DAE.emptyTypeSource);

// Boolean array
protected constant DAE.Type T_BOOL_ARRAY_1_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_2_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_3_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(3)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_4_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(4)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_5_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(5)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_6_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(6)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_7_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(7)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_8_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(8)}, DAE.emptyTypeSource);
protected constant DAE.Type T_BOOL_ARRAY_9_DEFAULT = DAE.T_ARRAY(DAE.T_BOOL_DEFAULT, {DAE.DIM_INTEGER(9)}, DAE.emptyTypeSource);

// String arrays
protected constant DAE.Type T_STRING_ARRAY_1_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_2_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(2)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_3_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(3)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_4_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(4)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_5_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(5)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_6_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(6)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_7_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(7)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_8_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(8)}, DAE.emptyTypeSource);
protected constant DAE.Type T_STRING_ARRAY_9_DEFAULT = DAE.T_ARRAY(DAE.T_STRING_DEFAULT, {DAE.DIM_INTEGER(9)}, DAE.emptyTypeSource);

protected constant DAE.Type T_UNKNOWN_ARRAY_1_DEFAULT = DAE.T_ARRAY(DAE.T_UNKNOWN_DEFAULT, {DAE.DIM_INTEGER(1)}, DAE.emptyTypeSource);

public constant SCode.Prefixes commonPrefixes = 
  SCode.PREFIXES(
    SCode.PUBLIC(), 
    SCode.NOT_REDECLARE(), 
    SCode.FINAL(), /* make everything here final! */
    Absyn.NOT_INNER_OUTER(), 
    SCode.NOT_REPLACEABLE()); 

public constant SCode.Prefixes commonPrefixesNotFinal = 
  SCode.PREFIXES(
    SCode.PUBLIC(), 
    SCode.NOT_REDECLARE(), 
    SCode.NOT_FINAL(), /* make everything here final! */
    Absyn.NOT_INNER_OUTER(), 
    SCode.NOT_REPLACEABLE()); 

protected
constant SCode.Attributes attrConst = SCode.ATTR({},SCode.NOT_FLOW(),SCode.NOT_STREAM(),SCode.NON_PARALLEL(),SCode.CONST(),Absyn.BIDIR()); 
constant SCode.Attributes attrParam = SCode.ATTR({},SCode.NOT_FLOW(),SCode.NOT_STREAM(),SCode.NON_PARALLEL(),SCode.PARAM(),Absyn.BIDIR());
constant SCode.Attributes attrParamVectorNoDim = SCode.ATTR({Absyn.NOSUB()},SCode.NOT_FLOW(),SCode.NOT_STREAM(),SCode.NON_PARALLEL(),SCode.PARAM(),Absyn.BIDIR());
/*
- The primitive types
  These are the primitive types that are used to build the types
  `Real\', `Integer\' etc.
*/
public constant SCode.Element rlType = SCode.CLASS("RealType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_REAL(),
          SCode.PARTS({},{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) " real type ";

public constant SCode.Element intType = SCode.CLASS("IntegerType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_INTEGER(),
          SCode.PARTS({},{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

public constant SCode.Element strType = SCode.CLASS("StringType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_STRING(),
          SCode.PARTS({},{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

public constant SCode.Element boolType = SCode.CLASS("BooleanType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_BOOLEAN(),
          SCode.PARTS({},{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

protected constant SCode.Element enumType = SCode.CLASS("EnumType",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_ENUMERATION(),
          SCode.PARTS({},{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo);

protected constant SCode.Element unit = SCode.COMPONENT("unit",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false)), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo) "This `unit\' component is used in several places below, and it is
  declared once here to make the definitions below easier to read." ;

protected constant SCode.Element quantity = SCode.COMPONENT("quantity",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false)), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element displayUnit = SCode.COMPONENT("displayUnit",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false)), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element min = SCode.COMPONENT("min",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.REAL(-1e+099),false)), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element max = SCode.COMPONENT("max",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.REAL(1e+099),false)), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element realStart = SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.REAL(0.0),false)), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element integerStart = SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("IntegerType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.INTEGER(0),false)), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element stringStart = SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StringType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.STRING(""),false)), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element booleanStart = SCode.COMPONENT("start",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("BooleanType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.BOOL(false),false)), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element fixed = SCode.COMPONENT("fixed",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("BooleanType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},SOME((Absyn.BOOL(false),false)), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo) "Should be true for variables" ;

protected constant SCode.Element nominal = SCode.COMPONENT("nominal",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("RealType"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},NONE(), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo);

protected constant SCode.Element stateSelect = SCode.COMPONENT("stateSelect",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("StateSelect"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},
          SOME((
          Absyn.CREF(
          Absyn.CREF_QUAL("StateSelect",{},Absyn.CREF_IDENT("default",{}))),false)), Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo);

/* Extensions for uncertainties */          
protected constant SCode.Element uncertainty=SCode.COMPONENT("uncertain",commonPrefixes,
          attrParam,Absyn.TPATH(Absyn.IDENT("Uncertainty"),NONE()),
          SCode.MOD(SCode.NOT_FINAL(),SCode.NOT_EACH(),{},
          SOME((Absyn.CREF(Absyn.CREF_QUAL("Uncertainty",{},Absyn.CREF_IDENT("given",{}))),false)),Absyn.dummyInfo),NONE(),NONE(),Absyn.dummyInfo);            

protected constant SCode.Element distribution = SCode.COMPONENT("distribution",commonPrefixes,attrParam,Absyn.TPATH(Absyn.IDENT("Distribution"),NONE()),
          SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo); // Distribution is declared in ModelicaBuiltin.mo
/* END Extensions for uncertainties */

protected constant list<SCode.Element> stateSelectComps = {
          SCode.COMPONENT("never",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("avoid",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("default",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("prefer",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("always",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo)} "The StateSelect enumeration" ;

protected constant list<SCode.Element> uncertaintyComps = {
          SCode.COMPONENT("given",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("sought",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo),
          SCode.COMPONENT("refine",commonPrefixes,
          attrConst,Absyn.TPATH(Absyn.IDENT("EnumType"),NONE()),SCode.NOMOD(),NONE(),NONE(),Absyn.dummyInfo)} "The Uncertainty enumeration" ;

protected constant SCode.Element stateSelectType = SCode.CLASS("StateSelect",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_ENUMERATION(),
          SCode.PARTS(stateSelectComps,{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "The State Select Type";

protected constant SCode.Element uncertaintyType = SCode.CLASS("Uncertainty",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_ENUMERATION(),
          SCode.PARTS(uncertaintyComps,{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "The Uncertainty Type";
          
public constant SCode.Element ExternalObjectType = SCode.CLASS("ExternalObject",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_CLASS(),
          SCode.PARTS({},{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "ExternalObject type" ;

public constant SCode.Element realType = SCode.CLASS("Real",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_REAL(),
          SCode.PARTS({unit,quantity,displayUnit,min,max,realStart,fixed,nominal,
          stateSelect,uncertainty,distribution},{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `Real\' type" ;

protected constant SCode.Element integerType = SCode.CLASS("Integer",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_INTEGER(),
          SCode.PARTS({quantity,min,max,integerStart,fixed,uncertainty,distribution},{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `Integer\' type" ;

protected constant SCode.Element stringType = SCode.CLASS("String",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_STRING(),
          SCode.PARTS({quantity,stringStart},{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `String\' type" ;

protected constant SCode.Element booleanType = SCode.CLASS("Boolean",commonPrefixes,SCode.NOT_ENCAPSULATED(),SCode.NOT_PARTIAL(),SCode.R_PREDEFINED_BOOLEAN(),
          SCode.PARTS({quantity,booleanStart,fixed},{},{},{},{},{},{},NONE(),{},NONE()),Absyn.dummyInfo) "- The `Boolean\' type" ;

/* The builtin variable time. See also variableIsBuiltin */
protected constant DAE.Var timeVar = DAE.TYPES_VAR("time",
          DAE.ATTR(SCode.NOT_FLOW(),SCode.NOT_STREAM(),SCode.NON_PARALLEL(),SCode.VAR(),Absyn.INPUT(),Absyn.NOT_INNER_OUTER(), SCode.PUBLIC()),
          DAE.T_REAL_DEFAULT,DAE.UNBOUND(),NONE()) "- The `time\' variable" ;

protected constant DAE.Type stringIntInt2string = 
          DAE.T_FUNCTION(
              {
              ("x",DAE.T_STRING_DEFAULT,DAE.C_VAR(),NONE()),
              ("y",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE()),
              ("z",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE())
              },
              DAE.T_STRING_DEFAULT,
              DAE.FUNCTION_ATTRIBUTES_BUILTIN,
              DAE.emptyTypeSource);

protected constant DAE.Type real2real = 
          DAE.T_FUNCTION(
            {("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_REAL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type realReal2real = 
          DAE.T_FUNCTION(
            {("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE()),
             ("y",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_REAL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type int2int = 
          DAE.T_FUNCTION(
            {("x",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type int2bool = 
          DAE.T_FUNCTION(
            {("x",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_BOOL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type enumeration2int = 
          DAE.T_FUNCTION(
            {("x",DAE.T_ENUMERATION(NONE(), Absyn.IDENT(""), {}, {}, {}, DAE.emptyTypeSource),DAE.C_VAR(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type intInt2int = 
          DAE.T_FUNCTION(
            {("x",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE()),
             ("y",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type intInt2bool = 
          DAE.T_FUNCTION(
            {("x",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE()),
             ("y",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_BOOL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type bool2bool = 
          DAE.T_FUNCTION(
            {("x",DAE.T_BOOL_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_BOOL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type real2bool = 
          DAE.T_FUNCTION(
            {("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_BOOL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type realReal2bool = 
          DAE.T_FUNCTION(
            {("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE()),
             ("y",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_BOOL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type realRealReal2Real =
          DAE.T_FUNCTION(
            {("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE()),
             ("y",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE()),
             ("z",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_REAL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type anyNonExpandableConnector2int =
          DAE.T_FUNCTION(
            {("x", DAE.T_ANYTYPE(SOME(ClassInf.CONNECTOR(Absyn.IDENT("$dummy$"),false)),DAE.emptyTypeSource),DAE.C_VAR(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type anyExpandableConnector2int =
          DAE.T_FUNCTION(
            {("x",DAE.T_ANYTYPE(SOME(ClassInf.CONNECTOR(Absyn.IDENT("$dummy$"),true)),DAE.emptyTypeSource),DAE.C_VAR(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type vectorVector2int = 
          DAE.T_FUNCTION(
            {("x",T_INT_ARRAY_1_DEFAULT,DAE.C_VAR(),NONE()),
             ("y",T_INT_ARRAY_1_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type vectorVector2real = 
          DAE.T_FUNCTION(
            {("x", T_REAL_ARRAY_1_DEFAULT,DAE.C_VAR(),NONE()),
             ("y", T_REAL_ARRAY_1_DEFAULT,DAE.C_VAR(),NONE())}, 
            DAE.T_REAL_DEFAULT, 
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type intInt2vectorreal = 
          DAE.T_FUNCTION(
            {("x",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE()),
             ("y",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE())},
            T_REAL_ARRAY_1_DEFAULT, 
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type realRealInt2vectorreal = 
          DAE.T_FUNCTION(
            {("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE()),
             ("y",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE()),
             ("n",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE())},
            T_REAL_ARRAY_DEFAULT, 
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type array2real = 
          DAE.T_FUNCTION(
            {("x",T_INT_ARRAY_1_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_INTEGER_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource) "T_ARRAY is appearently not constant. To bad!" ;

protected constant DAE.Type int2boxed =  
          DAE.T_FUNCTION(
            {("index",DAE.T_INTEGER_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_METABOXED_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type string2string = 
          DAE.T_FUNCTION(
            {("x",DAE.T_STRING_DEFAULT,DAE.C_VAR(),NONE())},
            DAE.T_STRING_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type array1dimrealarray1dimrealarray1dimreal2array1dimreal = 
          DAE.T_FUNCTION(
            {
            ("x",T_REAL_ARRAY_1_DEFAULT,DAE.C_VAR(),NONE()),
            ("y",T_REAL_ARRAY_1_DEFAULT,DAE.C_VAR(),NONE()),
            ("z",T_REAL_ARRAY_1_DEFAULT,DAE.C_VAR(),NONE())
            },
            T_REAL_ARRAY_1_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

protected constant DAE.Type realrealreal2real = 
          DAE.T_FUNCTION(
            {
            ("x",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE()),
            ("y",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE()),
            ("z",DAE.T_REAL_DEFAULT,DAE.C_VAR(),NONE())
            },
            DAE.T_REAL_DEFAULT,
            DAE.FUNCTION_ATTRIBUTES_BUILTIN,
            DAE.emptyTypeSource);

public function variableIsBuiltin "Returns true if cref is a builtin variable.
Currently only 'time' is a builtin variable.
"
input DAE.ComponentRef cref;
output Boolean b;
algorithm
  b := match (cref)
    case(DAE.CREF_IDENT(ident="time")) then true;
    else false;
  end match;
end variableIsBuiltin;

public function isSubstring
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    case (Absyn.IDENT(name = "substring")) then ();
    case (Absyn.QUALIFIED(name = "Modelica",path = Absyn.QUALIFIED(name = "Utilities", path = Absyn.QUALIFIED(name = "Strings",path = Absyn.IDENT(name = "substring"))))) then ();
    case (Absyn.FULLYQUALIFIED(inPath)) equation isSubstring(inPath); then ();
  end match;
end isSubstring;

public function isDer
  input Absyn.Path inPath;
algorithm
  _:=
  match (inPath)
    local Absyn.Path path;
    case (Absyn.IDENT(name = "der")) then ();
    case (Absyn.FULLYQUALIFIED(path)) equation isDer(path); then ();
  end match;
end isDer;

public function simpleInitialEnv "
val array2array=  (DAE.T_FUNCTION({(\"x\",(DAE.T_ARRAY)},
              (DAE.T_ARRAY),NONE())
val array_array2array=
val int2array= (DAE.T_FUNCTION(\"x\",(DAE.T_ARRAY(1,_)),NONE())
  Specifierar en vector, array of dimension one
  zeroes, ones, fill?

val real_real_int2array
val array2real
val array_array2int

  - Initial environment
  function: simpleInitialEnv

  The initial environment where instantiation takes place is built
  up using this function.  It creates an empty environment and adds
  all the built-in types to it.

  This only creates a minimal environment, useful for debugging purposes.
"
  output list<Env.Frame> env;
algorithm
  env := Env.newEnvironment() "Debug.fprint (\"insttr\",\"Creating initial env.\\n\") &" ;
  env := Env.extendFrameC(env, rlType);
  env := Env.extendFrameC(env, intType);
  env := Env.extendFrameC(env, strType);
  env := Env.extendFrameC(env, boolType);
  env := Env.extendFrameC(env, enumType);
  env := Env.extendFrameC(env, ExternalObjectType);
  env := Env.extendFrameC(env, realType);
  env := Env.extendFrameC(env, integerType);
  env := Env.extendFrameC(env, stringType);
  env := Env.extendFrameC(env, booleanType);
  env := Env.extendFrameC(env, stateSelectType);
  env := Env.extendFrameC(env, uncertaintyType);
end simpleInitialEnv;

public function initialEnv "function: initialEnv

  The initial environment where instantiation takes place is built
  up using this function.  It creates an empty environment and adds
  all the built-in definitions to it.
  NOTE:
    The following built in operators can not be described in
    the type system, since they e.g. have arbitrary arguments, etc.
  - fill
  - cat
    These operators are catched in the elabBuiltinHandler, along with all
    others.
"
  input Env.Cache inCache;
  output Env.Cache outCache;
  output list<Env.Frame> env;
protected
  Env.Cache cache;
algorithm
  (outCache,env) := matchcontinue(inCache)
    local
      list<Absyn.Class> initialClasses;
      list<Absyn.Import> imports;

    // First look for cached version
    case (cache) equation
      env = Env.getCachedInitialEnv(cache);
    then (cache,env);
    // if no cached version found create initial env.
    case (cache) equation
      env = Env.openScope(Env.emptyEnv, SCode.NOT_ENCAPSULATED(), NONE(), NONE());
      env = Env.extendFrameC(env, rlType);
      env = Env.extendFrameC(env, intType);
      env = Env.extendFrameC(env, strType);
      env = Env.extendFrameC(env, boolType);
      env = Env.extendFrameC(env, enumType);
      env = Env.extendFrameC(env, ExternalObjectType);
      env = Env.extendFrameC(env, realType);
      env = Env.extendFrameC(env, integerType);
      env = Env.extendFrameC(env, stringType);
      env = Env.extendFrameC(env, booleanType);
      env = Env.extendFrameC(env, stateSelectType);
      env = Env.extendFrameC(env, uncertaintyType);
      env = Env.extendFrameV(env, timeVar, NONE(), Env.VAR_UNTYPED(), {}) "see also variableIsBuiltin";

      env = Env.extendFrameT(env, "cardinality", anyNonExpandableConnector2int);
      env = Env.extendFrameT(env, "cardinality", anyExpandableConnector2int);
      env = Env.extendFrameT(env, "Integer", enumeration2int);
      env = Env.extendFrameT(env, "noEvent", real2real);
      env = Env.extendFrameT(env, "constrain", realrealreal2real);
      env = Env.extendFrameT(env, "constrain", array1dimrealarray1dimrealarray1dimreal2array1dimreal);
      env = Env.extendFrameT(env, "actualStream", real2real);
      env = Env.extendFrameT(env, "inStream", real2real);
      env = Env.extendFrameT(env, "constrain", array1dimrealarray1dimrealarray1dimreal2array1dimreal);

      env = initialEnvMetaModelica(env);
      
      Absyn.PROGRAM(classes=initialClasses) = getInitialFunctions();
      env = Env.extendFrameClasses(env, listReverse(List.fold(initialClasses, SCodeUtil.translate2, {}))) "Add classes in the initial env";
      cache = Env.setCachedInitialEnv(cache,env);
    then (cache,env);
  end matchcontinue;
end initialEnv;

protected function initialEnvMetaModelica
  input list<Env.Frame> inEnv;
  output list<Env.Frame> outEnv;
algorithm
  outEnv := matchcontinue(inEnv)
    local
      list<Env.Frame> env;
    case (env)
      equation
        true = Config.acceptMetaModelicaGrammar();
        // getGlobalRoot can not be represented by a regular function...
        env = Env.extendFrameT(env, "getGlobalRoot", int2boxed);
      then env;
    case env then env;
  end matchcontinue;
end initialEnvMetaModelica;

public function getInitialFunctions
"Fetches the Absyn.Program representation of the functions (and other classes) in the initial environment"
  output Absyn.Program initialProgram;
algorithm
  initialProgram := matchcontinue ()
    local
      Boolean b;
      String msg,fileModelica,fileMetaModelica,initialFunctionStr,initialFunctionStrMM;
      list<tuple<Boolean,Absyn.Program>> assocLst;
      Option<Absyn.Program> optProgram;
      Absyn.Program initialProgram1,initialProgram2;
      list<Absyn.Class> classes,classes1,classes2;
    case ()
      equation
        failure(_ = getGlobalRoot(Global.builtinIndex));
        setGlobalRoot(Global.builtinIndex,{});
      then fail();
    case ()
      equation
        assocLst = getGlobalRoot(Global.builtinIndex);
      then Util.assoc(Config.acceptMetaModelicaGrammar(), assocLst);
    case ()
      equation
        false = Config.acceptMetaModelicaGrammar();
        fileModelica = Settings.getInstallationDirectoryPath() +& "/lib/omc/ModelicaBuiltin.mo";
        initialFunctionStr = System.readFile(fileModelica);
        initialProgram = Parser.parsebuiltinstring(initialFunctionStr, fileModelica);
        assocLst = getGlobalRoot(Global.builtinIndex);
        setGlobalRoot(Global.builtinIndex, (false,initialProgram)::assocLst);
      then initialProgram;
    case ()
      equation
        true = Config.acceptMetaModelicaGrammar();
        fileModelica = Settings.getInstallationDirectoryPath() +& "/lib/omc/ModelicaBuiltin.mo";
        fileMetaModelica = Settings.getInstallationDirectoryPath() +& "/lib/omc/MetaModelicaBuiltin.mo";
        initialFunctionStr = System.readFile(fileModelica);
        initialFunctionStrMM = System.readFile(fileMetaModelica);
        Absyn.PROGRAM(classes=classes1,within_=Absyn.TOP()) = Parser.parsebuiltinstring(initialFunctionStr, fileModelica);
        Absyn.PROGRAM(classes=classes2,within_=Absyn.TOP()) = Parser.parsebuiltinstring(initialFunctionStrMM, fileMetaModelica);
        classes = listAppend(classes1,classes2);
        initialProgram = Absyn.PROGRAM(classes,Absyn.TOP(),Absyn.dummyTimeStamp);
        assocLst = getGlobalRoot(Global.builtinIndex);
        setGlobalRoot(Global.builtinIndex, (true,initialProgram)::assocLst);
      then initialProgram;
    else
      equation
        Error.addMessage(Error.INTERNAL_ERROR, {"Builtin.getInitialFunctions failed."});
      then fail();
  end matchcontinue;
end getInitialFunctions;

end Builtin;

