#pragma once

class IAlgLoop;
class IContinous;

/*****************************************************************************/
/**

Abstract interface class for numerical methods for the (possibly iterative)
solution of algebraic loops in open modelica.

\date     October, 1st, 2008
\author   

*/
/*****************************************************************************
Copyright (c) 2008, OSMC
*****************************************************************************/
class IAlgLoopSolver
{

public:
  /// Enumeration to denote the status of iteration
  enum ITERATIONSTATUS
  {
    CONTINUE,
    SOLVERERROR,
    DONE,
  };

  virtual ~IAlgLoopSolver() {};

  /// (Re-) initialize the solver
  virtual void init() = 0;

  /// Solution of a (non-)linear system of equations
  virtual void solve(const IContinous::UPDATE command = IContinous::UNDEF_UPDATE) = 0;

  /// Returns the status of iteration
  virtual ITERATIONSTATUS getIterationStatus() = 0;

};
