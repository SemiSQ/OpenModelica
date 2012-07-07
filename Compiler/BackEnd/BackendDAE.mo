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

encapsulated package BackendDAE
" file:        BackendDAE.mo
  package:     BackendDAE
  description: BackendDAE contains the datatypes used by the backend.

  RCS: $Id$
"

public import Absyn;
public import DAE;
public import Env;
public import SCode;
public import Values;
public import HashTable2;
public import HashTable3;
public import HashTable4;
public import HashTableCG;
public import HashTableCrILst;

public constant String partialDerivativeNamePrefix="$pDER";
public constant Integer RT_PROFILER0=6;
public constant Integer RT_PROFILER1=7;
public constant Integer RT_PROFILER2=8;
public constant Integer RT_CLOCK_EXECSTAT_BACKEND_MODULES=12;
public constant Integer RT_CLOCK_EXECSTAT_JACOBIANS=16;

public type Type = .DAE.Type 
"Once we are in BackendDAE, the Type can be only basic types or enumeration. 
 We cannot do this in DAE because functions may contain many more types.
 adrpo: yes we can, we just simplify the DAE.Type, see Types.simplifyType";

public
uniontype BackendDAEType 
"- BackendDAEType to indicate different types of BackendDAEs.
   For example for simulation, initialization, jacobian, algebraic loops etc. "
  record SIMULATION  "Type for the normal BackendDAE.DAE for simulation" 
  end SIMULATION;
  record JACOBIAN  "Type for jacobian BackendDAE.DAE" 
  end JACOBIAN;
  record ALGEQSYSTEM "Type for algebraic loop BackendDAE.DAE" 
  end ALGEQSYSTEM;
  record ARRAYSYSTEM "Type for multidim equation arrays BackendDAE.DAE" 
  end ARRAYSYSTEM;
  record PARAMETERSYSTEM "Type for parameter system BackendDAE.DAE" 
  end PARAMETERSYSTEM;    
end BackendDAEType;

public
uniontype VarKind "- Variabile kind"
  record VARIABLE end VARIABLE;
  record STATE end STATE;
  record STATE_DER end STATE_DER;
  record DUMMY_DER end DUMMY_DER;
  record DUMMY_STATE end DUMMY_STATE;
  record DISCRETE end DISCRETE;
  record PARAM end PARAM;
  record CONST end CONST;
  record EXTOBJ Absyn.Path fullClassName; end EXTOBJ;
  record JAC_VAR end JAC_VAR;
  record JAC_DIFF_VAR end JAC_DIFF_VAR; 
end VarKind;

uniontype Var "- Variables"
  record VAR
    .DAE.ComponentRef varName "varName ; variable name" ;
    VarKind varKind "varKind ; Kind of variable" ;
    .DAE.VarDirection varDirection "varDirection ; input, output or bidirectional" ;
    .DAE.VarParallelism varParallelism "parallelism of the variable. parglobal, parlocal or non-parallel";
    Type varType "varType ; builtin type or enumeration" ;
    Option< .DAE.Exp> bindExp "bindExp ; Binding expression e.g. for parameters" ;
    Option<Values.Value> bindValue "bindValue ; binding value for parameters" ;
    .DAE.InstDims arryDim "arryDim ; array dimensions on nonexpanded var" ;
    Integer index "index ; index in impl. vector" ;
    .DAE.ElementSource source "origin of variable" ;
    Option< .DAE.VariableAttributes> values "values ; values on builtin attributes" ;
    Option<SCode.Comment> comment "comment ; this contains the comment and annotation from Absyn" ;
    .DAE.Flow flowPrefix "flow ; if the variable is a flow" ;
    .DAE.Stream streamPrefix "stream ; if the variable is a stream variable. Modelica 3.1 specs" ;
  end VAR;
end Var;

