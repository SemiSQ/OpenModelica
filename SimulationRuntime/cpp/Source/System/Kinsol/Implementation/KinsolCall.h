
#pragma once

#include "System/Interfaces/IAlgLoop.h"       // Interface to AlgLoop
#include "System/Interfaces/IAlgLoopSolver.h"   // Export function from dll

#include "System/Kinsol/Interfaces/IKinsolSettings.h"
#include<kinsol.h>
#include<nvector_serial.h>
#include<kinsol_dense.h>

#include<kinsol_spgmr.h>



class KinsolCall : public IAlgLoopSolver
{
public:

  KinsolCall(IAlgLoop* algLoop,IKinsolSettings* settings);

  virtual ~KinsolCall();

  /// (Re-) initialize the solver
  virtual void init();

  /// Solution of a (non-)linear system of equations
  virtual void solve(const IContinous::UPDATE command = IContinous::UNDEF_UPDATE);

  /// Returns the status of iteration
  virtual ITERATIONSTATUS getIterationStatus();
  

private:
  /// Encapsulation of determination of residuals to given unknowns
  void calcFunction(const double* y, double* residual);

  /// Encapsulation of determination of Jacobian
  void calcJacobian(); 
  int check_flag(void *flagvalue, char *funcname, int opt);
  static int kin_fCallback(N_Vector y, N_Vector fval, void *user_data);


  // Member variables
  //---------------------------------------------------------------
  IKinsolSettings
    *_kinsolSettings;     ///< Settings for the solver

  IAlgLoop
    *_algLoop;          ///< Algebraic loop to be solved

  ITERATIONSTATUS   
    _iterationStatus;     ///< Output   - Denotes the status of iteration

  long int      
    _dimSys;          ///< Temp   - Number of unknowns (=dimension of system of equations)

  bool
    _firstCall;         ///< Temp   - Denotes the first call to the solver, init() is called

  double
    *_y,            ///< Temp   - Unknowns
    *_f,            ///< Temp   - Residuals
    *_yHelp,          ///< Temp   - Auxillary variables
    *_fHelp,          ///< Temp   - Auxillary variables
    *_jac;            ///< Temp   - Jacobian

  N_Vector 
    _Kin_y,           ///< Temp     - Initial values in the Sundials Format
    _Kin_yScale,
    _Kin_fScale;
  void
    *_kinMem,         ///< Temp     - Memory for the solver
    *_data;           ///< Temp     - User data. Contains pointer to KinsolCall
};