public
uniontype Equation "- Equation"
  record EQUATION
    .DAE.Exp exp;
    .DAE.Exp scalar "scalar" ;
    .DAE.ElementSource source "origin of equation";
  end EQUATION;

  record ARRAY_EQUATION
    list<Integer> dimSize "dimSize ; dimension sizes" ;
    .DAE.Exp left "left ; lhs" ;
    .DAE.Exp right "right ; rhs" ;
    .DAE.ElementSource source "the element source";
  end ARRAY_EQUATION;

  record SOLVED_EQUATION
    .DAE.ComponentRef componentRef "componentRef" ;
    .DAE.Exp exp "exp" ;
    .DAE.ElementSource source "origin of equation";
  end SOLVED_EQUATION;

  record RESIDUAL_EQUATION
    .DAE.Exp exp "exp ; not present from front end" ;
    .DAE.ElementSource source "origin of equation";
  end RESIDUAL_EQUATION;

  record ALGORITHM
    Integer size "size of equation" ;
    .DAE.Algorithm alg;
    .DAE.ElementSource source "origin of algorithm";
  end ALGORITHM;
  
  record WHEN_EQUATION
    Integer size          "size of equation";
    WhenEquation whenEquation "whenEquation" ;
    .DAE.ElementSource source "origin of equation";
  end WHEN_EQUATION;

  record COMPLEX_EQUATION "complex equations: recordX = function call(x, y, ..);"
     Integer size "size of equation" ;
    .DAE.Exp left "left ; lhs" ;
    .DAE.Exp right "right ; rhs" ;
    .DAE.ElementSource source "the element source";  
  end COMPLEX_EQUATION;
  
  record IF_EQUATION " an if-equation"
    list< .DAE.Exp> conditions "Condition";
    list<list<Equation>> eqnstrue "Equations of true branch";
    list<Equation> eqnsfalse "Equations of false branch";
    .DAE.ElementSource source "origin of equation";
  end IF_EQUATION;

end Equation;

public
uniontype WhenEquation "- When Equation"
  record WHEN_EQ
    .DAE.Exp condition     "The when-condition" ;
    .DAE.ComponentRef left "Left hand side of equation" ;
    .DAE.Exp right         "Right hand side of equation" ;
    Option<WhenEquation> elsewhenPart "elsewhen equation with the same cref on the left hand side.";
  end WHEN_EQ;

end WhenEquation;

public
uniontype WhenOperator "- Reinit Statement"
  record REINIT
    .DAE.ComponentRef stateVar "State variable to reinit" ;
    .DAE.Exp value             "Value after reinit" ;
    .DAE.ElementSource source "origin of equation";
  end REINIT;

  record ASSERT
    .DAE.Exp condition;
    .DAE.Exp message;
    .DAE.ElementSource source "the origin of the component/equation/algorithm";
  end ASSERT;
  
  record TERMINATE " The Modelica builtin terminate(msg)"
    .DAE.Exp message;
    .DAE.ElementSource source "the origin of the component/equation/algorithm";
  end TERMINATE;
end WhenOperator;

public
uniontype WhenClause "- When Clause"
  record WHEN_CLAUSE
    .DAE.Exp condition                   "The when-condition" ;
    list<WhenOperator> reinitStmtLst "List of reinit statements associated to the when clause." ;
    Option<Integer> elseClause          "index of elsewhen clause" ;

  // HL only needs to know if it is an elsewhen the equations take care of which clauses are related.

    // The equations associated to the clause are linked to this when clause by the index in the
    // when clause list where this when clause is stored.
  end WHEN_CLAUSE;

end WhenClause;

public
uniontype ZeroCrossing "- Zero Crossing"
  record ZERO_CROSSING
    .DAE.Exp relation_          "function" ;
    list<Integer> occurEquLst  "List of equations where the function occurs" ;
    list<Integer> occurWhenLst "List of when clauses where the function occurs" ;
  end ZERO_CROSSING;

end ZeroCrossing;

public
uniontype EventInfo "- EventInfo"
  record EVENT_INFO
    list<WhenClause> whenClauseLst     "List of when clauses. The WhenEquation datatype refer to this list by position" ;
    list<ZeroCrossing> zeroCrossingLst "zeroCrossingLst" ;
  end EVENT_INFO;

end EventInfo;

public
uniontype BackendDAE "THE LOWERED DAE consist of variables and equations. The variables are split into
  two lists, one for unknown variables states and algebraic and one for known variables
  constants and parameters.
  The equations are also split into two lists, one with simple equations, a=b, a-b=0, etc., that
   are removed from  the set of equations to speed up calculations.

  - BackendDAE"
  record DAE
    EqSystems eqs;
    Shared shared;
  end DAE;

end BackendDAE;

uniontype Shared "Data shared for all equation-systems"
  record SHARED
    Variables knownVars "knownVars ; Known variables, i.e. constants and parameters" ;
    Variables externalObjects "External object variables";
    AliasVariables aliasVars "mappings of alias-variables to real-variables"; // added asodja 2010-03-03
    EquationArray initialEqs "initialEqs ; Initial equations" ;
    EquationArray removedEqs "these are equations that cannot solve for a variable. for example assertions, external function calls, algorithm sections without effect" ;
    array< .DAE.Constraint> constraints "constraints (Optimica extension)";
    .Env.Cache cache;
    .Env.Env env;
    .DAE.FunctionTree functionTree "functions for Backend";
    EventInfo eventInfo "eventInfo" ;
    ExternalObjectClasses extObjClasses "classes of external objects, contains constructor & destructor";
    BackendDAEType backendDAEType "indicate for what the BackendDAE is used";
    SymbolicJacobians symjacs "Symbolic Jacobians";   
  end SHARED;
end Shared;

type EqSystems = list<EqSystem> "NOTE: BackEnd does not yet support lists with different size than 1 everywhere (anywhere)";

uniontype EqSystem "An independent system of equations (and their corresponding variables)"
  record EQSYSTEM
    Variables orderedVars "orderedVars ; ordered Variables, only states and alg. vars" ;
    EquationArray orderedEqs "orderedEqs ; ordered Equations" ;
    Option<IncidenceMatrix> m;
    Option<IncidenceMatrixT> mT;
    Matching matching;
  end EQSYSTEM;
end EqSystem;

uniontype Matching
  record NO_MATCHING "matching has not yet been performed" end NO_MATCHING;
  record MATCHING "not yet used"
    array<Integer> ass1 "ass[varindx]=eqnindx";
    array<Integer> ass2 "ass[eqnindx]=varindx";
    StrongComponents comps;
  end MATCHING;
end Matching;

type ExternalObjectClasses = list<ExternalObjectClass> "classes of external objects stored in list";

uniontype ExternalObjectClass "class of external objects"
  record EXTOBJCLASS
    Absyn.Path path "className of external object";
    .DAE.ElementSource source "origin of equation";
  end EXTOBJCLASS;
end ExternalObjectClass;

public
uniontype Variables "- Variables"
  record VARIABLES
    array<list<CrefIndex>> crefIdxLstArr "crefIdxLstArr ; HashTB, cref->indx";
    VariableArray varArr "varArr ; Array of variables";
    Integer bucketSize "bucketSize ; bucket size";
    Integer numberOfVars "numberOfVars ; no. of vars";
    HashTableCrILst.HashTable fastht "cref -> list<Integer>(indxes)";
  end VARIABLES;
end Variables;

public
uniontype AliasVariables "
Data originating from removed simple equations needed to build 
variables' lookup table (in C output).

In that way, double buffering of variables in pre()-buffer, extrapolation 
buffer and results caching, etc., is avoided, but in C-code output all the 
data about variables' names, comments, units, etc. is preserved as well as 
pinter to their values (trajectories).
"
  record ALIASVARS
    HashTable2.HashTable varMappingsCref "Hashtable cref > exp";
    HashTable4.HashTable varMappingsExp  "Hashtable exp > cref";
    Variables aliasVars                  "removed variables";
  end ALIASVARS;
end AliasVariables;

uniontype AliasVariableType
  record NOALIAS end NOALIAS;
  record ALIAS end ALIAS;
  record NEGATEDALIAS end NEGATEDALIAS;
end AliasVariableType;

public
uniontype CrefIndex "- Component Reference Index"
  record CREFINDEX
    .DAE.ComponentRef cref "cref" ;
    Integer index "index" ;
  end CREFINDEX;

end CrefIndex;

public
uniontype VariableArray "array of Equations are expandable, to amortize the cost of adding
   equations in a more efficient manner

  - Variable Array"
  record VARIABLE_ARRAY
    Integer numberOfElements "numberOfElements ; no. elements" ;
    Integer arrSize "arrSize ; array size" ;
    array<Option<Var>> varOptArr "varOptArr" ;
  end VARIABLE_ARRAY;

end VariableArray;

public
uniontype EquationArray "- Equation Array"
  record EQUATION_ARRAY
    Integer size "size of the Equations in scalar form";
    Integer numberOfElement "numberOfElement ; no. elements" ;
    Integer arrSize "arrSize ; array size" ;
    array<Option<Equation>> equOptArr "equOptArr" ;
  end EQUATION_ARRAY;

end EquationArray;

public
uniontype Assignments "Assignments of variables to equations and vice versa are implemented by a
   expandable array to amortize addition of array elements more efficient
  - Assignments"
  record ASSIGNMENTS
    Integer actualSize "actualSize ; actual size" ;
    Integer allocatedSize "allocatedSize ; allocated size >= actual size" ;
    array<Integer> arrOfIndices "arrOfIndices ; array of indices" ;
  end ASSIGNMENTS;

end Assignments;

public
uniontype BinTree "Generic Binary tree implementation
  - Binary Tree"
  record TREENODE
    Option<TreeValue> value "value ; Value" ;
    Option<BinTree> leftSubTree "leftSubTree ; left subtree" ;
    Option<BinTree> rightSubTree "rightSubTree ; right subtree" ;
  end TREENODE;

end BinTree;

public
uniontype TreeValue "Each node in the binary tree can have a value associated with it.
  - Tree Value"
  record TREEVALUE
    Key key "Key" ;
    String str;
    Integer hash;
    Value value "Value" ;
  end TREEVALUE;

end TreeValue;

public
type Key = .DAE.ComponentRef "A key is a Component Reference";

public
type Value = Integer "- Value" ;

public
uniontype IndexType
  record ABSOLUTE "produce incidence matrix with absolute indexes"          end ABSOLUTE;
  record NORMAL   "produce incidence matrix with positive/negative indexes" end NORMAL;
  record SOLVABLE "procude incidence matrix with only solvable entries, for example {a,b,c}[d] then d is skipped" end SOLVABLE;
  record SPARSE   "produce incidence matrix as normal, but add for Inputs also a value" end SPARSE;
end IndexType;


public
type IncidenceMatrixElementEntry = Integer;

public
type IncidenceMatrixElement = list<IncidenceMatrixElementEntry>;

public
type IncidenceMatrix = array<IncidenceMatrixElement>;

public
type IncidenceMatrixT = IncidenceMatrix "IncidenceMatrixT : a list of equation indexes (1..n),
     one for each variable. Equations that -only-
     contain the state variable and not the derivative
     has a negative index.
- Incidence Matrix T" ;

public
uniontype Solvability 
  record SOLVABILITY_SOLVED "Equation is already solved for the variable" end SOLVABILITY_SOLVED;
  record SOLVABILITY_CONSTONE "Coefficient is equal 1 or -1" end SOLVABILITY_CONSTONE;
  record SOLVABILITY_CONST "Coefficient is constant" end SOLVABILITY_CONST;
  record SOLVABILITY_PARAMETER "Coefficient contains parameters"
    Boolean b "false if the partial derivative is zero";  
  end SOLVABILITY_PARAMETER;
  record SOLVABILITY_TIMEVARYING "Coefficient contains variables, is time varying"
    Boolean b "false if the partial derivative is zero";  
  end SOLVABILITY_TIMEVARYING;
  record SOLVABILITY_NONLINEAR "The variable occurse nonlinear in the equation." end SOLVABILITY_NONLINEAR;
  record SOLVABILITY_UNSOLVABLE "The variable occurse in the equation, but it is not posible to solve 
                     the equation for it." end SOLVABILITY_UNSOLVABLE;
end Solvability;

public
type AdjacencyMatrixElementEnhancedEntry = tuple<Integer,Solvability>;

public
type AdjacencyMatrixElementEnhanced = list<AdjacencyMatrixElementEnhancedEntry>;

public
type AdjacencyMatrixEnhanced = array<AdjacencyMatrixElementEnhanced>;

public
type AdjacencyMatrixTEnhanced = AdjacencyMatrixEnhanced;

public
uniontype JacobianType "- Jacobian Type"
  record JAC_CONSTANT "If jacobian has only constant values, for system
               of equations this means that it can be solved statically." end JAC_CONSTANT;

  record JAC_TIME_VARYING "If jacobian has time varying parts, like parameters or
                  algebraic variables" end JAC_TIME_VARYING;

  record JAC_NONLINEAR "If jacobian contains variables that are solved for,
              means that a nonlinear system of equations needs to be
              solved" end JAC_NONLINEAR;

  record JAC_NO_ANALYTIC "No analytic jacobian available" end JAC_NO_ANALYTIC;

end JacobianType;

public
uniontype IndexReduction "- Index Reduction"
  record INDEX_REDUCTION "Use index reduction during matching" end INDEX_REDUCTION;

  record NO_INDEX_REDUCTION "do not use index reduction during matching" end NO_INDEX_REDUCTION;

end IndexReduction;

public
uniontype EquationConstraints "- Equation Constraints"
  record ALLOW_UNDERCONSTRAINED "for e.g. initial eqns.
                  where not all variables
                  have a solution" end ALLOW_UNDERCONSTRAINED;

  record EXACT "exact as many equations
                   as variables" end EXACT;

end EquationConstraints;

public
type MatchingOptions = tuple<IndexReduction, EquationConstraints> "- Matching Options" ;

public
uniontype DAEHandlerJop
  record STARTSTEP end STARTSTEP;
  record REDUCE_INDEX end REDUCE_INDEX;
  record ENDSTEP end ENDSTEP;
end DAEHandlerJop;

public
type DAEHandlerArg = tuple<StateOrder,ConstraintEquations,array<list<Integer>>,array<Integer>>;

public
type StructurallySingularSystemHandlerArg = tuple<StateOrder,ConstraintEquations,array<list<Integer>>,array<Integer>> "StateOrder,ConstraintEqns,Eqn->EqnsIndxes,EqnIndex->Eqns";


public
type ConstraintEquations = list<tuple<Integer,list<Equation>>>;


public
uniontype StateOrder 
  record STATEORDER
    HashTableCG.HashTable hashTable "x -> dx";
    HashTable3.HashTable invHashTable "dx -> {x,y,z}";
  end STATEORDER;
end StateOrder;

public
uniontype StrongComponent
  record SINGLEEQUATION
    Value eqn;  
    Value var;
  end SINGLEEQUATION;
   
  record EQUATIONSYSTEM
    list<Value> eqns;
    list<Value> vars "be carefule with states, this are solved for der(x)";
    Option<list<tuple<Integer, Integer, Equation>>> jac;
    JacobianType jacType;
  end EQUATIONSYSTEM; 
  
  record MIXEDEQUATIONSYSTEM
    StrongComponent condSystem;
    list<Value> disc_eqns;
    list<Value> disc_vars;
  end MIXEDEQUATIONSYSTEM;   
  
  record SINGLEARRAY
    Value arrayIndx;
    list<Value> eqns;
    list<Value> vars "be carefule with states, this are solved for der(x)";
  end SINGLEARRAY;

  record SINGLEALGORITHM
    Value algorithmIndx;
    list<Value> eqns;
    list<Value> vars "be carefule with states, this are solved for der(x)";
  end SINGLEALGORITHM;

  record SINGLECOMPLEXEQUATION
    Value arrayIndx;
    list<Value> eqns;
    list<Value> vars "be carefule with states, this are solved for der(x)";
  end SINGLECOMPLEXEQUATION;

end StrongComponent;

public
type StrongComponents = list<StrongComponent> "- Order of the equations the have to be solved" ;

public
uniontype DivZeroExpReplace "- Should the division operator replaced by a operator with check of the denominator"
  record ALL  " check all expressions" end ALL;
  record ONLY_VARIABLES  " for expressions with variable variables(no parameters)" end ONLY_VARIABLES;
end DivZeroExpReplace;

public constant BinTree emptyBintree=TREENODE(NONE(),NONE(),NONE()) " Empty binary tree " ;


public 
type SymbolicJacobian = tuple< BackendDAE,              // symbolic equation system 
                                String,                 // Matrix name
                                list<Var>,              // diff vars
                                list<Var>,              // result diffed equation
                                list<Var>              // all diffed equation
                                >;

public
type SymbolicJacobians = list<SymbolicJacobian>;

end BackendDAE;
